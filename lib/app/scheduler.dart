import '../data/notifications/local_notification_gateway.dart';
import '../data/repositories/notification_plans_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/notifications/blackout_policy.dart';
import '../domain/notifications/notification_plan.dart';
import '../domain/time/operational_clock.dart';
import 'schedule_reconciler.dart';

/// Coordena os planos semanais de notificação da Revisão (RF-08.5 a RF-08.18).
///
/// Aplica o blackout **antes de persistir** e **antes de agendar/entregar**
/// (RNF-04.7): a decisão de qual plano deve existir é do domínio
/// (`NotificationPlanner`), e este serviço apenas materializa o resultado no
/// banco e no SO. Reconciliar é idempotente — chamar `reconcilePlans` várias
/// vezes converge para o mesmo conjunto de planos, sem duplicar (chave
/// idempotente semanal) e sem criar reagendamento, snooze ou follow-up.
final class NotificationScheduler {
  NotificationScheduler({
    required OperationalClock clock,
    required NotificationPlansRepository plans,
    required SettingsRepository settings,
    required LocalNotificationGateway gateway,
    BlackoutPolicy? blackout,
    NotificationPlanner? planner,
  }) : _clock = clock,
       // ignore: prefer_initializing_formals
       _plans = plans,
       // ignore: prefer_initializing_formals
       _settings = settings,
       // ignore: prefer_initializing_formals
       _gateway = gateway,
       _planner = planner ?? NotificationPlanner(clock, blackout: blackout);

  final OperationalClock _clock;
  final NotificationPlansRepository _plans;
  final SettingsRepository _settings;
  final LocalNotificationGateway _gateway;
  final NotificationPlanner _planner;

  /// Recalcula os planos futuros a partir da configuração vigente e do instante
  /// corrente. Persiste e agenda o plano da semana quando houver, cancela os
  /// que não devem mais existir e nunca viola o blackout (RF-08.15).
  Future<void> reconcilePlans() async {
    final snapshot = await _settings.load();
    final now = _clock.nowInBusinessZone();
    final config = _configFrom(snapshot);

    final desired = _planner.planForWeekOf(now, config);
    final keepKeys = <String>{};

    if (desired != null && now.isBefore(desired.plannedAt)) {
      // Preserva o estado já entregue: um plano entregue não volta a `planned`.
      final existing = await _plans.findByKey(desired.idempotencyKey);
      if (existing == null || existing.state == PlanState.planned) {
        await _plans.upsert(desired);
        await _schedule(desired);
      }
      keepKeys.add(desired.idempotencyKey);
    }

    final cancelled = await _plans.cancelPlansNotIn(keepKeys);
    for (final key in cancelled) {
      await _gateway.cancel(_notificationId(key));
    }
  }

  /// Revalida um plano no momento da entrega (segunda validação, RNF-04.7,
  /// RNF-04.8) e marca seu estado. Retorna `true` quando o fluxo de Revisão
  /// pode ser aberto agora; `false` quando a entrega foi suprimida.
  ///
  /// A abertura do fluxo é responsabilidade do chamador; a exceção dominical
  /// nunca altera a home nem retira o `mute` (RF-08.9, RF-08.12).
  Future<bool> handleDelivery(String idempotencyKey) async {
    final plan = await _plans.findByKey(idempotencyKey);
    if (plan == null) return false;

    final snapshot = await _settings.load();
    final now = _clock.nowInBusinessZone();
    final canDeliver = _planner.canDeliverNow(
      plan,
      now,
      sundayExceptionEnabled: snapshot.sundayNotificationEnabled,
    );
    await _plans.updateState(
      idempotencyKey,
      canDeliver ? PlanState.delivered : PlanState.suppressed,
    );
    return canDeliver;
  }

  Future<void> _schedule(NotificationPlan plan) => _gateway.schedule(
    ScheduledNotification(
      id: _notificationId(plan.idempotencyKey),
      idempotencyKey: plan.idempotencyKey,
      title: _title,
      body: _body,
      scheduledAt: plan.plannedAt,
    ),
  );

  ReviewNotificationConfig _configFrom(SettingsSnapshot snapshot) =>
      ReviewNotificationConfig(
        weekday: snapshot.reviewWeekday,
        time: snapshot.reviewTime,
        sundayExceptionEnabled: snapshot.sundayNotificationEnabled,
      );

  static const String _title = 'Revisão Semanal';
  static const String _body = 'É hora de revisar sua semana no Ritmo.';

  /// Id numérico estável e não negativo para o SO, derivado da chave semanal.
  static int _notificationId(String idempotencyKey) =>
      idempotencyKey.hashCode & 0x7fffffff;
}

/// Adaptador pós-fronteira: reconcilia os planos após o commit de uma
/// travessia, sem introduzir dependência reversa da Fase 1 sobre a Fase 2
/// (a `BoundaryCrossingService` conhece apenas a interface `ScheduleReconciler`).
final class NotificationScheduleReconciler implements ScheduleReconciler {
  const NotificationScheduleReconciler(this._scheduler);

  final NotificationScheduler _scheduler;

  @override
  Future<void> reconcileAfterBoundary(BoundaryCommittedEvent event) =>
      _scheduler.reconcilePlans();
}
