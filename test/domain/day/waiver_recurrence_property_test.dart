// Feature: ritmo, Property 12: Recorrência de dispensa segue o modelo de
// referência
//
// Para qualquer linha do tempo com dias úteis, dias `mute`, dispensas ativas e
// revogadas de pilares variados, o veredito de recorrência de um novo pedido
// coincide com o de uma implementação de referência que caminha para trás sobre
// dias úteis, ignora dias `mute`, conta somente dispensas ativas do mesmo pilar
// e corta a cadeia ao encontrar dispensa ativa de outro pilar, dia útil sem
// dispensa ativa daquele pilar ou dia útil selado sem essa dispensa.
//
// **Validates: Requirements RF-02.12, RF-02.13, RF-02.14, RF-02.15, RF-02.21**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater, isNull;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/day/waiver_policy.dart';
import 'package:ritmo/domain/day/waiver_recurrence.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

/// Estados persistíveis de um dia da janela avaliada, do ponto de vista da
/// recorrência: presença ou ausência do dia, classificação `mute`, selo e a
/// dispensa conhecida naquela data.
enum _SlotKind {
  /// Dia nunca materializado: a recorrência só pode usar o calendário civil.
  absent,
  muteWeekend,
  muteHolidayWithSameWaiver,
  muteHolidayBare,
  activeSameWaiver,
  activeOtherWaiver,
  revokedSameWaiver,
  bareClosed,
  bareOpen,
  sealedWithSameWaiver,
  sealedBare,
}

typedef _Slot = ({OperationalDate date, _SlotKind kind});
typedef _RefAssessment = ({int chainLength, OperationalDate? chainStartDate});
typedef _RecurrenceInput = ({
  Pillar pillar,
  OperationalDate start,
  List<_Slot> slots,
  OperationalDate anchorDate,
  OperationalDate otherPillarProbe,
  OperationalDate bridgeFriday,
  OperationalDate bridgeMonday,
  OperationalDate revokedProbe,
  OperationalDate sealedWithWaiverProbe,
  OperationalDate sealedBareProbe,
});

/// Espaço explorado nas posições livres. Dispensa ativa do mesmo pilar é mais
/// provável para produzir cadeias longas, mas todos os cortes de cadeia, o dia
/// ausente e o feriado retroativo sobre dispensa também aparecem.
const List<_SlotKind> _freeWeekdayPool = <_SlotKind>[
  _SlotKind.activeSameWaiver,
  _SlotKind.activeSameWaiver,
  _SlotKind.activeSameWaiver,
  _SlotKind.sealedWithSameWaiver,
  _SlotKind.activeOtherWaiver,
  _SlotKind.revokedSameWaiver,
  _SlotKind.bareClosed,
  _SlotKind.bareOpen,
  _SlotKind.sealedBare,
  _SlotKind.muteHolidayWithSameWaiver,
  _SlotKind.muteHolidayBare,
  _SlotKind.absent,
];

/// Posições fixas, contadas a partir de uma segunda-feira, que garantem
/// testemunhas não vacuosas em toda amostra: cadeia cortada por dispensa de
/// outro pilar (0..3), ponte sexta -> segunda separada apenas por fim de semana
/// (4..7), dispensa revogada ignorada (8..9), dia selado com a dispensa que
/// mantém a cadeia (10..11) e dia selado sem a dispensa que a corta (11..14).
const Map<int, _SlotKind> _plantedOffsets = <int, _SlotKind>{
  0: _SlotKind.activeSameWaiver,
  1: _SlotKind.activeOtherWaiver,
  2: _SlotKind.activeSameWaiver,
  3: _SlotKind.bareClosed,
  4: _SlotKind.activeSameWaiver,
  5: _SlotKind.muteWeekend,
  6: _SlotKind.muteWeekend,
  7: _SlotKind.bareClosed,
  8: _SlotKind.revokedSameWaiver,
  9: _SlotKind.bareOpen,
  10: _SlotKind.sealedWithSameWaiver,
  11: _SlotKind.sealedBare,
  12: _SlotKind.muteWeekend,
  13: _SlotKind.muteWeekend,
  14: _SlotKind.bareClosed,
};

/// Offsets plantados (0..14) mais a data avaliada.
const int _minimumSpan = 16;

