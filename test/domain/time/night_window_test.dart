import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/time/night_window.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

void main() {
  final date = OperationalDate(2026, 1, 9);

  SystemOperationalClock clockFor(OperationalCalendar calendar) =>
      SystemOperationalClock(
        calendar: calendar,
        deviceInstant: () => DateTime.utc(2000),
      );

  group('NightWindow com janela de recuperação', () {
    const calendar = OperationalCalendar(
      dayCloseTime: LocalTimeOfDay(3, 0),
      nightEndTime: LocalTimeOfDay(1, 30),
    );
    final clock = clockFor(calendar);
    final window = NightWindow(clock);
    final deadline = clock.blockDeadline(date);
    final close = clock.operationalClose(date);

    test('um instante antes do deadline oferece estudo e recuperação', () {
      final state = window.evaluate(
        now: deadline.subtract(const Duration(microseconds: 1)),
        operationalDate: date,
      );

      expect(
        state.actions,
        const <NightAction>{NightAction.study, NightAction.recovery},
      );
      expect(state.allowsStudy, isTrue);
      expect(state.allowsRecovery, isTrue);
      expect(state.copy, isNull);
    });

    test('no deadline oferece somente recuperação e a copy literal', () {
      final state = window.evaluate(
        now: deadline,
        operationalDate: date,
      );

      expect(state.actions, const <NightAction>{NightAction.recovery});
      expect(state.allowsStudy, isFalse);
      expect(state.allowsRecovery, isTrue);
      expect(state.copy, Copy.nightRecoveryOnly);
    });

    test('um instante antes do fechamento ainda oferece recuperação', () {
      final state = window.evaluate(
        now: close.subtract(const Duration(microseconds: 1)),
        operationalDate: date,
      );

      expect(state.actions, const <NightAction>{NightAction.recovery});
      expect(state.copy, Copy.nightRecoveryOnly);
    });

    test('no fechamento e depois dele não oferece ações nem copy', () {
      final atClose = window.evaluate(now: close, operationalDate: date);
      final afterClose = window.evaluate(
        now: close.add(const Duration(microseconds: 1)),
        operationalDate: date,
      );

      for (final state in <NightWindowState>[atClose, afterClose]) {
        expect(state.actions, isEmpty);
        expect(state.hasActions, isFalse);
        expect(state.copy, isNull);
      }
    });
  });

  group('NightWindow com deadline igual ao fechamento', () {
    const calendar = OperationalCalendar.seed();
    final clock = clockFor(calendar);
    final window = NightWindow(clock);
    final close = clock.operationalClose(date);

    test('mantém ambas as ações até imediatamente antes do fechamento', () {
      expect(clock.blockDeadline(date), close);

      final state = window.evaluate(
        now: close.subtract(const Duration(microseconds: 1)),
        operationalDate: date,
      );

      expect(
        state.actions,
        const <NightAction>{NightAction.study, NightAction.recovery},
      );
      expect(state.copy, isNull);
    });

    test('fecha sem produzir estado intermediário de recuperação', () {
      final state = window.evaluate(now: close, operationalDate: date);

      expect(state.actions, isEmpty);
      expect(state.copy, isNull);
    });
  });
}
