import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/day/change_initiative.dart' as domain;
import '../db/database.dart' as db;

/// Consulta e troca a única iniciativa de mudança ativa.
final class ChangeInitiativesRepository {
  const ChangeInitiativesRepository(this._database);

  final db.RitmoDatabase _database;

  Future<domain.ChangeInitiative?> active() async {
    final row = await (_database.select(
      _database.changeInitiatives,
    )..where((initiative) => initiative.active.equals(true))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<domain.ChangeInitiative?> findById(String id) async {
    final row = await (_database.select(
      _database.changeInitiatives,
    )..where((initiative) => initiative.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<domain.ChangeInitiative>> all() async {
    final rows = await (_database.select(
      _database.changeInitiatives,
    )..orderBy([(initiative) => OrderingTerm.asc(initiative.name)])).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  /// Cria uma iniciativa e a torna ativa atomicamente.
  Future<Result<domain.ChangeInitiative, BusinessViolation>> createAndActivate({
    required String id,
    required String name,
  }) async {
    final candidate = domain.ChangeInitiative.create(id: id, name: name);
    if (candidate case Failure<domain.ChangeInitiative, BusinessViolation>(
      :final failure,
    )) {
      return Result.failure(failure);
    }
    final initiative =
        (candidate as Success<domain.ChangeInitiative, BusinessViolation>)
            .value;

    return _database.transaction(() async {
      final duplicate = await findById(initiative.id);
      if (duplicate != null) {
        return const Result.failure(
          ChangeInitiativeViolation(
            code: 'change_initiative_already_exists',
            message: 'Já existe uma iniciativa com esse identificador.',
          ),
        );
      }

      await _deactivateCurrent();
      await _database
          .into(_database.changeInitiatives)
          .insert(
            db.ChangeInitiativesCompanion.insert(
              id: initiative.id,
              name: initiative.name,
              active: const Value(true),
            ),
          );
      return Result.success(initiative);
    });
  }

  /// Ativa uma iniciativa existente e preserva todas as anteriores.
  Future<Result<domain.ChangeInitiative, ChangeInitiativeViolation>>
  changeActive(String id) {
    return _database.transaction(() async {
      final target = await findById(id);
      if (target == null) {
        return const Result.failure(
          ChangeInitiativeViolation(
            code: 'change_initiative_not_found',
            message: 'A iniciativa de mudança informada não existe.',
          ),
        );
      }
      if (target.active) return Result.success(target);

      await _deactivateCurrent();
      await (_database.update(_database.changeInitiatives)
            ..where((initiative) => initiative.id.equals(id)))
          .write(const db.ChangeInitiativesCompanion(active: Value(true)));
      return Result.success(target.withActive(true));
    });
  }

  Future<void> _deactivateCurrent() =>
      (_database.update(_database.changeInitiatives)
            ..where((initiative) => initiative.active.equals(true)))
          .write(const db.ChangeInitiativesCompanion(active: Value(false)));

  domain.ChangeInitiative _toDomain(db.ChangeInitiative row) =>
      domain.ChangeInitiative(id: row.id, name: row.name, active: row.active);
}
