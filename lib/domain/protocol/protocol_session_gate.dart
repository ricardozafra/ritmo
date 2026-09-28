import 'protocol_alarm.dart';

/// Seleciona qual protocolo pendente é exibido em uma abertura do aplicativo.
///
/// Uma "abertura" é uma inicialização a frio: cada instância desta classe vive
/// por exatamente uma abertura. Vários protocolos podem permanecer `pending`
/// simultaneamente (RF-03.9), mas somente o de menor `start_date` é exibido
/// durante a abertura (RF-03.10). Responder ao protocolo exibido encerra a
/// sessão de protocolo: nenhum outro pendente aparece antes de uma nova
/// abertura (RF-03.11, RF-03.12, RF-03.23).
///
/// A classe é pura: não consulta relógio, banco nem qualquer I/O, e nunca
/// dispara push, cobrança ou alerta externo (RF-03.21).
final class ProtocolSessionGate {
  ProtocolSessionGate();

  String? _selectedId;
  bool _selectionAttempted = false;
  bool _sessionClosed = false;

  /// Identificador do protocolo escolhido nesta abertura, se houver.
  String? get selectedId => _selectedId;

  /// Verdadeiro quando a sessão já cumpriu seu único protocolo.
  bool get isSessionClosed => _sessionClosed;

  /// Retorna o protocolo desta abertura, ou `null` quando não há o que exibir.
  ///
  /// [candidates] pode conter protocolos em qualquer estado e em qualquer
  /// ordem; apenas os `pending` são considerados. Chamadas repetidas devolvem
  /// sempre o mesmo protocolo enquanto ele continuar pendente. Quando o
  /// protocolo escolhido deixa de estar pendente — porque foi respondido ou
  /// invalidado — a sessão se encerra e nenhum substituto é revelado.
  ProtocolAlarm? selectForThisLaunch(Iterable<ProtocolAlarm> candidates) {
    if (_sessionClosed) return null;

    final pending = candidates.where((alarm) => alarm.isPending).toList()
      ..sort(_byStartDateThenId);

    final selectedId = _selectedId;
    if (selectedId != null) {
      final current = pending.where((alarm) => alarm.id == selectedId).toList();
      if (current.isEmpty) {
        _sessionClosed = true;
        return null;
      }
      return current.single;
    }

    if (_selectionAttempted) return null;
    _selectionAttempted = true;
    if (pending.isEmpty) {
      _sessionClosed = true;
      return null;
    }
    final oldest = pending.first;
    _selectedId = oldest.id;
    return oldest;
  }

  /// Encerra a sessão explicitamente, após a resposta ser persistida.
  ///
  /// Idempotente: chamar mais de uma vez não muda nada.
  void closeSession() => _sessionClosed = true;

  /// Ordem total determinística: `start_date` e, no empate, `id`.
  static int _byStartDateThenId(ProtocolAlarm left, ProtocolAlarm right) {
    final byStart = left.startDate.compareTo(right.startDate);
    return byStart != 0 ? byStart : left.id.compareTo(right.id);
  }
}
