// Feature: ritmo, Property 33: “Aguardando encerramento” é derivado e não
// bloqueia
//
// Para qualquer ciclo ativo, depois do último checkpoint próprio o estado
// derivado é “aguardando encerramento”, sem alterar o ciclo, sua finalidade,
// os checkpoints ou a taxa. Na data do último checkpoint e antes dela, sem
// checkpoint próprio ou em ciclo arquivado, o estado não é derivado.
//
// A projeção da finalidade/estado na tela Hoje e o heatmap ainda não possuem
// API de produção. Essas projeções serão cobertas nas tarefas 17.2 e 17.5;
// este teste não inventa substitutos de UI ou heatmap.
//
// **Validates: Requirements RF-06.8, RF-06.19, RF-06.21**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/metrics/metrics_calculator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _AwaitingClosureFixture = ({
  Cycle cycle,
  List<Checkpoint> checkpoints,
  OperationalDate lastCheckpointDate,
  OperationalDate today,
  TimelineFixture timeline,
});

typedef _CycleSnapshot = ({
  String id,
  String name,
  String purposeText,
  OperationalDate startDate,
  OperationalDate endDate,
  CycleState state,
});

typedef _CheckpointSnapshot = ({
  String id,
  String cycleId,
  Competency competency,
  OperationalDate date,
  String status,
});

final Generator<_AwaitingClosureFixture>
_anyAwaitingClosureFixture = any.simple(
  generate: (random, size) {
    final lastCheckpointDate = anyOperationalDate(random, size).value;
    final today = lastCheckpointDate.addDays(1 + random.nextInt(30));
    final token = random.nextInt(1 << 30);
    final cycleId = 'cycle-$token';
    final foreignCycleId = 'foreign-cycle-$token';
    final cycle = Cycle(
      id: cycleId,
      name: 'Ciclo $token',
      purposeText: 'Finalidade preservada $token',
      startDate: lastCheckpointDate.addDays(-30 - random.nextInt(90)),
      endDate: lastCheckpointDate,
      state: CycleState.active,
    );

    final checkpoints = <Checkpoint>[
      Checkpoint(
        id: 'own-last-$token',
        cycleId: cycleId,
        competency: Competency.values[random.nextInt(Competency.values.length)],
        date: lastCheckpointDate,
        status: 'status-${random.nextInt(4)}',
      ),
      for (var index = 0; index < random.nextInt(5); index++)
        Checkpoint(
          id: 'own-$index-$token',
          cycleId: cycleId,
          competency:
              Competency.values[random.nextInt(Competency.values.length)],
          date: lastCheckpointDate.addDays(-1 - random.nextInt(120)),
          status: 'status-${random.nextInt(4)}',
        ),
      // Esta testemunha estrangeira é posterior a `today`: se a política
      // não filtrar por ciclo, ela impedirá indevidamente o estado.
      Checkpoint(
        id: 'foreign-future-$token',
        cycleId: foreignCycleId,
        competency: Competency.values[random.nextInt(Competency.values.length)],
        date: today.addDays(1 + random.nextInt(30)),
        status: 'status-${random.nextInt(4)}',
      ),
      for (var index = 0; index < random.nextInt(4); index++)
        Checkpoint(
          id: 'foreign-$index-$token',
          cycleId: foreignCycleId,
          competency:
              Competency.values[random.nextInt(Competency.values.length)],
          date: lastCheckpointDate.addDays(random.nextInt(241) - 120),
          status: 'status-${random.nextInt(4)}',
        ),
    ]..shuffle(random);

    return (
      cycle: cycle,
      checkpoints: checkpoints,
      lastCheckpointDate: lastCheckpointDate,
      today: today,
      timeline: anyTimeline(random, size).value,
    );
  },
  shrink: (fixture) sync* {
    if (fixture.cycle.id == 'cycle-minimal') return;

    final metricDay = fixture.timeline.days.firstWhere(
      (day) => _countsInRate(day, fixture.timeline.activationDate),
    );
    final lastCheckpointDate = canonicalOperationalDate;
    final cycle = Cycle(
      id: 'cycle-minimal',
      name: 'Ciclo mínimo',
      purposeText: 'Finalidade mínima preservada',
      startDate: lastCheckpointDate.addDays(-1),
      endDate: lastCheckpointDate,
      state: CycleState.active,
    );
    yield (
      cycle: cycle,
      checkpoints: <Checkpoint>[
        Checkpoint(
          id: 'foreign-future-minimal',
          cycleId: 'foreign-cycle-minimal',
          competency: Competency.in_,
          date: lastCheckpointDate.addDays(2),
          status: 'pending',
        ),
        Checkpoint(
          id: 'own-last-minimal',
          cycleId: cycle.id,
          competency: Competency.st,
          date: lastCheckpointDate,
          status: 'done',
        ),
      ],
      lastCheckpointDate: lastCheckpointDate,
      today: lastCheckpointDate.next,
      timeline: (
        activationDate: metricDay.date,
        days: <TimelineDayFixture>[metricDay],
      ),
    );
  },
);

