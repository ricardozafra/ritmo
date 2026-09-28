// Feature: ritmo, Property 32: Próximo checkpoint e contagem regressiva
//
// Para qualquer conjunto de checkpoints e qualquer data operacional de hoje,
// o próximo checkpoint é o de menor data estritamente futura do ciclo ativo,
// com desempate por menor id. A contagem é a diferença positiva em dias civis;
// na ausência de futuro, nenhuma data, checkpoint ou contagem é fabricada.
//
// **Validates: Requirements RF-06.4, RF-06.15, RF-06.18**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _Scenario = ({
  String label,
  Cycle cycle,
  OperationalDate today,
  List<Checkpoint> checkpoints,
});

typedef _ScenarioBatch = ({bool shrunk, List<_Scenario> scenarios});

typedef _CheckpointSnapshot = ({
  Checkpoint instance,
  String id,
  String cycleId,
  Competency competency,
  OperationalDate date,
  String status,
});

typedef _CycleSnapshot = ({
  Cycle instance,
  String id,
  String name,
  String purposeText,
  OperationalDate startDate,
  OperationalDate endDate,
  CycleState state,
});

typedef _CivilTurn = ({
  String label,
  OperationalDate today,
  OperationalDate tomorrow,
});

final List<_CivilTurn> _civilTurns = <_CivilTurn>[
  (
    label: 'virada de mês',
    today: OperationalDate(2026, 1, 31),
    tomorrow: OperationalDate(2026, 2, 1),
  ),
  (
    label: 'entrada no dia bissexto',
    today: OperationalDate(2024, 2, 28),
    tomorrow: OperationalDate(2024, 2, 29),
  ),
  (
    label: 'saída do dia bissexto',
    today: OperationalDate(2024, 2, 29),
    tomorrow: OperationalDate(2024, 3, 1),
  ),
  (
    label: 'virada de ano',
    today: OperationalDate(2026, 12, 31),
    tomorrow: OperationalDate(2027, 1, 1),
  ),
];

Cycle _cycle({
  required String id,
  required OperationalDate today,
  CycleState state = CycleState.active,
}) => Cycle(
  id: id,
  name: 'Ciclo $id',
  purposeText: 'Propósito preservado de $id',
  startDate: today.addDays(-60),
  endDate: today.addDays(180),
  state: state,
);

Checkpoint _checkpoint({
  required Random random,
  required String id,
  required String cycleId,
  required OperationalDate date,
}) => Checkpoint(
  id: id,
  cycleId: cycleId,
  competency: Competency.values[random.nextInt(Competency.values.length)],
  date: date,
  status: random.nextBool() ? 'pending' : 'done',
);

