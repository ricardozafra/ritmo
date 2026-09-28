// Feature: ritmo, Property 1: Particionamento da linha temporal operacional
//
// Para qualquer `day_close_time` válido e qualquer instante `t` no fuso
// oficial, existe exatamente uma data operacional `d` cuja janela contém
// `t`; `operationalDateOf(t)` devolve `d` e o fechamento de `d` coincide com
// a abertura de `d + 1 dia`.
//
// **Validates: Requirements RF-05.1, RF-05.4, RF-05.5, RF-05.9, RF-05.10,
// RF-05.11, RNF-04.1, RNF-04.2**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

tz.TZDateTime _inBusinessZone(tz.Location location, DateTime civil) =>
    tz.TZDateTime(
      location,
      civil.year,
      civil.month,
      civil.day,
      civil.hour,
      civil.minute,
      civil.second,
      civil.millisecond,
      civil.microsecond,
    );

bool _contains(
  OperationalClock clock,
  OperationalDate date,
  tz.TZDateTime instant,
) {
  final open = clock.operationalOpen(date);
  final close = clock.operationalClose(date);
  return !instant.isBefore(open) && instant.isBefore(close);
}

void main() {
  Glados2<InstantFixture, DeviceZoneFixture>(
    anyInstant,
    anyDeviceZone,
    RitmoGlados.ci(),
  ).test('Propriedade 1: particionamento da linha temporal operacional', (
    InstantFixture input,
    DeviceZoneFixture deviceZone,
  ) {
    final businessLocation = ensureBusinessLocation();
    final instant = _inBusinessZone(businessLocation, input.civilInstant);
    final clock = SystemOperationalClock(
      calendar: input.calendar,
      businessLocation: businessLocation,
      deviceInstant: () => instant.toUtc(),
      deviceOffset: (_) => deviceZone.offset,
      deviceZoneId: () => deviceZone.zoneId,
    );
    final now = clock.nowInBusinessZone();
    final operationalDate = clock.operationalDateNow();
    final civil = clock.civilMomentOf(now);
    final expectedDate = civil.time < input.calendar.dayCloseTime
        ? civil.date.previous
        : civil.date;
    final context =
        'civil=$civil, close=${input.calendar.dayCloseTime}, '
        'edge=${input.edge.name}, deviceZone=${deviceZone.zoneId}';

    // RF-05.1 e RNF-04.1/04.2: a fonte controlada é sempre reexpressa no
    // fuso oficial; o fuso do aparelho apenas informa divergência.
    expect(now.location.name, kBusinessTimeZone, reason: context);
    expect(clock.businessLocation.name, kBusinessTimeZone, reason: context);
    expect(
      clock.deviceZoneDiverges,
      deviceZone.zoneId != kBusinessTimeZone,
      reason: context,
    );

    // RF-05.4, RF-05.9, RF-05.10 e RF-05.11: a regra civil anterior/atual
    // determina tanto a data consultada diretamente quanto o conteúdo da home.
    expect(operationalDate, expectedDate, reason: context);
    expect(clock.operationalDateOf(now), operationalDate, reason: context);
    expect(
      input.calendar.operationalDateOf(civil.toCivilDateTime()),
      operationalDate,
      reason: context,
    );

    // Existência: a data calculada contém o instante em uma janela semiaberta.
    expect(_contains(clock, operationalDate, now), isTrue, reason: context);

    // Unicidade: como as janelas vizinhas são contíguas, somente uma entre as
    // candidatas ao redor de `d` pode conter o instante.
    final owners = <OperationalDate>[
      for (var offset = -2; offset <= 2; offset++)
        operationalDate.addDays(offset),
    ].where((date) => _contains(clock, date, now)).toList(growable: false);
    expect(owners, <OperationalDate>[operationalDate], reason: context);

    // RF-05.5: não há lacuna nem sobreposição entre datas consecutivas.
    final close = clock.operationalClose(operationalDate);
    expect(close, clock.operationalOpen(operationalDate.next), reason: context);
    expect(
      input.calendar.operationalClose(operationalDate),
      input.calendar.operationalOpen(operationalDate.next),
      reason: context,
    );
  });
}
