import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/data/db/database.dart';

void main() {
  late RitmoDatabase database;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('creates the complete v1 schema and enables foreign keys', () async {
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(tables.map((row) => row.read<String>('name')), [
      'audio_assets',
      'change_initiatives',
      'checkpoint_evals',
      'checkpoints',
      'contacts',
      'cycle_closure_invites',
      'cycles',
      'days',
      'holidays',
      'manifests',
      'mentorships',
      'notification_plans',
      'pillar_entries',
      'pillar_waivers',
      'protocol_alarms',
      'settings',
      'study_blocks',
      'weekly_contact_suggestions',
      'weekly_reviews',
    ]);
    final pragma = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    expect(pragma.read<int>('foreign_keys'), 1);
  });

  test(
    'settings accepts only the seeded singleton and fixed timezone',
    () async {
      final seeded = await database.select(database.settings).getSingle();
      expect(seeded.id, 1);

      await expectLater(
        database.customStatement('INSERT INTO settings (id) VALUES (2)'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.customStatement(
          "UPDATE settings SET business_timezone = 'UTC' WHERE id = 1",
        ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('rejects foreign keys to an absent operational day', () async {
    await expectLater(
      database.customStatement(
        "INSERT INTO study_blocks "
        "(id, operational_date, started_at, block_deadline) "
        "VALUES ('block', '2026-05-04', 100, 200)",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO pillar_entries (operational_date, pillar) "
        "VALUES ('2026-05-04', 'morning')",
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('enforces one entry per operational date and pillar', () async {
    await _insertOpenDay(database, '2026-05-04');
    await database.customStatement(
      "INSERT INTO pillar_entries (operational_date, pillar) "
      "VALUES ('2026-05-04', 'morning')",
    );

    await expectLater(
      database.customStatement(
        "INSERT INTO pillar_entries (operational_date, pillar) "
        "VALUES ('2026-05-04', 'morning')",
      ),
      throwsA(isA<Exception>()),
    );
    await database.customStatement(
      "INSERT INTO pillar_entries (operational_date, pillar) "
      "VALUES ('2026-05-04', 'day')",
    );
  });

  test('enforces the central day state checks', () async {
    await expectLater(
      database.customStatement(
        "INSERT INTO days "
        "(operational_date, base_result, effective_result) "
        "VALUES ('2026-05-04', 'sealed', 'sealed')",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO days "
        "(operational_date, base_result, effective_result) "
        "VALUES ('2026-05-05', 'unsealed', 'mute')",
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('allows orphan and zero-duration blocks within the deadline', () async {
    await _insertOpenDay(database, '2026-05-04');
    await database.customStatement(
      "INSERT INTO study_blocks "
      "(id, operational_date, started_at, block_deadline) "
      "VALUES ('orphan', '2026-05-04', 100, 200)",
    );
    await database.customStatement(
      "INSERT INTO study_blocks "
      "(id, operational_date, started_at, block_deadline, ended_at) "
      "VALUES ('zero', '2026-05-04', 100, 200, 100)",
    );

    final count = await database
        .customSelect('SELECT count(*) AS count FROM study_blocks')
        .getSingle();
    expect(count.read<int>('count'), 2);
  });
  test('creates partial indexes with the specified predicates', () async {
    final indexes = await database
        .customSelect(
          "SELECT name, sql FROM sqlite_master WHERE type = 'index' "
          "AND name IN ('waiver_one_active_per_day', "
          "'protocol_one_live_per_generation', 'protocol_pending_oldest') "
          'ORDER BY name',
        )
        .get();

    expect(indexes.map((row) => row.read<String>('name')), [
      'protocol_one_live_per_generation',
      'protocol_pending_oldest',
      'waiver_one_active_per_day',
    ]);
    expect(
      indexes[0].read<String>('sql'),
      contains("WHERE state <> 'invalidated'"),
    );
    expect(indexes[1].read<String>('sql'), contains("WHERE state = 'pending'"));
    expect(
      indexes[2].read<String>('sql'),
      contains('WHERE revoked_at IS NULL'),
    );
  });

  test('allows one active waiver while preserving revoked waivers', () async {
    await _insertOpenDay(database, '2026-05-04');
    await database.customStatement(
      "INSERT INTO pillar_waivers "
      "(id, date, pillar, reason_text) "
      "VALUES ('waiver-1', '2026-05-04', 'morning', 'Consulta médica')",
    );

    await expectLater(
      database.customStatement(
        "INSERT INTO pillar_waivers "
        "(id, date, pillar, reason_text) "
        "VALUES ('waiver-2', '2026-05-04', 'day', 'Imprevisto')",
      ),
      throwsA(isA<Exception>()),
    );
    await database.customStatement(
      "UPDATE pillar_waivers SET revoked_at = 100 WHERE id = 'waiver-1'",
    );
    await database.customStatement(
      "INSERT INTO pillar_waivers "
      "(id, date, pillar, reason_text) "
      "VALUES ('waiver-2', '2026-05-04', 'day', 'Imprevisto')",
    );

    final count = await database
        .customSelect('SELECT count(*) AS count FROM pillar_waivers')
        .getSingle();
    expect(count.read<int>('count'), 2);
  });

  test('allows a new live protocol only after invalidation', () async {
    await _insertOpenDay(database, '2026-05-04');
    await _insertOpenDay(database, '2026-05-05');
    const insert =
        "INSERT INTO protocol_alarms "
        "(id, generation_id, start_date, end_date, sequence_length, state) ";
    await database.customStatement(
      "${insert}VALUES ('protocol-1', 'seq:2026-05-04', "
      "'2026-05-04', '2026-05-05', 2, 'pending')",
    );

    await expectLater(
      database.customStatement(
        "${insert}VALUES ('protocol-2', 'seq:2026-05-04', "
        "'2026-05-04', '2026-05-05', 2, 'pending')",
      ),
      throwsA(isA<Exception>()),
    );
    await database.customStatement(
      "UPDATE protocol_alarms SET state = 'invalidated', "
      "previous_state = 'pending' WHERE id = 'protocol-1'",
    );
    await database.customStatement(
      "${insert}VALUES ('protocol-2', 'seq:2026-05-04', "
      "'2026-05-04', '2026-05-05', 2, 'pending')",
    );

    final count = await database
        .customSelect('SELECT count(*) AS count FROM protocol_alarms')
        .getSingle();
    expect(count.read<int>('count'), 2);
  });

  test('preserves holiday creation and removal audit data', () async {
    await _insertOpenDay(database, '2026-05-04');
    await database.customStatement(
      "INSERT INTO holidays "
      "(operational_date, active, created_at, apply_reason_text) "
      "VALUES ('2026-05-04', 1, 100, 'Feriado local')",
    );
    await database.customStatement(
      "UPDATE holidays SET active = 0, removed_at = 200, "
      "remove_reason_text = 'Correção' "
      "WHERE operational_date = '2026-05-04'",
    );

    final holiday = await database
        .customSelect(
          "SELECT * FROM holidays WHERE operational_date = '2026-05-04'",
        )
        .getSingle();
    expect(holiday.read<int>('active'), 0);
    expect(holiday.read<int>('created_at'), 100);
    expect(holiday.read<int>('removed_at'), 200);
    expect(holiday.read<String>('apply_reason_text'), 'Feriado local');
    expect(holiday.read<String>('remove_reason_text'), 'Correção');
  });

  test(
    'rejects invalid study start, negative duration, and late end',
    () async {
      await _insertOpenDay(database, '2026-05-04');

      for (final values in const [
        "('late-start', '2026-05-04', 201, 200, NULL)",
        "('negative', '2026-05-04', 100, 200, 99)",
        "('late-end', '2026-05-04', 100, 200, 201)",
      ]) {
        await expectLater(
          database.customStatement(
            'INSERT INTO study_blocks '
            '(id, operational_date, started_at, block_deadline, ended_at) '
            'VALUES $values',
          ),
          throwsA(isA<Exception>()),
        );
      }
    },
  );
}

Future<void> _insertOpenDay(RitmoDatabase database, String operationalDate) {
  return database.customStatement(
    'INSERT INTO days '
    '(operational_date, base_result, effective_result) '
    "VALUES ('$operationalDate', 'unsealed', 'unsealed')",
  );
}
