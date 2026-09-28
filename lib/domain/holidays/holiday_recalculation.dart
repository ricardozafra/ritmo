import '../time/operational_calendar.dart';

/// Alteração manual possível sobre a classificação de uma data operacional.
enum HolidayOperation { apply, remove }

/// Confirmação sóbria apresentada antes de qualquer escrita (RF-05.26).
final class RecalcPreview {
  const RecalcPreview({
    required this.date,
    required this.operation,
    required this.title,
    required this.message,
  });

  final OperationalDate date;
  final HolidayOperation operation;
  final String title;
  final String message;
}

/// Evento interno, sem semântica ou dependência de notificação.
///
/// Consumidores futuros (como o scheduler da Fase 2) podem reconciliar seus
/// próprios planos depois do commit observando [occurredAtMillisecondsSinceEpoch].
final class HolidayChangedEvent {
  const HolidayChangedEvent({
    required this.date,
    required this.operation,
    required this.occurredAtMillisecondsSinceEpoch,
  });

  final OperationalDate date;
  final HolidayOperation operation;
  final int occurredAtMillisecondsSinceEpoch;
}
