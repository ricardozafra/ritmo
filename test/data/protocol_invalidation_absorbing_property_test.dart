// Feature: ritmo, Property 18: A invalidação é absorvente e o histórico
// nunca encolhe
//
// Para qualquer sequência de aplicações e remoções de feriado seguidas de
// reconciliação, protocolos invalidados nunca são reativados, preservam estado
// e resposta, o histórico só cresce e critérios recalculados criam um novo
// protocolo pendente.
//
// **Validates: Requirements RF-03.16, RF-03.17, RF-03.18, RF-03.19,
// RF-03.20, RF-03.24, RF-05.25, RD-15, RNF-04.10**

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../generators/shared.dart';

enum _DayKind { failure, sealed }

typedef _Day = ({OperationalDate date, _DayKind kind});
typedef _HolidayAction = ({int dayIndex, bool apply});
typedef _Scenario = ({
  OperationalDate activationDate,
  bool answerInitialProtocols,
  List<_HolidayAction> actions,
});
typedef _ReferenceSequence = ({
  String generationId,
  String startDate,
  String endDate,
  int length,
});
typedef _Protocol = ({
  String id,
  String generationId,
  String startDate,
  String endDate,
  int sequenceLength,
  String state,
  String? previousState,
  int? triggeredAt,
  String? cause,
  String? planOrExecution,
  String? adjustment,
});

const int _closedAt = 1767600000000;
const int _sealedAt = 1767596400000;
const int _answeredAt = 1767657600000;
const String _cause = 'Agenda sobrecarregada';
const String _classification = 'plan';
const String _adjustment = 'Reduzir compromissos da noite';

const List<_HolidayAction> _essentialRoundTrip = <_HolidayAction>[
  (dayIndex: 0, apply: true),
  (dayIndex: 0, apply: false),
  (dayIndex: 2, apply: true),
  (dayIndex: 2, apply: false),
];

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (Random random, int size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final extraCount = random.nextInt(max(1, min(size ~/ 4 + 1, 9)));
    final actions = <_HolidayAction>[
      ..._essentialRoundTrip,
      for (var index = 0; index < extraCount; index++)
        (dayIndex: random.nextInt(5), apply: random.nextBool()),
    ];
    return (
      activationDate: activation,
      answerInitialProtocols: random.nextBool(),
      actions: actions,
    );
  },
  shrink: (_Scenario scenario) sync* {
    final canonical = (
      activationDate: canonicalOperationalDate,
      answerInitialProtocols: false,
      actions: _essentialRoundTrip,
    );
    if (scenario != canonical) yield canonical;
  },
);

List<_Day> _buildDays(OperationalDate activationDate) {
  final dates = <OperationalDate>[];
  var cursor = activationDate;
  while (dates.length < 5) {
    if (!cursor.isWeekend) dates.add(cursor);
    cursor = cursor.next;
  }
  return <_Day>[
    (date: dates[0], kind: _DayKind.failure),
    (date: dates[1], kind: _DayKind.failure),
    (date: dates[2], kind: _DayKind.sealed),
    (date: dates[3], kind: _DayKind.failure),
    (date: dates[4], kind: _DayKind.failure),
  ];
}

/// Oráculo independente: feriados são removidos da linha útil; dias selados
/// encerram a cadeia; somente cadeias com duas ou mais falhas têm critério.
List<_ReferenceSequence> _referenceSequences(
  List<_Day> days,
  Set<int> holidays,
) {
  final result = <_ReferenceSequence>[];
  OperationalDate? start;
  OperationalDate? end;
  var length = 0;

  void finish() {
    if (length >= 2) {
      final sequenceStart = start!;
      result.add((
        generationId: 'seq:${sequenceStart.iso}',
        startDate: sequenceStart.iso,
        endDate: end!.iso,
        length: length,
      ));
    }
    start = null;
    end = null;
    length = 0;
  }

  for (var index = 0; index < days.length; index++) {
    if (holidays.contains(index)) continue;
    final day = days[index];
    switch (day.kind) {
      case _DayKind.failure:
        start ??= day.date;
        end = day.date;
        length++;
      case _DayKind.sealed:
        finish();
    }
  }
  finish();
  return result;
}

Future<void> _insertDay(RitmoDatabase database, _Day day) {
  final sealed = day.kind == _DayKind.sealed;
  return database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp, mute_cause, previous_result) '
    'VALUES (?, ?, ?, ?, ?, NULL, NULL)',
    [
      day.date.iso,
      sealed ? 'sealed' : 'unsealed',
      sealed ? 'sealed' : 'unsealed',
      _closedAt,
      sealed ? _sealedAt : null,
    ],
  );
}

Future<void> _setHoliday(
  RitmoDatabase database,
  _Day day, {
  required bool apply,
}) {
  if (apply) {
    return database.customStatement(
      "UPDATE days SET effective_result = 'mute', mute_cause = 'holiday', "
      'previous_result = base_result WHERE operational_date = ?',
      [day.date.iso],
    );
  }
  return database.customStatement(
    'UPDATE days SET effective_result = base_result, mute_cause = NULL '
    'WHERE operational_date = ?',
    [day.date.iso],
  );
}

Future<void> _answerLiveProtocols(RitmoDatabase database) =>
    database.customStatement(
      "UPDATE protocol_alarms SET state = 'answered', triggered_at = ?, "
      'cause = ?, plan_or_execution = ?, adjustment = ? '
      "WHERE state <> 'invalidated'",
      [_answeredAt, _cause, _classification, _adjustment],
    );

