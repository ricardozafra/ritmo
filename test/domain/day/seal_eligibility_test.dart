import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';

void main() {
  PillarStatus status({
    bool morning = true,
    bool day = true,
    bool night = true,
  }) => PillarStatus(
    morningCompleted: morning,
    dayCompleted: day,
    nightCompleted: night,
  );

  test('três pilares concluídos permitem selo sem dispensa', () {
    expect(sealEligible(status(), null), isTrue);
  });

  test('dois concluídos e o incompleto coberto permitem selo', () {
    expect(
      sealEligible(
        status(night: false),
        const PillarWaiver(pillar: Pillar.night),
      ),
      isTrue,
    );
  });

  test('dispensa de outro pilar não cobre o pilar incompleto', () {
    final current = status(day: false);
    final waiver = const PillarWaiver(pillar: Pillar.morning);

    expect(sealEligible(current, waiver), isFalse);
    expect(uncoveredIncompletePillars(current, waiver), {Pillar.day});
  });

  test('mais de um pilar incompleto nunca permite selo', () {
    expect(
      sealEligible(
        status(morning: false, night: false),
        const PillarWaiver(pillar: Pillar.morning),
      ),
      isFalse,
    );
  });
}
