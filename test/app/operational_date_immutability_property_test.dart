// Feature: ritmo, Property 27: operational_date nunca é reclassificada
//
// Para qualquer data operacional, configuração válida de fronteira e valores
// de comandos, os registros diários preservam sua data de origem durante
// comandos, feriados, blocos, snapshot/fronteira e recuperação de órfãos.
//
// **Validates: Requirements RF-01.20, RF-05.32, RD-38**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/boundary_observer.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/data/repositories/open_day_commands_repository.dart';
import 'package:ritmo/data/repositories/study_block_repository.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

typedef _Scenario = ({
  OperationalDate date,
  OperationalCalendar calendar,
  bool workoutDone,
  bool briefingDone,
  bool dayToggle,
  String note,
});

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (random, size) {
    var date = anyOperationalDate(random, size).value;
    while (date.isWeekend) {
      date = date.next;
    }
    return (
      date: date,
      calendar: anySettings(random, size).value,
      workoutDone: random.nextBool(),
      briefingDone: random.nextBool(),
      dayToggle: random.nextBool(),
      note: 'origem-${random.nextInt(1 << 31)}',
    );
  },
  shrink: (scenario) sync* {
    final canonical = (
      date: canonicalOperationalDate,
      calendar: const OperationalCalendar.seed(),
      workoutDone: true,
      briefingDone: true,
      dayToggle: true,
      note: 'origem-canonica',
    );
    if (scenario != canonical) yield canonical;
  },
);

