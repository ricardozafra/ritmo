import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  const defaultCalendar = OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(3, 0),
    nightEndTime: LocalTimeOfDay(1, 30),
  );

  group('LocalTimeOfDay', () {
    test('converte entre hora civil e minutos desde a meia-noite', () {
      expect(const LocalTimeOfDay(1, 30).minutesFromMidnight, 90);
      expect(LocalTimeOfDay.fromMinutes(90), const LocalTimeOfDay(1, 30));
      expect(
        const LocalTimeOfDay(3, 0).sinceMidnight,
        const Duration(hours: 3),
      );
    });

    test('lê a hora civil de um DateTime do fuso oficial', () {
      final civil = DateTime.utc(2026, 1, 10, 1, 30);

      expect(LocalTimeOfDay.fromDateTime(civil), const LocalTimeOfDay(1, 30));
    });

    test('rejeita minutos fora da janela civil de um dia', () {
      expect(() => LocalTimeOfDay.fromMinutes(-1), throwsArgumentError);
      expect(() => LocalTimeOfDay.fromMinutes(1440), throwsArgumentError);
    });

    test('ordena pela posição na hora civil e formata com dois dígitos', () {
      expect(const LocalTimeOfDay(1, 30) < const LocalTimeOfDay(3, 0), isTrue);
      expect(const LocalTimeOfDay(3, 0) <= const LocalTimeOfDay(3, 0), isTrue);
      expect(const LocalTimeOfDay(4, 0) > const LocalTimeOfDay(3, 0), isTrue);
      expect(const LocalTimeOfDay(0, 5).toString(), '00:05');
    });
  });

  group('OperationalDate', () {
    test('rejeita data civil inexistente', () {
      expect(() => OperationalDate(2026, 2, 30), throwsArgumentError);
      expect(() => OperationalDate(2026, 13, 1), throwsArgumentError);
    });

    test('classifica sábado e domingo como fim de semana', () {
      expect(OperationalDate(2026, 1, 9).isWeekend, isFalse); // sexta
      expect(OperationalDate(2026, 1, 10).isWeekend, isTrue); // sábado
      expect(OperationalDate(2026, 1, 11).isWeekend, isTrue); // domingo
      expect(OperationalDate(2026, 1, 12).isWeekend, isFalse); // segunda
    });

    test('atravessa fronteiras de mês e de ano', () {
      expect(OperationalDate(2026, 1, 31).next, OperationalDate(2026, 2, 1));
      expect(
        OperationalDate(2027, 1, 1).previous,
        OperationalDate(2026, 12, 31),
      );
      expect(
        OperationalDate(2026, 2, 28).addDays(1),
        OperationalDate(2026, 3, 1),
      );
    });

    test('expõe representação ISO estável e ordem total', () {
      expect(OperationalDate(2026, 1, 5).iso, '2026-01-05');
      expect(OperationalDate(2026, 1, 5) < OperationalDate(2026, 1, 6), isTrue);
      expect(
        OperationalDate(2026, 1, 5) >= OperationalDate(2026, 1, 5),
        isTrue,
      );
      expect(OperationalDate(2026, 1, 5), OperationalDate(2026, 1, 5));
    });
  });

  group('OperationalCalendar.operationalDateOf', () {
    test('antes de day_close_time atribui a data civil anterior', () {
      final instant = DateTime.utc(2026, 1, 10, 2, 59);

      expect(
        defaultCalendar.operationalDateOf(instant),
        OperationalDate(2026, 1, 9),
      );
    });

    test('em day_close_time atribui a data civil corrente', () {
      final instant = DateTime.utc(2026, 1, 10, 3);

      expect(
        defaultCalendar.operationalDateOf(instant),
        OperationalDate(2026, 1, 10),
      );
    });

    test('sábado civil 01h00 ainda pertence à sexta operacional', () {
      final saturdayEarly = DateTime.utc(2026, 1, 10, 1);
      final operationalDate = defaultCalendar.operationalDateOf(saturdayEarly);

      expect(operationalDate, OperationalDate(2026, 1, 9));
      expect(operationalDate.isWeekend, isFalse);
    });

    test('segunda civil 01h00 ainda pertence ao domingo operacional', () {
      final mondayEarly = DateTime.utc(2026, 1, 12, 1);
      final operationalDate = defaultCalendar.operationalDateOf(mondayEarly);

      expect(operationalDate, OperationalDate(2026, 1, 11));
      expect(operationalDate.isWeekend, isTrue);
    });

    test('com fechamento à meia-noite a data operacional é a data civil', () {
      const midnightCalendar = OperationalCalendar(
        dayCloseTime: LocalTimeOfDay(0, 0),
        nightEndTime: LocalTimeOfDay(0, 0),
      );

      expect(
        midnightCalendar.operationalDateOf(DateTime.utc(2026, 1, 10)),
        OperationalDate(2026, 1, 10),
      );
      expect(
        midnightCalendar.operationalDateOf(DateTime.utc(2026, 1, 10, 23, 59)),
        OperationalDate(2026, 1, 10),
      );
    });
  });

  group('OperationalCalendar.operationalOpen/Close', () {
    test('abertura é a data civil em day_close_time', () {
      expect(
        defaultCalendar.operationalOpen(OperationalDate(2026, 1, 9)),
        CivilMoment(
          date: OperationalDate(2026, 1, 9),
          time: const LocalTimeOfDay(3, 0),
        ),
      );
    });

    test('fechamento de d é a abertura de d + 1', () {
      final friday = OperationalDate(2026, 1, 9);

      expect(
        defaultCalendar.operationalClose(friday),
        defaultCalendar.operationalOpen(friday.next),
      );
      expect(
        defaultCalendar.operationalClose(friday).toCivilDateTime(),
        DateTime.utc(2026, 1, 10, 3),
      );
    });

    test(
      'a data operacional da abertura é ela mesma e a do fechamento é a seguinte',
      () {
        final friday = OperationalDate(2026, 1, 9);
        final open = defaultCalendar.operationalOpen(friday).toCivilDateTime();
        final close = defaultCalendar
            .operationalClose(friday)
            .toCivilDateTime();

        expect(defaultCalendar.operationalDateOf(open), friday);
        expect(
          defaultCalendar.operationalDateOf(
            open.subtract(const Duration(minutes: 1)),
          ),
          friday.previous,
        );
        expect(defaultCalendar.operationalDateOf(close), friday.next);
      },
    );
  });

  group('OperationalCalendar.offset', () {
    test('mede a hora civil dentro da janela operacional', () {
      expect(
        defaultCalendar.offset(const LocalTimeOfDay(1, 30)),
        const Duration(hours: 22, minutes: 30),
      );
      expect(
        defaultCalendar.offset(const LocalTimeOfDay(23, 0)),
        const Duration(hours: 20),
      );
      expect(
        defaultCalendar.offset(const LocalTimeOfDay(3, 1)),
        const Duration(minutes: 1),
      );
    });

    test('o próprio day_close_time tem deslocamento de 24h, não zero', () {
      expect(
        defaultCalendar.offset(defaultCalendar.dayCloseTime),
        OperationalCalendar.operationalDayLength,
      );
      expect(
        const OperationalCalendar.seed().nightOffset,
        OperationalCalendar.operationalDayLength,
      );
    });
  });

  group('OperationalCalendar.blockDeadline', () {
    test(
      'night_end_time 01h30 com fechamento 03h00 vence no dia civil seguinte',
      () {
        final friday = OperationalDate(2026, 1, 9);

        expect(
          defaultCalendar.blockDeadline(friday).toCivilDateTime(),
          DateTime.utc(2026, 1, 10, 1, 30),
        );
        expect(
          defaultCalendar.blockDeadline(friday) <
              defaultCalendar.operationalClose(friday),
          isTrue,
        );
      },
    );

    test('o deadline pertence à data operacional de origem', () {
      final friday = OperationalDate(2026, 1, 9);
      final deadline = defaultCalendar.blockDeadline(friday);

      expect(
        defaultCalendar.operationalDateOf(
          deadline.toCivilDateTime().subtract(const Duration(minutes: 1)),
        ),
        friday,
      );
      expect(
        defaultCalendar.operationalDateOf(deadline.toCivilDateTime()),
        friday,
      );
    });

    test('no seed o deadline coincide com o fechamento', () {
      const seed = OperationalCalendar.seed();
      final friday = OperationalDate(2026, 1, 9);

      expect(seed.blockDeadline(friday), seed.operationalClose(friday));
    });

    test('nunca ultrapassa o fechamento em nenhuma configuração válida', () {
      for (var closeMinutes = 0; closeMinutes <= 240; closeMinutes += 15) {
        final close = LocalTimeOfDay.fromMinutes(closeMinutes);
        for (var nightMinutes = 0; nightMinutes < 1440; nightMinutes += 15) {
          final calendar = OperationalCalendar(
            dayCloseTime: close,
            nightEndTime: LocalTimeOfDay.fromMinutes(nightMinutes),
          );
          final date = OperationalDate(2026, 1, 9);
          final open = calendar.operationalOpen(date);
          final deadline = calendar.blockDeadline(date);

          expect(open < deadline, isTrue, reason: '$close / $nightMinutes');
          expect(
            deadline <= calendar.operationalClose(date),
            isTrue,
            reason: '$close / $nightMinutes',
          );
        }
      }
    });
  });

  group('CivilMoment', () {
    test('propaga o excedente de minutos para a data', () {
      final moment = CivilMoment(
        date: OperationalDate(2026, 1, 9),
        time: const LocalTimeOfDay(23, 30),
      ).plus(const Duration(hours: 2));

      expect(moment.date, OperationalDate(2026, 1, 10));
      expect(moment.time, const LocalTimeOfDay(1, 30));
    });

    test('aceita duração negativa e retrocede a data', () {
      final moment = CivilMoment(
        date: OperationalDate(2026, 1, 9),
        time: const LocalTimeOfDay(0, 30),
      ).plus(const Duration(hours: -1));

      expect(moment.date, OperationalDate(2026, 1, 8));
      expect(moment.time, const LocalTimeOfDay(23, 30));
    });

    test('rejeita duração que não é múltiplo de minuto', () {
      expect(
        () => CivilMoment(
          date: OperationalDate(2026, 1, 9),
          time: const LocalTimeOfDay(3, 0),
        ).plus(const Duration(seconds: 30)),
        throwsArgumentError,
      );
    });
  });

  test('o fuso de negócio é fixo', () {
    expect(kBusinessTimeZone, 'America/Sao_Paulo');
  });
}
