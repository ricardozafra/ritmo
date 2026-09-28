import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Transições históricas de `America/Sao_Paulo` presentes na base IANA:
  //   2018-11-04T03:00Z  -03 -> -02  (entra o horário de verão)
  //   2019-02-17T02:00Z  -02 -> -03  (sai o horário de verão)
  // Logo: 00:00–00:59 de 2018-11-04 não existem, e 23:00–23:59 de 2019-02-16
  // acontecem duas vezes.
  final springForward = DateTime.utc(2018, 11, 4, 3);
  final fallBack = DateTime.utc(2019, 2, 17, 2);

  const seed = OperationalCalendar.seed();

  SystemOperationalClock clockAt(
    DateTime utcInstant, {
    OperationalCalendar calendar = seed,
    Duration? deviceOffset,
    String? deviceZoneId,
  }) => SystemOperationalClock(
    calendar: calendar,
    deviceInstant: () => utcInstant,
    deviceOffset: deviceOffset == null ? null : (_) => deviceOffset,
    deviceZoneId: deviceZoneId == null ? null : () => deviceZoneId,
  );

  group('fuso oficial', () {
    test('carrega America/Sao_Paulo de forma idempotente', () {
      final first = ensureBusinessLocation();
      final second = ensureBusinessLocation();

      expect(first.name, kBusinessTimeZone);
      expect(second, same(first));
      expect(SystemOperationalClock().businessLocation.name, kBusinessTimeZone);
    });

    test('converte o instante do aparelho para o fuso oficial', () {
      // 2026-01-10T04:00Z = 2026-01-10 01:00 em São Paulo (-03:00).
      final clock = clockAt(DateTime.utc(2026, 1, 10, 4));

      final now = clock.nowInBusinessZone();

      expect(now.location.name, kBusinessTimeZone);
      expect(now.timeZone.offset, const Duration(hours: -3));
      expect(now.hour, 1);
      expect(now.day, 10);
    });
  });

  group('data operacional', () {
    test('antes do fechamento pertence à data civil anterior (RF-05.10)', () {
      // Sábado civil 01:00, fechamento 03:00: ainda é a sexta operacional.
      final clock = clockAt(DateTime.utc(2026, 1, 10, 4));

      expect(clock.operationalDateNow(), OperationalDate(2026, 1, 9));
    });

    test('a partir do fechamento abre a nova data operacional', () {
      final clock = clockAt(DateTime.utc(2026, 1, 10, 6));

      expect(clock.operationalDateNow(), OperationalDate(2026, 1, 10));
    });

    test('não depende do fuso em que o instante é expresso (RNF-04.3)', () {
      final clock = clockAt(DateTime.utc(2026, 1, 10, 4));
      final tokyo = tz.TZDateTime.from(
        DateTime.utc(2026, 1, 10, 4),
        tz.getLocation('Asia/Tokyo'),
      );

      expect(clock.operationalDateOf(tokyo), OperationalDate(2026, 1, 9));
      expect(
        clock.operationalDateOf(clock.nowInBusinessZone()),
        clock.operationalDateOf(tokyo),
      );
    });
  });

  group('fronteiras materializadas', () {
    final clock = clockAt(DateTime.utc(2026, 1, 10, 4));

    test('abertura e fechamento seguem day_close_time', () {
      final friday = OperationalDate(2026, 1, 9);

      final open = clock.operationalOpen(friday);
      final close = clock.operationalClose(friday);

      expect(open.day, 9);
      expect(open.hour, 3);
      expect(close.day, 10);
      expect(close.hour, 3);
      expect(close, clock.operationalOpen(friday.next));
      expect(close.isAfter(open), isTrue);
    });

    test('block_deadline nunca passa do fechamento (RF-01.12)', () {
      final calendar = OperationalCalendar(
        dayCloseTime: const LocalTimeOfDay(3, 0),
        nightEndTime: const LocalTimeOfDay(1, 30),
      );
      final configured = clockAt(
        DateTime.utc(2026, 1, 10, 4),
        calendar: calendar,
      );
      final friday = OperationalDate(2026, 1, 9);

      final deadline = configured.blockDeadline(friday);

      expect(deadline.day, 10);
      expect(deadline.hour, 1);
      expect(deadline.minute, 30);
      expect(deadline.isBefore(configured.operationalClose(friday)), isTrue);
    });

    test('no seed o deadline coincide com o fechamento', () {
      final friday = OperationalDate(2026, 1, 9);

      expect(clock.blockDeadline(friday), clock.operationalClose(friday));
    });
  });

  group('normalização de horário de verão (RNF-04.3)', () {
    test('hora civil inexistente é deslocada para frente', () {
      final calendar = OperationalCalendar(
        dayCloseTime: const LocalTimeOfDay(0, 0),
        nightEndTime: const LocalTimeOfDay(0, 30),
      );
      final clock = clockAt(springForward, calendar: calendar);

      // 2018-11-04 00:00 e 00:30 não existem: viram 01:00 e 01:30 em -02:00.
      final open = clock.operationalOpen(OperationalDate(2018, 11, 4));
      final deadline = clock.blockDeadline(OperationalDate(2018, 11, 4));

      expect(open.timeZone.offset, const Duration(hours: -2));
      expect(open.hour, 1);
      expect(open.minute, 0);
      expect(open.millisecondsSinceEpoch, springForward.millisecondsSinceEpoch);
      expect(deadline.hour, 1);
      expect(deadline.minute, 30);
      expect(deadline.isAfter(open), isTrue);
    });

    test('hora civil ambígua resolve na primeira ocorrência', () {
      final calendar = OperationalCalendar(
        dayCloseTime: const LocalTimeOfDay(0, 0),
        nightEndTime: const LocalTimeOfDay(23, 30),
      );
      final clock = clockAt(fallBack, calendar: calendar);

      final deadline = clock.blockDeadline(OperationalDate(2019, 2, 16));
      final secondOccurrence = clock.toBusinessZone(
        fallBack.add(const Duration(minutes: 30)),
      );

      // As duas ocorrências existem e escrevem a mesma hora civil...
      expect(secondOccurrence.hour, 23);
      expect(secondOccurrence.minute, 30);
      expect(secondOccurrence.timeZone.offset, const Duration(hours: -3));
      // ...e a normalização escolhe a primeira (ainda em -02:00).
      expect(deadline.hour, 23);
      expect(deadline.minute, 30);
      expect(deadline.timeZone.offset, const Duration(hours: -2));
      expect(deadline.isBefore(secondOccurrence), isTrue);
    });

    test(
      'cada data tem exatamente um fechamento, mesmo na transição (RNF-04.4)',
      () {
        final calendar = OperationalCalendar(
          dayCloseTime: const LocalTimeOfDay(0, 0),
          nightEndTime: const LocalTimeOfDay(0, 0),
        );
        final clock = clockAt(springForward, calendar: calendar);
        final closes = <int>{};

        for (var offset = -2; offset <= 2; offset++) {
          final date = OperationalDate(2018, 11, 4).addDays(offset);
          final close = clock.operationalClose(date);
          closes.add(close.millisecondsSinceEpoch);
          expect(close, clock.operationalOpen(date.next));
          expect(clock.operationalDateOf(close), date.next);
        }

        expect(closes.length, 5);
      },
    );
  });

  group('divergência de fuso do aparelho (RF-05.2)', () {
    final instant = DateTime.utc(2026, 1, 10, 4);

    test('não diverge quando o aparelho informa o fuso oficial', () {
      expect(
        clockAt(instant, deviceZoneId: kBusinessTimeZone).deviceZoneDiverges,
        isFalse,
      );
    });

    test('diverge quando o aparelho informa outro fuso', () {
      expect(
        clockAt(instant, deviceZoneId: 'Asia/Tokyo').deviceZoneDiverges,
        isTrue,
      );
    });

    test('sem identificador, compara o deslocamento vigente', () {
      expect(
        clockAt(
          instant,
          deviceOffset: const Duration(hours: -3),
        ).deviceZoneDiverges,
        isFalse,
      );
      expect(
        clockAt(
          instant,
          deviceOffset: const Duration(hours: 9),
        ).deviceZoneDiverges,
        isTrue,
      );
    });

    test('o fuso do aparelho nunca substitui o oficial (RNF-04.2)', () {
      final abroad = clockAt(
        instant,
        deviceOffset: const Duration(hours: 9),
        deviceZoneId: 'Asia/Tokyo',
      );

      expect(abroad.deviceZoneDiverges, isTrue);
      expect(abroad.nowInBusinessZone().hour, 1);
      expect(abroad.operationalDateNow(), OperationalDate(2026, 1, 9));
    });
  });

  test('withCalendar troca as fronteiras preservando o fuso e as fontes', () {
    final clock = clockAt(
      DateTime.utc(2026, 1, 10, 4),
      deviceZoneId: 'Asia/Tokyo',
    );

    final relaxed = clock.withCalendar(
      const OperationalCalendar(
        dayCloseTime: LocalTimeOfDay(0, 0),
        nightEndTime: LocalTimeOfDay(0, 0),
      ),
    );

    expect(relaxed.businessLocation, clock.businessLocation);
    expect(relaxed.deviceZoneDiverges, isTrue);
    expect(relaxed.operationalDateNow(), OperationalDate(2026, 1, 10));
    expect(clock.operationalDateNow(), OperationalDate(2026, 1, 9));
  });
}