final Generator<_RecurrenceInput> _anyRecurrenceInput = any.simple(
  generate: (Random random, int size) {
    // A janela sempre começa numa segunda-feira: os offsets plantados exigem
    // que 0..4 sejam dias úteis e 5..6, fim de semana.
    var start = anyOperationalDate(random, size).value;
    while (start.weekday != DateTime.monday) {
      start = start.next;
    }
    final pillar = Pillar.values[random.nextInt(Pillar.values.length)];
    final span = _minimumSpan + random.nextInt(max(1, min(size + 1, 13)));
    return _buildInput(
      start: start,
      span: span,
      pillar: pillar,
      freeKind: (_) => _freeWeekdayPool[random.nextInt(_freeWeekdayPool.length)],
    );
  },
  shrink: (input) sync* {
    if (input.slots.length > _minimumSpan) {
      yield _buildInput(
        start: input.start,
        span: _minimumSpan,
        pillar: input.pillar,
        freeKind: (_) => _SlotKind.bareClosed,
      );
    }
    if (input.pillar != Pillar.morning) {
      yield _buildInput(
        start: input.start,
        span: input.slots.length,
        pillar: Pillar.morning,
        freeKind: (offset) => input.slots[offset].kind,
      );
    }
  },
);

_RecurrenceInput _buildInput({
  required OperationalDate start,
  required int span,
  required Pillar pillar,
  required _SlotKind Function(int offset) freeKind,
}) {
  // A data avaliada é sempre o último dia da janela e precisa ser dia útil.
  var length = span;
  while (start.addDays(length - 1).isWeekend) {
    length++;
  }
  final anchorOffset = length - 1;
  final slots = <_Slot>[
    for (var offset = 0; offset < length; offset++)
      (
        date: start.addDays(offset),
        kind: offset == anchorOffset
            ? _SlotKind.bareOpen
            : _plantedOffsets[offset] ??
                  (start.addDays(offset).isWeekend
                      ? _SlotKind.muteWeekend
                      : freeKind(offset)),
      ),
  ];

  return (
    pillar: pillar,
    start: start,
    slots: slots,
    anchorDate: start.addDays(anchorOffset),
    otherPillarProbe: start.addDays(3),
    bridgeFriday: start.addDays(4),
    bridgeMonday: start.addDays(7),
    revokedProbe: start.addDays(9),
    sealedWithWaiverProbe: start.addDays(11),
    sealedBareProbe: start.addDays(14),
  );
}

Pillar _otherPillar(Pillar pillar) =>
    pillar == Pillar.morning ? Pillar.night : Pillar.morning;

bool _isMuteKind(_SlotKind kind) =>
    kind == _SlotKind.muteWeekend ||
    kind == _SlotKind.muteHolidayWithSameWaiver ||
    kind == _SlotKind.muteHolidayBare;

/// Pilar da dispensa **ativa** daquela data, ou `null` quando não há nenhuma.
Pillar? _activeWaiverPillar(_SlotKind kind, Pillar pillar) => switch (kind) {
  _SlotKind.activeSameWaiver ||
  _SlotKind.sealedWithSameWaiver ||
  _SlotKind.muteHolidayWithSameWaiver => pillar,
  _SlotKind.activeOtherWaiver => _otherPillar(pillar),
  _ => null,
};

/// Modelo de referência independente: opera somente sobre os slots brutos do
/// teste, sem chamar `WaiverRecurrence`, `WaiverHistory` ou qualquer filtro de
/// produção. Caminha para trás sobre dias úteis, ignora dias `mute` (inclusive
/// feriados retroativos sobre dias com dispensa), conta apenas dispensas ativas
/// do mesmo pilar e corta a cadeia na primeira posição que não satisfaça isso.
_RefAssessment _reference(
  _RecurrenceInput input,
  OperationalDate target, {
  Set<OperationalDate> forceActive = const <OperationalDate>{},
}) {
  final kinds = <OperationalDate, _SlotKind>{
    for (final slot in input.slots)
      if (slot.kind != _SlotKind.absent) slot.date: slot.kind,
  };

  var chainLength = 0;
  OperationalDate? chainStartDate;
  var cursor = target.previous;
  while (cursor >= input.start) {
    final kind = kinds[cursor];
    // Data ausente da projeção só pode ser classificada pelo calendário civil.
    final skipped = kind == null ? cursor.isWeekend : _isMuteKind(kind);
    if (skipped) {
      cursor = cursor.previous;
      continue;
    }
    final activePillar = forceActive.contains(cursor)
        ? input.pillar
        : (kind == null ? null : _activeWaiverPillar(kind, input.pillar));
    if (activePillar != input.pillar) break;
    chainLength++;
    chainStartDate = cursor;
    cursor = cursor.previous;
  }

  return (chainLength: chainLength, chainStartDate: chainStartDate);
}

