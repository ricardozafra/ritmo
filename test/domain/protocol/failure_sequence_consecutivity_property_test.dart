// Feature: ritmo, Property 16: Consecutividade ignora dias `mute` e o período
// pré-ativação
//
// Para qualquer linha do tempo, inserir dias `mute` em posições arbitrárias
// entre dias úteis não altera o conjunto de sequências de falha detectadas;
// nenhum dia anterior a `activation_date` participa de sequência; e a inserção
// de um dia útil selado em qualquer posição parte a sequência que o contém.
//
// **Validates: Requirements RF-03.5, RF-03.6, RF-03.7, RF-02.16**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/protocol/failure_sequence_detector.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

/// Cada posição da linha do tempo é ausente (dia nunca materializado), `mute`
/// em uma de suas três formas persistíveis, ou dia útil encerrado sem selo,
/// encerrado com selo e ainda aberto.
enum _SlotKind {
  absent,
  muteWeekend,
  muteHolidayOverSealed,
  muteHolidayOpen,
  failure,
  sealedWorkday,
  openWorkday,
}

typedef _Slot = ({OperationalDate date, _SlotKind kind});
typedef _RefSeq = ({OperationalDate start, OperationalDate end, int length});
typedef _ConsecutivityInput = ({
  OperationalDate activationDate,
  List<_Slot> slots,
  OperationalDate insertionDate,
  List<OperationalDate> preActivationFailures,
  OperationalDate bridgeFriday,
  OperationalDate bridgeMonday,
});

/// Espaço explorado nas posições livres: falha é mais provável para produzir
/// sequências longas, mas selo, dia aberto, feriado e ausência aparecem.
const List<_SlotKind> _freeWeekdayPool = <_SlotKind>[
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.sealedWorkday,
  _SlotKind.sealedWorkday,
  _SlotKind.openWorkday,
  _SlotKind.muteHolidayOverSealed,
  _SlotKind.muteHolidayOpen,
  _SlotKind.absent,
];

/// Posições fixas que garantem testemunhas não vacuosas em toda amostra:
/// duas falhas separadas por uma data ausente (ponto de inserção do dia
/// selado) e a ponte sexta -> segunda com apenas dias `mute` entre elas.
const Map<int, _SlotKind> _plantedOffsets = <int, _SlotKind>{
  0: _SlotKind.failure,
  1: _SlotKind.absent,
  2: _SlotKind.failure,
  4: _SlotKind.failure,
  5: _SlotKind.muteWeekend,
  6: _SlotKind.muteWeekend,
  7: _SlotKind.failure,
};

const int _minimumSpan = 8;

final Generator<_ConsecutivityInput> _anyConsecutivityInput = any.simple(
  generate: (Random random, int size) {
    // A ativação sempre cai em uma segunda-feira: os deslocamentos plantados
    // dependem de 0..4 serem dias úteis e 5..6, fim de semana.
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final span = _minimumSpan + 2 + random.nextInt(max(1, min(size + 1, 11)));
    return _buildInput(
      activation: activation,
      span: span,
      freeWeekdayKind: (_) =>
          _freeWeekdayPool[random.nextInt(_freeWeekdayPool.length)],
    );
  },
  shrink: (input) sync* {
    if (input.slots.length > _minimumSpan + 4) {
      yield _buildInput(
        activation: input.activationDate,
        span: _minimumSpan,
        freeWeekdayKind: (_) => _SlotKind.sealedWorkday,
      );
    }
  },
);