_ScenarioBatch _buildScenarioBatch(
  Random random,
  int size, {
  bool shrunk = false,
}) {
  final today = anyOperationalDate(random, size).value;
  final token = random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
  final spread = max(2, min(size + 2, 45));
  final nearestOffset = 1 + random.nextInt(spread);
  final fartherOffset = nearestOffset + 2 + random.nextInt(spread);
  final pastOffset = 1 + random.nextInt(spread);

  List<Checkpoint> shuffled(List<Checkpoint> values) =>
      List<Checkpoint>.of(values)..shuffle(random);

  final scenarios = <_Scenario>[];

  final emptyCycle = _cycle(id: '$token-empty', today: today);
  scenarios.add((
    label: 'lista vazia',
    cycle: emptyCycle,
    today: today,
    checkpoints: <Checkpoint>[],
  ));

  final noEligibleCycle = _cycle(id: '$token-no-eligible', today: today);
  scenarios.add((
    label: 'presente, passado e outro ciclo',
    cycle: noEligibleCycle,
    today: today,
    checkpoints: shuffled(<Checkpoint>[
      _checkpoint(
        random: random,
        id: '$token-past',
        cycleId: noEligibleCycle.id,
        date: today.addDays(-pastOffset),
      ),
      _checkpoint(
        random: random,
        id: '$token-today',
        cycleId: noEligibleCycle.id,
        date: today,
      ),
      _checkpoint(
        random: random,
        id: '$token-foreign-future',
        cycleId: '$token-foreign-cycle',
        date: today.next,
      ),
    ]),
  ));

  final selectionCycle = _cycle(id: '$token-selection', today: today);
  scenarios.add((
    label: 'mínimo futuro em entrada fora de ordem',
    cycle: selectionCycle,
    today: today,
    checkpoints: shuffled(<Checkpoint>[
      _checkpoint(
        random: random,
        id: '$token-farther',
        cycleId: selectionCycle.id,
        date: today.addDays(fartherOffset),
      ),
      _checkpoint(
        random: random,
        id: '$token-nearest',
        cycleId: selectionCycle.id,
        date: today.addDays(nearestOffset),
      ),
      _checkpoint(
        random: random,
        id: '$token-middle',
        cycleId: selectionCycle.id,
        date: today.addDays(nearestOffset + 1),
      ),
      _checkpoint(
        random: random,
        id: '$token-selection-today',
        cycleId: selectionCycle.id,
        date: today,
      ),
      _checkpoint(
        random: random,
        id: '$token-selection-past',
        cycleId: selectionCycle.id,
        date: today.previous,
      ),
      _checkpoint(
        random: random,
        id: '$token-foreign-earlier',
        cycleId: '$token-other-cycle',
        date: today.next,
      ),
    ]),
  ));

  final tieCycle = _cycle(id: '$token-tie', today: today);
  final tieDate = today.addDays(nearestOffset);
  scenarios.add((
    label: 'empate com menor id depois na lista',
    cycle: tieCycle,
    today: today,
    checkpoints: <Checkpoint>[
      _checkpoint(
        random: random,
        id: '$token-tie-z',
        cycleId: tieCycle.id,
        date: tieDate,
      ),
      _checkpoint(
        random: random,
        id: '$token-tie-a',
        cycleId: tieCycle.id,
        date: tieDate,
      ),
      _checkpoint(
        random: random,
        id: '$token-tie-later',
        cycleId: tieCycle.id,
        date: tieDate.next,
      ),
    ],
  ));

  final archivedCycle = _cycle(
    id: '$token-archived',
    today: today,
    state: CycleState.archived,
  );
  scenarios.add((
    label: 'ciclo arquivado com checkpoint futuro',
    cycle: archivedCycle,
    today: today,
    checkpoints: <Checkpoint>[
      _checkpoint(
        random: random,
        id: '$token-archived-future',
        cycleId: archivedCycle.id,
        date: today.next,
      ),
    ],
  ));

  for (final turn in _civilTurns) {
    final turnCycle = _cycle(id: '$token-${turn.label}', today: turn.today);
    scenarios.add((
      label: turn.label,
      cycle: turnCycle,
      today: turn.today,
      checkpoints: <Checkpoint>[
        _checkpoint(
          random: random,
          id: '$token-${turn.label}-farther',
          cycleId: turnCycle.id,
          date: turn.tomorrow.addDays(3),
        ),
        _checkpoint(
          random: random,
          id: '$token-${turn.label}-tomorrow',
          cycleId: turnCycle.id,
          date: turn.tomorrow,
        ),
      ],
    ));
  }

  return (shrunk: shrunk, scenarios: scenarios);
}

final Generator<_ScenarioBatch> _anyScenarioBatch = any.simple(
  generate: (Random random, int size) => _buildScenarioBatch(random, size),
  shrink: (_ScenarioBatch batch) sync* {
    if (!batch.shrunk) {
      yield _buildScenarioBatch(Random(0), 0, shrunk: true);
    }
  },
);

Checkpoint? _referenceNext(_Scenario scenario) {
  if (scenario.cycle.state != CycleState.active) return null;

  final eligible =
      <Checkpoint>[
        for (final checkpoint in scenario.checkpoints)
          if (checkpoint.cycleId == scenario.cycle.id &&
              checkpoint.date > scenario.today)
            checkpoint,
      ]..sort((left, right) {
        final byDate = left.date.compareTo(right.date);
        return byDate != 0 ? byDate : left.id.compareTo(right.id);
      });

  return eligible.isEmpty ? null : eligible.first;
}

/// Número ordinal gregoriano, calculado sem reutilizar a implementação da
/// política. O deslocamento absoluto é irrelevante; apenas diferenças importam.
int _civilOrdinal(OperationalDate date) {
  final adjustedYear = date.year - (date.month <= 2 ? 1 : 0);
  final era = adjustedYear ~/ 400;
  final yearOfEra = adjustedYear - era * 400;
  final shiftedMonth = date.month + (date.month > 2 ? -3 : 9);
  final dayOfYear = (153 * shiftedMonth + 2) ~/ 5 + date.day - 1;
  final dayOfEra =
      yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
  return era * 146097 + dayOfEra;
}

int _referenceCountdown(Checkpoint checkpoint, OperationalDate today) =>
    _civilOrdinal(checkpoint.date) - _civilOrdinal(today);

_CheckpointSnapshot _snapshotCheckpoint(Checkpoint checkpoint) => (
  instance: checkpoint,
  id: checkpoint.id,
  cycleId: checkpoint.cycleId,
  competency: checkpoint.competency,
  date: checkpoint.date,
  status: checkpoint.status,
);