EligibleDay? _projectDay(_Slot slot) => switch (slot.kind) {
  _SlotKind.absent => null,
  _SlotKind.muteWeekend ||
  _SlotKind.muteHolidayWithSameWaiver ||
  _SlotKind.muteHolidayBare => EligibleDay(
    date: slot.date,
    isWorkday: false,
    isClosed: true,
    isSealed: false,
    isMute: true,
  ),
  _SlotKind.sealedWithSameWaiver || _SlotKind.sealedBare => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: true,
    isMute: false,
  ),
  _SlotKind.bareOpen => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: false,
    isSealed: false,
    isMute: false,
  ),
  _SlotKind.activeSameWaiver ||
  _SlotKind.activeOtherWaiver ||
  _SlotKind.revokedSameWaiver ||
  _SlotKind.bareClosed => EligibleDay(
    date: slot.date,
    isWorkday: true,
    isClosed: true,
    isSealed: false,
    isMute: false,
  ),
};

PillarWaiver? _projectWaiver(
  _Slot slot,
  Pillar pillar, {
  Set<OperationalDate> forceActive = const <OperationalDate>{},
}) {
  final active = _activeWaiverPillar(slot.kind, pillar);
  final revoked = slot.kind == _SlotKind.revokedSameWaiver;
  if (active == null && !revoked) return null;
  final waiverPillar = active ?? pillar;
  return PillarWaiver(
    id: 'waiver-${slot.date.iso}-${waiverPillar.name}',
    date: slot.date,
    pillar: waiverPillar,
    reasonText: 'Motivo registrado',
    revokedAt: revoked && !forceActive.contains(slot.date)
        ? tz.TZDateTime(tz.UTC, slot.date.year, slot.date.month, slot.date.day)
        : null,
  );
}

WaiverHistory _history(
  _RecurrenceInput input, {
  Set<OperationalDate> forceActive = const <OperationalDate>{},
}) => WaiverHistory(
  days: <EligibleDay>[
    for (final slot in input.slots)
      if (_projectDay(slot) case final EligibleDay day) day,
  ],
  waivers: <PillarWaiver>[
    for (final slot in input.slots)
      if (_projectWaiver(slot, input.pillar, forceActive: forceActive)
          case final PillarWaiver waiver)
        waiver,
  ],
);

