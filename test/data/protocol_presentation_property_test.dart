// Feature: ritmo, Property 19: Um protocolo por abertura, o mais antigo
// primeiro
//
// Para qualquer conjunto de protocolos `pending` e qualquer sequência de
// aberturas com respostas, cada abertura exibe no máximo um protocolo, sempre
// o mais antigo; responder não revela outro na mesma sessão, e o próximo só
// pode aparecer em uma nova abertura.
//
// **Validates: Requirements RF-03.9, RF-03.10, RF-03.11, RF-03.12, RF-03.23**

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/data/db/database.dart' hide ProtocolAlarm;
import 'package:ritmo/data/repositories/protocol_repository.dart';
import 'package:ritmo/domain/protocol/protocol_alarm.dart';
import 'package:ritmo/domain/protocol/protocol_session_gate.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

typedef _ProtocolSeed = ({String id, OperationalDate startDate});
typedef _Launch = ({bool answer, bool reverseCandidates});
typedef _PresentationCase = ({
  List<_ProtocolSeed> protocols,
  List<_Launch> launches,
});

final Generator<_PresentationCase> _anyPresentationCase = any.simple(
  generate: (Random random, int size) {
    final base = anyOperationalDate(random, size).value;
    final count = 2 + random.nextInt(max(1, min(size + 1, 8)));
    final protocols = <_ProtocolSeed>[
      for (var index = 0; index < count; index++)
        (
          id: 'protocol-${index.toString().padLeft(2, '0')}',
          startDate: base.addDays(random.nextInt(max(2, count * 3))),
        ),
    ]..shuffle(random);

    final launches = <_Launch>[];
    for (var index = 0; index < count; index++) {
      final unansweredLaunches = random.nextInt(3);
      for (var pause = 0; pause < unansweredLaunches; pause++) {
        launches.add((answer: false, reverseCandidates: random.nextBool()));
      }
      launches.add((answer: true, reverseCandidates: random.nextBool()));
    }
    for (var extra = 0; extra < random.nextInt(3); extra++) {
      launches.add((answer: true, reverseCandidates: random.nextBool()));
    }
    return (protocols: protocols, launches: launches);
  },
  shrink: (_PresentationCase input) sync* {
    if (input.protocols.length > 2 || input.launches.length > 3) {
      yield (
        protocols: input.protocols.take(2).toList(growable: false),
        launches: const <_Launch>[
          (answer: false, reverseCandidates: true),
          (answer: true, reverseCandidates: false),
          (answer: true, reverseCandidates: true),
        ],
      );
    }
  },
);

/// Oráculo independente: deriva o próximo protocolo somente dos seeds brutos
/// e do conjunto modelado como pendente, sem usar a ordenação de produção.
_ProtocolSeed? _referenceOldest(
  List<_ProtocolSeed> protocols,
  Set<String> pendingIds,
) {
  final pending = protocols
      .where((protocol) => pendingIds.contains(protocol.id))
      .toList();
  if (pending.isEmpty) return null;
  pending.sort((left, right) {
    final byDate = left.startDate.compareTo(right.startDate);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return pending.first;
}

List<String> _referencePendingOrder(
  List<_ProtocolSeed> protocols,
  Set<String> pendingIds,
) {
  final remaining = protocols
      .where((protocol) => pendingIds.contains(protocol.id))
      .toList();
  remaining.sort((left, right) {
    final byDate = left.startDate.compareTo(right.startDate);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return remaining.map((protocol) => protocol.id).toList(growable: false);
}

void main() {
  Glados<_PresentationCase>(
    _anyPresentationCase,
    RitmoGlados.ci(),
  ).test('Propriedade 19: um protocolo por abertura, o mais antigo primeiro', (
    _PresentationCase input,
  ) async {
    final database = RitmoDatabase(NativeDatabase.memory());
    final location = ensureBusinessLocation();
    final repository = ProtocolRepository(database, businessLocation: location);
    final pendingIds = input.protocols.map((protocol) => protocol.id).toSet();

    try {
      for (final protocol in input.protocols) {
        await _insertProtocol(database, protocol);
      }

      for (
        var launchIndex = 0;
        launchIndex < input.launches.length;
        launchIndex++
      ) {
        final launch = input.launches[launchIndex];
        final expected = _referenceOldest(input.protocols, pendingIds);
        final persisted = await repository.pendingProtocols();
        final candidates = launch.reverseCandidates
            ? persisted.reversed.toList(growable: false)
            : persisted;
        final gate = ProtocolSessionGate();
        final displayedIds = <String>{};
        final context =
            'abertura=$launchIndex, pendentes=${pendingIds.length}, '
            'invertida=${launch.reverseCandidates}, '
            'responde=${launch.answer}';

        // Releituras na mesma abertura nunca selecionam um segundo item.
        for (var read = 0; read < 3; read++) {
          final selected = gate.selectForThisLaunch(candidates);
          if (selected != null) displayedIds.add(selected.id);
          expect(selected?.id, expected?.id, reason: context);
        }
        expect(displayedIds.length, lessThanOrEqualTo(1), reason: context);

        if (expected != null && launch.answer) {
          final answered = await repository.answer(
            id: expected.id,
            answer: ProtocolAnswer(
              triggeredAt: tz.TZDateTime(
                location,
                2026,
                1,
                5,
              ).add(Duration(minutes: launchIndex)),
              cause: 'Causa da abertura $launchIndex',
              planOrExecution: launchIndex.isEven
                  ? PlanOrExecution.plan
                  : PlanOrExecution.execution,
              adjustment: 'Ajuste da abertura $launchIndex',
            ),
          );
          expect(answered.isSuccess, isTrue, reason: context);
          pendingIds.remove(expected.id);

          // Mesmo com outro pendente já persistido, esta sessão terminou.
          final refreshed = await repository.pendingProtocols();
          expect(gate.selectForThisLaunch(refreshed), isNull, reason: context);
          expect(gate.isSessionClosed, isTrue, reason: context);
        }

        expect(
          (await repository.pendingProtocols())
              .map((protocol) => protocol.id)
              .toList(),
          _referencePendingOrder(input.protocols, pendingIds),
          reason: context,
        );
      }

      // O gerador sempre inclui uma resposta por protocolo; aberturas extras
      // exercitam o estado vazio sem tornar a propriedade vacuosa.
      expect(pendingIds, isEmpty);
      expect(await repository.pendingProtocols(), isEmpty);
    } finally {
      await database.close();
    }
  });
}

Future<void> _insertProtocol(
  RitmoDatabase database,
  _ProtocolSeed protocol,
) async {
  final endDate = protocol.startDate.next;
  for (final date in <OperationalDate>[protocol.startDate, endDate]) {
    await database.customStatement(
      "INSERT OR IGNORE INTO days "
      "(operational_date, base_result, effective_result) "
      "VALUES (?, 'unsealed', 'unsealed')",
      [date.iso],
    );
  }
  await database.customStatement(
    'INSERT INTO protocol_alarms '
    '(id, generation_id, start_date, end_date, sequence_length, state) '
    "VALUES (?, ?, ?, ?, 2, 'pending')",
    [
      protocol.id,
      'seq:${protocol.startDate.iso}:${protocol.id}',
      protocol.startDate.iso,
      endDate.iso,
    ],
  );
}
