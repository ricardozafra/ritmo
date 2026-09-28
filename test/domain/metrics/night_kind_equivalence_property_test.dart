// Feature: ritmo, Property 14: Estudo e Recuperação são equivalentes na métrica
//
// Para qualquer linha do tempo, trocar arbitrariamente `study` por `recovery`
// (ou o inverso) em qualquer subconjunto de dias selados não altera o
// numerador nem o denominador. Cada um desses dias contribui exatamente uma
// unidade ao numerador e ao denominador quando avaliado isoladamente.
//
// **Validates: Requirements RF-04.3, RF-04.5**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/metrics/metrics_calculator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _NightTimelineFixture = ({
  TimelineFixture timeline,
  List<NightKind?> nightKinds,
  Set<int> swappedIndexes,
});

final Generator<_NightTimelineFixture> _anyNightTimeline = any.simple(
  generate: (random, size) {
    final generated = anyTimeline(random, size).value;
    final days = [...generated.days];

    // Evita casos exclusivamente vacuosos: toda amostra contém ao menos um
    // dia elegível, encerrado e selado cujo tipo noturno pode ser trocado.
    // Dias abertos, mute e pré-ativação não satisfazem RF-04.3/RF-04.5 porque
    // não participam da taxa, ainda que um fixture bruto carregue isSealed.
    if (!days.any(
      (day) =>
          _isMetricEligible(day, generated.activationDate) && day.isSealed,
    )) {
      final index = days.indexWhere(
        (day) => _isMetricEligible(day, generated.activationDate),
      );
      assert(index >= 0, 'anyTimeline deve gerar ao menos um dia elegível');
      final day = days[index];
      days[index] = (
        date: day.date,
        isWorkday: day.isWorkday,
        isClosed: day.isClosed,
        isSealed: true,
        isMute: day.isMute,
        muteCause: day.muteCause,
      );
    }

    final eligibleSealedIndexes = <int>[
      for (var index = 0; index < days.length; index++)
        if (_isMetricEligible(days[index], generated.activationDate) &&
            days[index].isSealed)
          index,
    ];
    final swappedIndexes = <int>{
      for (final index in eligibleSealedIndexes)
        if (random.nextBool()) index,
    };
    if (swappedIndexes.isEmpty) {
      swappedIndexes.add(
        eligibleSealedIndexes[random.nextInt(eligibleSealedIndexes.length)],
      );
    }

    return (
      timeline: (activationDate: generated.activationDate, days: days),
      nightKinds: <NightKind?>[
        for (final day in days)
          day.isSealed
              ? (random.nextBool() ? NightKind.study : NightKind.recovery)
              : null,
      ],
      swappedIndexes: swappedIndexes,
    );
  },
  shrink: (fixture) sync* {
    // Preserva uma testemunha mínima não vacuosa: um único dia elegível,
    // encerrado e selado cujo tipo noturno ainda será efetivamente trocado.
    final index = fixture.swappedIndexes.first;
    final day = fixture.timeline.days[index];
    yield (
      timeline: (activationDate: day.date, days: <TimelineDayFixture>[day]),
      nightKinds: <NightKind?>[fixture.nightKinds[index]],
      swappedIndexes: <int>{0},
    );
  },
);

void main() {
  const calculator = MetricsCalculator();

  Glados<_NightTimelineFixture>(
    _anyNightTimeline,
    RitmoGlados.ci(),
  ).test('Propriedade 14: Estudo e Recuperação são equivalentes na métrica', (
    fixture,
  ) {
    final before = _project(fixture.timeline.days, fixture.nightKinds);
    final afterKinds = <NightKind?>[
      for (var index = 0; index < fixture.nightKinds.length; index++)
        fixture.swappedIndexes.contains(index)
            ? _opposite(fixture.nightKinds[index]!)
            : fixture.nightKinds[index],
    ];
    final after = _project(fixture.timeline.days, afterKinds);

    final beforeRate = calculator.rate(
      before,
      fixture.timeline.activationDate,
    );
    final afterRate = calculator.rate(after, fixture.timeline.activationDate);

    expect(afterRate.numerator, beforeRate.numerator);
    expect(afterRate.denominator, beforeRate.denominator);

    for (final index in fixture.swappedIndexes) {
      expect(afterKinds[index], isNot(fixture.nightKinds[index]));
      final day = after[index];
      expect(
        calculator.rate([day], day.date),
        Rate(numerator: 1, denominator: 1),
        reason: 'Dia selado ${day.date} deve valer uma unidade com '
            '${afterKinds[index]}.',
      );
    }
  });
}

bool _isMetricEligible(
  TimelineDayFixture day,
  OperationalDate activationDate,
) =>
    day.date >= activationDate &&
    day.isWorkday &&
    day.isClosed &&
    !day.isMute;

List<EligibleDay> _project(
  List<TimelineDayFixture> days,
  List<NightKind?> nightKinds,
) {
  assert(days.length == nightKinds.length);
  return <EligibleDay>[
    for (var index = 0; index < days.length; index++)
      EligibleDay(
        date: days[index].date,
        isWorkday: days[index].isWorkday,
        isClosed: days[index].isClosed,
        isSealed: days[index].isSealed,
        isMute: days[index].isMute,
      ),
  ];
}

NightKind _opposite(NightKind kind) => switch (kind) {
  NightKind.study => NightKind.recovery,
  NightKind.recovery => NightKind.study,
};
