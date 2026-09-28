import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/pillar_entries_repository.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late RitmoDatabase database;
  late DayRepository days;
  late PillarEntriesRepository pillars;
  final date = OperationalDate(2026, 5, 4);

  setUp(() async {
    database = RitmoDatabase(NativeDatabase.memory());
    days = DayRepository(database);
    pillars = PillarEntriesRepository(database);
    await days.ensureDayMaterialized(date);
  });

  tearDown(() => database.close());

  test(
    'workout plus manual zero-duration briefing completes morning',
    () async {
      final at = tz.TZDateTime(tz.UTC, 2026, 5, 4, 10);

      _success(await pillars.completeWorkout(date, at: at));
      final morning = _success(
        await pillars.completeBriefingManually(date, at: at),
      );
      final status = await pillars.statusForDate(date);

      expect(morning.workoutDone, isTrue);
      expect(morning.briefingDone, isTrue);
      expect(morning.briefingMode, BriefingCompletion.manual);
      expect(
        morning.workoutAt?.millisecondsSinceEpoch,
        at.millisecondsSinceEpoch,
      );
      expect(
        morning.briefingAt?.millisecondsSinceEpoch,
        at.millisecondsSinceEpoch,
      );
      expect(status.morningCompleted, isTrue);
      expect(await _entryCount(database, date.iso, 'morning'), 1);
    },
  );
  test('local MP3 end persists automatic briefing completion', () async {
    final at = tz.TZDateTime(tz.UTC, 2026, 5, 4, 10, 15);

    final morning = _success(
      await pillars.completeBriefingFromLocalMp3End(date, at: at),
    );

    expect(morning.briefingDone, isTrue);
    expect(morning.briefingMode, BriefingCompletion.automatic);
    expect(
      morning.briefingAt?.millisecondsSinceEpoch,
      at.millisecondsSinceEpoch,
    );
  });

  test('day note stays optional and never controls completion', () async {
    final withoutNote = _success(await pillars.recordDay(date, toggleOn: true));
    expect(withoutNote.note, isNull);
    expect((await pillars.statusForDate(date)).dayCompleted, isTrue);

    final noteWithoutToggle = _success(
      await pillars.recordDay(
        date,
        toggleOn: false,
        note: 'Hipótese ainda não resolvida',
      ),
    );
    expect(noteWithoutToggle.note, 'Hipótese ainda não resolvida');
    expect((await pillars.statusForDate(date)).dayCompleted, isFalse);
  });

  test(
    'confirmed recovery completes night without block or duration',
    () async {
      final night = _success(
        await pillars.confirmRecovery(date, note: 'Descompressão deliberada'),
      );
      final status = await pillars.statusForDate(date);

      expect(night.kind, NightKind.recovery);
      expect(night.recoveryNote, 'Descompressão deliberada');
      expect(night.studyBlockId, isNull);
      expect(status.nightCompleted, isTrue);
    },
  );
  test('study completes night only when its linked block is ended', () async {
    await database.customStatement(
      'INSERT INTO study_blocks '
      '(id, operational_date, started_at, block_deadline) '
      "VALUES ('block-1', ?, 100, 200)",
      [date.iso],
    );
    await database.customStatement(
      'INSERT INTO pillar_entries '
      '(operational_date, pillar, night_kind, study_block_id) '
      "VALUES (?, 'night', 'study', 'block-1')",
      [date.iso],
    );

    expect((await pillars.statusForDate(date)).nightCompleted, isFalse);

    await database.customStatement(
      "UPDATE study_blocks SET ended_at = 200 WHERE id = 'block-1'",
    );
    expect((await pillars.statusForDate(date)).nightCompleted, isTrue);
  });

  test('active morning waiver jointly covers workout and briefing', () async {
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
      "VALUES ('waiver-1', ?, 'morning', 'Recuperação médica')",
      [date.iso],
    );

    final status = await pillars.statusForDate(date);

    expect(status.morningCompleted, isTrue);
  });

  test('guard rejects writes to a closed day', () async {
    await (database.update(database.days)
          ..where((day) => day.operationalDate.equals(date.iso)))
        .write(const DaysCompanion(closedAt: Value(200)));

    final result = await pillars.recordDay(date, toggleOn: true);

    expect(_failureCode(result), 'day_closed');
    expect(await _entryCount(database, date.iso, 'day'), 0);
  });
}

T _success<T>(Result<T, DayViolation> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode<T>(Result<T, DayViolation> result) =>
    result.fold(onSuccess: (_) => null, onFailure: (failure) => failure.code);

Future<int> _entryCount(
  RitmoDatabase database,
  String date,
  String pillar,
) async {
  final row = await database
      .customSelect(
        'SELECT count(*) AS count FROM pillar_entries '
        'WHERE operational_date = ? AND pillar = ?',
        variables: [Variable.withString(date), Variable.withString(pillar)],
      )
      .getSingle();
  return row.read<int>('count');
}