void main() {
  const recurrence = WaiverRecurrence();
  const policy = WaiverPolicy();

  // Semente fixa 0x5249544D ("RITM") e no mínimo 100 execuções em CI.
  Glados<_RecurrenceInput>(_anyRecurrenceInput, RitmoGlados.ci()).test(
    'Propriedade 12: recorrência de dispensa segue o modelo de referência',
    (_RecurrenceInput input) {
      final history = _history(input);
      final context =
          'pilar=${input.pillar.name}, janela=${input.start.iso}..'
          '${input.anchorDate.iso} (${input.slots.length} dias)';

      void agreesWithReference(OperationalDate target) {
        final expected = _reference(input, target);
        final actual = recurrence.assess(input.pillar, target, history);
        final where = 'data=${target.iso}, $context';

        expect(actual.previousChainLength, expected.chainLength, reason: where);
        expect(actual.chainStartDate, expected.chainStartDate, reason: where);
        expect(
          actual.verdict,
          expected.chainLength >= 1
              ? RecurrenceVerdict.requiresReturnRuleDialog
              : RecurrenceVerdict.first,
          reason: where,
        );
        expect(actual.position, expected.chainLength + 1, reason: where);
        expect(
          recurrence.verdict(input.pillar, target, history),
          actual.verdict,
          reason: where,
        );
      }

      // 1. Coincidência com o modelo de referência na data avaliada e em cada
      // testemunha plantada.
      for (final target in <OperationalDate>[
        input.anchorDate,
        input.otherPillarProbe,
        input.bridgeMonday,
        input.revokedProbe,
        input.sealedWithWaiverProbe,
        input.sealedBareProbe,
      ]) {
        agreesWithReference(target);
      }

      // 2. RF-02.13 e RF-02.14: a política aceita a primeira dispensa da
      // recorrência sem diálogo e exige o diálogo da Regra do Retorno, antes de
      // persistir, a partir da segunda.
      final expectedAnchor = _reference(input, input.anchorDate);
      final dayContext = DayContext(
        days: history.days,
        waivers: history.waivers,
      );
      const reason = 'Compromisso inadiável';
      final withoutDialog = policy.create(
        CreateWaiver(
          id: 'waiver-property-12',
          date: input.anchorDate,
          pillar: input.pillar,
          reasonText: reason,
        ),
        dayContext,
      );

      if (expectedAnchor.chainLength == 0) {
        final created =
            (withoutDialog as Success<PillarWaiver, WaiverViolation>).value;
        expect(created.recurrenceConfirmed, isFalse, reason: context);
        expect(created.pillar, input.pillar, reason: context);
      } else {
        final failure =
            (withoutDialog as Failure<PillarWaiver, WaiverViolation>).failure;
        expect(
          failure.code,
          'waiver_return_rule_dialog_required',
          reason: context,
        );
        expect(failure.message, contains('Regra do Retorno'), reason: context);

        final confirmed = policy.create(
          CreateWaiver(
            id: 'waiver-property-12',
            date: input.anchorDate,
            pillar: input.pillar,
            reasonText: reason,
            recurrenceConfirmed: true,
          ),
          dayContext,
        );
        expect(
          (confirmed as Success<PillarWaiver, WaiverViolation>)
              .value
              .recurrenceConfirmed,
          isTrue,
          reason: context,
        );
      }

      // 3. RF-02.15: dispensa ativa de outro pilar corta a cadeia sem apagar o
      // trecho posterior.
      final otherPillarCut = recurrence.assess(
        input.pillar,
        input.otherPillarProbe,
        history,
      );
      expect(otherPillarCut.previousChainLength, 1, reason: context);
      expect(
        otherPillarCut.chainStartDate,
        input.start.addDays(2),
        reason: context,
      );

      // 4. RF-02.21: duas dispensas ativas do mesmo pilar em dias úteis
      // consecutivos, separadas apenas por dias `mute`, exigem o diálogo.
      final bridge = recurrence.assess(
        input.pillar,
        input.bridgeMonday,
        history,
      );
      expect(
        bridge.verdict,
        RecurrenceVerdict.requiresReturnRuleDialog,
        reason: 'ponte ${input.bridgeFriday.iso} -> '
            '${input.bridgeMonday.iso} ($context)',
      );
      expect(bridge.chainStartDate, input.bridgeFriday, reason: context);
      for (final between in <OperationalDate>[
        input.bridgeFriday.next,
        input.bridgeFriday.addDays(2),
      ]) {
        expect(
          history.days.singleWhere((day) => day.date == between).isMute,
          isTrue,
          reason: context,
        );
      }
      final bridgeCreate = policy.create(
        CreateWaiver(
          id: 'waiver-property-12-bridge',
          date: input.bridgeMonday,
          pillar: input.pillar,
          reasonText: reason,
        ),
        dayContext,
      );
      expect(
        (bridgeCreate as Failure<PillarWaiver, WaiverViolation>).failure.message,
        contains('Regra do Retorno'),
        reason: context,
      );

      // 5. RF-02.12: dispensa revogada nunca conta. A mesma linha do tempo com
      // aquela dispensa ativa muda o veredito, o que impede a testemunha vazia.
      expect(
        recurrence.verdict(input.pillar, input.revokedProbe, history),
        RecurrenceVerdict.first,
        reason: context,
      );
      final reactivated = _history(
        input,
        forceActive: <OperationalDate>{input.start.addDays(8)},
      );
      final reactivatedAssessment = recurrence.assess(
        input.pillar,
        input.revokedProbe,
        reactivated,
      );
      expect(
        reactivatedAssessment.verdict,
        RecurrenceVerdict.requiresReturnRuleDialog,
        reason: context,
      );
      expect(
        reactivatedAssessment.previousChainLength,
        _reference(
          input,
          input.revokedProbe,
          forceActive: <OperationalDate>{input.start.addDays(8)},
        ).chainLength,
        reason: context,
      );

      // 6. RF-02.15: dia útil selado mantém a cadeia quando carrega a dispensa
      // ativa do pilar e a corta quando não carrega.
      final sealedWithWaiver = recurrence.assess(
        input.pillar,
        input.sealedWithWaiverProbe,
        history,
      );
      expect(sealedWithWaiver.previousChainLength, 1, reason: context);
      expect(
        sealedWithWaiver.chainStartDate,
        input.start.addDays(10),
        reason: context,
      );
      expect(
        recurrence.verdict(input.pillar, input.sealedBareProbe, history),
        RecurrenceVerdict.first,
        reason: context,
      );
    },
  );
}
