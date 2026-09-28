import 'package:timezone/timezone.dart' as tz;

import '../review/review_schedule_validator.dart';
import '../time/operational_calendar.dart';
import '../time/operational_clock.dart';
import 'blackout_policy.dart';

/// Tipos de notificação do Ritmo. Somente a Revisão Semanal notifica; nenhum
/// protocolo, Encerramento de Ciclo ou mentoria gera notificação (RF-03.21,
/// RF-06.10, RF-07.21, Restrição 6.5).
enum NotificationKind {
  weeklyReviewSunday('weekly_review_sunday'),
  weeklyReviewMonday('weekly_review_monday');

  const NotificationKind(this.wireValue);

  /// Forma persistida na coluna `kind`.
  final String wireValue;

  static NotificationKind? fromWire(String value) {
    for (final kind in values) {
      if (kind.wireValue == value) return kind;
    }
    return null;
  }
}

/// Ciclo de vida de um plano de notificação.
///
/// - `planned`: persistido e agendado no SO, aguardando entrega.
/// - `delivered`: revalidado na entrega e liberado para abrir o fluxo.
/// - `cancelled`: reconciliação removeu o plano (configuração mudou).
/// - `suppressed`: bloqueado pelo blackout ou pela revalidação na entrega.
enum PlanState {
  planned('planned'),
  delivered('delivered'),
  cancelled('cancelled'),
  suppressed('suppressed');

  const PlanState(this.wireValue);

  /// Forma persistida na coluna `state`.
  final String wireValue;

  static PlanState? fromWire(String value) {
    for (final state in values) {
      if (state.wireValue == value) return state;
    }
    return null;
  }
}

/// Plano semanal idempotente de notificação da Revisão.
///
/// A [idempotencyKey] combina o tipo e a semana operacional
/// (`"<kind>:<week_start ISO>"`), garantindo no máximo um plano por
/// `(kind, week_start)` mesmo diante de reagendamentos ou mudanças de fuso do
/// aparelho (RNF-04.3, RNF-04.8, RNF-04.9).
final class NotificationPlan {
  const NotificationPlan({
    required this.idempotencyKey,
    required this.kind,
    required this.plannedAt,
    required this.state,
  });

  final String idempotencyKey;
  final NotificationKind kind;
  final tz.TZDateTime plannedAt;
  final PlanState state;

  /// Compõe a chave idempotente semanal de um [kind] e uma [weekStart].
  static String keyFor(NotificationKind kind, OperationalDate weekStart) =>
      '${kind.wireValue}:${weekStart.iso}';

  NotificationPlan copyWith({PlanState? state}) => NotificationPlan(
    idempotencyKey: idempotencyKey,
    kind: kind,
    plannedAt: plannedAt,
    state: state ?? this.state,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPlan &&
      other.idempotencyKey == idempotencyKey &&
      other.kind == kind &&
      other.plannedAt.millisecondsSinceEpoch ==
          plannedAt.millisecondsSinceEpoch &&
      other.state == state;

  @override
  int get hashCode => Object.hash(
    idempotencyKey,
    kind,
    plannedAt.millisecondsSinceEpoch,
    state,
  );

  @override
  String toString() =>
      'NotificationPlan($idempotencyKey, ${kind.wireValue}, '
      '$plannedAt, ${state.wireValue})';
}

/// Configuração vigente da Revisão Semanal relevante para o agendamento.
final class ReviewNotificationConfig {
  const ReviewNotificationConfig({
    required this.weekday,
    required this.time,
    required this.sundayExceptionEnabled,
  });

  final ReviewWeekday weekday;
  final LocalTimeOfDay time;

  /// `sunday_notification_enabled`: opt-in dominical, desligado por padrão
  /// (RF-08.6).
  final bool sundayExceptionEnabled;
}

/// Decisão pura sobre qual plano deve existir para uma semana operacional.
///
/// Não persiste, não agenda e não lê o relógio do aparelho: recebe o
/// [OperationalClock] para converter coordenadas civis em instantes absolutos
/// no fuso oficial e o [BlackoutPolicy] para o filtro de fim de semana. Toda a
/// política de blackout, janela dominical e abertura de segunda é resolvida
/// aqui, antes de qualquer efeito (RNF-04.7).
final class NotificationPlanner {
  NotificationPlanner(this._clock, {BlackoutPolicy? blackout})
    : _blackout = blackout ?? BlackoutPolicy(_clock);

