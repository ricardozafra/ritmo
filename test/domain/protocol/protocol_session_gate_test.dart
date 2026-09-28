import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/protocol/protocol_alarm.dart';
import 'package:ritmo/domain/protocol/protocol_session_gate.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  test('sem pendentes, nada é exibido', () {
    final gate = ProtocolSessionGate();

    expect(gate.selectForThisLaunch(const []), isNull);
    expect(gate.selectedId, isNull);
  });

  test('uma abertura sem pendentes não seleciona protocolo criado depois', () {
    final gate = ProtocolSessionGate();

    expect(gate.selectForThisLaunch(const []), isNull);
    expect(
      gate.selectForThisLaunch([
        _pending(id: 'a', start: OperationalDate(2026, 1, 5)),
      ]),
      isNull,
    );
  });

  test('exibe o pendente de menor start_date', () {
    final gate = ProtocolSessionGate();
    final selected = gate.selectForThisLaunch([
      _pending(id: 'b', start: OperationalDate(2026, 2, 10)),
      _pending(id: 'a', start: OperationalDate(2026, 1, 5)),
      _pending(id: 'c', start: OperationalDate(2026, 3, 2)),
    ]);

    expect(selected?.id, 'a');
    expect(gate.selectedId, 'a');
  });

  test('empate de start_date é desfeito pelo id, de forma estável', () {
    final start = OperationalDate(2026, 1, 5);

    final first = ProtocolSessionGate().selectForThisLaunch([
      _pending(id: 'z', start: start),
      _pending(id: 'k', start: start),
    ]);
    final second = ProtocolSessionGate().selectForThisLaunch([
      _pending(id: 'k', start: start),
      _pending(id: 'z', start: start),
    ]);

    expect(first?.id, 'k');
    expect(second?.id, 'k');
  });

  test('chamadas repetidas na mesma abertura devolvem o mesmo protocolo', () {
    final gate = ProtocolSessionGate();
    final pending = [
      _pending(id: 'a', start: OperationalDate(2026, 1, 5)),
      _pending(id: 'b', start: OperationalDate(2026, 2, 10)),
    ];

    expect(gate.selectForThisLaunch(pending)?.id, 'a');
    expect(gate.selectForThisLaunch(pending)?.id, 'a');
    expect(gate.selectForThisLaunch(pending.reversed)?.id, 'a');
  });

  test('responder não revela outro pendente na mesma abertura', () {
    final gate = ProtocolSessionGate();
    final older = _pending(id: 'a', start: OperationalDate(2026, 1, 5));
    final newer = _pending(id: 'b', start: OperationalDate(2026, 2, 10));
    expect(gate.selectForThisLaunch([older, newer])?.id, 'a');

    gate.closeSession();

    expect(gate.selectForThisLaunch([newer]), isNull);
    expect(gate.isSessionClosed, isTrue);
  });

  test('o pendente restante aparece somente em nova abertura', () {
    final answered = ProtocolAlarm(
      id: 'a',
      generationId: 'seq:2026-01-05',
      startDate: OperationalDate(2026, 1, 5),
      endDate: OperationalDate(2026, 1, 6),
      sequenceLength: 2,
      state: ProtocolState.answered,
    );
    final newer = _pending(id: 'b', start: OperationalDate(2026, 2, 10));

    final nextLaunch = ProtocolSessionGate().selectForThisLaunch([
      answered,
      newer,
    ]);

    expect(nextLaunch?.id, 'b');
  });

  test('o protocolo escolhido deixando de estar pendente encerra a sessão', () {
    final gate = ProtocolSessionGate();
    final older = _pending(id: 'a', start: OperationalDate(2026, 1, 5));
    final newer = _pending(id: 'b', start: OperationalDate(2026, 2, 10));
    expect(gate.selectForThisLaunch([older, newer])?.id, 'a');

    expect(gate.selectForThisLaunch([newer]), isNull);
    expect(gate.isSessionClosed, isTrue);
  });

  test('estados answered e invalidated nunca são exibidos', () {
    final gate = ProtocolSessionGate();

    final selected = gate.selectForThisLaunch([
      ProtocolAlarm(
        id: 'a',
        generationId: 'seq:2026-01-05',
        startDate: OperationalDate(2026, 1, 5),
        endDate: OperationalDate(2026, 1, 6),
        sequenceLength: 2,
        state: ProtocolState.invalidated,
        previousState: ProtocolState.pending,
      ),
      ProtocolAlarm(
        id: 'b',
        generationId: 'seq:2026-02-10',
        startDate: OperationalDate(2026, 2, 10),
        endDate: OperationalDate(2026, 2, 11),
        sequenceLength: 2,
        state: ProtocolState.answered,
      ),
    ]);

    expect(selected, isNull);
  });
}

ProtocolAlarm _pending({required String id, required OperationalDate start}) =>
    ProtocolAlarm(
      id: id,
      generationId: 'seq:${start.iso}',
      startDate: start,
      endDate: start.next,
      sequenceLength: 2,
      state: ProtocolState.pending,
    );
