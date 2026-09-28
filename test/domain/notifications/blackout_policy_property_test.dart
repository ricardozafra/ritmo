// Feature: ritmo, Property 28: Blackout é respeitado sem exceções
//
// Para qualquer instante civil dentro do intervalo [sábado 00h00,
// operationalOpen(segunda-feira operacional)), BlackoutPolicy.isBlocked avalia
// como verdadeiro e nenhuma notificação é agendada para esse instante (ou
// entregue nele), com a única exceção do lembrete dominical opt-in em
// [20h00, 22h00]. O fim do blackout é exatamente a abertura operacional da
// segunda-feira (operationalOpen(week_start)), e não max(03h, day_close_time).
//
// **Validates: Requirements RF-05.19, RF-05.22, RF-05.24, RF-08.7, RF-08.15, RNF-04.7**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/domain/notifications/blackout_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _BlackoutFixture = ({
  OperationalCalendar calendar,
  tz.TZDateTime moment,
  bool sundayExceptionEnabled,
});

final Generator<_BlackoutFixture> _anyBlackoutFixture = any.simple(
  generate: (random, size) {
    // day_close_time between 00:00 and 04:00
    final closeMin = random.nextInt(241);
    final calendar = OperationalCalendar(
      dayCloseTime: LocalTimeOfDay.fromMinutes(closeMin),
      nightEndTime: const LocalTimeOfDay(23, 0),
    );
    final location = ensureBusinessLocation();

    // Moment within a 2-week window to sample weekdays, saturdays, sundays, and monday dawns
    final baseYear = 2026;
    final baseMonth = 1 + random.nextInt(12);
    final baseDay = 1 + random.nextInt(20);
    final baseDate = OperationalDate(baseYear, baseMonth, baseDay);
    final dayOffset = random.nextInt(14);
    final targetDate = baseDate.addDays(dayOffset);

    final hour = random.nextInt(24);
    final minute = random.nextInt(60);
    final moment = tz.TZDateTime(
      location,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    return (
      calendar: calendar,
      moment: moment,
      sundayExceptionEnabled: random.nextBool(),
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_BlackoutFixture>(
    _anyBlackoutFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 28: Blackout é respeitado sem exceções', (fixture) {
    final clock = SystemOperationalClock(calendar: fixture.calendar);
    final policy = BlackoutPolicy(clock);

    final moment = fixture.moment;
    final civil = clock.civilMomentOf(moment);
    final weekday = civil.date.weekday;

    // Calcula se está dentro do intervalo semiaberto [sábado 00:00, operationalOpen(segunda))
    bool inBlackoutInterval;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      inBlackoutInterval = true;
    } else if (weekday == DateTime.monday) {
      final mondayOpen = clock.operationalOpen(civil.date);
      inBlackoutInterval = moment.isBefore(mondayOpen);
    } else {
      inBlackoutInterval = false;
    }

    final isWithinWindow = policy.isWithinBlackoutWindow(moment);
    expect(
      isWithinWindow,
      equals(inBlackoutInterval),
      reason:
          'isWithinBlackoutWindow deve ser exato com o intervalo do fim de semana até a abertura de segunda',
    );

    final isSundayOptInMoment =
        weekday == DateTime.sunday &&
        civil.time >= const LocalTimeOfDay(20, 0) &&
        civil.time <= const LocalTimeOfDay(22, 0);

    final isBlocked = policy.isBlocked(
      moment,
      sundayExceptionEnabled: fixture.sundayExceptionEnabled,
    );

    if (inBlackoutInterval) {
      if (fixture.sundayExceptionEnabled && isSundayOptInMoment) {
        expect(isBlocked, isFalse);
      } else {
        expect(isBlocked, isTrue);
      }
    } else {
      expect(isBlocked, isFalse);
    }
  });

  group('Propriedade 28: Casos de borda da abertura de segunda-feira', () {
    test(
      'segunda-feira 1 minuto antes da abertura operacional está em blackout',
      () {
        final calendar = const OperationalCalendar(
          dayCloseTime: LocalTimeOfDay(3, 30),
          nightEndTime: LocalTimeOfDay(23, 0),
        );
        final clock = SystemOperationalClock(calendar: calendar);
        final policy = BlackoutPolicy(clock);
        final location = ensureBusinessLocation();

        // Segunda-feira 03:29
        final mondayDawn = tz.TZDateTime(location, 2026, 3, 9, 3, 29);
        expect(policy.isWithinBlackoutWindow(mondayDawn), isTrue);
        expect(
          policy.isBlocked(mondayDawn, sundayExceptionEnabled: true),
          isTrue,
        );
      },
    );

    test(
      'segunda-feira exatamente na abertura operacional NÃO está em blackout',
      () {
        final calendar = const OperationalCalendar(
          dayCloseTime: LocalTimeOfDay(3, 30),
          nightEndTime: LocalTimeOfDay(23, 0),
        );
        final clock = SystemOperationalClock(calendar: calendar);
        final policy = BlackoutPolicy(clock);
        final location = ensureBusinessLocation();

        // Segunda-feira 03:30 (operationalOpen)
        final mondayOpen = tz.TZDateTime(location, 2026, 3, 9, 3, 30);
        expect(policy.isWithinBlackoutWindow(mondayOpen), isFalse);
        expect(
          policy.isBlocked(mondayOpen, sundayExceptionEnabled: true),
          isFalse,
        );
      },
    );

    test('exceção dominical cobre 20:00 e 22:00 inclusivos', () {
      final clock = SystemOperationalClock(
        calendar: const OperationalCalendar.seed(),
      );
      final policy = BlackoutPolicy(clock);
      final location = ensureBusinessLocation();

      final sun2000 = tz.TZDateTime(location, 2026, 3, 8, 20, 0);
      final sun2200 = tz.TZDateTime(location, 2026, 3, 8, 22, 0);
      final sun1959 = tz.TZDateTime(location, 2026, 3, 8, 19, 59);
      final sun2201 = tz.TZDateTime(location, 2026, 3, 8, 22, 1);

      expect(policy.isBlocked(sun2000, sundayExceptionEnabled: true), isFalse);
      expect(policy.isBlocked(sun2200, sundayExceptionEnabled: true), isFalse);
      expect(policy.isBlocked(sun1959, sundayExceptionEnabled: true), isTrue);
      expect(policy.isBlocked(sun2201, sundayExceptionEnabled: true), isTrue);

      // Com sundayExceptionEnabled == false, tudo bloqueia
      expect(policy.isBlocked(sun2000, sundayExceptionEnabled: false), isTrue);
      expect(policy.isBlocked(sun2200, sundayExceptionEnabled: false), isTrue);
    });
  });
}
