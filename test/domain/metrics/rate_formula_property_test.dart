// Feature: ritmo, Property 13: Fórmula da taxa
//
// Para qualquer linha do tempo e qualquer `activation_date`, a taxa é a razão
// entre dias úteis elegíveis encerrados e selados e todos os dias úteis
// elegíveis encerrados. Dias abertos, `mute` e anteriores à ativação não
// participam; um dia selado com dispensa ativa conta integralmente.
//
// **Validates: Requirements RF-02.16, RF-02.17, RF-02.18, RF-02.20, RF-05.8,
// RF-05.15**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/metrics/metrics_calculator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _RateDayInput = ({
  OperationalDate date,
  bool isWorkday,
  bool isClosed,
  bool isSealed,
  bool isMute,
  bool hasActiveWaiver,
});
typedef _RateInput = ({
  OperationalDate activationDate,
  List<_RateDayInput> days,
});
typedef _ReferenceRate = ({int numerator, int denominator});

final Generator<_RateInput> _anyRateInput = any.simple(
  generate: (Random random, int size) {
    final activationDate = anyOperationalDate(random, size).value;
    final start = activationDate.addDays(-7);
    final length = 15 + random.nextInt(max(1, min(size + 1, 26)));
    final holidayOffset = 7 + random.nextInt(length - 7);
    final days = <_RateDayInput>[
      for (var offset = 0; offset < length; offset++)
        _randomRateDay(
          random,
          start.addDays(offset),
          isHoliday: offset == holidayOffset,
        ),
    ];

    final beforeActivation = days.lastIndexWhere(
      (day) => day.date < activationDate && day.isWorkday,
    );
    final eligibleIndexes = <int>[
      for (var index = 0; index < days.length; index++)
        if (days[index].date >= activationDate && days[index].isWorkday) index,
    ];

    // Cada execução contém testemunhas não vacuosas para pré-ativação, dia
    // selado com dispensa, dia encerrado não selado e dia ainda aberto.
    days[beforeActivation] = _withState(
      days[beforeActivation],
      isClosed: true,
      isSealed: true,
    );
    days[eligibleIndexes[0]] = _withState(
      days[eligibleIndexes[0]],
      isClosed: true,
      isSealed: true,
      hasActiveWaiver: true,
    );
    days[eligibleIndexes[1]] = _withState(
      days[eligibleIndexes[1]],
      isClosed: true,
      isSealed: false,
    );
    days[eligibleIndexes[2]] = _withState(
      days[eligibleIndexes[2]],
      isClosed: false,
      isSealed: true,
    );

    return (activationDate: activationDate, days: days);
  },
  shrink: (input) sync* {
    if (input.days.isNotEmpty) {
      yield (activationDate: input.activationDate, days: <_RateDayInput>[]);
      yield (activationDate: input.activationDate, days: [input.days.first]);
    }
  },
);

_RateDayInput _randomRateDay(
  Random random,
  OperationalDate date, {
  required bool isHoliday,
}) {
  final isMute = date.isWeekend || isHoliday;
  final isSealed = random.nextBool();
  return (
    date: date,
    isWorkday: !isMute,
    isClosed: random.nextBool(),
    isSealed: isSealed,
    isMute: isMute,
    hasActiveWaiver: isSealed && !isMute && random.nextBool(),
  );
}

_RateDayInput _withState(
  _RateDayInput day, {
  bool? isClosed,
  bool? isSealed,
  bool? hasActiveWaiver,
}) => (
  date: day.date,
  isWorkday: day.isWorkday,
  isClosed: isClosed ?? day.isClosed,
  isSealed: isSealed ?? day.isSealed,
  isMute: day.isMute,
  hasActiveWaiver: hasActiveWaiver ?? day.hasActiveWaiver,
);

_ReferenceRate _referenceRate(_RateInput input) {
  var numerator = 0;
  var denominator = 0;
  for (final day in input.days) {
    final counts =
        day.date >= input.activationDate &&
        day.isWorkday &&
        day.isClosed &&
        !day.isMute;
    if (!counts) continue;
    denominator++;
    if (day.isSealed) numerator++;
  }
  return (numerator: numerator, denominator: denominator);
}

EligibleDay _toProductionDay(_RateDayInput day) => EligibleDay(
  date: day.date,
  isWorkday: day.isWorkday,
  isClosed: day.isClosed,
  isSealed: day.isSealed,
  isMute: day.isMute,
);

void main() {
  const calculator = MetricsCalculator();

  Glados<_RateInput>(_anyRateInput, RitmoGlados.ci()).test(
    'Propriedade 13: fórmula da taxa',
    (_RateInput input) {
      // Modelo de referência independente: opera apenas sobre a entrada bruta
      // do teste e não chama tipos, filtros ou helpers do cálculo de produção.
      final expected = _referenceRate(input);
      final timeline = input.days.map(_toProductionDay).toList(growable: false);
      final actual = calculator.rate(timeline, input.activationDate);
      final waivedEligible = input.days.where(
        (day) =>
            day.hasActiveWaiver &&
            day.date >= input.activationDate &&
            day.isWorkday &&
            day.isClosed &&
            !day.isMute &&
            day.isSealed,
      );
      final context =
          'activation=${input.activationDate}, total=${input.days.length}, '
          'esperado=${expected.numerator}/${expected.denominator}, '
          'dispensas seladas elegíveis=${waivedEligible.length}';

      expect(actual.numerator, expected.numerator, reason: context);
      expect(actual.denominator, expected.denominator, reason: context);

      // A testemunha gerada com dispensa ativa deve ser contada por inteiro;
      // a projeção de produção não lê a dispensa nem aplica peso fracionário.
      expect(waivedEligible, isNotEmpty, reason: context);
      expect(actual.numerator, greaterThanOrEqualTo(waivedEligible.length));

      // Remover exatamente os dias excluídos pelo modelo não altera a taxa.
      final referenceEligible = input.days.where(
        (day) =>
            day.date >= input.activationDate &&
            day.isWorkday &&
            day.isClosed &&
            !day.isMute,
      );
      expect(
        calculator.rate(
          referenceEligible.map(_toProductionDay).toList(growable: false),
          input.activationDate,
        ),
        actual,
        reason: context,
      );
    },
  );
}
