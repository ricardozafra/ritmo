import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../data/notifications/local_notification_gateway.dart';
import '../../data/repositories/notification_plans_repository.dart';
import '../scheduler.dart';
import 'boundary_providers.dart';
import 'holiday_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;
import 'settings_providers.dart';

final notificationPlansRepositoryProvider =
    Provider<NotificationPlansRepository>(
      (ref) => NotificationPlansRepository(ref.watch(ritmoDatabaseProvider)),
    );

/// Gateway local de notificações. Inerte por padrão; a composição de produção
/// (ex.: `main`) sobrescreve com `FlutterLocalNotificationGateway`. Manter o
/// NoOp como padrão permite que testes e execuções headless não toquem o SO,
/// e a ausência de permissão nunca impede o app de funcionar.
final localNotificationGatewayProvider = Provider<LocalNotificationGateway>(
  (ref) => const NoOpLocalNotificationGateway(),
);

/// Scheduler ligado ao clock vigente da fronteira. Reconstruído quando a
/// fronteira reconfigura o relógio (revisão do `boundaryRevisionProvider`).
final notificationSchedulerProvider = FutureProvider<NotificationScheduler>((
  ref,
) async {
  // Rebuild quando o clock é reconfigurado (mudança de horários).
  ref.watch(boundaryRevisionProvider);
  final runtime = await ref.watch(boundaryRuntimeProvider.future);
  return NotificationScheduler(
    clock: runtime.clock,
    plans: ref.watch(notificationPlansRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    gateway: ref.watch(localNotificationGatewayProvider),
  );
});

/// Fia o scheduler aos eventos internos do MVP — configurações, feriados e
/// fronteira — reconciliando os planos a cada mudança, sem que a Fase 1 conheça
/// a Fase 2. Mantê-lo observado (por exemplo, `ref.watch` no bootstrap) ativa a
/// reconciliação contínua (RF-08.15).
final notificationReconciliationProvider = Provider<void>((ref) {
  Future<void> reconcile() async {
    final scheduler = await ref.read(notificationSchedulerProvider.future);
    await scheduler.reconcilePlans();
  }

  ref.listen(settingsChangesProvider, (_, _) {
    unawaited(reconcile());
  });
  ref.listen(holidayChangesProvider, (_, _) {
    unawaited(reconcile());
  });
  ref.listen(boundaryRevisionProvider, (_, _) {
    unawaited(reconcile());
  });

  // Reconciliação inicial ao ativar.
  unawaited(reconcile());
});
