// Feature: ritmo, Property 23: Atomicidade da fronteira em foreground
//
// Para qualquer data operacional e ponto de falha interno, snapshot, fechamento
// do dia, encerramento de blocos órfãos e reconciliação de protocolos aparecem
// juntos após o commit ou nenhum deles permanece. Eventos são estritamente
// pós-commit e o snapshot nunca muda de data operacional.
//
// **Validates: Requirements RF-05.29, RF-05.30, RF-05.31, RF-05.32,
// RF-05.34, RF-05.35, RNF-04.11, RNF-04.12**

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/boundary_observer.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/app/schedule_reconciler.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

enum _InjectedFailure {
  none,
  afterSnapshotWrite,
  closeDay,
  orphanBlock,
  protocol,
}

typedef _Scenario = ({
  OperationalDate activationDate,
  _InjectedFailure failure,
  String snapshotText,
});

typedef _BoundaryState = ({
  int? closedAt,
  int snapshotCount,
  int reassignedSnapshotCount,
  int? orphanEndedAt,
  int protocolCount,
  String? protocolState,
  int? protocolLength,
});

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (Random random, int size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    return (
      activationDate: activation,
      failure: _InjectedFailure
          .values[random.nextInt(_InjectedFailure.values.length)],
      snapshotText: 'snapshot-${random.nextInt(1 << 31)}',
    );
  },
  shrink: (scenario) sync* {
    final canonical = (
      activationDate: canonicalOperationalDate,
      failure: _InjectedFailure.afterSnapshotWrite,
      snapshotText: 'snapshot-canonico',
    );
    if (scenario != canonical) yield canonical;
  },
);

void main() {
  Glados<_Scenario>(
    _anyScenario,
    RitmoGlados.ci(),
  ).test('Propriedade 23: Atomicidade da fronteira em foreground', (
    _Scenario scenario,
  ) async {
    final database = RitmoDatabase(NativeDatabase.memory());
    final closing = scenario.activationDate.next;
    var currentInstant = DateTime.utc(2000);
    final clock = SystemOperationalClock(deviceInstant: () => currentInstant);
    final expectedClose = clock.operationalClose(closing);
    currentInstant = expectedClose.add(const Duration(minutes: 5)).toUtc();
    final orphanDeadline = expectedClose.subtract(const Duration(hours: 1));
    final schedule = _RecordingScheduleReconciler();
    final service = BoundaryCrossingService(
      database,
      clock: clock,
      scheduleReconciler: schedule,
    );
    final snapshot = _TestSnapshot(
      database: database,
      operationalDate: closing,
      text: scenario.snapshotText,
      throwAfterWrite: scenario.failure == _InjectedFailure.afterSnapshotWrite,
    );
    final editors = EditorRegistry();
    final registration = editors.register(_TestEditor(snapshot));
    final observer = BoundaryObserver(clock, service, editors);
    final uiStates = <BoundaryUiState>[];
    final boundaryEvents = <BoundaryEvent>[];
    final uiSubscription = service.uiStates.listen(uiStates.add);
    final boundarySubscription = observer.events.listen(boundaryEvents.add);

    try {
      await _seed(
        database,
        activation: scenario.activationDate,
        closing: closing,
        previousClosedAt: clock
            .operationalClose(scenario.activationDate)
            .millisecondsSinceEpoch,
        orphanStartedAt: orphanDeadline
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        orphanDeadline: orphanDeadline.millisecondsSinceEpoch,
      );
      await _installFailureTrigger(database, scenario.failure);
      final before = await _state(database, closing);

      if (scenario.failure == _InjectedFailure.none) {
        await observer.onResumed();

        final after = await _state(database, closing);
        expect(after.closedAt, expectedClose.millisecondsSinceEpoch);
        expect(after.snapshotCount, 1);
        expect(after.reassignedSnapshotCount, 0);
        expect(after.orphanEndedAt, orphanDeadline.millisecondsSinceEpoch);
        expect(after.protocolCount, 1);
        expect(after.protocolState, 'pending');
        expect(after.protocolLength, 2);
        expect(await service.pendingBoundaries(before: closing.next), isEmpty);

        expect(uiStates, hasLength(1));
        expect(uiStates.single.closedDate, closing);
        expect(uiStates.single.currentDate, closing.next);
        expect(uiStates.single.isPreviousDayReadOnly, isTrue);
        expect(uiStates.single.notice, BoundaryUiState.readOnlyNotice);
        expect(boundaryEvents, hasLength(1));
        expect(boundaryEvents.single.closedDate, closing);
        expect(boundaryEvents.single.hadPendingEdit, isTrue);
        expect(schedule.events, hasLength(1));
        expect(schedule.events.single.closedDate, closing);
        expect(schedule.events.single.closedNow, isTrue);
      } else {
        await expectLater(observer.onResumed(), throwsA(anything));

        expect(
          await _state(database, closing),
          before,
          reason: 'falha injetada em ${scenario.failure.name}',
        );
        expect(uiStates, isEmpty);
        expect(boundaryEvents, isEmpty);
        expect(schedule.events, isEmpty);
      }
    } finally {
      registration.dispose();
      await boundarySubscription.cancel();
      await uiSubscription.cancel();
      await observer.dispose();
      await service.dispose();
      await database.close();
    }
  });
}

