import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

typedef HistoricalDatabasePopulator = void Function(Database database);
typedef TargetDatabaseOpener = Future<void> Function(File databaseFile);

typedef OperationalIdentity = ({String id, String operationalDate});

final class MigrationResult {
  const MigrationResult({required this.before, required this.after});

  final Map<String, List<OperationalIdentity>> before;
  final Map<String, List<OperationalIdentity>> after;
}

/// Recria versões históricas e valida migrações adjacentes sobre dados reais.
///
/// Cada nova versão deve adicionar seu dump em [schemaDirectory]. A partir da
/// v2, o teste abre v(n-1), chama [populate], aplica o opener do schema v(n) e
/// compara todos os pares `(id, operational_date)` existentes antes do upgrade.
final class MigrationTestHarness {
  const MigrationTestHarness({required this.schemaDirectory});

  final Directory schemaDirectory;

  File dumpFor(int version) =>
      File(p.join(schemaDirectory.path, 'schema_v$version.sql'));

  Future<T> withHistoricalDatabase<T>({
    required int version,
    required T Function(Database database) verify,
  }) async {
    final temporary = await Directory.systemTemp.createTemp(
      'ritmo-schema-v$version-',
    );
    final file = File(p.join(temporary.path, 'ritmo.sqlite'));
    Database? database;
    try {
      database = _createFromDump(file, version);
      return verify(database);
    } finally {
      database?.close();
      await temporary.delete(recursive: true);
    }
  }

  Future<MigrationResult> migrateAdjacent({
    required int fromVersion,
    required int toVersion,
    required HistoricalDatabasePopulator populate,
    required TargetDatabaseOpener openTarget,
  }) async {
    if (toVersion != fromVersion + 1) {
      throw ArgumentError.value(
        toVersion,
        'toVersion',
        'Only adjacent v(n-1) -> v(n) migrations are supported.',
      );
    }

    final temporary = await Directory.systemTemp.createTemp(
      'ritmo-migration-v$fromVersion-v$toVersion-',
    );
    final file = File(p.join(temporary.path, 'ritmo.sqlite'));
    try {
      final source = _createFromDump(file, fromVersion);
      populate(source);
      final before = _captureOperationalIdentities(source);
      source.close();

      await openTarget(file);

      final migrated = sqlite3.open(file.path);
      try {
        if (migrated.userVersion != toVersion) {
          throw StateError(
            'Expected schema v$toVersion, found v${migrated.userVersion}.',
          );
        }
        final after = _captureOperationalIdentities(
          migrated,
          tables: before.keys,
        );
        if (!_sameSnapshots(before, after)) {
          throw StateError(
            'Migration v$fromVersion -> v$toVersion lost or reclassified '
            '(id, operational_date) pairs. Before: $before; after: $after',
          );
        }
        return MigrationResult(before: before, after: after);
      } finally {
        migrated.close();
      }
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Database _createFromDump(File file, int version) {
    final dump = dumpFor(version);
    if (!dump.existsSync()) {
      throw StateError('Missing versioned schema dump: ${dump.path}');
    }
    final database = sqlite3.open(file.path);
    try {
      database.execute(dump.readAsStringSync());
      if (database.userVersion != version) {
        throw StateError(
          'Dump v$version set PRAGMA user_version=${database.userVersion}.',
        );
      }
      database.execute('PRAGMA foreign_keys = ON;');
      return database;
    } catch (_) {
      database.close();
      rethrow;
    }
  }
}

Map<String, List<OperationalIdentity>> _captureOperationalIdentities(
  Database database, {
  Iterable<String>? tables,
}) {
  final tableNames =
      tables ??
      database
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .map((row) => row['name'] as String);
  final result = <String, List<OperationalIdentity>>{};

  for (final table in tableNames) {
    final quotedTable = '"${table.replaceAll('"', '""')}"';
    final columns = database
        .select('PRAGMA table_info($quotedTable)')
        .map((row) => row['name'] as String)
        .toSet();
    if (!columns.contains('id') || !columns.contains('operational_date')) {
      continue;
    }
    result[table] = database
        .select(
          'SELECT id, operational_date FROM $quotedTable '
          'ORDER BY id, operational_date',
        )
        .map(
          (row) => (
            id: row['id'] as String,
            operationalDate: row['operational_date'] as String,
          ),
        )
        .toList(growable: false);
  }
  return result;
}

bool _sameSnapshots(
  Map<String, List<OperationalIdentity>> left,
  Map<String, List<OperationalIdentity>> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    final other = right[entry.key];
    if (other == null || entry.value.length != other.length) return false;
    for (var index = 0; index < entry.value.length; index++) {
      if (entry.value[index] != other[index]) return false;
    }
  }
  return true;
}