void main() {
  Glados<_Scenario>(_anyScenario, RitmoGlados.ci()).test(
    'Propriedade 27: operational_date nunca é reclassificada',
    (_Scenario scenario) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      final calendar = scenario.calendar;
      var currentInstant = DateTime.utc(2000);
      final clock = SystemOperationalClock(
        calendar: calendar,
        deviceInstant: () => currentInstant,
      );
      final date = scenario.date;
      final nextDate = date.next;
      final openedAt = clock.operationalOpen(date);
      final closedAt = clock.operationalClose(date);
      currentInstant = openedAt.add(const Duration(hours: 1)).toUtc();
      final days = DayRepository(database);
      final commands = OpenDayCommandsRepository(database, clock: clock);
      final blocks = StudyBlockRepository(database, clock: clock);
      final holidays = HolidayRecalculation(database, clock: clock);
      final service = BoundaryCrossingService(database, clock: clock);
      final editors = EditorRegistry();
      final snapshot = _WaiverSnapshot(
        database: database,
        operationalDate: date,
        id: 'snapshot-${scenario.note}',
      );
      final registration = editors.register(_SnapshotEditor(snapshot));
      final observer = BoundaryObserver(clock, service, editors);
      final context =
          '${date.iso}/${calendar.dayCloseTime}/${calendar.nightEndTime}/'
          '${scenario.note}';

      try {
        _expectSuccess(await days.ensureDayMaterialized(date), context);
        _expectSuccess(await days.ensureDayMaterialized(nextDate), context);
        await database.customStatement(
          'INSERT INTO pillar_waivers '
          '(id, date, pillar, reason_text, revoked_at) '
          "VALUES ('waiver-control', ?, 'morning', 'Origem', 1)",
          [date.iso],
        );

        _expectSuccess(
          await commands.setWorkout(
            date,
            done: scenario.workoutDone,
            at: openedAt.add(const Duration(seconds: 1)),
          ),
          context,
        );
        _expectSuccess(
          await commands.setBriefing(
            date,
            done: scenario.briefingDone,
            mode: BriefingCompletion.manual,
            at: openedAt.add(const Duration(seconds: 2)),
          ),
          context,
        );
        _expectSuccess(
          await commands.setDayToggle(date, on: scenario.dayToggle),
          context,
        );
        _expectSuccess(
          await commands.setDayNote(date, note: scenario.note),
          context,
        );
        final cancelledStartedAt = openedAt.add(const Duration(seconds: 3));
        _expectSuccess(
          await commands.startStudy(
            id: 'cancelled-command',
            date: date,
            startedAt: cancelledStartedAt,
          ),
          context,
        );
        _expectSuccess(await commands.cancelStudy(date), context);
        await _expectBlockAbsent(
          database,
          'cancelled-command',
          '$context/cancelamento',
        );
        _expectAllDailyRowsOnOrigin(
          await _dailyIdentities(database),
          origin: date,
          next: nextDate,
          context: '$context/cancelamento',
        );

        final replacedStartedAt = openedAt.add(const Duration(seconds: 5));
        _expectSuccess(
          await commands.startStudy(
            id: 'study-to-recovery',
            date: date,
            startedAt: replacedStartedAt,
          ),
          context,
        );
        _expectSuccess(
          await commands.finishStudy(
            date,
            at: replacedStartedAt.add(const Duration(seconds: 1)),
          ),
          context,
        );
        _expectSuccess(
          await commands.chooseRecovery(
            date,
            at: openedAt.add(const Duration(seconds: 7)),
            note: 'recuperacao-${scenario.note}',
          ),
          context,
        );
        await _expectBlockAbsent(
          database,
          'study-to-recovery',
          '$context/estudo-para-recuperacao',
        );

        final replacementStartedAt = openedAt.add(const Duration(seconds: 8));
        _expectSuccess(
          await commands.startStudy(
            id: 'recovery-to-study',
            date: date,
            startedAt: replacementStartedAt,
          ),
          context,
        );
        _expectSuccess(
          await commands.finishStudy(
            date,
            at: replacementStartedAt.add(const Duration(seconds: 1)),
          ),
          context,
        );
        _expectSuccess(await commands.removeNightChoice(date), context);
        await _expectBlockAbsent(
          database,
          'recovery-to-study',
          '$context/recuperacao-para-estudo-removido',
        );
        _expectAllDailyRowsOnOrigin(
          await _dailyIdentities(database),
          origin: date,
          next: nextDate,
          context: '$context/substituicoes-noturnas',
        );

        final completedStartedAt = openedAt.add(const Duration(seconds: 10));
        _expectSuccess(
          await commands.startStudy(
            id: 'completed-command',
            date: date,
            startedAt: completedStartedAt,
          ),
          context,
        );
        _expectSuccess(
          await commands.finishStudy(
            date,
            at: completedStartedAt.add(const Duration(seconds: 1)),
          ),
          context,
        );
        final orphan = _expectSuccess(
          await blocks.start(
            id: 'orphan-recovery',
            operationalDate: date,
            startedAt: openedAt.add(const Duration(seconds: 15)),
          ),
          context,
        );

        final commandIdentities = await _dailyIdentities(database);
        _expectAllDailyRowsOnOrigin(
          commandIdentities,
          origin: date,
          next: nextDate,
          context: '$context/comandos-e-blocos',
        );

        _expectSuccess(
          await holidays.apply(date, reasonText: scenario.note),
          context,
        );
        var holiday = await database.select(database.holidays).getSingle();
        expect(holiday.operationalDate, date.iso, reason: context);
        _expectIdentitiesPreserved(
          commandIdentities,
          await _dailyIdentities(database),
          '$context/feriado-aplicado',
        );

        _expectSuccess(
          await holidays.remove(date, reasonText: 'remover-${scenario.note}'),
          context,
        );
        holiday = await database.select(database.holidays).getSingle();
        expect(holiday.operationalDate, date.iso, reason: context);
        _expectIdentitiesPreserved(
          commandIdentities,
          await _dailyIdentities(database),
          '$context/feriado-removido',
        );

        final beforePersistenceFailure = await _dailyIdentities(database);
        await expectLater(
          service.crossBoundary(
            date,
            snapshot: _FailingWaiverSnapshot(
              database: database,
              operationalDate: date,
              id: 'snapshot-falha-${scenario.note}',
            ),
          ),
          throwsA(isA<StateError>()),
        );
        expect(
          await _dailyIdentities(database),
          beforePersistenceFailure,
          reason: '$context/falha-de-persistencia',
        );
        final stillOpenDay = await (database.select(
          database.days,
        )..where((row) => row.operationalDate.equals(date.iso))).getSingle();
        expect(stillOpenDay.closedAt, isNull, reason: context);

        final beforeMismatch = await _dailyIdentities(database);
        await expectLater(
          service.crossBoundary(
            date,
            snapshot: _WaiverSnapshot(
              database: database,
              operationalDate: nextDate,
              id: 'snapshot-invalido',
            ),
          ),
          throwsA(
            isA<BoundaryCrossingException>().having(
              (error) => error.code,
              'code',
              'boundary_snapshot_date_mismatch',
            ),
          ),
        );
        expect(
          await _dailyIdentities(database),
          beforeMismatch,
          reason: '$context/snapshot-divergente',
        );

        currentInstant = closedAt.add(const Duration(minutes: 5)).toUtc();
        await observer.onResumed();

        final afterBoundary = await _dailyIdentities(database);
        _expectIdentitiesPreserved(
          commandIdentities,
          afterBoundary,
          '$context/fronteira',
        );
        expect(afterBoundary['waiver:snapshot-${scenario.note}'], date.iso);
        expect(
          afterBoundary.values.where((value) => value == nextDate.iso),
          isEmpty,
          reason: '$context/nenhum-registro-reatribuido',
        );
        final persistedDay = await (database.select(
          database.days,
        )..where((row) => row.operationalDate.equals(date.iso))).getSingle();
        expect(
          persistedDay.closedAt,
          closedAt.millisecondsSinceEpoch,
          reason: context,
        );
        var persistedOrphan = await blocks.findById('orphan-recovery');
        expect(persistedOrphan!.operationalDate, date, reason: context);
        expect(persistedOrphan.endedAt, orphan.blockDeadline, reason: context);

        await OrphanBlockCloser(
          database,
        ).closeExpired(now: closedAt.add(const Duration(days: 3)));
        persistedOrphan = await blocks.findById('orphan-recovery');
        expect(persistedOrphan!.operationalDate, date, reason: context);
        expect(persistedOrphan.endedAt, orphan.blockDeadline, reason: context);
        _expectIdentitiesPreserved(
          afterBoundary,
          await _dailyIdentities(database),
          '$context/recuperacao-idempotente',
        );

        final beforeRejectedEdit = await _dailyIdentities(database);
        final rejectedEdit = await commands.setDayNote(
          date,
          note: 'edicao-pos-fechamento',
        );
        expect(rejectedEdit.isFailure, isTrue, reason: context);
        expect(
          await _dailyIdentities(database),
          beforeRejectedEdit,
          reason: '$context/escrita-pos-fechamento',
        );
        _expectAllDailyRowsOnOrigin(
          beforeRejectedEdit,
          origin: date,
          next: nextDate,
          context: '$context/estado-final',
        );
      } finally {
        registration.dispose();
        await observer.dispose();
        await service.dispose();
        await holidays.dispose();
        await database.close();
      }
    },
  );
}

