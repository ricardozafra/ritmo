// Feature: ritmo, Property 17: Um protocolo vivo por geração, idempotente sob
// repetição
//
// Para qualquer linha do tempo e qualquer número de execuções do reconciliador,
// inclusive intercaladas, existe no máximo um protocolo com estado diferente de
// `invalidated` por `generation_id`, seu `sequence_length` e `end_date`
// correspondem exatamente à sequência detectada, e nenhuma sequência com dois
// ou mais dias fica sem protocolo vivo.
//
// **Validates: Requirements RF-03.3, RF-03.4, RF-03.8, RF-03.22, RD-14**

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../generators/shared.dart';

/// Estados persistíveis de uma data operacional relevantes para a sequência.
enum _SlotKind { muteWeekend, muteHoliday, failure, sealedWorkday, openWorkday }

/// Formas de acionar o reconciliador, incluindo repetição e execução
/// intercalada com duas instâncias distintas sobre o mesmo banco.
enum _RunPlan { fullOnce, fullTwice, scopedFromLast, concurrentBurst }

typedef _Slot = ({OperationalDate date, _SlotKind kind});
typedef _Step = ({List<_Slot> slots, _RunPlan plan});
typedef _Timeline = ({OperationalDate activationDate, List<_Step> steps});
typedef _Protocol = ({
  String id,
  String generationId,
  String startDate,
  String endDate,
  int sequenceLength,
  String state,
  String? previousState,
});
typedef _DayRow = ({
  String base,
  String effective,
  int? closedAt,
  int? sealAt,
  String? cause,
  String? previous,
});

const int _closedAt = 1767600000000;
const int _sealedAt = 1767596400000;

/// Espaço explorado nas datas livres: a falha domina para produzir sequências
/// longas, mas selo, dia aberto e feriado aparecem e partem ou atravessam.
const List<_SlotKind> _freeWeekdayPool = <_SlotKind>[
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.failure,
  _SlotKind.sealedWorkday,
  _SlotKind.openWorkday,
  _SlotKind.muteHoliday,
];

/// Testemunha fixa do RF-03.22: quatro dias úteis não selados aplicados de uma
/// vez e reconciliados concorrentemente.
const int _plantedFailures = 4;

final Generator<_Timeline> _anyTimeline = any.simple(
  generate: (Random random, int size) {
    // A ativação sempre cai em uma segunda-feira, para que os quatro dias
    // plantados sejam dias úteis consecutivos.
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final extraSteps = 1 + random.nextInt(max(1, min(size ~/ 3 + 1, 4)));
    return _buildTimeline(
      activation: activation,
      extraSteps: extraSteps,
      lengthAt: (_) => 1 + random.nextInt(3),
      kindAt: (_) => _freeWeekdayPool[random.nextInt(_freeWeekdayPool.length)],
      planAt: (_) => _RunPlan.values[random.nextInt(_RunPlan.values.length)],
    );
  },
  shrink: (_Timeline timeline) sync* {
    if (timeline.steps.length > 2) {
      yield _buildTimeline(
        activation: timeline.activationDate,
        extraSteps: 1,
        lengthAt: (_) => 1,
        kindAt: (_) => _SlotKind.failure,
        planAt: (_) => _RunPlan.fullOnce,
      );
    }
  },
);

_Timeline _buildTimeline({
  required OperationalDate activation,
  required int extraSteps,
  required int Function(int step) lengthAt,
  required _SlotKind Function(int index) kindAt,
  required _RunPlan Function(int step) planAt,
}) {
  final steps = <_Step>[
    (
      slots: <_Slot>[
        for (var offset = 0; offset < _plantedFailures; offset++)
          (date: activation.addDays(offset), kind: _SlotKind.failure),
      ],
      plan: _RunPlan.concurrentBurst,
    ),
  ];

  var cursor = activation.addDays(_plantedFailures);
  var index = 0;
  for (var step = 1; step <= extraSteps; step++) {
    final slots = <_Slot>[];
    for (var taken = 0; taken < lengthAt(step); taken++) {
      slots.add((
        date: cursor,
        kind: cursor.isWeekend ? _SlotKind.muteWeekend : kindAt(index++),
      ));
      cursor = cursor.next;
    }
    steps.add((slots: slots, plan: planAt(step)));
  }

  return (activationDate: activation, steps: steps);
}

