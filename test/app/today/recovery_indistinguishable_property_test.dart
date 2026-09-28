// Feature: ritmo, Property 15: Recuperação é indistinguível na apresentação
//
// Para qualquer dia útil aberto cujos demais pilares variam livremente, trocar
// a conclusão noturna entre Estudo encerrado e Recuperação não altera nada na
// projeção que a interface usa para apresentar o dia: a conclusão do Pilar da
// Noite, a elegibilidade de selo, os pilares descobertos e o modo permanecem
// idênticos. Recuperação nunca recebe peso, ordenação ou estado inferior.
//
// **Validates: Requirements RF-04.4**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/app/today/today_projection.dart';
import 'package:ritmo/data/repositories/today_repository.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/study_block.dart';
import 'package:ritmo/domain/day/today_view.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _DayShape = ({bool workoutDone, bool briefingDone, bool toggleOn});

/// Combinações dos pilares Manhã e Dia; o Pilar da Noite é sempre concluído,
/// ora por Estudo encerrado, ora por Recuperação, para isolar a equivalência.
final Generator<_DayShape> _anyDayShape = any.simple(
  generate: (random, size) => (
    workoutDone: random.nextBool(),
    briefingDone: random.nextBool(),
    toggleOn: random.nextBool(),
  ),
  shrink: (value) sync* {
    if (value.workoutDone || value.briefingDone || value.toggleOn) {
      yield (workoutDone: false, briefingDone: false, toggleOn: false);
    }
  },
);

final tz.Location _location = ensureBusinessLocation();
final OperationalDate _date = OperationalDate(2026, 1, 5); // segunda, dia útil

void main() {
  final clock = SystemOperationalClock(
    deviceInstant: () => DateTime.utc(2026, 1, 5, 12),
  );

  Glados<_DayShape>(_anyDayShape, RitmoGlados.ci()).test(
    'Propriedade 15: Estudo encerrado e Recuperação projetam-se igualmente',
    (shape) {
      final studyView = _project(
        shape,
        night: const NightEntry(kind: NightKind.study, studyBlockId: 'block-1'),
        studyBlock: _endedBlock(),
        clock: clock,
      );
      final recoveryView = _project(
        shape,
        night: const NightEntry(kind: NightKind.recovery),
        studyBlock: null,
        clock: clock,
      );

      final context = 'shape=$shape';

      // O Pilar da Noite conclui igualmente em ambos.
      expect(recoveryView.pillarStatus.nightCompleted, isTrue, reason: context);
      expect(
        studyView.pillarStatus.nightCompleted,
        recoveryView.pillarStatus.nightCompleted,
        reason: context,
      );

      // Nenhuma diferença de peso na apresentação derivada do dia.
      expect(recoveryView.mode, studyView.mode, reason: context);
      expect(
        recoveryView.sealEligible,
        studyView.sealEligible,
        reason: context,
      );
      expect(
        recoveryView.pillarStatus.morningCompleted,
        studyView.pillarStatus.morningCompleted,
        reason: context,
      );
      expect(
        recoveryView.pillarStatus.dayCompleted,
        studyView.pillarStatus.dayCompleted,
        reason: context,
      );
      expect(
        recoveryView.uncoveredIncompletePillars,
        studyView.uncoveredIncompletePillars,
        reason: context,
      );
    },
  );
}

WorkdayTodayView _project(
  _DayShape shape, {
  required NightEntry night,
  required StudyBlock? studyBlock,
  required SystemOperationalClock clock,
}) {
  final snapshot = TodaySnapshot(
    day: Day(
      operationalDate: _date,
      baseResult: DayResult.unsealed,
      effectiveResult: DayResult.unsealed,
    ),
    entries: PillarEntriesSnapshot(
      morning: MorningEntry(
        workoutDone: shape.workoutDone,
        briefingDone: shape.briefingDone,
      ),
      day: DayEntry(toggleOn: shape.toggleOn),
      night: night,
    ),
    linkedStudyBlock: studyBlock,
    activeWaiver: null,
    visibleInitiative: null,
    cycle: _seedCycle,
    checkpoints: const <Checkpoint>[],
  );

  final view = const TodayProjection().project(
    snapshot: snapshot,
    clock: clock,
    now: clock.nowInBusinessZone(),
  );
  return view as WorkdayTodayView;
}

StudyBlock _endedBlock() {
  final started = tz.TZDateTime(_location, 2026, 1, 5, 22);
  return StudyBlock(
    id: 'block-1',
    operationalDate: _date,
    startedAt: started,
    blockDeadline: tz.TZDateTime(_location, 2026, 1, 6, 3),
    endedAt: started.add(const Duration(minutes: 30)),
  );
}

final Cycle _seedCycle = Cycle(
  id: 'cycle-seed-v1',
  name: 'Ciclo',
  purposeText: 'Finalidade do ciclo seed',
  startDate: OperationalDate(2026, 1, 1),
  endDate: OperationalDate(2027, 6, 30),
  state: CycleState.active,
);
