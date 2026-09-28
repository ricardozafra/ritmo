/// Validação das fronteiras configuráveis do tempo operacional.
///
/// Domínio puro: nenhuma consulta ao relógio, nenhum I/O. Violações de
/// configuração são retornadas como [ConfigViolation] em um [Result]; exceções
/// ficam reservadas a erros de programação.
library;

import '../../core/result.dart';
import 'operational_calendar.dart';

/// Valida o par `day_close_time` / `night_end_time` (RF-05.3, RA-01.1, RF-01.12).
///
/// A configuração é aceita se e somente se `day_close_time ∈ [00:00, 04:00]` e
/// `offset(night_end_time) ∈ (0, 24h]`. Toda configuração aceita satisfaz
/// `blockDeadline(d) <= operationalClose(d)` para qualquer data operacional `d`.
final class SettingsValidator {
  const SettingsValidator();

  /// Menor `day_close_time` permitido: meia-noite civil (RF-05.3).
  static const LocalTimeOfDay minDayCloseTime = LocalTimeOfDay(0, 0);

  /// Maior `day_close_time` permitido: 04h00 civil, inclusive (RF-05.3).
  static const LocalTimeOfDay maxDayCloseTime = LocalTimeOfDay(4, 0);

  /// Padrão normativo de `day_close_time`: 03h00 (RF-05.3).
  static const LocalTimeOfDay defaultDayCloseTime =
      OperationalCalendar.defaultDayCloseTime;

  /// Padrão de seed de `night_end_time`: igual a `day_close_time`, portanto
  /// deslocamento de 24h — Estudo permitido até o fechamento.
  static const LocalTimeOfDay defaultNightEndTime = defaultDayCloseTime;

  /// Configuração de seed já validada por construção.
  static const OperationalCalendar seedCalendar = OperationalCalendar.seed();

  static const ConfigViolation dayCloseTimeOutOfRange = ConfigViolation(
    code: 'day_close_time_out_of_range',
    message: 'O fechamento do dia deve ficar entre 00:00 e 04:00.',
  );

  static const ConfigViolation nightEndTimeOutOfWindow = ConfigViolation(
    code: 'night_end_time_out_of_window',
    message:
        'O limite da noite deve cair dentro da janela do dia operacional, '
        'até o fechamento.',
  );

  /// Verdadeiro quando [dayCloseTime] pertence a `[00:00, 04:00]`.
  bool isDayCloseTimeAllowed(LocalTimeOfDay dayCloseTime) =>
      dayCloseTime >= minDayCloseTime && dayCloseTime <= maxDayCloseTime;

  /// Verdadeiro quando `offset(nightEndTime)` pertence a `(0, 24h]` na linha
  /// operacional definida por [dayCloseTime].
  bool isNightEndTimeAllowed({
    required LocalTimeOfDay dayCloseTime,
    required LocalTimeOfDay nightEndTime,
  }) {
    final offset = OperationalCalendar(
      dayCloseTime: dayCloseTime,
      nightEndTime: nightEndTime,
    ).nightOffset;
    return offset > Duration.zero &&
        offset <= OperationalCalendar.operationalDayLength;
  }

  /// Valida um par de horários candidatos e devolve o calendário resultante.
  Result<OperationalCalendar, ConfigViolation> validate({
    required LocalTimeOfDay dayCloseTime,
    required LocalTimeOfDay nightEndTime,
  }) {
    if (!isDayCloseTimeAllowed(dayCloseTime)) {
      return const Result.failure(dayCloseTimeOutOfRange);
    }
    if (!isNightEndTimeAllowed(
      dayCloseTime: dayCloseTime,
      nightEndTime: nightEndTime,
    )) {
      return const Result.failure(nightEndTimeOutOfWindow);
    }
    return Result.success(
      OperationalCalendar(
        dayCloseTime: dayCloseTime,
        nightEndTime: nightEndTime,
      ),
    );
  }

  /// Valida a forma persistida da configuração: minutos desde a meia-noite
  /// civil (`day_close_time_min`, `night_end_time_min`).
  ///
  /// Minutos fora da janela civil `[0, 1440)` são rejeitados no campo
  /// correspondente, sem lançar exceção.
  Result<OperationalCalendar, ConfigViolation> validateMinutes({
    required int dayCloseTimeMinutes,
    required int nightEndTimeMinutes,
  }) {
    if (!_isCivilMinute(dayCloseTimeMinutes)) {
      return const Result.failure(dayCloseTimeOutOfRange);
    }
    if (!_isCivilMinute(nightEndTimeMinutes)) {
      return const Result.failure(nightEndTimeOutOfWindow);
    }
    return validate(
      dayCloseTime: LocalTimeOfDay.fromMinutes(dayCloseTimeMinutes),
      nightEndTime: LocalTimeOfDay.fromMinutes(nightEndTimeMinutes),
    );
  }

  static bool _isCivilMinute(int minutes) =>
      minutes >= 0 && minutes < Duration.minutesPerDay;
}