_CycleSnapshot _snapshotCycle(Cycle cycle) => (
  instance: cycle,
  id: cycle.id,
  name: cycle.name,
  purposeText: cycle.purposeText,
  startDate: cycle.startDate,
  endDate: cycle.endDate,
  state: cycle.state,
);

void _expectInputsUnchanged(
  _Scenario scenario,
  _CycleSnapshot cycleBefore,
  List<_CheckpointSnapshot> checkpointsBefore,
  String context,
) {
  expect(scenario.cycle, same(cycleBefore.instance), reason: context);
  expect(scenario.cycle.id, cycleBefore.id, reason: context);
  expect(scenario.cycle.name, cycleBefore.name, reason: context);
  expect(scenario.cycle.purposeText, cycleBefore.purposeText, reason: context);
  expect(
    scenario.cycle.startDate,
    same(cycleBefore.startDate),
    reason: context,
  );
  expect(scenario.cycle.endDate, same(cycleBefore.endDate), reason: context);
  expect(scenario.cycle.state, cycleBefore.state, reason: context);

  expect(
    scenario.checkpoints.length,
    checkpointsBefore.length,
    reason: context,
  );
  for (var index = 0; index < checkpointsBefore.length; index++) {
    final checkpoint = scenario.checkpoints[index];
    final before = checkpointsBefore[index];
    expect(checkpoint, same(before.instance), reason: context);
    expect(checkpoint.id, before.id, reason: context);
    expect(checkpoint.cycleId, before.cycleId, reason: context);
    expect(checkpoint.competency, before.competency, reason: context);
    expect(checkpoint.date, same(before.date), reason: context);
    expect(checkpoint.status, before.status, reason: context);
  }
}

String _context(_Scenario scenario) {
  final checkpoints = scenario.checkpoints
      .map(
        (checkpoint) =>
            '${checkpoint.id}/${checkpoint.cycleId}/${checkpoint.date.iso}',
      )
      .join(', ');
  return '${scenario.label}; state=${scenario.cycle.state.name}; '
      'today=${scenario.today.iso}; checkpoints=[$checkpoints]';
}

void main() {
  const policy = CyclePolicy();

  Glados<_ScenarioBatch>(
    _anyScenarioBatch,
    RitmoGlados.ci(),
  ).test('Propriedade 32: próximo checkpoint e contagem regressiva', (
    _ScenarioBatch batch,
  ) {
    for (final scenario in batch.scenarios) {
      final context = _context(scenario);
      final cycleBefore = _snapshotCycle(scenario.cycle);
      final checkpointsBefore = <_CheckpointSnapshot>[
        for (final checkpoint in scenario.checkpoints)
          _snapshotCheckpoint(checkpoint),
      ];
      final expected = _referenceNext(scenario);

      final selected = policy.nextFutureCheckpoint(
        scenario.cycle,
        scenario.checkpoints,
        scenario.today,
      );

      if (expected == null) {
        expect(selected, isNull, reason: context);
        expect(
          policy.countdownDays(selected, scenario.today),
          isNull,
          reason: context,
        );
      } else {
        expect(selected, same(expected), reason: context);
        final actual = selected!;
        expect(actual.cycleId, scenario.cycle.id, reason: context);
        expect(actual.date > scenario.today, isTrue, reason: context);
        expect(
          scenario.checkpoints.any(
            (checkpoint) => identical(checkpoint, actual),
          ),
          isTrue,
          reason: context,
        );

        final expectedDays = _referenceCountdown(actual, scenario.today);
        final countdown = policy.countdownDays(actual, scenario.today);
        expect(countdown, expectedDays, reason: context);
        expect(countdown, greaterThan(0), reason: context);
      }

      // O método isolado deriva apenas da data recebida. O filtro de ciclo e
      // estado já foi exercitado acima pelo resultado de seleção.
      expect(
        policy.countdownDays(null, scenario.today),
        isNull,
        reason: context,
      );
      for (final checkpoint in scenario.checkpoints) {
        final countdown = policy.countdownDays(checkpoint, scenario.today);
        if (checkpoint.date <= scenario.today) {
          expect(countdown, isNull, reason: context);
        } else {
          final expectedDays = _referenceCountdown(checkpoint, scenario.today);
          expect(countdown, expectedDays, reason: context);
          expect(countdown, greaterThan(0), reason: context);
        }
      }

      _expectInputsUnchanged(scenario, cycleBefore, checkpointsBefore, context);
    }
  });
}
