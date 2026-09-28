import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/study_block_repository.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late RitmoDatabase database;
  late DayRepository days;
  late StudyBlockRepository blocks;
  late OrphanBlockCloser orphanCloser;
  late SystemOperationalClock clock;
  late tz.Location location;

  final date = OperationalDate(2026, 5, 4);
  const calendar = OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(3, 0),
    nightEndTime: LocalTimeOfDay(1, 0),
  );

  setUp(() async {
    database = RitmoDatabase(NativeDatabase.memory());
    location = ensureBusinessLocation();
    clock = SystemOperationalClock(
      calendar: calendar,
      businessLocation: location,
    );
    days = DayRepository(database, businessLocation: location);
    blocks = StudyBlockRepository(database, clock: clock);
    orphanCloser = OrphanBlockCloser(database);
    _success(await days.ensureDayMaterialized(date));
  });

  tearDown(() => database.close());

  test('starts only before the calculated deadline and preserves origin', () async {
    final startedAt = tz.TZDateTime(location, 2026, 5, 4, 22);

    final block = _success(
      await blocks.start(
        id: 'study-1',
        operationalDate: date,
        startedAt: startedAt,
      ),
    );

    expect(block.operationalDate, date);
    expect(block.startedAt, startedAt);
    expect(block.blockDeadline, clock.blockDeadline(date));
    expect(block.endedAt, isNull);
    final persisted = await database.select(database.studyBlocks).getSingle();
    expect(persisted.operationalDate, date.iso);
    expect(persisted.blockDeadline, clock.blockDeadline(date).millisecondsSinceEpoch);
  });

  test('rejects starting exactly at or after block deadline', () async {
    final deadline = clock.blockDeadline(date);

    final atDeadline = await blocks.start(
      id: 'at-deadline',
      operationalDate: date,
      startedAt: deadline,
    );
    final afterDeadline = await blocks.start(
      id: 'after-deadline',
      operationalDate: date,
      startedAt: deadline.add(const Duration(minutes: 1)),
    );

    expect(_failureCode(atDeadline), 'study_deadline_reached');
    expect(_failureCode(afterDeadline), 'study_deadline_reached');
    expect(await database.select(database.studyBlocks).get(), isEmpty);
  });

  test('normal finish allows zero duration and never exceeds deadline', () async {
    final startedAt = tz.TZDateTime(location, 2026, 5, 4, 22);
    _success(
      await blocks.start(
        id: 'zero',
        operationalDate: date,
        startedAt: startedAt,
      ),
    );
    _success(
      await blocks.start(
        id: 'late-delivery',
        operationalDate: date,
        startedAt: startedAt,
      ),
    );

    final zero = _success(await blocks.finish('zero', at: startedAt));
    final late = _success(
      await blocks.finish(
        'late-delivery',
        at: clock.blockDeadline(date).add(const Duration(minutes: 30)),
      ),
    );

    expect(zero.endedAt, startedAt);
    expect(late.endedAt, clock.blockDeadline(date));
  });

  test('rejects a normal finish before the persisted start', () async {
    final startedAt = tz.TZDateTime(location, 2026, 5, 4, 22);
    _success(
      await blocks.start(
        id: 'invalid-end',
        operationalDate: date,
        startedAt: startedAt,
      ),
    );

    final result = await blocks.finish(
      'invalid-end',
      at: startedAt.subtract(const Duration(minutes: 1)),
    );

    expect(_failureCode(result), 'study_end_before_start');
    expect((await blocks.findById('invalid-end'))!.endedAt, isNull);
  });

  test('automatic timer closes exactly at the persisted deadline', () async {
    _success(
      await blocks.start(
        id: 'timer',
        operationalDate: date,
        startedAt: tz.TZDateTime(location, 2026, 5, 4, 22),
      ),
    );

    final closed = _success(await blocks.closeAtDeadline('timer'));
    final repeated = _success(await blocks.closeAtDeadline('timer'));

    expect(closed.endedAt, closed.blockDeadline);
    expect(repeated.endedAt, closed.blockDeadline);
  });

  test('orphan closer silently closes only expired blocks and is idempotent', () async {
    final nextDate = date.next;
    _success(await days.ensureDayMaterialized(nextDate));
    _success(
      await blocks.start(
        id: 'expired',
        operationalDate: date,
        startedAt: tz.TZDateTime(location, 2026, 5, 4, 22),
      ),
    );
    _success(
      await blocks.start(
        id: 'future',
        operationalDate: nextDate,
        startedAt: tz.TZDateTime(location, 2026, 5, 5, 22),
      ),
    );

    final firstCount = await orphanCloser.closeExpired(
      now: clock.blockDeadline(date).add(const Duration(minutes: 1)),
    );
    final secondCount = await orphanCloser.closeExpired(
      now: clock.blockDeadline(date).add(const Duration(minutes: 1)),
    );
    final expired = await blocks.findById('expired');
    final future = await blocks.findById('future');

    expect(firstCount, 1);
    expect(secondCount, 0);
    expect(expired!.endedAt, expired.blockDeadline);
    expect(expired.operationalDate, date);
    expect(future!.endedAt, isNull);
    expect(future.operationalDate, nextDate);
  });

  test('start uses the day guard but deadline closure survives a closed day', () async {
    await (database.update(database.days)
          ..where((row) => row.operationalDate.equals(date.iso)))
        .write(const DaysCompanion(closedAt: Value(100)));

    final rejected = await blocks.start(
      id: 'rejected',
      operationalDate: date,
      startedAt: tz.TZDateTime(location, 2026, 5, 4, 22),
    );
    expect(_failureCode(rejected), 'day_closed');

    await database.customStatement(
      'INSERT INTO study_blocks '
      '(id, operational_date, started_at, block_deadline) VALUES (?, ?, ?, ?)',
      [
        'orphan-on-closed-day',
        date.iso,
        tz.TZDateTime(location, 2026, 5, 4, 22).millisecondsSinceEpoch,
        clock.blockDeadline(date).millisecondsSinceEpoch,
      ],
    );
    final closed = _success(
      await blocks.closeAtDeadline('orphan-on-closed-day'),
    );
    expect(closed.endedAt, closed.blockDeadline);
  });
}

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode<T>(Result<T, BusinessViolation> result) => result.fold(
  onSuccess: (_) => null,
  onFailure: (failure) => failure.code,
);