T _expectSuccess<T, F>(Result<T, F> result, String context) {
  expect(result, isA<Success<T, F>>(), reason: context);
  return (result as Success<T, F>).value;
}

final class _WaiverSnapshot implements DayEditSnapshot {
  const _WaiverSnapshot({
    required this.database,
    required this.operationalDate,
    required this.id,
  });

  final RitmoDatabase database;
  @override
  final OperationalDate operationalDate;
  final String id;

  @override
  Future<void> persist() => database.customStatement(
    'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
    "VALUES (?, ?, 'day', 'Snapshot de fronteira')",
    [id, operationalDate.iso],
  );
}

final class _FailingWaiverSnapshot implements DayEditSnapshot {
  const _FailingWaiverSnapshot({
    required this.database,
    required this.operationalDate,
    required this.id,
  });

  final RitmoDatabase database;
  @override
  final OperationalDate operationalDate;
  final String id;

  @override
  Future<void> persist() async {
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
      "VALUES (?, ?, 'day', 'Snapshot que deve sofrer rollback')",
      [id, operationalDate.iso],
    );
    throw StateError('falha injetada depois da escrita do snapshot');
  }
}

final class _SnapshotEditor implements DayScopedEditor {
  const _SnapshotEditor(this.snapshot);

  final DayEditSnapshot snapshot;

  @override
  OperationalDate get operationalDate => snapshot.operationalDate;

  @override
  DayEditSnapshot captureSnapshot() => snapshot;
}

Future<Map<String, String>> _dailyIdentities(RitmoDatabase database) async {
  final identities = <String, String>{};
  final entries = await database.select(database.pillarEntries).get();
  for (final entry in entries) {
    identities['pillar:${entry.pillar}'] = entry.operationalDate;
  }
  final blocks = await database.select(database.studyBlocks).get();
  for (final block in blocks) {
    identities['block:${block.id}'] = block.operationalDate;
  }
  final waivers = await database.select(database.pillarWaivers).get();
  for (final waiver in waivers) {
    identities['waiver:${waiver.id}'] = waiver.date;
  }
  final holidays = await database.select(database.holidays).get();
  for (final holiday in holidays) {
    identities['holiday'] = holiday.operationalDate;
  }
  return identities;
}

Future<void> _expectBlockAbsent(
  RitmoDatabase database,
  String id,
  String context,
) async {
  final rows = await (database.select(
    database.studyBlocks,
  )..where((block) => block.id.equals(id))).get();
  expect(rows, isEmpty, reason: '$context/bloco-descartado-nao-reatribuido');
}

void _expectAllDailyRowsOnOrigin(
  Map<String, String> identities, {
  required OperationalDate origin,
  required OperationalDate next,
  required String context,
}) {
  expect(identities, isNotEmpty, reason: context);
  expect(
    identities.values,
    everyElement(origin.iso),
    reason: '$context/origem',
  );
  expect(
    identities.values.where((value) => value == next.iso),
    isEmpty,
    reason: '$context/data-seguinte',
  );
}

void _expectIdentitiesPreserved(
  Map<String, String> before,
  Map<String, String> after,
  String context,
) {
  for (final identity in before.entries) {
    expect(
      after[identity.key],
      identity.value,
      reason: '$context/${identity.key}',
    );
  }
}
