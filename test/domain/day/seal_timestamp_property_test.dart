// Feature: ritmo, Property 9: Selo e reabertura preservam apenas o último
// timestamp
//
// Para qualquer dia elegível e qualquer sequência de ações alternadas
// "Selar o Dia" e "Reabrir o Dia", o estado final tem `seal_timestamp` nulo
// quando `unsealed` e igual ao instante do último selo aplicado quando
// `sealed`; nenhum timestamp intermediário é preservado.
//
// **Validates: Requirements RF-02.2, RF-02.4, RF-02.5**

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

/// Ações do usuário sobre o selo do dia aberto (RF-02.2, RF-02.4).
enum SealAction { seal, reopen }

/// Estado dos pilares mais uma sequência arbitrária de selo/reabertura,
/// incluindo repetições fora de ordem: a máquina de estados precisa rejeitá-las
/// sem alterar o timestamp.
typedef SealRun = ({PillarStateFixture pillars, List<SealAction> actions});

final Generator<SealRun> anySealRun = any.simple(
  generate: (random, size) {
    final length = 1 + random.nextInt(math.max(1, math.min(size, 12)));
    return (
      pillars: anyPillarState(random, size).value,
      actions: List<SealAction>.generate(
        length,
        (_) => random.nextBool() ? SealAction.seal : SealAction.reopen,
      ),
    );
  },
  shrink: (value) sync* {
    if (value.actions.length > 1) {
      yield (
        pillars: value.pillars,
        actions: value.actions.sublist(0, value.actions.length - 1),
      );
    }
  },
);

void main() {
  const machine = DayStateMachine();

  Glados3<OperationalDate, OperationalCalendar, SealRun>(
    anyOperationalDate,
    anySettings,
    anySealRun,
    RitmoGlados.ci(),
  ).test('Propriedade 9: apenas o último seal_timestamp é preservado', (
    OperationalDate date,
    OperationalCalendar calendar,
    SealRun run,
  ) {
    final pillars = run.pillars;
    final actions = run.actions;
    final clock = SystemOperationalClock(calendar: calendar);
    // Relógio controlado dentro da janela da própria data operacional: cada
    // ação acontece em um instante estritamente posterior ao anterior.
    final fakeClock = FakeClock(
      calendar.operationalOpen(date).toCivilDateTime(),
      calendar: calendar,
    );

    final waiverPillar = activeWaiverPillar(pillars.waiver);
    final status = PillarStatus(
      morningCompleted: pillars.completed.contains(FixturePillar.morning),
      dayCompleted: pillars.completed.contains(FixturePillar.day),
      nightCompleted: pillars.completed.contains(FixturePillar.night),
    );
    final waiver = waiverPillar == null
        ? null
        : PillarWaiver(pillar: waiverPillar);
    final isEligible = sealEligible(status, waiver);

    var day = Day(
      operationalDate: date,
      baseResult: DayResult.unsealed,
      effectiveResult: DayResult.unsealed,
    );

    final appliedSeals = <tz.TZDateTime>[];

    for (final action in actions) {
      fakeClock.advance(const Duration(minutes: 7));
      final now = clock.resolveCivil(fakeClock.civilMoment);
      final previous = day;
      final result = machine.apply(
        previous,
        action == SealAction.seal ? const SealDay() : const ReopenDay(),
        SealContext(
          isEligible: isEligible,
          now: now,
          uncoveredIncompletePillars: uncoveredIncompletePillars(
            status,
            waiver,
          ),
        ),
      );
      final context =
          'data ${date.iso}, fechamento ${calendar.dayCloseTime}, '
          'elegível $isEligible, ação $action, instante $now';

      switch (result) {
        case Success<Day, DayViolation>(:final value):
          day = value;
          if (action == SealAction.seal) {
            appliedSeals.add(now);
            expect(day.baseResult, DayResult.sealed, reason: context);
            expect(day.sealTimestamp, now, reason: context);
          } else {
            expect(day.baseResult, DayResult.unsealed, reason: context);
            expect(day.sealTimestamp, isNull, reason: context);
          }
        case Failure<Day, DayViolation>():
          // Ação rejeitada não aplica selo nem reabertura: o estado, incluindo
          // o timestamp, permanece idêntico.
          expect(day.baseResult, previous.baseResult, reason: context);
          expect(day.sealTimestamp, previous.sealTimestamp, reason: context);
      }

      // Invariante contínua: `sealed` se e somente se há timestamp, e o
      // timestamp é sempre o do último selo aplicado.
      expect(
        day.sealTimestamp,
        day.baseResult == DayResult.sealed ? appliedSeals.last : isNull,
        reason: context,
      );
      expect(day.isOpen, isTrue, reason: context);
    }

    final finalContext =
        'sequência $actions, elegível $isEligible, selos $appliedSeals';

    if (day.baseResult == DayResult.sealed) {
      expect(day.sealTimestamp, appliedSeals.last, reason: finalContext);
      expect(day.effectiveResult, DayResult.sealed, reason: finalContext);
      // Nenhum timestamp intermediário sobrevive ao último selo.
      for (final intermediate in appliedSeals.take(appliedSeals.length - 1)) {
        expect(day.sealTimestamp, isNot(intermediate), reason: finalContext);
      }
    } else {
      expect(day.sealTimestamp, isNull, reason: finalContext);
      expect(day.effectiveResult, DayResult.unsealed, reason: finalContext);
    }
  });
}