_ConsecutivityInput _buildInput({
  required OperationalDate activation,
  required int span,
  required _SlotKind Function(int offset) freeWeekdayKind,
}) {
  final slots = <_Slot>[
    // Período pré-ativação: duas falhas contíguas que formariam sequência se
    // fossem contadas, seguidas do fim de semana `mute`.
    (date: activation.addDays(-4), kind: _SlotKind.failure),
    (date: activation.addDays(-3), kind: _SlotKind.failure),
    (date: activation.addDays(-2), kind: _SlotKind.muteWeekend),
    (date: activation.addDays(-1), kind: _SlotKind.muteWeekend),
  ];
  for (var offset = 0; offset < span; offset++) {
    final date = activation.addDays(offset);
    final kind =
        _plantedOffsets[offset] ??
        (date.isWeekend ? _SlotKind.muteWeekend : freeWeekdayKind(offset));
    slots.add((date: date, kind: kind));
  }
  return (
    activationDate: activation,
    slots: slots,
    insertionDate: activation.addDays(1),
    preActivationFailures: <OperationalDate>[
      activation.addDays(-4),
      activation.addDays(-3),
    ],
    bridgeFriday: activation.addDays(4),
    bridgeMonday: activation.addDays(7),
  );
}

bool _isMute(_SlotKind kind) =>
    kind == _SlotKind.muteWeekend ||
    kind == _SlotKind.muteHolidayOverSealed ||
    kind == _SlotKind.muteHolidayOpen;

EligibleDay _project(_Slot slot) => switch (slot.kind) {
  _SlotKind.muteWeekend => EligibleDay(
    date: slot.date,
    isWorkday: false,
    isClosed: true,
    isSealed: false,
    isMute: true,
  ),
  _SlotKind.muteHolidayOverSealed => EligibleDay(
    date: slot.date,
    isWorkday: false,
    isClosed: true,
    isSealed: true,
    isMute: true,
  ),
  _SlotKind.muteHolidayOpen => EligibleDay(
    date: slot.date,
    isWorkday: false,
    isClosed: false,
    isSealed: false,
    isMute: true,
  ),
  _SlotKind.failure => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: false,
    isMute: false,
  ),
  _SlotKind.sealedWorkday => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: true,
    isMute: false,
  ),
  _SlotKind.openWorkday => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: false,
    isSealed: false,
    isMute: false,
  ),
  _SlotKind.absent => throw StateError('data ausente não é projetada'),
};

List<EligibleDay> _projectAll(Iterable<_Slot> slots) => <EligibleDay>[
  for (final slot in slots)
    if (slot.kind != _SlotKind.absent) _project(slot),
];

/// Modelo de referência independente sobre a entrada bruta do teste: percorre
/// as datas em ordem, descarta ausências, `mute` e datas pré-ativação, e emite
/// as corridas de falha com dois ou mais elementos.
List<_RefSeq> _reference(List<_Slot> slots, OperationalDate activation) {
  final ordered = List<_Slot>.of(slots)
    ..sort((left, right) => left.date.compareTo(right.date));
  final sequences = <_RefSeq>[];
  final run = <OperationalDate>[];

  void flush() {
    if (run.length >= 2) {
      sequences.add((start: run.first, end: run.last, length: run.length));
    }
    run.clear();
  }

  for (final slot in ordered) {
    if (slot.kind == _SlotKind.absent) continue;
    if (slot.date < activation) continue;
    if (_isMute(slot.kind)) continue;
    if (slot.kind == _SlotKind.failure) {
      run.add(slot.date);
    } else {
      flush();
    }
  }
  flush();
  return sequences;
}

_RefSeq _asRef(FailureSequence sequence) =>
    (start: sequence.startDate, end: sequence.endDate, length: sequence.length);

List<_RefSeq> _asRefs(Iterable<FailureSequence> sequences) =>
    sequences.map(_asRef).toList(growable: false);

