import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/data/db/database.dart';

void main() {
  late RitmoDatabase database;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('seeds v1 settings, active cycle, checkpoints, and mentorships', () async {
    final settings = await database.select(database.settings).getSingle();
    expect(settings.activationDate, isNull);
    expect(settings.businessTimezone, 'America/Sao_Paulo');
    expect(settings.dayCloseTimeMin, 180);
    expect(settings.nightEndTimeMin, 180);
    expect(settings.sundayNotificationEnabled, isFalse);
    expect(settings.syncEnabled, isFalse);

    final cycle = await database.select(database.cycles).getSingle();
    expect(cycle.state, 'active');
    expect(
      cycle.purposeText,
      'Nível Avançado em Strategic Thinking, Innovative e Change Advocate '
      'até Junho/2027 + consolidação de Business Acumen',
    );

    final checkpoints = await database.customSelect(
      'SELECT date, competency FROM checkpoints ORDER BY date',
    ).get();
    expect(
      checkpoints
          .map((row) => (row.read<String>('date'), row.read<String>('competency')))
          .toList(),
      [
        ('2026-12-31', 'IN'),
        ('2027-02-28', 'ST'),
        ('2027-06-30', 'CA'),
      ],
    );

    final mentorships = await database.customSelect(
      'SELECT competency, mentor_name FROM mentorships ORDER BY competency',
    ).get();
    expect(
      mentorships.map((row) => row.read<String>('competency')).toList(),
      ['CA', 'IN', 'ST'],
    );
    expect(
      mentorships.every((row) => row.readNullable<String>('mentor_name') == null),
      isTrue,
    );
  });

  test('enforces one active cycle and one active initiative', () async {
    await expectLater(
      database.customStatement(
        "INSERT INTO cycles "
        "(id, name, purpose_text, start_date, end_date, state) VALUES "
        "('other', 'Outro', 'Outra finalidade', '2027-07-01', "
        "'2028-06-30', 'active')",
      ),
      throwsA(isA<Exception>()),
    );

    await database.customStatement(
      "INSERT INTO change_initiatives (id, name, active) "
      "VALUES ('first', 'Primeira', 1)",
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO change_initiatives (id, name, active) "
        "VALUES ('second', 'Segunda', 1)",
      ),
      throwsA(isA<Exception>()),
    );
    await database.customStatement(
      "INSERT INTO change_initiatives (id, name, active) "
      "VALUES ('inactive', 'Inativa', 0)",
    );
  });

  test('materializes pillar foreign keys added by the v1 schema', () async {
    await database.customStatement(
      "INSERT INTO days (operational_date, base_result, effective_result) "
      "VALUES ('2026-05-04', 'unsealed', 'unsealed')",
    );

    await expectLater(
      database.customStatement(
        "INSERT INTO pillar_entries "
        "(operational_date, pillar, change_initiative_id) "
        "VALUES ('2026-05-04', 'day', 'missing')",
      ),
      throwsA(isA<Exception>()),
    );
  });
}
