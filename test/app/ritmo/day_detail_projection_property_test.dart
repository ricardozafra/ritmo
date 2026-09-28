// Feature: ritmo, Property 50: O detalhe do dia reflete o que está persistido
//
// Para qualquer estado diário válido, a projeção de detalhe da tela Ritmo
// espelha exatamente o que foi persistido: data operacional, resultado base e
// efetivo, lifecycle (`closed_at`), selo, `mute_cause` e `previous_result`. A
// projeção não inventa, oculta nem transforma nenhum desses campos.
//
// **Validates: Requirements RA-01.5, RA-01.6, RA-01.8**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/app/ritmo/ritmo_projection.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

void main() {
  final location = ensureBusinessLocation();

  Glados<DayStateFixture>(anyDayState, RitmoGlados.ci()).test(
    'Propriedade 50: o detalhe do dia espelha o estado persistido',
    (fixture) {
      final day = _day(fixture, location);
      final detail = const RitmoProjection().projectDay(day);
      final context =
          'base=${fixture.baseResult}, effective=${fixture.effectiveResult}, '
          'muteCause=${fixture.muteCause}, previous=${fixture.previousResult}, '
          'closed=${fixture.closedAt}, seal=${fixture.sealTimestamp}';

      expect(detail.operationalDate, day.operationalDate, reason: context);
      expect(detail.baseResult, day.baseResult, reason: context);
      expect(detail.effectiveResult, day.effectiveResult, reason: context);
      expect(detail.closedAt, day.closedAt, reason: context);
      expect(detail.sealTimestamp, day.sealTimestamp, reason: context);
      expect(detail.muteCause, day.muteCause, reason: context);
      expect(detail.previousResult, day.previousResult, reason: context);

      // Lifecycle derivado permanece coerente com o persistido.
      expect(detail.isOpen, day.isOpen, reason: context);
      expect(detail.isOpen, fixture.closedAt == null, reason: context);

      // Um dia mute preserva a causa e, no feriado, o resultado anterior.
      if (fixture.effectiveResult == FixtureDayResult.mute) {
        expect(detail.muteCause, isNotNull, reason: context);
        if (fixture.muteCause == FixtureMuteCause.holiday) {
          expect(detail.previousResult, isNotNull, reason: context);
        }
      } else {
        expect(detail.muteCause, isNull, reason: context);
      }
    },
  );
}

Day _day(DayStateFixture fx, tz.Location location) => Day(
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

DayResult _result(FixtureDayResult result) => switch (result) {
  FixtureDayResult.sealed => DayResult.sealed,
  FixtureDayResult.unsealed => DayResult.unsealed,
  FixtureDayResult.mute => DayResult.mute,
};