Future<List<_Protocol>> _protocols(RitmoDatabase database) async {
  final rows = await database
      .customSelect(
        'SELECT id, generation_id, start_date, end_date, sequence_length, state, '
        'previous_state, triggered_at, cause, plan_or_execution, adjustment '
        'FROM protocol_alarms ORDER BY id',
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
          triggeredAt: row.readNullable<int>('triggered_at'),
          cause: row.readNullable<String>('cause'),
          planOrExecution: row.readNullable<String>('plan_or_execution'),
          adjustment: row.readNullable<String>('adjustment'),
        ),
      )
      .toList(growable: false);
}

bool _matches(_Protocol protocol, _ReferenceSequence sequence) =>
    protocol.generationId == sequence.generationId &&
    protocol.startDate == sequence.startDate &&
    protocol.endDate == sequence.endDate &&
    protocol.sequenceLength == sequence.length;

void _expectPreserved(
  _Protocol before,
  _Protocol after, {
  required String context,
}) {
  expect(after.id, before.id, reason: context);
  expect(after.generationId, before.generationId, reason: context);
  expect(after.startDate, before.startDate, reason: context);
  expect(after.endDate, before.endDate, reason: context);
  expect(after.sequenceLength, before.sequenceLength, reason: context);
  expect(after.triggeredAt, before.triggeredAt, reason: context);
  expect(after.cause, before.cause, reason: context);
  expect(after.planOrExecution, before.planOrExecution, reason: context);
  expect(after.adjustment, before.adjustment, reason: context);
}

void main() {
  Glados<_Scenario>(_anyScenario, RitmoGlados.ci()).test(
    'Propriedade 18: a invalidação é absorvente e o histórico nunca encolhe',
    (_Scenario scenario) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      final reconciler = ProtocolReconciler(database);
      final days = _buildDays(scenario.activationDate);
      final holidays = <int>{};

      try {
        await database.customStatement(
          'UPDATE settings SET activation_date = ?',
          [scenario.activationDate.iso],
        );
        for (final day in days) {
          await _insertDay(database, day);
        }
        await reconciler.reconcileProtocols();
        if (scenario.answerInitialProtocols) {
          await _answerLiveProtocols(database);
        }

        var beforeProtocols = await _protocols(database);
        var beforeSequences = _referenceSequences(days, holidays);
        expect(beforeProtocols, hasLength(2));
        expect(beforeSequences, hasLength(2));

        for (var step = 0; step < scenario.actions.length; step++) {
          final action = scenario.actions[step];
          final wasActive = holidays.contains(action.dayIndex);
          final changesState = action.apply != wasActive;
          if (changesState) {
            await _setHoliday(
              database,
              days[action.dayIndex],
              apply: action.apply,
            );
            if (action.apply) {
              holidays.add(action.dayIndex);
            } else {
              holidays.remove(action.dayIndex);
            }
          }

          await reconciler.reconcileProtocols(
            from: days[action.dayIndex].date,
            reason: changesState
                ? ProtocolReconcileReason.holidayMutation
                : ProtocolReconcileReason.normalProgress,
          );
          final afterProtocols = await _protocols(database);
          final afterSequences = _referenceSequences(days, holidays);
          final context =
              'passo $step: ${action.apply ? 'aplicar' : 'remover'} feriado '
              'em ${days[action.dayIndex].date.iso}; '
              'antes=$beforeSequences, depois=$afterSequences';

          // O histórico é não destrutivo: nenhum id desaparece e a contagem
          // total nunca diminui, mesmo em round trips e fusões.
          expect(
            afterProtocols.length,
            greaterThanOrEqualTo(beforeProtocols.length),
            reason: context,
          );
          final afterById = {for (final row in afterProtocols) row.id: row};
          expect(
            beforeProtocols.every((row) => afterById.containsKey(row.id)),
            isTrue,
            reason: context,
          );

          // Invalidated é absorvente e todos os dados anteriores permanecem.
          for (final before in beforeProtocols) {
            final after = afterById[before.id]!;
            if (before.state == 'invalidated') {
              expect(after.state, 'invalidated', reason: context);
              expect(
                after.previousState,
                before.previousState,
                reason: context,
              );
              _expectPreserved(before, after, context: context);
            }
          }

          // Se a sequência anterior perdeu seu critério exato, seu protocolo
          // vivo deve ser invalidado preservando o estado e a resposta.
          for (final before in beforeProtocols.where(
            (row) => row.state != 'invalidated',
          )) {
            final stillExists = afterSequences.any(
              (sequence) => _matches(before, sequence),
            );
            if (!stillExists) {
              final after = afterById[before.id]!;
              expect(after.state, 'invalidated', reason: context);
              expect(after.previousState, before.state, reason: context);
              _expectPreserved(before, after, context: context);
            }
          }

          // Toda sequência recalculada que não existia antes recebe uma linha
          // nova e pending; isso inclui restauração e fusão de sequências.
          for (final sequence in afterSequences.where(
            (candidate) => !beforeSequences.contains(candidate),
          )) {
            final candidates = afterProtocols.where(
              (protocol) =>
                  protocol.state != 'invalidated' &&
                  _matches(protocol, sequence),
            );
            expect(candidates, hasLength(1), reason: context);
            expect(candidates.single.state, 'pending', reason: context);
            expect(
              beforeProtocols.any((row) => row.id == candidates.single.id),
              isFalse,
              reason: context,
            );
          }

          beforeProtocols = afterProtocols;
          beforeSequences = afterSequences;
        }
      } finally {
        await database.close();
      }
    },
  );
}