void main() {
  const detector = FailureSequenceDetector();

  Glados<_ConsecutivityInput>(_anyConsecutivityInput, RitmoGlados.ci()).test(
    'Propriedade 16: consecutividade ignora dias mute e o período '
    'pré-ativação',
    (_ConsecutivityInput input) {
      final activation = input.activationDate;
      final withMute = detector.detect(_projectAll(input.slots), activation);
      final context =
          'activation=${activation.iso}, slots=${input.slots.length}, '
          'sequências=${withMute.length}';

      expect(
        _asRefs(withMute),
        _reference(input.slots, activation),
        reason: context,
      );
      for (final sequence in withMute) {
        expect(
          sequence.generationId,
          'seq:${sequence.startDate.iso}',
          reason: context,
        );
      }

      // 1. Dias `mute` são transparentes: removê-los de posições arbitrárias
      // entre dias úteis não altera o conjunto de sequências detectadas.
      final withoutMute = detector.detect(
        _projectAll(input.slots.where((slot) => !_isMute(slot.kind))),
        activation,
      );
      expect(_asRefs(withoutMute), _asRefs(withMute), reason: context);

      // RF-03.7: sexta e a segunda útil seguinte, com apenas dias `mute`
      // entre elas, pertencem à mesma sequência.
      expect(
        withMute.any(
          (sequence) =>
              sequence.startDate <= input.bridgeFriday &&
              input.bridgeMonday <= sequence.endDate,
        ),
        isTrue,
        reason:
            'ponte ${input.bridgeFriday.iso} -> '
            '${input.bridgeMonday.iso} deve ficar na mesma sequência '
            '($context)',
      );

      // 2. Nenhum dia anterior à ativação participa de sequência, e restringir
      // a linha do tempo a partir da ativação não muda nada.
      for (final sequence in withMute) {
        expect(sequence.startDate >= activation, isTrue, reason: context);
      }
      expect(
        _asRefs(
          detector.detect(
            _projectAll(input.slots.where((slot) => slot.date >= activation)),
            activation,
          ),
        ),
        _asRefs(withMute),
        reason: context,
      );

      // Testemunha não vacuosa: as falhas pré-ativação são falhas de verdade,
      // e só a data de ativação as mantém fora do resultado.
      final withEarlyActivation = detector.detect(
        _projectAll(input.slots),
        input.preActivationFailures.first,
      );
      expect(
        withEarlyActivation.first.startDate,
        input.preActivationFailures.first,
        reason: context,
      );
      expect(
        _asRefs(withEarlyActivation),
        isNot(_asRefs(withMute)),
        reason: context,
      );

      // 3. Inserir um dia útil selado em uma data livre interna parte a
      // sequência que o contém; os pedaços com dois ou mais dias sobrevivem.
      final containing = withMute.singleWhere(
        (sequence) =>
            sequence.startDate <= input.insertionDate &&
            input.insertionDate <= sequence.endDate,
      );
      final inserted = <_Slot>[
        for (final slot in input.slots)
          if (slot.date != input.insertionDate) slot,
        (date: input.insertionDate, kind: _SlotKind.sealedWorkday),
      ];
      final afterInsertion = detector.detect(_projectAll(inserted), activation);

      final failureDates = <OperationalDate>[
        for (final slot in input.slots)
          if (slot.kind == _SlotKind.failure &&
              containing.startDate <= slot.date &&
              slot.date <= containing.endDate)
            slot.date,
      ]..sort((left, right) => left.compareTo(right));
      final left = failureDates
          .where((date) => date < input.insertionDate)
          .toList(growable: false);
      final right = failureDates
          .where((date) => date > input.insertionDate)
          .toList(growable: false);
      final expectedAfter = <_RefSeq>[
        for (final sequence in withMute)
          if (sequence != containing)
            _asRef(sequence)
          else ...<_RefSeq>[
            if (left.length >= 2)
              (start: left.first, end: left.last, length: left.length),
            if (right.length >= 2)
              (start: right.first, end: right.last, length: right.length),
          ],
      ];

      expect(_asRefs(afterInsertion), expectedAfter, reason: context);
      expect(
        _asRefs(afterInsertion),
        _reference(inserted, activation),
        reason: context,
      );
      expect(
        afterInsertion.any(
          (sequence) =>
              sequence.startDate <= input.insertionDate &&
              input.insertionDate <= sequence.endDate,
        ),
        isFalse,
        reason:
            'nenhuma sequência pode atravessar '
            '${input.insertionDate.iso} ($context)',
      );
    },
  );
}
