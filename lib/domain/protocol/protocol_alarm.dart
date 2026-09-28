import 'package:timezone/timezone.dart' as tz;

import '../time/operational_calendar.dart';

/// Estados possíveis de um Alarme de Protocolo (RD-12).
enum ProtocolState { pending, answered, invalidated }

/// Classificação exigida pela segunda pergunta do protocolo (RD-13).
enum PlanOrExecution { plan, execution }

/// Reflexão de uma geração de sequência de falha, tal como persistida.
///
/// Um protocolo `invalidated` permanece imutável e nunca é reutilizado
/// (RF-03.17, RD-15); um `answered` guarda data de disparo, causa,
/// classificação e ajuste (RF-03.15).
final class ProtocolAlarm {
  const ProtocolAlarm({
    required this.id,
    required this.generationId,
    required this.startDate,
    required this.endDate,
    required this.sequenceLength,
    required this.state,
    this.previousState,
    this.triggeredAt,
    this.cause,
    this.planOrExecution,
    this.adjustment,
  });

  final String id;
  final String generationId;
  final OperationalDate startDate;
  final OperationalDate endDate;
  final int sequenceLength;
  final ProtocolState state;

  /// Estado vivo anterior, preservado quando o protocolo é invalidado.
  final ProtocolState? previousState;

  final tz.TZDateTime? triggeredAt;
  final String? cause;
  final PlanOrExecution? planOrExecution;
  final String? adjustment;

  bool get isPending => state == ProtocolState.pending;
  bool get isAnswered => state == ProtocolState.answered;
  bool get isInvalidated => state == ProtocolState.invalidated;

  @override
  String toString() =>
      'ProtocolAlarm($id, $generationId, ${startDate.iso}..${endDate.iso}, '
      'length: $sequenceLength, state: ${state.name})';
}

/// Resposta completa ao formulário do protocolo (RF-03.14, RF-03.15).
final class ProtocolAnswer {
  const ProtocolAnswer({
    required this.triggeredAt,
    required this.cause,
    required this.planOrExecution,
    required this.adjustment,
  });

  /// Instante em que o protocolo foi disparado ao usuário, no fuso oficial.
  final tz.TZDateTime triggeredAt;
  final String cause;
  final PlanOrExecution planOrExecution;
  final String adjustment;
}
