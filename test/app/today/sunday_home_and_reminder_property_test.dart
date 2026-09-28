// Feature: ritmo, Property 30: Home dominical e o lembrete dominical
//
// Para qualquer instante civil de domingo dentro da janela [20h00, 22h00], a tela
// Hoje permanece no estado mute e a data operacional não avança para a próxima
// semana antes da abertura de segunda-feira (operationalOpen(week_start + 7)).
//
// **Validates: Requirements RF-05.20, RF-08.9, RF-08.12**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/app/today/today_projection.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/data/repositories/today_repository.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/today_view.dart';
import 'package:ritmo/domain/notifications/blackout_policy.dart';
import 'package:ritmo/domain/people/weekly_contact_suggestion.dart'
    show operationalWeekStart;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _SundayFixture = ({
  OperationalCalendar calendar,
  OperationalDate sundayDate,
  int minuteOffset, // 0 to 120 minutes from 20:00
  bool sundayNotificationEnabled,
});

final Generator<_SundayFixture> _anySundayMoment = any.simple(
  generate: (random, size) {
    // Arbitrary calendar with day_close_time in [00:00, 04:00]
    final closeMin = random.nextInt(241);
    final calendar = OperationalCalendar(
      dayCloseTime: LocalTimeOfDay.fromMinutes(closeMin),
      nightEndTime: const LocalTimeOfDay(23, 0),
    );

    // Pick an arbitrary Sunday
    final anyDate = anyOperationalDate(random, size).value;
    final sunday = anyDate.addDays(DateTime.sunday - anyDate.weekday);

    final minuteOffset = random.nextInt(121); // 20:00 to 22:00
    final enabled = random.nextBool();

    return (
      calendar: calendar,
      sundayDate: sunday,
      minuteOffset: minuteOffset,
      sundayNotificationEnabled: enabled,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_SundayFixture>(_anySundayMoment, RitmoGlados.ci()).test(
    'Propriedade 30: Home dominical permanece mute e não avança semana no domingo à noite',
    (fixture) {
      final location = ensureBusinessLocation();
      final hour = 20 + (fixture.minuteOffset ~/ 60);
      final minute = fixture.minuteOffset % 60;

      final sundayInstant = tz.TZDateTime(
        location,
        fixture.sundayDate.year,
        fixture.sundayDate.month,
        fixture.sundayDate.day,
        hour,
        minute,
      );

      final clock = SystemOperationalClock(
        calendar: fixture.calendar,
        deviceInstant: () => sundayInstant.toUtc(),
      );

      // 1. Data operacional calculada para o instante de domingo à noite
      final currentOperationalDate = clock.operationalDateOf(sundayInstant);

      // Como é domingo entre 20h e 22h, e day_close_time está entre 00h e 04h,
      // a data operacional é exatamente o domingo
      expect(currentOperationalDate, equals(fixture.sundayDate));

      // A semana operacional corrente NÃO avançou para a próxima segunda
      final thisWeekStart = operationalWeekStart(currentOperationalDate);
      final nextWeekStart = thisWeekStart.addDays(7);
      final nextMondayOpen = clock.operationalOpen(nextWeekStart);

      // O instante ainda é estritamente anterior à abertura da próxima segunda
      expect(sundayInstant.isBefore(nextMondayOpen), isTrue);

      // 2. A tela Hoje projeta MuteTodayView independentemente de notificações
      final snapshot = TodaySnapshot(
        day: Day(
          operationalDate: fixture.sundayDate,
          baseResult: DayResult.unsealed,
          effectiveResult: DayResult.mute,
          muteCause: MuteCause.weekend,
        ),
        entries: const PillarEntriesSnapshot(
          morning: MorningEntry(),
          day: DayEntry(),
          night: NightEntry(),
        ),
        linkedStudyBlock: null,
        activeWaiver: null,
        visibleInitiative: null,
        cycle: _seedCycle,
        checkpoints: const [],
      );

      final view = const TodayProjection().project(
        snapshot: snapshot,
        clock: clock,
        now: sundayInstant,
      );

      expect(view, isA<MuteTodayView>());
      final muteView = view as MuteTodayView;
      expect(muteView.message, equals(Copy.muteDay));
      expect(muteView.operationalDate, equals(fixture.sundayDate));

      // 3. BlackoutPolicy libera APENAS se a exceção dominical estiver habilitada
      final blackout = BlackoutPolicy(clock);
      final isBlocked = blackout.isBlocked(
        sundayInstant,
        sundayExceptionEnabled: fixture.sundayNotificationEnabled,
      );
      expect(isBlocked, equals(!fixture.sundayNotificationEnabled));
    },
  );

  group('Propriedade 30: Casos pontuais no domingo 20:00 e 22:00', () {
    test('domingo 20:00 pontual', () {
      final location = ensureBusinessLocation();
      final sunday = OperationalDate(2026, 3, 8);
      final instant = tz.TZDateTime(location, 2026, 3, 8, 20, 0);
      final clock = SystemOperationalClock(
        calendar: const OperationalCalendar.seed(),
        deviceInstant: () => instant.toUtc(),
      );

      expect(clock.operationalDateOf(instant), equals(sunday));
      expect(
        operationalWeekStart(clock.operationalDateOf(instant)),
        equals(OperationalDate(2026, 3, 2)),
      );

      final blackout = BlackoutPolicy(clock);
      expect(
        blackout.isBlocked(instant, sundayExceptionEnabled: true),
        isFalse,
      );
    });

    test('domingo 22:00 pontual', () {
      final location = ensureBusinessLocation();
      final sunday = OperationalDate(2026, 3, 8);
      final instant = tz.TZDateTime(location, 2026, 3, 8, 22, 0);
      final clock = SystemOperationalClock(
        calendar: const OperationalCalendar.seed(),
        deviceInstant: () => instant.toUtc(),
      );

      expect(clock.operationalDateOf(instant), equals(sunday));
      expect(
        operationalWeekStart(clock.operationalDateOf(instant)),
        equals(OperationalDate(2026, 3, 2)),
      );

      final blackout = BlackoutPolicy(clock);
      expect(
        blackout.isBlocked(instant, sundayExceptionEnabled: true),
        isFalse,
      );
    });
  });
}

final Cycle _seedCycle = Cycle(
  id: 'cycle-seed-v1',
  name: 'Ciclo',
  purposeText: 'Finalidade do ciclo seed',
  startDate: OperationalDate(2026, 1, 1),
  endDate: OperationalDate(2027, 6, 30),
  state: CycleState.active,
);
