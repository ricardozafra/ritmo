// Feature: ritmo, Property 6: Reversibilidade em `open/unsealed`
//
// Para qualquer dia em `open/unsealed` e qualquer comando ordinário reversível,
// aplicar o comando e seu inverso restaura a conclusão dos três pilares e a
// elegibilidade de selo, sem alterar nenhuma `operational_date`.
//
// **Validates: Requirements RF-01.23, RF-01.24, RF-01.25, RF-01.26,
// RF-01.29, RF-02.4, RF-02.22**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' hide PillarWaiver;
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/open_day_commands_repository.dart';
import 'package:ritmo/data/repositories/pillar_entries_repository.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

enum _ReversibleAction {
  workout,
  briefing,
  dayToggle,
  dayNote,
  cancelActiveStudy,
  removeCompletedStudy,
  removeRecovery,
  studyToRecovery,
  recoveryToStudy,
}

enum _NightState { none, activeStudy, completedStudy, recovery }

typedef _ReversibilityCase = ({
  OperationalDate date,
  _ReversibleAction action,
  bool workoutDone,
  bool briefingDone,
  bool toggleOn,
  String? initialNote,
  String? changedNote,
  Pillar? waiver,
  _NightState night,
  bool reopened,
});

final Generator<_ReversibilityCase> _anyReversibilityCase = any.simple(
  generate: (random, size) {
    final action = _ReversibleAction
        .values[random.nextInt(_ReversibleAction.values.length)];
    final initialNote = <String?>[null, '', 'nota inicial'][random.nextInt(3)];
    final changedNote = <String?>[
      null,
      '',
      'nota alterada',
    ].where((note) => note != initialNote).toList()[random.nextInt(2)];
    final generatedNight =
        _NightState.values[random.nextInt(_NightState.values.length)];
    final night = switch (action) {
      _ReversibleAction.cancelActiveStudy => _NightState.activeStudy,
      _ReversibleAction.removeCompletedStudy ||
      _ReversibleAction.studyToRecovery => _NightState.completedStudy,
      _ReversibleAction.removeRecovery ||
      _ReversibleAction.recoveryToStudy => _NightState.recovery,
      _ => generatedNight,
    };
    return (
      date: _asWorkday(anyOperationalDate(random, size).value),
      action: action,
      workoutDone: random.nextBool(),
      briefingDone: random.nextBool(),
      toggleOn: random.nextBool(),
      initialNote: initialNote,
      changedNote: changedNote,
      waiver: <Pillar?>[
        null,
        ...Pillar.values,
      ][random.nextInt(Pillar.values.length + 1)],
      night: night,
      reopened: random.nextBool(),
    );
  },
  shrink: (value) sync* {
    final canonical = (
      date: OperationalDate(2026, 1, 5),
      action: _ReversibleAction.workout,
      workoutDone: false,
      briefingDone: false,
      toggleOn: false,
      initialNote: null,
      changedNote: 'nota alterada',
      waiver: null,
      night: _NightState.none,
      reopened: false,
    );
    if (value != canonical) yield canonical;
  },
);

OperationalDate _asWorkday(OperationalDate date) {
  var candidate = date;
  while (candidate.isWeekend) {
    candidate = candidate.next;
  }
  return candidate;
}

void main() {
  Glados<_ReversibilityCase>(_anyReversibilityCase, RitmoGlados.ci()).test(
    'Propriedade 6: reversibilidade em open/unsealed',
    (fixture) async {
      const calendar = OperationalCalendar(
        dayCloseTime: LocalTimeOfDay(3, 0),
        nightEndTime: LocalTimeOfDay(1, 0),
      );
      final location = ensureBusinessLocation();
      final clock = SystemOperationalClock(
        calendar: calendar,
        businessLocation: location,
      );
      final database = RitmoDatabase(NativeDatabase.memory());
      final commands = OpenDayCommandsRepository(database, clock: clock);
      final entries = PillarEntriesRepository(
        database,
        businessLocation: location,
      );
      final context =
          'data ${fixture.date.iso}, ação ${fixture.action.name}, '
          'dispensa ${fixture.waiver?.name}, reaberto ${fixture.reopened}';

      try {
        await _seed(database, fixture, clock);
        if (fixture.reopened) {
          final reopened = _success(
            await DayRepository(
              database,
              businessLocation: location,
            ).reopenDay(fixture.date),
          );
          expect(reopened.baseResult.name, 'unsealed', reason: context);
          expect(reopened.sealTimestamp, isNull, reason: context);
        }

        await _expectOpenUnsealed(database, fixture.date, context);
        final before = await entries.statusForDate(fixture.date);
        final waiver = fixture.waiver == null
            ? null
            : PillarWaiver(pillar: fixture.waiver!);
        final eligibleBefore = sealEligible(before, waiver);

        await _applyThenInverse(commands, database, fixture, clock, context);

        final after = await entries.statusForDate(fixture.date);
        _expectSameStatus(after, before, context);
        expect(sealEligible(after, waiver), eligibleBefore, reason: context);
        await _expectOpenUnsealed(database, fixture.date, context);
        await _expectOnlyOperationalDate(database, fixture.date, context);
      } finally {
        await database.close();
      }
    },
  );
}

