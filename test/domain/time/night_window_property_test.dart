// Feature: ritmo, Property 3: Particionamento da janela noturna
//
// Para qualquer configuração válida, data operacional d e instante t com
// operationalOpen(d) <= t < operationalClose(d): antes de blockDeadline(d),
// as alternativas são exatamente {study, recovery}; a partir do deadline e
// antes do fechamento, são exatamente {recovery} com a copy literal. No
// fechamento e depois dele, nenhuma ação ordinária permanece disponível.
//
// **Validates: Requirements RF-01.11, RF-01.13, RF-01.17, RF-01.19,
// RF-01.21**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/time/night_window.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../../generators/shared.dart';

void main() {
  Glados2<OperationalCalendar, OperationalDate>(
    anySettings,
    anyOperationalDate,
    RitmoGlados.ci(),
  ).test('Propriedade 3: particionamento da janela noturna', (
    OperationalCalendar calendar,
    OperationalDate date,
  ) {
    var injectedInstant = DateTime.utc(2000);
    final clock = SystemOperationalClock(
      calendar: calendar,
      deviceInstant: () => injectedInstant,
    );
    final window = NightWindow(clock);
    final open = clock.operationalOpen(date);
    final deadline = clock.blockDeadline(date);
    final close = clock.operationalClose(date);

    expect(deadline.isAfter(open), isTrue);
    expect(deadline.isAfter(close), isFalse);

    void expectPartition(DateTime instant) {
      injectedInstant = instant.toUtc();
      final now = clock.nowInBusinessZone();
      final state = window.evaluate(now: now, operationalDate: date);
      final context =
          'data ${date.iso}, fechamento ${calendar.dayCloseTime}, '
          'deadline ${calendar.nightEndTime}, instante $now';

      if (now.isBefore(deadline)) {
        expect(state.actions, const <NightAction>{
          NightAction.study,
          NightAction.recovery,
        }, reason: context);
        expect(state.allowsStudy, isTrue, reason: context);
        expect(state.allowsRecovery, isTrue, reason: context);
        expect(state.copy, isNull, reason: context);
      } else if (now.isBefore(close)) {
        expect(state.actions, const <NightAction>{
          NightAction.recovery,
        }, reason: context);
        expect(state.allowsStudy, isFalse, reason: context);
        expect(state.allowsRecovery, isTrue, reason: context);
        expect(state.copy, Copy.nightRecoveryOnly, reason: context);
      } else {
        expect(state.actions, isEmpty, reason: context);
        expect(state.allowsStudy, isFalse, reason: context);
        expect(state.allowsRecovery, isFalse, reason: context);
        expect(state.copy, isNull, reason: context);
      }
    }

    // Fronteiras exatas e vizinhanças das três partições. Quando o deadline
    // coincide com o fechamento, a partição intermediária é corretamente
    // vazia e o instante exato já pertence ao estado fechado.
    for (final instant in <DateTime>{
      open,
      deadline.subtract(const Duration(microseconds: 1)),
      deadline,
      close.subtract(const Duration(microseconds: 1)),
      close,
      close.add(const Duration(microseconds: 1)),
    }) {
      expectPartition(instant);
    }
  });
}
