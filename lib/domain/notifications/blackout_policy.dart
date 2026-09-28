import 'package:timezone/timezone.dart' as tz;

import '../people/weekly_contact_suggestion.dart';
import '../time/operational_calendar.dart';
import '../time/operational_clock.dart';

/// Política pura do blackout de fim de semana (RF-05.19, RF-05.22, RF-08.7,
/// RF-08.14, RA-01.2).
///
/// O blackout cobre o intervalo semiaberto
/// `[sábado 00h00 civil, operationalOpen(segunda-feira operacional))`: nenhuma
/// notificação diária é agendada ou entregue enquanto o instante candidato
/// pertencer a ele. O fim do blackout é **sempre** a abertura operacional de
/// segunda-feira (`clock.operationalOpen(week_start)`), nunca
/// `max(03h, day_close_time)` — 03h00 é apenas o padrão de `day_close_time`
/// (RF-05.22, RF-08.14).
///
/// A única exceção é a notificação opt-in da revisão dominical: quando
/// habilitada, um instante de domingo dentro de `[20h00, 22h00]` civil não é
/// bloqueado (RF-05.20, RF-08.6, RF-08.8). A exceção não altera a home nem a
/// data operacional; isso é responsabilidade das projeções, não desta política.
///
/// Depende apenas de `OperationalClock` para localizar a abertura operacional
/// no fuso oficial e para converter instantes em coordenadas civis. Não lê o
/// relógio do aparelho nem persiste nada.
final class BlackoutPolicy {
  const BlackoutPolicy(this._clock);

  final OperationalClock _clock;

  /// Início inclusivo da janela dominical opt-in: 20h00 civil (RF-08.5).
  static const LocalTimeOfDay sundayExceptionStart = LocalTimeOfDay(20, 0);

  /// Fim inclusivo da janela dominical opt-in: 22h00 civil (RF-08.5).
  static const LocalTimeOfDay sundayExceptionEnd = LocalTimeOfDay(22, 0);

  /// Verdadeiro quando [candidate] cai no blackout e não é coberto por uma
  /// exceção dominical habilitada.
  ///
  /// [sundayExceptionEnabled] reflete `sunday_notification_enabled` das
  /// configurações (desligado por padrão, RF-08.6). Quando `false`, nenhuma
  /// exceção se aplica e todo o intervalo permanece bloqueado.
  bool isBlocked(
    tz.TZDateTime candidate, {
    required bool sundayExceptionEnabled,
  }) {
    if (!_isWithinBlackoutWindow(candidate)) {
      return false;
    }
    if (sundayExceptionEnabled && _isSundayExceptionMoment(candidate)) {
      return false;
    }
    return true;
  }

  /// Verdadeiro quando [candidate] pertence ao intervalo semiaberto
  /// `[sábado 00h00 civil, operationalOpen(segunda operacional))`.
  ///
  /// Ignora a exceção dominical: descreve apenas a janela bruta do blackout.
  bool isWithinBlackoutWindow(tz.TZDateTime candidate) =>
      _isWithinBlackoutWindow(candidate);

  bool _isWithinBlackoutWindow(tz.TZDateTime candidate) {
    final civil = _clock.civilMomentOf(candidate);
    // Segunda-feira que ABRE (e portanto encerra o blackout) do fim de semana
    // ao qual [candidate] pode pertencer. A janela é
    // `[sábado 00h00, operationalOpen(segunda))`, com sábado = segunda - 2.
    final closingMonday = _closingMonday(civil.date);
    final saturdayStart = _clock.resolveCivil(
      CivilMoment(
        date: closingMonday.addDays(-2),
        time: const LocalTimeOfDay(0, 0),
      ),
    );
    final mondayOpen = _clock.operationalOpen(closingMonday);
    return !candidate.isBefore(saturdayStart) && candidate.isBefore(mondayOpen);
  }

  /// Segunda-feira civil cuja abertura operacional encerra o blackout do fim de
  /// semana que contém [civilDate].
  ///
  /// Sábado e domingo pertencem ao fim de semana encerrado pela segunda
  /// seguinte (`operationalWeekStart(civilDate) + 7`). Uma segunda-feira civil
  /// antes de sua própria abertura operacional (madrugada `[00h00,
  /// day_close_time)`) ainda encerra o fim de semana anterior, então a segunda
  /// que fecha o blackout é ela mesma. Demais dias não têm blackout ativo; a
  /// segunda calculada resulta em uma janela que não os contém.
  OperationalDate _closingMonday(OperationalDate civilDate) {
    final thisWeekMonday = operationalWeekStart(civilDate);
    switch (civilDate.weekday) {
      case DateTime.saturday:
      case DateTime.sunday:
        return thisWeekMonday.addDays(7);
      default:
        return thisWeekMonday;
    }
  }

  bool _isSundayExceptionMoment(tz.TZDateTime candidate) {
    final civil = _clock.civilMomentOf(candidate);
    if (civil.date.weekday != DateTime.sunday) {
      return false;
    }
    return civil.time >= sundayExceptionStart &&
        civil.time <= sundayExceptionEnd;
  }
}