Future<void> _applyThenInverse(
  OpenDayCommandsRepository commands,
  RitmoDatabase database,
  _ReversibilityCase fixture,
  OperationalClock clock,
  String context,
) async {
  final open = clock.operationalOpen(fixture.date);
  final start = open.add(const Duration(hours: 1));
  final finish = start.add(const Duration(minutes: 1));

  switch (fixture.action) {
    case _ReversibleAction.workout:
      final changed = _success(
        await commands.setWorkout(
          fixture.date,
          done: !fixture.workoutDone,
          at: fixture.workoutDone ? null : start,
        ),
      );
      expect(changed.workoutDone, !fixture.workoutDone, reason: context);
      _success(
        await commands.setWorkout(
          fixture.date,
          done: fixture.workoutDone,
          at: fixture.workoutDone ? start : null,
        ),
      );

    case _ReversibleAction.briefing:
      final changed = _success(
        await commands.setBriefing(
          fixture.date,
          done: !fixture.briefingDone,
          mode: fixture.briefingDone ? null : BriefingCompletion.manual,
          at: fixture.briefingDone ? null : start,
        ),
      );
      expect(changed.briefingDone, !fixture.briefingDone, reason: context);
      _success(
        await commands.setBriefing(
          fixture.date,
          done: fixture.briefingDone,
          mode: fixture.briefingDone ? BriefingCompletion.manual : null,
          at: fixture.briefingDone ? start : null,
        ),
      );

    case _ReversibleAction.dayToggle:
      final changed = _success(
        await commands.setDayToggle(fixture.date, on: !fixture.toggleOn),
      );
      expect(changed.toggleOn, !fixture.toggleOn, reason: context);
      _success(await commands.setDayToggle(fixture.date, on: fixture.toggleOn));

    case _ReversibleAction.dayNote:
      final changed = _success(
        await commands.setDayNote(fixture.date, note: fixture.changedNote),
      );
      expect(changed.note, fixture.changedNote, reason: context);
      _success(
        await commands.setDayNote(fixture.date, note: fixture.initialNote),
      );

    case _ReversibleAction.cancelActiveStudy:
      final changed = _success(await commands.cancelStudy(fixture.date));
      expect(changed.kind, isNull, reason: context);
      await _expectNoBlocks(database, context);
      _success(
        await commands.startStudy(
          id: 'inverse-active',
          date: fixture.date,
          startedAt: start,
        ),
      );

    case _ReversibleAction.removeCompletedStudy:
      final changed = _success(await commands.removeNightChoice(fixture.date));
      expect(changed.kind, isNull, reason: context);
      await _expectNoBlocks(database, context);
      _success(
        await commands.startStudy(
          id: 'inverse-completed',
          date: fixture.date,
          startedAt: start,
        ),
      );
      _success(await commands.finishStudy(fixture.date, at: finish));

    case _ReversibleAction.removeRecovery:
      final changed = _success(await commands.removeNightChoice(fixture.date));
      expect(changed.kind, isNull, reason: context);
      _success(
        await commands.chooseRecovery(
          fixture.date,
          at: start,
          note: 'recuperação inicial',
        ),
      );

    case _ReversibleAction.studyToRecovery:
      final changed = _success(
        await commands.chooseRecovery(
          fixture.date,
          at: start,
          note: 'recuperação substituta',
        ),
      );
      expect(changed.kind, NightKind.recovery, reason: context);
      await _expectNoBlocks(database, context);
      _success(
        await commands.startStudy(
          id: 'inverse-study',
          date: fixture.date,
          startedAt: start,
        ),
      );
      _success(await commands.finishStudy(fixture.date, at: finish));

    case _ReversibleAction.recoveryToStudy:
      _success(
        await commands.startStudy(
          id: 'replacement-study',
          date: fixture.date,
          startedAt: start,
        ),
      );
      _success(await commands.finishStudy(fixture.date, at: finish));
      final changedStatus = await PillarEntriesRepository(
        database,
        businessLocation: clock.businessLocation,
      ).statusForDate(fixture.date);
      expect(changedStatus.nightCompleted, isTrue, reason: context);
      _success(
        await commands.chooseRecovery(
          fixture.date,
          at: start,
          note: 'recuperação inicial',
        ),
      );
  }
}

