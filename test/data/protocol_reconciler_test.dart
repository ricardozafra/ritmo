import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  late RitmoDatabase database;
  late ProtocolReconciler reconciler;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
    reconciler = ProtocolReconciler(database);
  });

  tearDown(() => database.close());

  test(
    'two closed unsealed workdays create exactly one pending protocol',
    () async {
      await _activate(database, '2026-01-05');
      await _insertDay(database, '2026-01-05');
      await _insertDay(database, '2026-01-06');

      final report = await reconciler.reconcileProtocols(
        from: OperationalDate(2026, 1, 6),
      );
      final protocols = await _protocols(database);

      expect(report.created, ['seq:2026-01-05']);
      expect(protocols, hasLength(1));
      expect(protocols.single.generationId, 'seq:2026-01-05');
      expect(protocols.single.startDate, '2026-01-05');
      expect(protocols.single.endDate, '2026-01-06');
      expect(protocols.single.sequenceLength, 2);
      expect(protocols.single.state, 'pending');
      expect(protocols.single.previousState, isNull);
    },
  );

  test(
    'growth expands to the sequence start and updates the same protocol',
    () async {
      await _activate(database, '2026-01-05');
      await _insertDay(database, '2026-01-05');
      await _insertDay(database, '2026-01-06');
      await reconciler.reconcileProtocols(from: OperationalDate(2026, 1, 6));
      final firstId = (await _protocols(database)).single.id;

      await _insertDay(database, '2026-01-07');
      await _insertDay(database, '2026-01-08');
      final report = await reconciler.reconcileProtocols(
        from: OperationalDate(2026, 1, 8),
      );
      final protocols = await _protocols(database);

      expect(report.scopeStart, OperationalDate(2026, 1, 5));
      expect(report.created, isEmpty);
      expect(report.updated, ['seq:2026-01-05']);
      expect(protocols, hasLength(1));
      expect(protocols.single.id, firstId);
      expect(protocols.single.sequenceLength, 4);
      expect(protocols.single.endDate, '2026-01-08');
    },
  );

  test('repeating the reconciliation changes nothing', () async {
    await _activate(database, '2026-01-05');
    await _insertDay(database, '2026-01-05');
    await _insertDay(database, '2026-01-06');
    await reconciler.reconcileProtocols();
    final before = await _protocols(database);

    final report = await reconciler.reconcileProtocols();

    expect(report.changedNothing, isTrue);
    expect(await _protocols(database), before);
  });

  test(
    'weekend mute days keep friday and monday in the same sequence',
    () async {
      await _activate(database, '2026-01-09');
      await _insertDay(database, '2026-01-09');
      await _insertDay(database, '2026-01-10', muteCause: 'weekend');
      await _insertDay(database, '2026-01-11', muteCause: 'weekend');
      await _insertDay(database, '2026-01-12');

      await reconciler.reconcileProtocols(from: OperationalDate(2026, 1, 12));
      final protocols = await _protocols(database);

      expect(protocols, hasLength(1));
      expect(protocols.single.startDate, '2026-01-09');
      expect(protocols.single.endDate, '2026-01-12');
      expect(protocols.single.sequenceLength, 2);
    },
  );

  test(
    'losing the criterion invalidates and preserves state and data',
    () async {
      await _activate(database, '2026-01-05');
      await _insertDay(database, '2026-01-05');
      await _insertDay(database, '2026-01-06');
      await reconciler.reconcileProtocols();
      await _answer(database, (await _protocols(database)).single.id);

      await _applyHoliday(database, '2026-01-06');
      final report = await reconciler.reconcileProtocols(
        from: OperationalDate(2026, 1, 6),
      );
      final protocols = await _protocols(database);

      expect(report.invalidated, ['seq:2026-01-05']);
      expect(protocols, hasLength(1));
      expect(protocols.single.state, 'invalidated');
      expect(protocols.single.previousState, 'answered');
      expect(protocols.single.cause, 'Agenda sobrecarregada');
      expect(protocols.single.adjustment, 'Reduzir compromissos da noite');
      expect(protocols.single.planOrExecution, 'plan');
      expect(protocols.single.triggeredAt, 1767657600000);
      expect(protocols.single.sequenceLength, 2);
      expect(protocols.single.endDate, '2026-01-06');
    },
  );

  test(
    'restored sequence gets a new protocol and never reactivates the old one',
    () async {
      await _activate(database, '2026-01-05');
      await _insertDay(database, '2026-01-05');
      await _insertDay(database, '2026-01-06');
      await reconciler.reconcileProtocols();
      final originalId = (await _protocols(database)).single.id;
      await _applyHoliday(database, '2026-01-06');
      await reconciler.reconcileProtocols(from: OperationalDate(2026, 1, 6));

      await _removeHoliday(database, '2026-01-06');
      final report = await reconciler.reconcileProtocols(
        from: OperationalDate(2026, 1, 6),
      );
      final protocols = await _protocols(database);

      expect(report.created, ['seq:2026-01-05']);
      expect(protocols, hasLength(2));
      final original = protocols.firstWhere((row) => row.id == originalId);
      final restored = protocols.firstWhere((row) => row.id != originalId);
      expect(original.state, 'invalidated');
      expect(original.previousState, 'pending');
      expect(restored.state, 'pending');
      expect(restored.previousState, isNull);
      expect(restored.generationId, original.generationId);
      expect(restored.sequenceLength, 2);
    },
  );

  test(
    'concurrent reconciliations converge to one protocol with the right length',
    () async {
      await _activate(database, '2026-01-05');
      for (final day in const [
        '2026-01-05',
        '2026-01-06',
        '2026-01-07',
        '2026-01-08',
      ]) {
        await _insertDay(database, day);
      }

      await Future.wait([
        reconciler.reconcileProtocols(from: OperationalDate(2026, 1, 8)),
        reconciler.reconcileProtocols(from: OperationalDate(2026, 1, 8)),
        ProtocolReconciler(database).reconcileProtocols(),
      ]);
      final protocols = await _protocols(database);

      expect(protocols, hasLength(1));
      expect(protocols.single.state, 'pending');
      expect(protocols.single.sequenceLength, 4);
      expect(protocols.single.endDate, '2026-01-08');
    },
  );
}