void main() {
  const policy = CyclePolicy();
  const metrics = MetricsCalculator();

  Glados<_AwaitingClosureFixture>(
    _anyAwaitingClosureFixture,
    RitmoGlados.ci(),
  ).test(
    'Propriedade 33: “Aguardando encerramento” é derivado e não bloqueia',
    (fixture) {
      final cycle = fixture.cycle;
      final checkpoints = fixture.checkpoints;
      final ownCheckpoints = checkpoints
          .where((checkpoint) => checkpoint.cycleId == cycle.id)
          .toList(growable: false);
      final foreignCheckpoints = checkpoints
          .where((checkpoint) => checkpoint.cycleId != cycle.id)
          .toList(growable: false);
      final modeledLastDate = ownCheckpoints
          .map((checkpoint) => checkpoint.date)
          .reduce((left, right) => left > right ? left : right);
      final context =
          'cycle=${cycle.id}, last=$modeledLastDate, today=${fixture.today}, '
          'own=${ownCheckpoints.length}, foreign=${foreignCheckpoints.length}';

      expect(
        modeledLastDate,
        fixture.lastCheckpointDate,
        reason:
            'O gerador deve identificar o último checkpoint próprio. '
            '$context',
      );
      expect(foreignCheckpoints, isNotEmpty, reason: context);
      expect(
        foreignCheckpoints.any((checkpoint) => checkpoint.date > fixture.today),
        isTrue,
        reason: 'Toda amostra deve desafiar o filtro de ciclo. $context',
      );

      final cycleBefore = _snapshotCycle(cycle);
      final checkpointObjectsBefore = List<Checkpoint>.of(checkpoints);
      final checkpointValuesBefore = checkpoints
          .map(_snapshotCheckpoint)
          .toList(growable: false);
      final sourceTimelineBefore = List<TimelineDayFixture>.of(
        fixture.timeline.days,
      );
      final metricTimeline = _project(fixture.timeline);
      final metricObjectsBefore = List<EligibleDay>.of(metricTimeline);
      final rateBefore = metrics.rate(
        metricTimeline,
        fixture.timeline.activationDate,
      );
      expect(
        rateBefore.denominator,
        greaterThan(0),
        reason: 'A comparação da taxa deve ter testemunha não vazia. $context',
      );

      final afterLast = policy.awaitingClosure(
        cycle,
        checkpoints,
        fixture.today,
      );

      expect(afterLast, isTrue, reason: context);
      expect(cycle.state, CycleState.active, reason: context);
      expect(cycle.purposeText, cycleBefore.purposeText, reason: context);

      final datesAroundLast = <OperationalDate>[
        fixture.lastCheckpointDate.previous,
        fixture.lastCheckpointDate,
        fixture.today,
      ];
      final expectedAroundLast = <bool>[false, false, true];
      for (var index = 0; index < datesAroundLast.length; index++) {
        final date = datesAroundLast[index];
        final ownOnly = policy.awaitingClosure(cycle, ownCheckpoints, date);
        final withForeign = policy.awaitingClosure(cycle, checkpoints, date);
        expect(
          ownOnly,
          expectedAroundLast[index],
          reason: '$context, at=$date',
        );
        expect(
          withForeign,
          ownOnly,
          reason:
              'Checkpoints estrangeiros não podem influenciar. '
              '$context, at=$date',
        );
      }

      expect(
        policy.awaitingClosure(cycle, foreignCheckpoints, fixture.today),
        isFalse,
        reason: 'Sem checkpoint próprio não há estado derivado. $context',
      );
      expect(
        policy.awaitingClosure(cycle, const <Checkpoint>[], fixture.today),
        isFalse,
        reason: 'Sem checkpoints não há estado derivado. $context',
      );

      final archivedCycle = _withState(cycle, CycleState.archived);
      expect(
        policy.awaitingClosure(archivedCycle, checkpoints, fixture.today),
        isFalse,
        reason: 'Ciclo arquivado nunca aguarda encerramento. $context',
      );

      final next = policy.nextFutureCheckpoint(
        cycle,
        checkpoints,
        fixture.today,
      );
      expect(
        next,
        isNull,
        reason: 'Após o último checkpoint próprio não há próximo. $context',
      );
      expect(
        policy.countdownDays(next, fixture.today),
        isNull,
        reason: 'Sem próximo checkpoint não há countdown. $context',
      );

      // Uma lista somente leitura torna qualquer tentativa de ordenar, inserir
      // ou remover checkpoints observável como falha do teste.
      expect(
        policy.awaitingClosure(
          cycle,
          List<Checkpoint>.unmodifiable(checkpoints),
          fixture.today,
        ),
        isTrue,
        reason: context,
      );

      // A API retorna apenas bool e não recebe repositório ou coleção de
      // ciclos. Logo, ausência de criação automática é observável pela mesma
      // instância ativa e pela lista de checkpoints sem adições/substituições.
      expect(_snapshotCycle(cycle), cycleBefore, reason: context);
      expect(
        checkpoints.length,
        checkpointObjectsBefore.length,
        reason: context,
      );
      expect(
        checkpoints.map(_snapshotCheckpoint),
        orderedEquals(checkpointValuesBefore),
        reason: context,
      );
      for (var index = 0; index < checkpoints.length; index++) {
        expect(
          checkpoints[index],
          same(checkpointObjectsBefore[index]),
          reason: '$context, checkpointIndex=$index',
        );
      }

      final rateAfter = metrics.rate(
        metricTimeline,
        fixture.timeline.activationDate,
      );
      expect(rateAfter, rateBefore, reason: context);
      expect(
        fixture.timeline.days,
        orderedEquals(sourceTimelineBefore),
        reason: context,
      );
      expect(
        metricTimeline.length,
        metricObjectsBefore.length,
        reason: context,
      );
      for (var index = 0; index < metricTimeline.length; index++) {
        expect(
          metricTimeline[index],
          same(metricObjectsBefore[index]),
          reason: '$context, metricDayIndex=$index',
        );
      }
    },
  );
}

_CycleSnapshot _snapshotCycle(Cycle cycle) => (
  id: cycle.id,
  name: cycle.name,
  purposeText: cycle.purposeText,
  startDate: cycle.startDate,
  endDate: cycle.endDate,
  state: cycle.state,
);

_CheckpointSnapshot _snapshotCheckpoint(Checkpoint checkpoint) => (
  id: checkpoint.id,
  cycleId: checkpoint.cycleId,
  competency: checkpoint.competency,
  date: checkpoint.date,
  status: checkpoint.status,
);

Cycle _withState(Cycle cycle, CycleState state) => Cycle(
  id: cycle.id,
  name: cycle.name,
  purposeText: cycle.purposeText,
  startDate: cycle.startDate,
  endDate: cycle.endDate,
  state: state,
);

bool _countsInRate(TimelineDayFixture day, OperationalDate activationDate) =>
    day.date >= activationDate && day.isWorkday && day.isClosed && !day.isMute;

List<EligibleDay> _project(TimelineFixture timeline) => <EligibleDay>[
  for (final day in timeline.days)
    EligibleDay(
      date: day.date,
      isWorkday: day.isWorkday,
      isClosed: day.isClosed,
      isSealed: day.isSealed,
      isMute: day.isMute,
    ),
];
