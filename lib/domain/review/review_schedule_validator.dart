/// Validação da configuração da Revisão Semanal (RF-08.5, RA-01.2).
///
/// Domínio puro: nenhuma consulta ao relógio, nenhum I/O. Violações são
/// retornadas como [ConfigViolation] em um [Result]; exceções ficam reservadas
/// a erros de programação.
library;

import '../../core/result.dart';
import '../time/operational_calendar.dart';

/// Dia da semana em que a Revisão Semanal pode ser configurada (RF-08.5).
enum ReviewWeekday {
  sunday('sunday'),
  monday('monday');

  const ReviewWeekday(this.wireValue);

  /// Forma persistida na coluna `review_weekday` (`'sunday'` | `'monday'`).
  final String wireValue;

  /// Converte a forma persistida, ou `null` quando o valor é desconhecido.
  static ReviewWeekday? fromWire(String value) {
    for (final weekday in values) {
      if (weekday.wireValue == value) return weekday;
    }
    return null;
  }
}

/// Valida o par `review_weekday` / `review_time_min` contra os limites do
/// RF-08.5, espelhando em domínio o `CHECK` persistido em `Settings`.
///
/// A configuração é aceita se e somente se:
/// - `review_weekday = 'sunday'` e o horário pertence a `[20h00, 22h00]`; ou
/// - `review_weekday = 'monday'` e o horário é estritamente posterior à
///   abertura operacional de segunda (`review_time_min > day_close_time_min`).
///
/// O limite de segunda depende de `day_close_time` e não de `max(03h, ...)`:
/// 03h00 é apenas o padrão de `day_close_time` (RF-05.22, RF-08.14). Como a
/// janela do domingo (`[20h00, 22h00]`) fica sempre acima de qualquer
/// `day_close_time` válido (`[00h00, 04h00]`), ela nunca colide com a regra de
/// segunda.
final class ReviewScheduleValidator {
  const ReviewScheduleValidator();

  /// Início inclusivo da janela dominical: 20h00 (RF-08.5).
  static const LocalTimeOfDay sundayWindowStart = LocalTimeOfDay(20, 0);

  /// Fim inclusivo da janela dominical: 22h00 (RF-08.5).
  static const LocalTimeOfDay sundayWindowEnd = LocalTimeOfDay(22, 0);

  static const ConfigViolation sundayTimeOutOfWindow = ConfigViolation(
    code: 'review_sunday_time_out_of_window',
    message: 'A revisão de domingo deve ficar entre 20:00 e 22:00.',
  );

  static const ConfigViolation
  mondayTimeBeforeOperationalOpen = ConfigViolation(
    code: 'review_monday_time_before_operational_open',
    message:
        'A revisão de segunda deve ficar após a abertura operacional do dia.',
  );

  static const ConfigViolation reviewTimeOutOfCivilRange = ConfigViolation(
    code: 'review_time_out_of_range',
    message: 'O horário da revisão deve ser uma hora civil válida.',
  );

  /// Verdadeiro quando [time] pertence à janela dominical `[20h00, 22h00]`.
  bool isSundayTimeAllowed(LocalTimeOfDay time) =>
      time >= sundayWindowStart && time <= sundayWindowEnd;

  /// Verdadeiro quando [time] é estritamente posterior a [dayCloseTime], a
  /// abertura operacional de segunda-feira.
  bool isMondayTimeAllowed({
    required LocalTimeOfDay time,
    required LocalTimeOfDay dayCloseTime,
  }) => time > dayCloseTime;

  /// Valida uma configuração de revisão já expressa em horas civis.
  ///
  /// [dayCloseTime] é a abertura operacional vigente, usada apenas quando
  /// [weekday] é [ReviewWeekday.monday].
  Result<ReviewSchedule, ConfigViolation> validate({
    required ReviewWeekday weekday,
    required LocalTimeOfDay time,
    required LocalTimeOfDay dayCloseTime,
  }) {
    switch (weekday) {
      case ReviewWeekday.sunday:
        if (!isSundayTimeAllowed(time)) {
          return const Result.failure(sundayTimeOutOfWindow);
        }
      case ReviewWeekday.monday:
        if (!isMondayTimeAllowed(time: time, dayCloseTime: dayCloseTime)) {
          return const Result.failure(mondayTimeBeforeOperationalOpen);
        }
    }
    return Result.success(ReviewSchedule(weekday: weekday, time: time));
  }

  /// Valida a forma persistida: `review_weekday` e minutos desde a meia-noite
  /// civil (`review_time_min`, `day_close_time_min`).
  ///
  /// Minutos fora de `[0, 1440)` são rejeitados sem lançar exceção. Um
  /// [weekdayWire] desconhecido também é rejeitado como configuração inválida.
  Result<ReviewSchedule, ConfigViolation> validateMinutes({
    required String weekdayWire,
    required int reviewTimeMinutes,
    required int dayCloseTimeMinutes,
  }) {
    final weekday = ReviewWeekday.fromWire(weekdayWire);
    if (weekday == null) {
      return const Result.failure(reviewTimeOutOfCivilRange);
    }
    if (!_isCivilMinute(reviewTimeMinutes) ||
        !_isCivilMinute(dayCloseTimeMinutes)) {
      return const Result.failure(reviewTimeOutOfCivilRange);
    }
    return validate(
      weekday: weekday,
      time: LocalTimeOfDay.fromMinutes(reviewTimeMinutes),
      dayCloseTime: LocalTimeOfDay.fromMinutes(dayCloseTimeMinutes),
    );
  }

  static bool _isCivilMinute(int minutes) =>
      minutes >= 0 && minutes < Duration.minutesPerDay;
}

/// Configuração validada da Revisão Semanal.
final class ReviewSchedule {
  const ReviewSchedule({required this.weekday, required this.time});

  final ReviewWeekday weekday;
  final LocalTimeOfDay time;

  @override
  bool operator ==(Object other) =>
      other is ReviewSchedule && other.weekday == weekday && other.time == time;

  @override
  int get hashCode => Object.hash(weekday, time);

  @override
  String toString() => 'ReviewSchedule(${weekday.wireValue}, $time)';
}