Future<void> _activate(RitmoDatabase database, String date) =>
    database.customStatement('UPDATE settings SET activation_date = ?', [date]);

Future<void> _insertDay(
  RitmoDatabase database,
  String date, {
  bool closed = true,
  bool sealed = false,
  String? muteCause,
}) async {
  final baseResult = sealed ? 'sealed' : 'unsealed';
  await database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp, mute_cause, previous_result) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      date,
      baseResult,
      muteCause == null ? baseResult : 'mute',
      closed ? 1767600000000 : null,
      sealed ? 1767596400000 : null,
      muteCause,
      muteCause == 'holiday' ? baseResult : null,
    ],
  );
}

Future<void> _applyHoliday(RitmoDatabase database, String date) =>
    database.customStatement(
      "UPDATE days SET effective_result = 'mute', mute_cause = 'holiday', "
      'previous_result = base_result WHERE operational_date = ?',
      [date],
    );

Future<void> _removeHoliday(RitmoDatabase database, String date) =>
    database.customStatement(
      'UPDATE days SET effective_result = previous_result, mute_cause = NULL '
      'WHERE operational_date = ?',
      [date],
    );

Future<void> _answer(RitmoDatabase database, String id) =>
    database.customStatement(
      "UPDATE protocol_alarms SET state = 'answered', triggered_at = ?, "
      'cause = ?, plan_or_execution = ?, adjustment = ? WHERE id = ?',
      [
        1767657600000,
        'Agenda sobrecarregada',
        'plan',
        'Reduzir compromissos da noite',
        id,
      ],
    );

Future<List<ProtocolAlarm>> _protocols(RitmoDatabase database) =>
    (database.select(
      database.protocolAlarms,
    )..orderBy([(row) => OrderingTerm(expression: row.id)])).get();
