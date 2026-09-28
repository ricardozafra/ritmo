import '../domain/time/operational_calendar.dart';

/// Fato publicado somente após o commit de uma fronteira operacional.
final class BoundaryCommittedEvent {
  const BoundaryCommittedEvent({
    required this.closedDate,
    required this.currentDate,
    required this.closedAtMillisecondsSinceEpoch,
    required this.closedNow,
  });

  final OperationalDate closedDate;
  final OperationalDate currentDate;
  final int closedAtMillisecondsSinceEpoch;
  final bool closedNow;
}

/// Porta pós-commit para reconciliar planos de agenda.
///
/// A travessia nunca agenda uma notificação sobre o próprio fechamento. Um
/// adaptador da Fase 2 poderá apenas recalcular os planos futuros.
abstract interface class ScheduleReconciler {
  Future<void> reconcileAfterBoundary(BoundaryCommittedEvent event);
}

/// MVP: não há agenda externa a reconciliar nem notificação a emitir.
final class NoOpScheduleReconciler implements ScheduleReconciler {
  const NoOpScheduleReconciler();

  @override
  Future<void> reconcileAfterBoundary(BoundaryCommittedEvent event) async {}
}