final class _TestSnapshot implements DayEditSnapshot {
  const _TestSnapshot({
    required this.database,
    required this.operationalDate,
    required this.text,
    required this.throwAfterWrite,
  });

  final RitmoDatabase database;
  @override
  final OperationalDate operationalDate;
  final String text;
  final bool throwAfterWrite;

  @override
  Future<void> persist() async {
    await database.customStatement(
      'INSERT INTO pillar_entries '
      '(operational_date, pillar, toggle_on, note_text) '
      "VALUES (?, 'day', 1, ?)",
      [operationalDate.iso, text],
    );
    if (throwAfterWrite) {
      throw StateError('falha injetada após o snapshot');
    }
  }
}

final class _TestEditor implements DayScopedEditor {
  const _TestEditor(this.snapshot);

  final DayEditSnapshot snapshot;

  @override
  OperationalDate get operationalDate => snapshot.operationalDate;

  @override
  DayEditSnapshot captureSnapshot() => snapshot;
}

final class _RecordingScheduleReconciler implements ScheduleReconciler {
  final List<BoundaryCommittedEvent> events = [];

  @override
  Future<void> reconcileAfterBoundary(BoundaryCommittedEvent event) async {
    events.add(event);
  }
}

Future<void> _seed(
  RitmoDatabase database, {
  required OperationalDate activation,
  required OperationalDate closing,
  required int previousClosedAt,
  required int orphanStartedAt,
  required int orphanDeadline,
}) async {
  await database.customStatement(
    'UPDATE settings SET activation_date = ? WHERE id = 1',
    [activation.iso],
  );
  await database.customStatement(
    'INSERT INTO days '
    '(operational_date, base_result, effective_result, closed_at) '
    "VALUES (?, 'unsealed', 'unsealed', ?)",
    [activation.iso, previousClosedAt],
  );
  await database.customStatement(
    'INSERT INTO days '
    '(operational_date, base_result, effective_result) '
    "VALUES (?, 'unsealed', 'unsealed')",
    [closing.iso],
  );
  await database.customStatement(
    'INSERT INTO study_blocks '
    '(id, operational_date, started_at, block_deadline) '
    "VALUES ('orphan-boundary', ?, ?, ?)",
    [closing.iso, orphanStartedAt, orphanDeadline],
  );
}

Future<void> _installFailureTrigger(
  RitmoDatabase database,
  _InjectedFailure failure,
) async {
  final (name, operation) = switch (failure) {
    _InjectedFailure.closeDay => (
      'fail_boundary_close',
      'BEFORE UPDATE OF closed_at ON days',
    ),
    _InjectedFailure.orphanBlock => (
      'fail_boundary_orphan',
      'BEFORE UPDATE OF ended_at ON study_blocks',
    ),
    _InjectedFailure.protocol => (
      'fail_boundary_protocol',
      'BEFORE INSERT ON protocol_alarms',
    ),
    _ => (null, null),
  };
  if (name == null || operation == null) return;
  await database.customStatement(
    "CREATE TRIGGER $name $operation BEGIN "
    "SELECT RAISE(ABORT, 'falha de fronteira injetada'); END",
  );
}

Future<_BoundaryState> _state(
  RitmoDatabase database,
  OperationalDate closing,
) async {
  final day = await (database.select(
    database.days,
  )..where((row) => row.operationalDate.equals(closing.iso))).getSingle();
  final snapshotRow = await database
      .customSelect(
        'SELECT count(*) AS total FROM pillar_entries '
        "WHERE operational_date = ? AND pillar = 'day'",
        variables: [Variable.withString(closing.iso)],
        readsFrom: {database.pillarEntries},
      )
      .getSingle();
  final reassignedRow = await database
      .customSelect(
        'SELECT count(*) AS total FROM pillar_entries '
        "WHERE operational_date = ? AND pillar = 'day'",
        variables: [Variable.withString(closing.next.iso)],
        readsFrom: {database.pillarEntries},
      )
      .getSingle();
  final orphan = await (database.select(
    database.studyBlocks,
  )..where((row) => row.id.equals('orphan-boundary'))).getSingle();
  final protocols = await database.select(database.protocolAlarms).get();
  final protocol = protocols.length == 1 ? protocols.single : null;
  return (
    closedAt: day.closedAt,
    snapshotCount: snapshotRow.read<int>('total'),
    reassignedSnapshotCount: reassignedRow.read<int>('total'),
    orphanEndedAt: orphan.endedAt,
    protocolCount: protocols.length,
    protocolState: protocol?.state,
    protocolLength: protocol?.sequenceLength,
  );
}
