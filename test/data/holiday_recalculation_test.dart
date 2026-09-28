import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/holidays/holiday_recalculation.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

void main() {
  late RitmoDatabase database;
  late HolidayRecalculation recalculation;
  final affected = OperationalDate(2026, 1, 6);
  final instant = DateTime.utc(2026, 1, 6, 15);

  setUp(() async {
    database = RitmoDatabase(NativeDatabase.memory());
    recalculation = HolidayRecalculation(
      database,
      clock: SystemOperationalClock(deviceInstant: () => instant),
    );
    await database.customStatement(
      "UPDATE settings SET activation_date = '2026-01-05' WHERE id = 1",
    );
    await _insertDay(database, '2026-01-05');
    await _insertDay(database, '2026-01-06');
  });

  tearDown(() async {
    await recalculation.dispose();
    await database.close();
  });

  test('preview is neutral and announces metric and protocol effects', () {
    for (final operation in HolidayOperation.values) {
      final preview = recalculation.preview(affected, operation);
      expect(preview.date, affected);
      expect(preview.message, contains('métricas'));
      expect(preview.message, contains('protocolos'));
      expect(preview.message.toLowerCase(), isNot(contains('fraude')));
      expect(preview.message.toLowerCase(), isNot(contains('puni')));
      expect(preview.message.toLowerCase(), isNot(contains('bloque')));
    }
  });

  test('apply atomically audits, reclassifies, reconciles and emits', () async {
    await ProtocolReconciler(database).reconcileProtocols();
    final original = (await database.select(database.protocolAlarms).get()).single;
    await database.customStatement(
      "UPDATE protocol_alarms SET state = 'answered', previous_state = NULL, "
      "triggered_at = 10, cause = 'Causa', plan_or_execution = 'plan', "
      "adjustment = 'Ajuste' WHERE id = ?",
      [original.id],
    );
    await database.customStatement(
      "INSERT INTO pillar_entries (operational_date, pillar, toggle_on) "
      "VALUES ('2026-01-06', 'day', 1)",
    );
    final eventFuture = recalculation.changes.first;

    final result = await recalculation.apply(
      affected,
      reasonText: '  Feriado local  ',
    );
    final report = _value(result);
    final event = await eventFuture;
    final holiday = await database.select(database.holidays).getSingle();
    final day = await _day(database, affected.iso);
    final protocol = (await database.select(database.protocolAlarms).get()).single;

    expect(report.holidayChanged, isTrue);
    expect(report.protocols.invalidated, ['seq:2026-01-05']);
    expect(holiday.active, isTrue);
    expect(holiday.applyReasonText, 'Feriado local');
    expect(holiday.createdAt, instant.millisecondsSinceEpoch);
    expect(day.effectiveResult, 'mute');
    expect(day.muteCause, 'holiday');
    expect(day.previousResult, 'unsealed');
    expect(protocol.state, 'invalidated');
    expect(protocol.previousState, 'answered');
    expect(protocol.cause, 'Causa');
    expect(await database.select(database.pillarEntries).get(), hasLength(1));
    expect(event.date, affected);
    expect(event.operation, HolidayOperation.apply);
  });

  test('remove restores the result, keeps audit and creates a new protocol', () async {
    await ProtocolReconciler(database).reconcileProtocols();
    final originalId = (await database.select(database.protocolAlarms).get()).single.id;
    _value(await recalculation.apply(affected, reasonText: 'Aplicação'));

    final eventFuture = recalculation.changes.first;
    final report = _value(
      await recalculation.remove(affected, reasonText: '  Correção  '),
    );
    final event = await eventFuture;
    final holiday = await database.select(database.holidays).getSingle();
    final day = await _day(database, affected.iso);
    final protocols = await (database.select(database.protocolAlarms)
          ..orderBy([(row) => OrderingTerm(expression: row.id)]))
        .get();

    expect(report.holidayChanged, isTrue);
    expect(report.protocols.created, ['seq:2026-01-05']);
    expect(holiday.active, isFalse);
    expect(holiday.applyReasonText, 'Aplicação');
    expect(holiday.removeReasonText, 'Correção');
    expect(holiday.removedAt, instant.millisecondsSinceEpoch);
    expect(day.effectiveResult, 'unsealed');
    expect(day.muteCause, isNull);
    expect(day.previousResult, 'unsealed');
    expect(protocols, hasLength(2));
    expect(protocols.firstWhere((row) => row.id == originalId).state, 'invalidated');
    expect(
      protocols.firstWhere((row) => row.id != originalId).state,
      'pending',
    );
    expect(event.operation, HolidayOperation.remove);
  });

  test('repeating the same operation is idempotent and emits no new event', () async {
    _value(await recalculation.apply(affected));
    var events = 0;
    final subscription = recalculation.changes.listen((_) => events++);

    final report = _value(await recalculation.apply(affected));
    await Future<void>.delayed(Duration.zero);

    expect(report.holidayChanged, isFalse);
    expect(report.protocols.changedNothing, isTrue);
    expect(events, 0);
    await subscription.cancel();
  });

  test('an over-limit optional reason changes no persisted state', () async {
    final result = await recalculation.apply(
      affected,
      reasonText: List.filled(501, 'á').join(),
    );

    expect(result, isA<Failure<RecalcReport, HolidayViolation>>());
    expect(
      (result as Failure<RecalcReport, HolidayViolation>).failure.code,
      'holiday_reason_too_long',
    );
    expect(await database.select(database.holidays).get(), isEmpty);
    expect((await _day(database, affected.iso)).effectiveResult, 'unsealed');
  });

  test('a protocol failure rolls back holiday and day changes', () async {
    await ProtocolReconciler(database).reconcileProtocols();
    await database.customStatement(
      "CREATE TRIGGER reject_protocol_invalidation "
      "BEFORE UPDATE OF state ON protocol_alarms "
      "WHEN NEW.state = 'invalidated' BEGIN "
      "SELECT RAISE(ABORT, 'forced failure'); END",
    );

    await expectLater(
      recalculation.apply(affected, reasonText: 'Não deve persistir'),
      throwsA(isA<Exception>()),
    );

    expect(await database.select(database.holidays).get(), isEmpty);
    final day = await _day(database, affected.iso);
    expect(day.effectiveResult, 'unsealed');
    expect(day.muteCause, isNull);
    expect(
      (await database.select(database.protocolAlarms).get()).single.state,
      'pending',
    );
  });
}

RecalcReport _value(Result<RecalcReport, HolidayViolation> result) {
  expect(result, isA<Success<RecalcReport, HolidayViolation>>());
  return (result as Success<RecalcReport, HolidayViolation>).value;
}

Future<void> _insertDay(RitmoDatabase database, String date) =>
    database.customStatement(
      'INSERT INTO days (operational_date, base_result, effective_result, '
      "closed_at) VALUES (?, 'unsealed', 'unsealed', 100)",
      [date],
    );

Future<Day> _day(RitmoDatabase database, String date) =>
    (database.select(database.days)
          ..where((row) => row.operationalDate.equals(date)))
        .getSingle();