typedef _ReferenceSequence = ({
  String generationId,
  OperationalDate startDate,
  OperationalDate endDate,
  int length,
});

/// Oráculo local independente do detector de produção: dias `mute` são
/// ignorados; dia útil aberto ou selado encerra a cadeia; somente cadeias com
/// pelo menos duas falhas encerradas geram protocolo.
List<_ReferenceSequence> _referenceSequences(
  Iterable<_Slot> slots,
  OperationalDate activationDate,
) {
  final ordered = slots.where((slot) => slot.date >= activationDate).toList()
    ..sort((left, right) => left.date.compareTo(right.date));
  final result = <_ReferenceSequence>[];
  OperationalDate? start;
  OperationalDate? end;
  var length = 0;

  void finish() {
    if (length >= 2) {
      final sequenceStart = start!;
      result.add((
        generationId: 'seq:${sequenceStart.iso}',
        startDate: sequenceStart,
        endDate: end!,
        length: length,
      ));
    }
    start = null;
    end = null;
    length = 0;
  }

  for (final slot in ordered) {
    switch (slot.kind) {
      case _SlotKind.muteWeekend:
      case _SlotKind.muteHoliday:
        continue;
      case _SlotKind.failure:
        start ??= slot.date;
        end = slot.date;
        length++;
      case _SlotKind.sealedWorkday:
      case _SlotKind.openWorkday:
        finish();
    }
  }
  finish();
  return result;
}

Future<void> _insertDay(RitmoDatabase database, _Slot slot) {
  final _DayRow row = switch (slot.kind) {
    _SlotKind.muteWeekend => (
      base: 'unsealed',
      effective: 'mute',
      closedAt: _closedAt,
      sealAt: null,
      cause: 'weekend',
      previous: null,
    ),
    _SlotKind.muteHoliday => (
      base: 'unsealed',
      effective: 'mute',
      closedAt: _closedAt,
      sealAt: null,
      cause: 'holiday',
      previous: 'unsealed',
    ),
    _SlotKind.failure => (
      base: 'unsealed',
      effective: 'unsealed',
      closedAt: _closedAt,
      sealAt: null,
      cause: null,
      previous: null,
    ),
    _SlotKind.sealedWorkday => (
      base: 'sealed',
      effective: 'sealed',
      closedAt: _closedAt,
      sealAt: _sealedAt,
      cause: null,
      previous: null,
    ),
    _SlotKind.openWorkday => (
      base: 'unsealed',
      effective: 'unsealed',
      closedAt: null,
      sealAt: null,
      cause: null,
      previous: null,
    ),
  };
  return database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp, mute_cause, previous_result) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      slot.date.iso,
      row.base,
      row.effective,
      row.closedAt,
      row.sealAt,
      row.cause,
      row.previous,
    ],
  );
}

Future<List<_Protocol>> _protocols(RitmoDatabase database) async {
  final rows = await database
      .customSelect(
        'SELECT id, generation_id, start_date, end_date, sequence_length, '
        'state, previous_state FROM protocol_alarms ORDER BY start_date, id',
      )
      .get();
  return rows
      .map(
        (row) => (
          id: row.read<String>('id'),
          generationId: row.read<String>('generation_id'),
          startDate: row.read<String>('start_date'),
          endDate: row.read<String>('end_date'),
          sequenceLength: row.read<int>('sequence_length'),
          state: row.read<String>('state'),
          previousState: row.readNullable<String>('previous_state'),
        ),
      )
      .toList(growable: false);
}

List<_Protocol> _live(List<_Protocol> protocols) => protocols
    .where((protocol) => protocol.state != 'invalidated')
    .toList(growable: false);

Future<void> _runPlan(
  ProtocolReconciler reconciler,
  RitmoDatabase database,
  _RunPlan plan,
  OperationalDate lastDate,
) async {
  switch (plan) {
    case _RunPlan.fullOnce:
      await reconciler.reconcileProtocols();
    case _RunPlan.fullTwice:
      await reconciler.reconcileProtocols();
      await reconciler.reconcileProtocols();
    case _RunPlan.scopedFromLast:
      await reconciler.reconcileProtocols(from: lastDate);
    case _RunPlan.concurrentBurst:
      await Future.wait<ReconcileReport>([
        reconciler.reconcileProtocols(from: lastDate),
        reconciler.reconcileProtocols(),
        ProtocolReconciler(database).reconcileProtocols(from: lastDate),
      ]);
  }
}

