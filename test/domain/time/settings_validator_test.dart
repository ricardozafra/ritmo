import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/settings_validator.dart';

void main() {
  const validator = SettingsValidator();

  OperationalCalendar accepted(
    LocalTimeOfDay dayCloseTime,
    LocalTimeOfDay nightEndTime,
  ) {
    final result = validator.validate(
      dayCloseTime: dayCloseTime,
      nightEndTime: nightEndTime,
    );

    return result.fold(
      onSuccess: (calendar) => calendar,
      onFailure: (failure) =>
          fail('configuração deveria ser aceita, veio ${failure.code}'),
    );
  }

  ConfigViolation rejected(
    LocalTimeOfDay dayCloseTime,
    LocalTimeOfDay nightEndTime,
  ) {
    final result = validator.validate(
      dayCloseTime: dayCloseTime,
      nightEndTime: nightEndTime,
    );

    return result.fold(
      onSuccess: (calendar) =>
          fail('configuração deveria ser rejeitada: $dayCloseTime'),
      onFailure: (failure) => failure,
    );
  }

  group('day_close_time', () {
    test('aceita a borda inferior 00:00', () {
      final calendar = accepted(
        const LocalTimeOfDay(0, 0),
        const LocalTimeOfDay(0, 0),
      );

      expect(calendar.dayCloseTime, const LocalTimeOfDay(0, 0));
    });

    test('aceita a borda superior 04:00', () {
      final calendar = accepted(
        const LocalTimeOfDay(4, 0),
        const LocalTimeOfDay(1, 30),
      );

      expect(calendar.dayCloseTime, const LocalTimeOfDay(4, 0));
    });

    test('aceita o padrão 03:00', () {
      final calendar = accepted(
        SettingsValidator.defaultDayCloseTime,
        SettingsValidator.defaultNightEndTime,
      );

      expect(calendar.dayCloseTime, const LocalTimeOfDay(3, 0));
      expect(
        SettingsValidator.defaultDayCloseTime,
        OperationalCalendar.defaultDayCloseTime,
      );
    });

    test('rejeita 04:01, o primeiro minuto além da borda', () {
      final violation = rejected(
        const LocalTimeOfDay(4, 1),
        const LocalTimeOfDay(1, 30),
      );

      expect(violation.code, 'day_close_time_out_of_range');
    });

    test('rejeita 23:59, o último minuto antes da borda inferior', () {
      expect(
        rejected(
          const LocalTimeOfDay(23, 59),
          const LocalTimeOfDay(23, 59),
        ).code,
        'day_close_time_out_of_range',
      );
    });

    test('a rejeição do fechamento tem precedência sobre a da noite', () {
      final violation = validator
          .validateMinutes(dayCloseTimeMinutes: -1, nightEndTimeMinutes: 2000)
          .fold(
            onSuccess: (_) => fail('configuração deveria ser rejeitada'),
            onFailure: (failure) => failure,
          );

      expect(violation.code, 'day_close_time_out_of_range');
    });
  });

  group('offset(night_end_time)', () {
    test('night_end_time igual a day_close_time vale 24h e é aceito', () {
      final calendar = accepted(
        const LocalTimeOfDay(3, 0),
        const LocalTimeOfDay(3, 0),
      );

      expect(calendar.nightOffset, OperationalCalendar.operationalDayLength);
    });

    test('o deslocamento aceito é sempre estritamente positivo', () {
      for (var closeMinutes = 0; closeMinutes <= 240; closeMinutes++) {
        final dayCloseTime = LocalTimeOfDay.fromMinutes(closeMinutes);
        for (
          var nightMinutes = 0;
          nightMinutes < Duration.minutesPerDay;
          nightMinutes += 7
        ) {
          final nightEndTime = LocalTimeOfDay.fromMinutes(nightMinutes);

          expect(
            validator.isNightEndTimeAllowed(
              dayCloseTime: dayCloseTime,
              nightEndTime: nightEndTime,
            ),
            isTrue,
            reason: '$dayCloseTime / $nightEndTime',
          );
          expect(
            accepted(dayCloseTime, nightEndTime).nightOffset,
            greaterThan(Duration.zero),
          );
        }
      }
    });

    test('toda configuração aceita mantém o deadline até o fechamento', () {
      final date = OperationalDate(2026, 1, 9);

      for (var closeMinutes = 0; closeMinutes <= 240; closeMinutes += 15) {
        for (
          var nightMinutes = 0;
          nightMinutes < Duration.minutesPerDay;
          nightMinutes += 15
        ) {
          final calendar = accepted(
            LocalTimeOfDay.fromMinutes(closeMinutes),
            LocalTimeOfDay.fromMinutes(nightMinutes),
          );

          expect(
            calendar.operationalOpen(date) < calendar.blockDeadline(date),
            isTrue,
          );
          expect(
            calendar.blockDeadline(date) <= calendar.operationalClose(date),
            isTrue,
          );
        }
      }
    });
  });

  group('validateMinutes', () {
    test('aceita a forma persistida do padrão (180 / 180)', () {
      final result = validator.validateMinutes(
        dayCloseTimeMinutes: 180,
        nightEndTimeMinutes: 180,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.fold(
          onSuccess: (calendar) => calendar.nightOffset,
          onFailure: (_) => Duration.zero,
        ),
        OperationalCalendar.operationalDayLength,
      );
    });

    test('aceita 240 e rejeita 241 minutos de fechamento', () {
      expect(
        validator
            .validateMinutes(dayCloseTimeMinutes: 240, nightEndTimeMinutes: 90)
            .isSuccess,
        isTrue,
      );
      expect(
        validator
            .validateMinutes(dayCloseTimeMinutes: 241, nightEndTimeMinutes: 90)
            .isFailure,
        isTrue,
      );
    });

    test('rejeita minutos fora da janela civil sem lançar exceção', () {
      final belowZero = validator.validateMinutes(
        dayCloseTimeMinutes: -1,
        nightEndTimeMinutes: 180,
      );
      final nightTooLarge = validator.validateMinutes(
        dayCloseTimeMinutes: 180,
        nightEndTimeMinutes: Duration.minutesPerDay,
      );

      expect(
        belowZero.fold(
          onSuccess: (_) => null,
          onFailure: (failure) => failure.code,
        ),
        'day_close_time_out_of_range',
      );
      expect(
        nightTooLarge.fold(
          onSuccess: (_) => null,
          onFailure: (failure) => failure.code,
        ),
        'night_end_time_out_of_window',
      );
    });
  });

  test('o seed usa night_end_time = day_close_time e é válido', () {
    expect(
      SettingsValidator.seedCalendar.dayCloseTime,
      SettingsValidator.defaultDayCloseTime,
    );
    expect(
      SettingsValidator.seedCalendar.nightEndTime,
      SettingsValidator.seedCalendar.dayCloseTime,
    );
    expect(
      validator
          .validate(
            dayCloseTime: SettingsValidator.seedCalendar.dayCloseTime,
            nightEndTime: SettingsValidator.seedCalendar.nightEndTime,
          )
          .isSuccess,
      isTrue,
    );
  });
}
