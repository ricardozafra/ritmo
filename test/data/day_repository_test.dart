import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/domain/day/day_state_machine.dart' as domain;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late RitmoDatabase database;
  late DayRepository repository;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
    repository = DayRepository(database);
  });

  tearDown(() => database.close());

  test('first weekday use persists activation and creates open unsealed day', () async {
    final date = OperationalDate(2026, 1, 5);

    final result = await repository.ensureDayMaterialized(date);
    final day = _success(result);

    expect(day.operationalDate, date);
    expect(day.baseResult, domain.DayResult.unsealed);
    expect(day.effectiveResult, domain.DayResult.unsealed);
    expect(day.muteCause, isNull);
    expect(day.closedAt, isNull);
    expect(await _activationDate(database), date.iso);
    expect(await _dayCount(database, date.iso), 1);
  });

  test('weekend starts mute with weekend cause', () async {
    final date = OperationalDate(2026, 1, 10);

    final day = _success(await repository.ensureDayMaterialized(date));

    expect(day.baseResult, domain.DayResult.unsealed);
    expect(day.effectiveResult, domain.DayResult.mute);
    expect(day.muteCause, domain.MuteCause.weekend);
    expect(day.previousResult, isNull);
  });

  test('active holiday starts mute and preserves its previous result', () async {
    final date = OperationalDate(2026, 1, 6);
    await database.select(database.settings).getSingle();
    await database.customStatement('PRAGMA foreign_keys = OFF');
    await database.customStatement(
      'INSERT INTO holidays (operational_date, active, created_at) '
      'VALUES (?, 1, 100)',
      [date.iso],
    );
    await database.customStatement('PRAGMA foreign_keys = ON');

    final day = _success(await repository.ensureDayMaterialized(date));

    expect(day.baseResult, domain.DayResult.unsealed);
    expect(day.effectiveResult, domain.DayResult.mute);
    expect(day.muteCause, domain.MuteCause.holiday);
    expect(day.previousResult, domain.DayResult.unsealed);
  });
  test('never creates a day before the persisted activation date', () async {
    final activation = OperationalDate(2026, 1, 5);
    final earlier = OperationalDate(2026, 1, 4);
    await repository.ensureDayMaterialized(activation);

    final result = await repository.ensureDayMaterialized(earlier);

    expect(_failureCode(result), 'day_before_activation');
    expect(await _activationDate(database), activation.iso);
    expect(await _dayCount(database, earlier.iso), 0);
  });

  test('repeated materialization is idempotent and keeps first activation', () async {
    final first = OperationalDate(2026, 1, 5);
    final later = OperationalDate(2026, 1, 6);

    final initial = _success(await repository.ensureDayMaterialized(first));
    final repeated = _success(await repository.ensureDayMaterialized(first));
    _success(await repository.ensureDayMaterialized(later));

    expect(repeated.operationalDate, initial.operationalDate);
    expect(await _dayCount(database, first.iso), 1);
    expect(await _activationDate(database), first.iso);
  });

  test('seal command persists timestamp when all pillars are complete', () async {
    final date = OperationalDate(2026, 1, 5);
    final at = tz.TZDateTime(tz.UTC, 2026, 1, 5, 22);
    await repository.ensureDayMaterialized(date);
    await _insertCompletedPillars(database, date.iso);

    final sealed = _success(await repository.sealDay(date, at: at));
    final persisted = await _persistedDay(database, date.iso);

    expect(sealed.baseResult, domain.DayResult.sealed);
    expect(sealed.sealTimestamp, at);
    expect(persisted.baseResult, 'sealed');
    expect(persisted.sealTimestamp, at.millisecondsSinceEpoch);
  });

  test('matching active waiver covers exactly one incomplete pillar', () async {
    final date = OperationalDate(2026, 1, 5);
    await repository.ensureDayMaterialized(date);
    await _insertCompletedPillars(database, date.iso, omit: 'night');
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
      "VALUES ('w1', ?, 'night', 'Recuperação médica')",
      [date.iso],
    );

    final result = await repository.sealDay(
      date,
      at: tz.TZDateTime(tz.UTC, 2026, 1, 5, 22),
    );

    expect(result.isSuccess, isTrue);
  });

  test('rejects two incomplete pillars and neutrally identifies uncovered one', () async {
    final date = OperationalDate(2026, 1, 5);
    await repository.ensureDayMaterialized(date);
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, toggle_on) '
      "VALUES (?, 'day', 1)",
      [date.iso],
    );
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
      "VALUES ('w1', ?, 'morning', 'Consulta médica')",
      [date.iso],
    );

    final result = await repository.sealDay(
      date,
      at: tz.TZDateTime(tz.UTC, 2026, 1, 5, 22),
    );
    final failure = (result as Failure<domain.Day, DayViolation>).failure;

    expect(failure.code, 'day_not_seal_eligible');
    expect(failure.message, contains('Noite/Futuro'));
    expect(failure.message, isNot(contains('erro')));
  });

  test('explicit reopen clears timestamp and reseal keeps only the new one', () async {
    final date = OperationalDate(2026, 1, 5);
    final first = tz.TZDateTime(tz.UTC, 2026, 1, 5, 21);
    final second = tz.TZDateTime(tz.UTC, 2026, 1, 5, 23);
    await repository.ensureDayMaterialized(date);
    await _insertCompletedPillars(database, date.iso);
    _success(await repository.sealDay(date, at: first));

    final reopened = _success(await repository.reopenDay(date));
    final afterReopen = await _persistedDay(database, date.iso);
    expect(reopened.sealTimestamp, isNull);
    expect(afterReopen.sealTimestamp, isNull);

    final resealed = _success(await repository.sealDay(date, at: second));
    expect(resealed.sealTimestamp, second);
    expect((await _persistedDay(database, date.iso)).sealTimestamp,
        second.millisecondsSinceEpoch);
  });
}

domain.Day _success(Result<domain.Day, DayViolation> result) => result.fold(
  onSuccess: (day) => day,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode(Result<domain.Day, DayViolation> result) => result.fold(
  onSuccess: (_) => null,
  onFailure: (failure) => failure.code,
);

Future<String?> _activationDate(RitmoDatabase database) async =>
    (await (database.select(database.settings)
          ..where((row) => row.id.equals(1)))
        .getSingle())
        .activationDate;

Future<int> _dayCount(RitmoDatabase database, String operationalDate) async {
  final row = await database
      .customSelect(
        'SELECT count(*) AS count FROM days WHERE operational_date = ?',
        variables: [Variable.withString(operationalDate)],
      )
      .getSingle();
  return row.read<int>('count');
}

Future<void> _insertCompletedPillars(
  RitmoDatabase database,
  String date, {
  String? omit,
}) async {
  if (omit != 'morning') {
    await database.customStatement(
      'INSERT INTO pillar_entries '
      '(operational_date, pillar, workout_done, briefing_done) '
      "VALUES (?, 'morning', 1, 1)",
      [date],
    );
  }
  if (omit != 'day') {
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, toggle_on) '
      "VALUES (?, 'day', 1)",
      [date],
    );
  }
  if (omit != 'night') {
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, night_kind) '
      "VALUES (?, 'night', 'recovery')",
      [date],
    );
  }
}

Future<Day> _persistedDay(
  RitmoDatabase database,
  String date,
) => (database.select(database.days)
      ..where((day) => day.operationalDate.equals(date)))
    .getSingle();