void main() {
  Glados<_Timeline>(_anyTimeline, RitmoGlados.ci()).test(
    'Propriedade 17: um protocolo vivo por geração, idempotente sob repetição',
    (_Timeline timeline) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      final reconciler = ProtocolReconciler(database);
      final activation = timeline.activationDate;
      final applied = <_Slot>[];
      var snapshot = const <_Protocol>[];

      try {
        await database.customStatement(
          'UPDATE settings SET activation_date = ?',
          [activation.iso],
        );

        for (var step = 0; step < timeline.steps.length; step++) {
          final current = timeline.steps[step];
          for (final slot in current.slots) {
            await _insertDay(database, slot);
            applied.add(slot);
          }
          final context =
              'passo $step (${current.plan.name}), '
              'ativação ${activation.iso}, ${applied.length} dias';

          await _runPlan(
            reconciler,
            database,
            current.plan,
            current.slots.last.date,
          );

          // 1. Unicidade por geração vale em todo instante observável, mesmo
          // depois de execuções concorrentes ou de escopo parcial (RD-14).
          final afterPlan = await _protocols(database);
          final livePerGeneration = <String, int>{};
          for (final protocol in _live(afterPlan)) {
            livePerGeneration.update(
              protocol.generationId,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
          expect(
            livePerGeneration.values.every((count) => count == 1),
            isTrue,
            reason:
                'protocolos vivos duplicados: $livePerGeneration ($context)',
          );

          // RF-03.22: quatro dias úteis não selados reconciliados
          // concorrentemente produzem um único protocolo com comprimento 4.
          if (step == 0) {
            final live = _live(afterPlan);
            expect(live, hasLength(1), reason: context);
            expect(
              live.single.generationId,
              'seq:${activation.iso}',
              reason: context,
            );
            expect(live.single.startDate, activation.iso, reason: context);
            expect(
              live.single.endDate,
              activation.addDays(_plantedFailures - 1).iso,
              reason: context,
            );
            expect(
              live.single.sequenceLength,
              _plantedFailures,
              reason: context,
            );
            expect(live.single.state, 'pending', reason: context);
          }

          // 2. Idempotência: uma reconciliação completa converge e a repetição
          // imediata não altera nada.
          await reconciler.reconcileProtocols();
          snapshot = await _protocols(database);
          final repeated = await reconciler.reconcileProtocols();
          expect(repeated.changedNothing, isTrue, reason: context);
          expect(await _protocols(database), snapshot, reason: context);

          // 3. Cada sequência detectada tem exatamente um protocolo vivo com
          // `sequence_length` e `end_date` correspondentes, e nada além disso
          // está vivo (RF-03.3, RF-03.4).
          final expected = _referenceSequences(applied, activation);
          final live = _live(snapshot);
          expect(
            live.map((protocol) => protocol.generationId).toList(),
            expected.map((sequence) => sequence.generationId).toList(),
            reason: context,
          );
          for (var index = 0; index < expected.length; index++) {
            final sequence = expected[index];
            final protocol = live[index];
            expect(protocol.startDate, sequence.startDate.iso, reason: context);
            expect(protocol.endDate, sequence.endDate.iso, reason: context);
            expect(protocol.sequenceLength, sequence.length, reason: context);
            expect(protocol.state, 'pending', reason: context);
            expect(protocol.previousState, isNull, reason: context);
          }

          // Crescimento nunca cria um segundo protocolo nem invalida o vivo:
          // sem alteração retroativa, o histórico tem só as gerações vivas.
          expect(snapshot, live, reason: context);

          // Testemunha não vacuosa: a linha do tempo sempre produz sequência.
          expect(expected, isNotEmpty, reason: context);
        }

        // 4. A proibição é atômica no banco, não apenas no reconciliador: o
        // índice único parcial rejeita um segundo protocolo vivo (RF-03.8).
        final target = _live(snapshot).first;
        await expectLater(
          database.customStatement(
            'INSERT INTO protocol_alarms (id, generation_id, start_date, '
            'end_date, sequence_length, state) '
            "VALUES (?, ?, ?, ?, ?, 'pending')",
            [
              '${target.generationId}#duplicado',
              target.generationId,
              target.startDate,
              target.endDate,
              target.sequenceLength,
            ],
          ),
          throwsA(isA<Exception>()),
        );
        expect(await _protocols(database), snapshot);
      } finally {
        await database.close();
      }
    },
  );
}