  final OperationalClock _clock;
  final BlackoutPolicy _blackout;

  /// Plano que deve estar agendado para a semana operacional que contém [now],
  /// ou `null` quando nada deve ser agendado.
  ///
  /// - Domingo: só há plano quando a exceção dominical está habilitada e o
  ///   horário configurado cai em `[20h00, 22h00]`; caso contrário nada é
  ///   agendado (RF-08.6, RF-08.8, RF-08.16).
  /// - Segunda: o plano existe sempre, mas o instante é a abertura operacional
  ///   de segunda no horário configurado; a entrega antes da abertura é barrada
  ///   na revalidação (RF-05.21, RF-08.13, RF-08.18).
  ///
  /// O instante planejado nunca viola o blackout: para domingo é a própria
  /// exceção; para segunda é, por construção, posterior à abertura operacional
  /// e, portanto, fora da janela `[sábado 00h00, operationalOpen(segunda))`.
  NotificationPlan? planForWeekOf(
    tz.TZDateTime now,
    ReviewNotificationConfig config,
  ) {
    final currentDate = _clock.operationalDateOf(now);
    final weekStart = _operationalWeekStart(currentDate);

    switch (config.weekday) {
      case ReviewWeekday.sunday:
        if (!config.sundayExceptionEnabled) return null;
        if (!_isWithinSundayWindow(config.time)) return null;
        final sunday = weekStart.addDays(6);
        final plannedAt = _clock.resolveCivil(
          CivilMoment(date: sunday, time: config.time),
        );
        return _planIfSchedulable(
          kind: NotificationKind.weeklyReviewSunday,
          weekStart: weekStart,
          plannedAt: plannedAt,
          sundayExceptionEnabled: config.sundayExceptionEnabled,
        );
      case ReviewWeekday.monday:
        // A semana da Revisão de segunda é nomeada pela própria segunda que a
        // abre. O instante planejado é essa segunda no horário configurado.
        final nextMonday = weekStart.addDays(7);
        final plannedAt = _clock.resolveCivil(
          CivilMoment(date: nextMonday, time: config.time),
        );
        return _planIfSchedulable(
          kind: NotificationKind.weeklyReviewMonday,
          weekStart: nextMonday,
          plannedAt: plannedAt,
          sundayExceptionEnabled: config.sundayExceptionEnabled,
        );
    }
  }

  /// Revalida um plano no momento da entrega (segunda validação, RNF-04.7,
  /// RNF-04.8). Verdadeiro quando a notificação pode abrir o fluxo agora.
  ///
  /// Reaplica o blackout ao instante corrente e, para a Revisão de segunda,
  /// exige que a abertura operacional de segunda já tenha ocorrido
  /// (RF-08.13, RF-08.18).
  bool canDeliverNow(
    NotificationPlan plan,
    tz.TZDateTime now, {
    required bool sundayExceptionEnabled,
  }) {
    if (_blackout.isBlocked(
      now,
      sundayExceptionEnabled: sundayExceptionEnabled,
    )) {
      return false;
    }
    if (plan.kind == NotificationKind.weeklyReviewMonday) {
      return !now.isBefore(plan.plannedAt);
    }
    return true;
  }

  /// Constrói o plano `planned` quando o instante é agendável (não bloqueado
  /// pelo blackout); caso contrário retorna `null` — nada a persistir ou
  /// agendar (RNF-04.7).
  NotificationPlan? _planIfSchedulable({
    required NotificationKind kind,
    required OperationalDate weekStart,
    required tz.TZDateTime plannedAt,
    required bool sundayExceptionEnabled,
  }) {
    if (_blackout.isBlocked(
      plannedAt,
      sundayExceptionEnabled: sundayExceptionEnabled,
    )) {
      return null;
    }
    return NotificationPlan(
      idempotencyKey: NotificationPlan.keyFor(kind, weekStart),
      kind: kind,
      plannedAt: plannedAt,
      state: PlanState.planned,
    );
  }

  bool _isWithinSundayWindow(LocalTimeOfDay time) =>
      time >= BlackoutPolicy.sundayExceptionStart &&
      time <= BlackoutPolicy.sundayExceptionEnd;

  /// Segunda-feira operacional que nomeia a semana de [date] (RF-07.5).
  OperationalDate _operationalWeekStart(OperationalDate date) =>
      date.addDays(1 - date.weekday);
}
