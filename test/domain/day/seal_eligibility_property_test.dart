// Feature: ritmo, Property 8: Elegibilidade do selo
//
// Para qualquer estado de conclusão dos três pilares e qualquer dispensa
// ativa, o selo é permitido se e somente se o conjunto de pilares incompletos
// é vazio, ou tem exatamente um elemento e esse elemento é o pilar coberto
// pela dispensa ativa.
//
// **Validates: Requirements RF-02.1, RF-02.2, RF-02.3, RF-02.7, RF-02.8**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

Pillar _pillarOf(FixturePillar pillar) => switch (pillar) {
  FixturePillar.morning => Pillar.morning,
  FixturePillar.day => Pillar.day,
  FixturePillar.night => Pillar.night,
};

/// Somente dispensas com `revoked_at` nulo têm efeito (RF-02.25).
Pillar? _activeWaiverPillar(FixtureWaiver waiver) => switch (waiver) {
  FixtureWaiver.none || FixtureWaiver.revoked => null,
  FixtureWaiver.activeMorning => Pillar.morning,
  FixtureWaiver.activeDay => Pillar.day,
  FixtureWaiver.activeNight => Pillar.night,
};

void main() {
  final tz.Location businessLocation = ensureBusinessLocation();
  final OperationalDate workday = OperationalDate(2026, 1, 5); // segunda
  final tz.TZDateTime sealInstant = tz.TZDateTime(
    businessLocation,
    2026,
    1,
    5,
    22,
    30,
  );
  const DayStateMachine stateMachine = DayStateMachine();

  Glados<PillarStateFixture>(anyPillarState, RitmoGlados.ci()).test(
    'Propriedade 8: elegibilidade do selo',
    (PillarStateFixture fixture) {
      // Modelo de referência derivado do fixture, sem consultar o domínio.
      final Set<Pillar> missing = {
        for (final pillar in FixturePillar.values)
          if (!fixture.completed.contains(pillar)) _pillarOf(pillar),
      };
      final Pillar? waiverPillar = _activeWaiverPillar(fixture.waiver);
      final bool expectedEligible =
          missing.isEmpty ||
          (missing.length == 1 && waiverPillar == missing.single);
      final Set<Pillar> expectedUncovered = {
        for (final pillar in missing)
          if (pillar != waiverPillar) pillar,
      };

      final status = PillarStatus(
        morningCompleted: fixture.completed.contains(FixturePillar.morning),
        dayCompleted: fixture.completed.contains(FixturePillar.day),
        nightCompleted: fixture.completed.contains(FixturePillar.night),
      );
      final PillarWaiver? activeWaiver = waiverPillar == null
          ? null
          : PillarWaiver(pillar: waiverPillar);
      final context = 'incompletos $missing, dispensa ${fixture.waiver.name}';

      // Bicondicional da elegibilidade (RF-02.2, RF-02.3, RF-02.7).
      expect(
        sealEligible(status, activeWaiver),
        expectedEligible,
        reason: context,
      );
      expect(status.incompletePillars, missing, reason: context);

      // O que falta é exatamente o incompleto não coberto (RF-02.8).
      expect(
        uncoveredIncompletePillars(status, activeWaiver),
        expectedUncovered,
        reason: context,
      );
      expect(expectedUncovered.isEmpty, expectedEligible, reason: context);

      // O comando de selo em dia útil aberto respeita a elegibilidade e
      // registra `seal_timestamp` mantendo o dia aberto (RF-02.1, RF-02.2).
      final open = Day(
        operationalDate: workday,
        baseResult: DayResult.unsealed,
        effectiveResult: DayResult.unsealed,
      );
      final transition = stateMachine.apply(
        open,
        const SealDay(),
        SealContext(
          isEligible: sealEligible(status, activeWaiver),
          now: sealInstant,
          uncoveredIncompletePillars: uncoveredIncompletePillars(
            status,
            activeWaiver,
          ),
        ),
      );

      switch (transition) {
        case Success<Day, DayViolation>(:final value):
          expect(expectedEligible, isTrue, reason: context);
          expect(value.isOpen, isTrue, reason: context);
          expect(value.baseResult, DayResult.sealed, reason: context);
          expect(value.effectiveResult, DayResult.sealed, reason: context);
          expect(value.sealTimestamp, sealInstant, reason: context);
        case Failure<Day, DayViolation>(:final failure):
          expect(expectedEligible, isFalse, reason: context);
          expect(failure.code, 'day_not_seal_eligible', reason: context);
          expect(failure.message, isNotEmpty, reason: context);
      }
    },
  );
}