Future<void> _seed(
  RitmoDatabase database,
  _ReversibilityCase fixture,
  OperationalClock clock,
) async {
  final date = fixture.date.iso;
  final sealAt = clock.operationalOpen(fixture.date).millisecondsSinceEpoch;
  await database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'seal_timestamp) VALUES (?, ?, ?, ?)',
    [
      date,
      fixture.reopened ? 'sealed' : 'unsealed',
      fixture.reopened ? 'sealed' : 'unsealed',
      fixture.reopened ? sealAt : null,
    ],
  );

  final instant = clock
      .operationalOpen(fixture.date)
      .add(const Duration(hours: 1))
      .millisecondsSinceEpoch;
  await database.customStatement(
    'INSERT INTO pillar_entries (operational_date, pillar, workout_done, '
    'briefing_done, briefing_mode, workout_at, briefing_at) '
    "VALUES (?, 'morning', ?, ?, ?, ?, ?)",
    [
      date,
      fixture.workoutDone ? 1 : 0,
      fixture.briefingDone ? 1 : 0,
      fixture.briefingDone ? 'automatic' : null,
      fixture.workoutDone ? instant : null,
      fixture.briefingDone ? instant : null,
    ],
  );
  await database.customStatement(
    'INSERT INTO pillar_entries (operational_date, pillar, toggle_on, '
    "note_text) VALUES (?, 'day', ?, ?)",
    [date, fixture.toggleOn ? 1 : 0, fixture.initialNote],
  );
  await _seedNight(database, fixture, clock);

  if (fixture.waiver != null) {
    await database.customStatement(
      'INSERT INTO pillar_waivers '
      '(id, date, pillar, reason_text) VALUES (?, ?, ?, ?)',
      ['active-waiver', date, fixture.waiver!.name, 'Motivo válido'],
    );
  }
}

Future<void> _seedNight(
  RitmoDatabase database,
  _ReversibilityCase fixture,
  OperationalClock clock,
) async {
  if (fixture.night == _NightState.none) return;
  final date = fixture.date.iso;
  if (fixture.night == _NightState.recovery) {
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, night_kind, '
      "recovery_note) VALUES (?, 'night', 'recovery', ?)",
      [date, 'recuperação inicial'],
    );
    return;
  }

  final start = clock
      .operationalOpen(fixture.date)
      .add(const Duration(hours: 1));
  final deadline = clock.blockDeadline(fixture.date);
  final endedAt = fixture.night == _NightState.completedStudy
      ? start.add(const Duration(minutes: 1)).millisecondsSinceEpoch
      : null;
  await database.customStatement(
    'INSERT INTO study_blocks '
    '(id, operational_date, started_at, block_deadline, ended_at) '
    'VALUES (?, ?, ?, ?, ?)',
    [
      'initial-study',
      date,
      start.millisecondsSinceEpoch,
      deadline.millisecondsSinceEpoch,
      endedAt,
    ],
  );
  await database.customStatement(
    'INSERT INTO pillar_entries '
    '(operational_date, pillar, night_kind, study_block_id) '
    "VALUES (?, 'night', 'study', 'initial-study')",
    [date],
  );
}

void _expectSameStatus(
  PillarStatus actual,
  PillarStatus expected,
  String reason,
) {
  expect(actual.morningCompleted, expected.morningCompleted, reason: reason);
  expect(actual.dayCompleted, expected.dayCompleted, reason: reason);
  expect(actual.nightCompleted, expected.nightCompleted, reason: reason);
}

Future<void> _expectOpenUnsealed(
  RitmoDatabase database,
  OperationalDate date,
  String context,
) async {
  final row = await (database.select(
    database.days,
  )..where((day) => day.operationalDate.equals(date.iso))).getSingle();
  expect(row.baseResult, 'unsealed', reason: context);
  expect(row.effectiveResult, 'unsealed', reason: context);
  expect(row.closedAt, isNull, reason: context);
  expect(row.sealTimestamp, isNull, reason: context);
}

Future<void> _expectOnlyOperationalDate(
  RitmoDatabase database,
  OperationalDate date,
  String context,
) async {
  final dayDates = (await database.select(database.days).get()).map(
    (row) => row.operationalDate,
  );
  final entryDates = (await database.select(database.pillarEntries).get()).map(
    (row) => row.operationalDate,
  );
  final blockDates = (await database.select(database.studyBlocks).get()).map(
    (row) => row.operationalDate,
  );
  final waiverDates = (await database.select(database.pillarWaivers).get()).map(
    (row) => row.date,
  );
  expect(
    {...dayDates, ...entryDates, ...blockDates, ...waiverDates},
    {date.iso},
    reason: context,
  );
}

Future<void> _expectNoBlocks(RitmoDatabase database, String context) async {
  expect(
    await database.select(database.studyBlocks).get(),
    isEmpty,
    reason: context,
  );
}

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);
