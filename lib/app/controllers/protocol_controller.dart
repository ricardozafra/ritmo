import '../../core/result.dart';
import '../../data/repositories/protocol_repository.dart';
import '../../domain/protocol/protocol_alarm.dart';
import '../../domain/protocol/protocol_session_gate.dart';

/// Orquestra a resposta do único protocolo escolhido nesta abertura.
final class ProtocolController {
  const ProtocolController(this._repository, this._gate);

  final ProtocolRepository _repository;
  final ProtocolSessionGate _gate;

  Future<Result<ProtocolAlarm, BusinessViolation>> answerSelected(
    ProtocolAnswer answer,
  ) async {
    final id = _gate.selectedId;
    if (id == null || _gate.isSessionClosed) {
      return const Result<ProtocolAlarm, BusinessViolation>.failure(
        ProtocolViolation(
          code: 'protocol_not_selected',
          message: 'Nenhum protocolo está disponível nesta abertura.',
        ),
      );
    }

    final result = await _repository.answer(id: id, answer: answer);
    if (result.isSuccess) _gate.closeSession();
    return result;
  }
}
