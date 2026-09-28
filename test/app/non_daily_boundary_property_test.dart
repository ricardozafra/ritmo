// Feature: ritmo, Property 24: Fluxos não diários atravessam a fronteira intactos
//
// Para qualquer estado em edição de Revisão ou Pedra, a fronteira operacional
// fecha o dia e atualiza apenas o contexto de data. O fluxo permanece ativo,
// seu estado volátil e persistido não muda e nenhum snapshot diário é criado.
//
// **Validates: Requirements RF-05.33, RNF-04.13**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/boundary_observer.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/app/schedule_reconciler.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

enum _NonDailyFlowKind { weeklyReview, stone }

typedef _Scenario = ({
  OperationalDate activationDate,
  _NonDailyFlowKind flowKind,
  String draftText,
  int cursor,
  bool dirty,
});

typedef _VolatileFlowState = ({
  _NonDailyFlowKind kind,
  String draftText,
  int cursor,
  bool dirty,
  bool active,
  int interruptionCount,
});

typedef _PersistedFlowState = ({
  String? reviewAnswer,
  String reviewState,
  int? reviewAutosavedAt,
  String manifestContent,
  int? manifestLastEditedAt,
});

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (random, size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final text = 'rascunho-${random.nextInt(1 << 31)}';
    return (
      activationDate: activation,
      flowKind: _NonDailyFlowKind
          .values[random.nextInt(_NonDailyFlowKind.values.length)],
      draftText: text,
      cursor: random.nextInt(text.length + 1),
      dirty: random.nextBool(),
    );
  },
  shrink: (scenario) sync* {
    final canonical = (
      activationDate: canonicalOperationalDate,
      flowKind: _NonDailyFlowKind.weeklyReview,
      draftText: 'rascunho-canonico',
      cursor: 0,
      dirty: true,
    );
    if (scenario != canonical) yield canonical;
  },
);

void main() {
  Glados<_Scenario>(_anyScenario, RitmoGlados.ci()).test(
    'Propriedade 24: Fluxos não diários atravessam a fronteira intactos',
    (_Scenario scenario) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      final closing = scenario.activationDate.next;
      var currentInstant = DateTime.utc(2000);
      final clock = SystemOperationalClock(deviceInstant: () => currentInstant);
      final expectedClose = clock.operationalClose(closing);
      currentInstant = expectedClose.add(const Duration(minutes: 5)).toUtc();
      final schedule = _RecordingScheduleReconciler();
      final service = BoundaryCrossingService(
        database,
        clock: clock,
        scheduleReconciler: schedule,
      );
      final editors = EditorRegistry();
      final observer = BoundaryObserver(clock, service, editors);
      final flow = _NonDailyFlow(
        kind: scenario.flowKind,
        draftText: scenario.draftText,
        cursor: scenario.cursor,
        dirty: scenario.dirty,
      );
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
          reviewAnswer: scenario.flowKind == _NonDailyFlowKind.weeklyReview
              ? scenario.draftText
              : 'revisão preservada',
          manifestContent: scenario.flowKind == _NonDailyFlowKind.stone
              ? '# Pedra\n\n${scenario.draftText}'
              : '# Pedra\n\nManifesto preservado',
        );
        final volatileBefore = flow.state;
        final persistedBefore = await _persistedFlowState(database);

        expect(editors.hasDayScopedEditor, isFalse);
        await observer.onResumed();

        expect(flow.state, volatileBefore);
        expect(flow.state.active, isTrue);
        expect(flow.state.interruptionCount, 0);
        expect(await _persistedFlowState(database), persistedBefore);
        expect(await _dailyWriteCount(database), 0);
        expect(
          await _closedAt(database, closing),
          expectedClose.millisecondsSinceEpoch,
        );

        expect(uiStates, hasLength(1));
        expect(uiStates.single.closedDate, closing);
        expect(uiStates.single.currentDate, closing.next);
        expect(uiStates.single.isPreviousDayReadOnly, isFalse);
        expect(uiStates.single.notice, isNull);
        expect(boundaryEvents, hasLength(1));
        expect(boundaryEvents.single.closedDate, closing);
        expect(boundaryEvents.single.currentDate, closing.next);
        expect(boundaryEvents.single.hadPendingEdit, isFalse);
        expect(schedule.events, hasLength(1));
        expect(schedule.events.single.closedDate, closing);
        expect(schedule.events.single.currentDate, closing.next);
      } finally {
        await boundarySubscription.cancel();
        await uiSubscription.cancel();
        await observer.dispose();
        await service.dispose();
        await database.close();
      }
    },
  );
}

final class _NonDailyFlow {
  _NonDailyFlow({
    required this.kind,
    required this.draftText,
    required this.cursor,
    required this.dirty,
  });

  final _NonDailyFlowKind kind;
  final String draftText;
  final int cursor;
  final bool dirty;
  bool active = true;
  int interruptionCount = 0;

  _VolatileFlowState get state => (
    kind: kind,
    draftText: draftText,
    cursor: cursor,
    dirty: dirty,
    active: active,
    interruptionCount: interruptionCount,
  );
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
  required String reviewAnswer,
  required String manifestContent,
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
    'INSERT INTO weekly_reviews '
    '(id, week_start, answer_fulfilled, state, created_at) '
    "VALUES ('review-boundary', ?, ?, 'draft', 1)",
    [activation.iso, reviewAnswer],
  );
  await database.customStatement(
    'INSERT INTO manifests '
    '(id, content_markdown, asset_version, first_copied_at) '
    "VALUES ('manifest', ?, 'test-v1', 1)",
    [manifestContent],
  );
}

Future<_PersistedFlowState> _persistedFlowState(RitmoDatabase database) async {
  final review = await (database.select(
    database.weeklyReviews,
  )..where((row) => row.id.equals('review-boundary'))).getSingle();
  final manifest = await (database.select(
    database.manifests,
  )..where((row) => row.id.equals('manifest'))).getSingle();
  return (
    reviewAnswer: review.answerFulfilled,
    reviewState: review.state,
    reviewAutosavedAt: review.autosavedAt,
    manifestContent: manifest.contentMarkdown,
    manifestLastEditedAt: manifest.lastEditedAt,
  );
}

Future<int> _dailyWriteCount(RitmoDatabase database) async {
  final row = await database
      .customSelect(
        'SELECT count(*) AS total FROM pillar_entries',
        readsFrom: {database.pillarEntries},
      )
      .getSingle();
  return row.read<int>('total');
}

Future<int?> _closedAt(
  RitmoDatabase database,
  OperationalDate date,
) async => (await (database.select(
  database.days,
)..where((row) => row.operationalDate.equals(date.iso))).getSingle()).closedAt;
