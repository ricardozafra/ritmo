// Feature: ritmo, Property 20: Copy de dia único
//
// Para qualquer linha do tempo, a copy literal de dia perdido está disponível
// se e somente se a sequência corrente de dias úteis encerrados e não selados
// tem exatamente um elemento.
//
// **Validates: Requirements RF-03.2**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/protocol/single_lost_day_copy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

enum _SlotKind {
  absent,
  failure,
  sealed,
  openUnsealed,
  openSealed,
  muteHoliday,
  muteWeekend,
}

typedef _Slot = ({OperationalDate date, _SlotKind kind});
typedef _TimelineInput = ({OperationalDate activationDate, List<_Slot> slots});

const List<_SlotKind> _weekdayPool = <_SlotKind>[
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.sealed,
  _SlotKind.sealed,
  _SlotKind.openUnsealed,
  _SlotKind.openSealed,
  _SlotKind.muteHoliday,
  _SlotKind.absent,
];

final Generator<_TimelineInput> _anyTimeline = any.simple(
  generate: (Random random, int size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }

    final daysBeforeActivation = random.nextInt(5);
    final maximumLength = max(2, min(size + 2, 25));
    final length = random.nextInt(maximumLength);
    final slots = <_Slot>[];
    for (var index = 0; index < length; index++) {
      final date = activation.addDays(index - daysBeforeActivation);
      final kind = date.isWeekend
          ? _SlotKind.muteWeekend
          : _weekdayPool[random.nextInt(_weekdayPool.length)];
      slots.add((date: date, kind: kind));
    }

    // A derivação deve depender da cronologia, não da ordem recebida.
    slots.shuffle(random);
    return (activationDate: activation, slots: slots);
  },
  shrink: (input) sync* {
    final canonical = (
      activationDate: canonicalOperationalDate,
      slots: <_Slot>[(date: canonicalOperationalDate, kind: _SlotKind.failure)],
    );
    if (input.activationDate != canonical.activationDate ||
        input.slots.length != 1 ||
        input.slots.single.kind != _SlotKind.failure) {
      yield canonical;
    }
  },
);

bool _isMute(_SlotKind kind) =>
    kind == _SlotKind.muteHoliday || kind == _SlotKind.muteWeekend;

EligibleDay _project(_Slot slot) => switch (slot.kind) {
  _SlotKind.failure => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: false,
    isMute: false,
  ),
  _SlotKind.sealed => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: true,
    isMute: false,
  ),

  _SlotKind.openUnsealed => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: false,
    isSealed: false,
    isMute: false,
  ),
  _SlotKind.openSealed => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: false,
    isSealed: true,
    isMute: false,
  ),
  _SlotKind.muteHoliday || _SlotKind.muteWeekend => EligibleDay(
    date: slot.date,
    isWorkday: false,
    isClosed: true,
    isSealed: false,
    isMute: true,
  ),
  _SlotKind.absent => throw StateError('data ausente não é projetada'),
};

List<EligibleDay> _projectAll(Iterable<_Slot> slots) => <EligibleDay>[
  for (final slot in slots)
    if (slot.kind != _SlotKind.absent) _project(slot),
];

bool _referenceMakesCopyAvailable(
  List<_Slot> slots,
  OperationalDate activationDate,
) {
  final ordered = List<_Slot>.of(slots)
    ..sort((left, right) => left.date.compareTo(right.date));
  var currentFailures = 0;

  for (final slot in ordered) {
    if (slot.kind == _SlotKind.absent ||
        slot.date < activationDate ||
        _isMute(slot.kind)) {
      continue;
    }
    switch (slot.kind) {
      case _SlotKind.failure:
        currentFailures++;
      case _SlotKind.sealed:
        currentFailures = 0;
      case _SlotKind.openUnsealed || _SlotKind.openSealed:
        break;
      case _SlotKind.absent || _SlotKind.muteHoliday || _SlotKind.muteWeekend:
        throw StateError('slot já filtrado');
    }
  }

  return currentFailures == 1;
}

void main() {
  const deriver = SingleLostDayCopyDeriver();

  Glados<_TimelineInput>(_anyTimeline, RitmoGlados.ci()).test(
    'Propriedade 20: Copy de dia único',
    (_TimelineInput input) {
      final expected = _referenceMakesCopyAvailable(
        input.slots,
        input.activationDate,
      );
      final presentation = deriver.derive(
        _projectAll(input.slots),
        input.activationDate,
      );
      final context =
          'activation=${input.activationDate.iso}, '
          'slots=${input.slots.map((slot) => '${slot.date.iso}:'
              '${slot.kind.name}').join(',')}';

      expect(presentation != null, expected, reason: context);
      if (expected) {
        expect(presentation!.text, Copy.singleLostDay, reason: context);
        expect(
          presentation.text,
          'Um dia perdido não é derrota; é dado.',
          reason: context,
        );
      }
    },
  );
}
