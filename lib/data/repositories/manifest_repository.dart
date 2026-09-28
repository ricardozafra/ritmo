import 'package:drift/drift.dart';

import '../../domain/manifest/manifest_service.dart' as domain;
import '../db/database.dart' as db;

/// Persistência Drift da cópia local editável do manifesto.
final class DriftManifestRepository implements domain.ManifestRepository {
  const DriftManifestRepository(this._database);

  final db.RitmoDatabase _database;

  @override
  Future<domain.Manifest?> findById(String id) async {
    final row = await (_database.select(
      _database.manifests,
    )..where((manifest) => manifest.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.Manifest> insertIfAbsent(domain.Manifest manifest) {
    return _database.transaction(() async {
      await _database
          .into(_database.manifests)
          .insert(
            db.ManifestsCompanion.insert(
              id: manifest.id,
              contentMarkdown: manifest.contentMarkdown,
              assetVersion: manifest.assetVersion,
              firstCopiedAt: manifest.firstCopiedAt.millisecondsSinceEpoch,
              lastEditedAt: Value(
                manifest.lastEditedAt?.millisecondsSinceEpoch,
              ),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      final persisted = await findById(manifest.id);
      if (persisted == null) {
        throw StateError('A cópia local do manifesto não pôde ser criada.');
      }
      return persisted;
    });
  }

  @override
  Future<domain.Manifest> saveEdit({
    required String id,
    required String contentMarkdown,
    required DateTime editedAt,
  }) {
    return _database.transaction(() async {
      final updated =
          await (_database.update(
            _database.manifests,
          )..where((manifest) => manifest.id.equals(id))).write(
            db.ManifestsCompanion(
              contentMarkdown: Value(contentMarkdown),
              lastEditedAt: Value(editedAt.millisecondsSinceEpoch),
            ),
          );
      if (updated != 1) {
        throw StateError('A cópia local do manifesto não está disponível.');
      }

      final persisted = await findById(id);
      if (persisted == null) {
        throw StateError('A edição do manifesto não pôde ser recuperada.');
      }
      return persisted;
    });
  }

  domain.Manifest _toDomain(db.Manifest row) => domain.Manifest(
    id: row.id,
    contentMarkdown: row.contentMarkdown,
    assetVersion: row.assetVersion,
    firstCopiedAt: DateTime.fromMillisecondsSinceEpoch(
      row.firstCopiedAt,
      isUtc: true,
    ),
    lastEditedAt: row.lastEditedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastEditedAt!, isUtc: true),
  );
}
