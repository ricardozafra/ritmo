// Feature: ritmo, Property 31: Projeção do dia mute
//
// Para qualquer configuração válida e qualquer dia com resultado efetivo
// `mute` (fim de semana ou feriado), a projeção da tela Hoje é sempre a visão
// muda: expõe exclusivamente a frase literal "Território sagrado. Presença
// integral." e nunca revela pilares, ações ou o resumo do ciclo, ainda que os
// registros brutos dos pilares variem livremente.
//
// **Validates: Requirements RF-05.12, RF-05.14**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/app/today/today_projection.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/data/repositories/today_repository.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/today_view.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _MuteFixture = ({
  DayStateFixture day,
  PillarEntriesFixture entries,
  OperationalCalendar calendar,
});

/// Somente os estados `mute` (fim de semana e feriado) do gerador de dias,
/// combinados com registros de pilar arbitrários e uma configuração válida.
final Generator<_MuteFixture> _anyMuteDay = any.simple(
  generate: (random, size) {
    DayStateFixture day;
    do {
      day = anyDayState(random, size).value;
    } while (day.effectiveResult != FixtureDayResult.mute);
    return (
      day: day,
      entries: anyPillarEntries(random, size).value,
      calendar: anySettings(random, size).value,
    );
  },
  shrink: (fixture) sync* {
    if (fixture.calendar != canonicalCalendar) {
      yield (
        day: fixture.day,
        entries: fixture.entries,
        calendar: canonicalCalendar,
      );
    }
  },
);

void main() {
  Glados<_MuteFixture>(_anyMuteDay, RitmoGlados.ci()).test(
    'Propriedade 31: todo dia mute projeta apenas a visão muda',
    (fixture) {
      final clock = SystemOperationalClock(
        calendar: fixture.calendar,
        deviceInstant: () => DateTime.utc(2026, 1, 5, 12),
      );
      final snapshot = _snapshot(fixture, clock.businessLocation);

      final view = const TodayProjection().project(
        snapshot: snapshot,
        clock: clock,
        now: clock.nowInBusinessZone(),
      );

      final context =
          'muteCause=${fixture.day.muteCause}, '
          'previous=${fixture.day.previousResult}, '
          'entries=${fixture.entries}';

      expect(view, isA<MuteTodayView>(), reason: context);
      final mute = view as MuteTodayView;
      expect(mute.message, Copy.muteDay, reason: context);
      expect(mute.operationalDate, fixture.day.date, reason: context);
      // A visão muda não é um WorkdayTodayView: pilares, ações, selo e resumo
      // do ciclo simplesmente não existem nesse ramo do tipo selado.
      expect(view, isNot(isA<WorkdayTodayView>()), reason: context);
    },
  );
}

TodaySnapshot _snapshot(_MuteFixture fixture, tz.Location location) {
  final fx = fixture.day;
  final day = Day(
    operationalDate: fx.date,
    baseResult: _result(fx.baseResult),
    effectiveResult: _result(fx.effectiveResult),
    closedAt: fx.closedAt == null
        ? null
        : tz.TZDateTime.from(fx.closedAt!, location),
    sealTimestamp: fx.sealTimestamp == null
        ? null
        : tz.TZDateTime.from(fx.sealTimestamp!, location),
    muteCause: switch (fx.muteCause) {
      FixtureMuteCause.weekend => MuteCause.weekend,
      FixtureMuteCause.holiday => MuteCause.holiday,
      null => null,
    },
    previousResult: fx.previousResult == null
        ? null
        : _result(fx.previousResult!),
  );

  return TodaySnapshot(
    day: day,
    entries: _entries(fixture.entries),
    linkedStudyBlock: null,
    activeWaiver: null,
    visibleInitiative: null,
    cycle: _seedCycle,
    checkpoints: const <Checkpoint>[],
  );
}

PillarEntriesSnapshot _entries(PillarEntriesFixture fx) =>
    PillarEntriesSnapshot(
      morning: MorningEntry(
        workoutDone: fx.workoutDone,
        briefingDone: fx.briefingDone,
        briefingMode: fx.briefingMode,
      ),
      day: DayEntry(toggleOn: fx.toggleOn, note: fx.note),
      night: NightEntry(kind: fx.nightKind, recoveryNote: fx.recoveryNote),
    );

DayResult _result(FixtureDayResult result) => switch (result) {
  FixtureDayResult.sealed => DayResult.sealed,
  FixtureDayResult.unsealed => DayResult.unsealed,
  FixtureDayResult.mute => DayResult.mute,
};

final Cycle _seedCycle = Cycle(
  id: 'cycle-seed-v1',
  name: 'Ciclo',
  purposeText: 'Finalidade do ciclo seed',
  startDate: OperationalDate(2026, 1, 1),
  endDate: OperationalDate(2027, 6, 30),
  state: CycleState.active,
);
