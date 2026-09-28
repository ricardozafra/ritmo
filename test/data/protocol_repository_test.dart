import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/controllers/protocol_controller.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' hide ProtocolAlarm;
import 'package:ritmo/data/repositories/protocol_repository.dart';
import 'package:ritmo/domain/protocol/protocol_alarm.dart';
import 'package:ritmo/domain/protocol/protocol_session_gate.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late RitmoDatabase database;
  late ProtocolRepository repository;
  late tz.Location location;

  setUp(() async {
    location = ensureBusinessLocation();
    database = RitmoDatabase(NativeDatabase.memory());
    repository = ProtocolRepository(database, businessLocation: location);
    await _insertProtocol(database, id: 'newer', start: '2026-02-02');
    await _insertProtocol(database, id: 'older', start: '2026-01-05');
  });

  tearDown(() => database.close());

  test(
    'resposta persiste todos os campos e encerra somente esta sessão',
    () async {
      final gate = ProtocolSessionGate();
      expect(
        gate.selectForThisLaunch(await repository.pendingProtocols())?.id,
        'older',
      );
      final triggeredAt = tz.TZDateTime(location, 2026, 2, 3, 9, 15);

      final result = await ProtocolController(repository, gate).answerSelected(
        ProtocolAnswer(
          triggeredAt: triggeredAt,
          cause: 'Plano amplo demais',
          planOrExecution: PlanOrExecution.plan,
          adjustment: 'Reduzir o escopo diário',
        ),
      );

      expect(result.isSuccess, isTrue);
      final answered = await repository.findById('older');
      expect(answered?.state, ProtocolState.answered);
      expect(answered?.triggeredAt, triggeredAt);
      expect(answered?.cause, 'Plano amplo demais');
      expect(answered?.planOrExecution, PlanOrExecution.plan);
      expect(answered?.adjustment, 'Reduzir o escopo diário');
      expect(
        gate.selectForThisLaunch(await repository.pendingProtocols()),
        isNull,
      );
      expect(
        ProtocolSessionGate()
            .selectForThisLaunch(await repository.pendingProtocols())
            ?.id,
        'newer',
      );
    },
  );

  test(
    'resposta acima do limite é rejeitada sem alterar o protocolo',
    () async {
      final gate = ProtocolSessionGate();
      gate.selectForThisLaunch(await repository.pendingProtocols());

      final result = await ProtocolController(repository, gate).answerSelected(
        ProtocolAnswer(
          triggeredAt: tz.TZDateTime(location, 2026, 2, 3),
          cause: 'x' * 2001,
          planOrExecution: PlanOrExecution.execution,
          adjustment: 'Antecipar o início',
        ),
      );

      expect(result, isA<Failure<ProtocolAlarm, BusinessViolation>>());
      expect(
        (await repository.findById('older'))?.state,
        ProtocolState.pending,
      );
      expect(gate.isSessionClosed, isFalse);
    },
  );
}

Future<void> _insertProtocol(
  RitmoDatabase database, {
  required String id,
  required String start,
}) async {
  final end = start == '2026-01-05' ? '2026-01-06' : '2026-02-03';
  for (final date in [start, end]) {
    await database.customStatement(
      "INSERT OR IGNORE INTO days (operational_date, base_result, effective_result) VALUES (?, 'unsealed', 'unsealed')",
      [date],
    );
  }
  await database.customStatement(
    "INSERT INTO protocol_alarms (id, generation_id, start_date, end_date, sequence_length, state) VALUES (?, ?, ?, ?, 2, 'pending')",
    [id, 'seq:$start', start, end],
  );
}
