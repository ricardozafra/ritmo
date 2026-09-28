import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../support/migration_test_harness.dart';

void main() {
  final harness = MigrationTestHarness(
    schemaDirectory: Directory('drift_schemas'),
  );

  test(
    'schema_v1.sql is an exact replayable dump of the fresh v1 schema',
    () async {
      final current = RitmoDatabase(NativeDatabase.memory());
      try {
        final expected = await _driftSchema(current);
        final actual = await harness.withHistoricalDatabase(
          version: 1,
          verify: _sqliteSchema,
        );

        expect(actual, expected);
        expect(
          actual.keys.where((name) => name.startsWith('table:')),
          hasLength(19),
        );
        expect(actual, contains('index:waiver_one_active_per_day'));
        expect(actual, contains('index:protocol_one_live_per_generation'));
        expect(actual, contains('index:cycle_one_active'));
        expect(actual, contains('index:initiative_one_active'));
      } finally {
        await current.close();
      }
    },
  );

  test('fresh v1 database has exact cycle seeds and enforced constraints', () async {
    final database = RitmoDatabase(NativeDatabase.memory());
    try {
      final settings = await database.select(database.settings).getSingle();
      expect(settings.syncEnabled, isFalse);
      expect(settings.sundayNotificationEnabled, isFalse);

      final cycle = await database.select(database.cycles).getSingle();
      expect(
        cycle.purposeText,
        'Nível Avançado em Strategic Thinking, Innovative e Change Advocate '
        'até Junho/2027 + consolidação de Business Acumen',
      );
      final checkpoints = await database
          .customSelect(
            'SELECT date, competency FROM checkpoints ORDER BY date',
          )
          .get();
      expect(
        checkpoints.map(
          (row) => (row.read<String>('date'), row.read<String>('competency')),
        ),
        [('2026-12-31', 'IN'), ('2027-02-28', 'ST'), ('2027-06-30', 'CA')],
      );

      await expectLater(
        database.customStatement(
          "INSERT INTO cycles (id, name, purpose_text, start_date, end_date, state) "
          "VALUES ('duplicate', 'Outro', 'Outro', '2027-01-01', '2027-12-31', 'active')",
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO study_blocks (id, operational_date, started_at, block_deadline) "
          "VALUES ('orphan', '2099-01-01', 10, 20)",
        ),
        throwsA(isA<Exception>()),
      );
    } finally {
      await database.close();
    }
  });

  test(
    'harness applies v(n-1) to v(n) and preserves every identity/date pair',
    () async {
      final result = await harness.migrateAdjacent(
        fromVersion: 1,
        toVersion: 2,
        populate: (database) {
          database.execute(
            "INSERT INTO days (operational_date, base_result, effective_result) VALUES "
            "('2026-05-04', 'unsealed', 'unsealed'), "
            "('2026-05-05', 'unsealed', 'unsealed')",
          );
          database.execute(
            'INSERT INTO study_blocks '
            '(id, operational_date, started_at, block_deadline, ended_at) VALUES '
            "('block-a', '2026-05-04', 10, 20, 20), "
            "('block-b', '2026-05-05', 30, 40, NULL)",
          );
        },
        openTarget: _applyAdditiveV2Probe,
      );

      expect(result.after, result.before);
      expect(result.before, {
        'study_blocks': [
          (id: 'block-a', operationalDate: '2026-05-04'),
          (id: 'block-b', operationalDate: '2026-05-05'),
        ],
      });
    },
  );

  test('harness rejects an operational_date reclassification', () async {
    expect(
      () => harness.migrateAdjacent(
        fromVersion: 1,
        toVersion: 2,
        populate: (database) {
          database.execute(
            "INSERT INTO days (operational_date, base_result, effective_result) "
            "VALUES ('2026-05-04', 'unsealed', 'unsealed')",
          );
          database.execute(
            "INSERT INTO study_blocks "
            "(id, operational_date, started_at, block_deadline) "
            "VALUES ('block', '2026-05-04', 10, 20)",
          );
        },
        openTarget: _applyReclassifyingV2Probe,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

Future<Map<String, String>> _driftSchema(RitmoDatabase database) async {
  final rows = await database.customSelect('''
SELECT type, name, sql FROM sqlite_master
WHERE sql IS NOT NULL AND type IN ('table', 'index')
  AND name NOT LIKE 'sqlite_%'
ORDER BY type, name
''').get();
  return {
    for (final row in rows)
      '${row.read<String>('type')}:${row.read<String>('name')}': row
          .read<String>('sql'),
  };
}

Map<String, String> _sqliteSchema(Database database) {
  final rows = database.select('''
SELECT type, name, sql FROM sqlite_master
WHERE sql IS NOT NULL AND type IN ('table', 'index')
  AND name NOT LIKE 'sqlite_%'
ORDER BY type, name
''');
  expect(database.userVersion, 1);
  expect(database.select('PRAGMA foreign_keys').single['foreign_keys'], 1);
  return {
    for (final row in rows)
      '${row['type']}:${row['name']}': row['sql'] as String,
  };
}

Future<void> _applyAdditiveV2Probe(File file) async {
  final database = sqlite3.open(file.path);
  try {
    database.execute(
      'CREATE TABLE migration_probe_v2 '
      '(id TEXT NOT NULL PRIMARY KEY, created_at INTEGER NOT NULL);',
    );
    database.userVersion = 2;
  } finally {
    database.close();
  }
}

Future<void> _applyReclassifyingV2Probe(File file) async {
  final database = sqlite3.open(file.path);
  try {
    database.execute(
      "INSERT INTO days (operational_date, base_result, effective_result) "
      "VALUES ('2026-05-05', 'unsealed', 'unsealed')",
    );
    database.execute(
      "UPDATE study_blocks SET operational_date = '2026-05-05' "
      "WHERE id = 'block'",
    );
    database.userVersion = 2;
  } finally {
    database.close();
  }
}
