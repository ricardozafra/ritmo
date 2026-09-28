import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/db/guarded_writer.dart';

void main() {
  late RitmoDatabase database;
  late GuardedDayWriter dayWriter;
  late GuardedWriter reviewWriter;
  late HolidayReclassifier holidayReclassifier;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
    dayWriter = GuardedDayWriter(database);
    reviewWriter = GuardedWriter(database);
    holidayReclassifier = HolidayReclassifier(database);
  });

  tearDown(() => database.close());

  group('GuardedDayWriter', () {
    test('writes an ordinary record while the day is open', () async {
      await _insertDay(database, '2026-05-04');

      final result = await dayWriter.write(
        operationalDate: '2026-05-04',
        write: () => database.customStatement(
          'INSERT INTO pillar_entries (operational_date, pillar) '
          "VALUES ('2026-05-04', 'morning')",
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(await _pillarCount(database, '2026-05-04'), 1);
    });

    test('rejects a closed day before invoking the write', () async {
      await _insertDay(database, '2026-05-04', closedAt: 200);
      var invoked = false;

      final result = await dayWriter.write<void>(
        operationalDate: '2026-05-04',
        write: () async {
          invoked = true;
        },
      );

      expect(invoked, isFalse);
      expect(_failureCode(result), 'day_closed');
    });

    test('rolls back every write when the transactional body fails', () async {
      await _insertDay(database, '2026-05-04');

      await expectLater(
        dayWriter.write<void>(
          operationalDate: '2026-05-04',
          write: () async {
            await database.customStatement(
              'INSERT INTO pillar_entries (operational_date, pillar) '
              "VALUES ('2026-05-04', 'day')",
            );
            throw StateError('interrupted');
          },
        ),
        throwsStateError,
      );

      expect(await _pillarCount(database, '2026-05-04'), 0);
    });

    test('reports a missing operational day without writing', () async {
      var invoked = false;

      final result = await dayWriter.write<void>(
        operationalDate: '2026-05-04',
        write: () async {
          invoked = true;
        },
      );

      expect(invoked, isFalse);
      expect(_failureCode(result), 'day_not_found');
    });
  });

  group('GuardedWriter', () {
    test('allows draft autosave and makes finalization absorbing', () async {
      await database.customStatement(
        'INSERT INTO weekly_reviews (id, week_start, created_at) '
        "VALUES ('review-1', '2026-05-04', 100)",
      );

      final autosave = await reviewWriter.writeReview(
        reviewId: 'review-1',
        write: () => database.customStatement(
          "UPDATE weekly_reviews SET answer_fulfilled = 'Cumpri', "
          "autosaved_at = 110 WHERE id = 'review-1'",
        ),
      );
      final finalize = await reviewWriter.writeReview(
        reviewId: 'review-1',
        write: () => database.customStatement(
          "UPDATE weekly_reviews SET state = 'finalized', "
          "finalized_at = 120 WHERE id = 'review-1'",
        ),
      );

      var invoked = false;
      final rejected = await reviewWriter.writeReview<void>(
        reviewId: 'review-1',
        write: () async {
          invoked = true;
          await database.customStatement(
            "UPDATE weekly_reviews SET answer_fulfilled = 'Alterado' "
            "WHERE id = 'review-1'",
          );
        },
      );

      expect(autosave.isSuccess, isTrue);
      expect(finalize.isSuccess, isTrue);
      expect(invoked, isFalse);
      expect(_failureCode(rejected), 'review_finalized');
      final review = await database
          .customSelect(
            "SELECT answer_fulfilled FROM weekly_reviews WHERE id = 'review-1'",
          )
          .getSingle();
      expect(review.read<String>('answer_fulfilled'), 'Cumpri');
    });
  });

  group('HolidayReclassifier', () {
    test('reclassifies a closed day without changing ordinary data', () async {
      await _insertDay(
        database,
        '2026-05-04',
        baseResult: 'sealed',
        effectiveResult: 'sealed',
        closedAt: 200,
        sealTimestamp: 150,
      );
      await database.customStatement(
        'INSERT INTO pillar_entries '
        '(operational_date, pillar, workout_done) '
        "VALUES ('2026-05-04', 'morning', 1)",
      );

      final applied = await holidayReclassifier.apply('2026-05-04');
      final muted = await _readDay(database, '2026-05-04');

      expect(applied.isSuccess, isTrue);
      expect(muted.read<String>('base_result'), 'sealed');
      expect(muted.read<String>('effective_result'), 'mute');
      expect(muted.read<String>('mute_cause'), 'holiday');
      expect(muted.read<String>('previous_result'), 'sealed');
      expect(muted.read<int>('closed_at'), 200);
      expect(muted.read<int>('seal_timestamp'), 150);
      expect(await _pillarCount(database, '2026-05-04'), 1);

      final removed = await holidayReclassifier.remove('2026-05-04');
      final restored = await _readDay(database, '2026-05-04');

      expect(removed.isSuccess, isTrue);
      expect(restored.read<String>('effective_result'), 'sealed');
      expect(restored.readNullable<String>('mute_cause'), isNull);
      expect(restored.read<String>('previous_result'), 'sealed');
      expect(restored.read<int>('closed_at'), 200);
      expect(restored.read<int>('seal_timestamp'), 150);
      expect(await _pillarCount(database, '2026-05-04'), 1);
    });

    test(
      'is idempotent when holiday classification is applied twice',
      () async {
        await _insertDay(database, '2026-05-04');

        await holidayReclassifier.apply('2026-05-04');
        await holidayReclassifier.apply('2026-05-04');
        final day = await _readDay(database, '2026-05-04');

        expect(day.read<String>('effective_result'), 'mute');
        expect(day.read<String>('mute_cause'), 'holiday');
        expect(day.read<String>('previous_result'), 'unsealed');
      },
    );
  });
}

String? _failureCode<T, F extends RitmoFailure>(Result<T, F> result) {
  return result.fold(
    onSuccess: (_) => null,
    onFailure: (failure) => failure.code,
  );
}

Future<void> _insertDay(
  RitmoDatabase database,
  String operationalDate, {
  String baseResult = 'unsealed',
  String effectiveResult = 'unsealed',
  int? closedAt,
  int? sealTimestamp,
}) {
  return database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp) VALUES (?, ?, ?, ?, ?)',
    [operationalDate, baseResult, effectiveResult, closedAt, sealTimestamp],
  );
}

Future<int> _pillarCount(RitmoDatabase database, String operationalDate) async {
  final row = await database
      .customSelect(
        'SELECT count(*) AS count FROM pillar_entries WHERE operational_date = ?',
        variables: [Variable.withString(operationalDate)],
      )
      .getSingle();
  return row.read<int>('count');
}

Future<QueryRow> _readDay(RitmoDatabase database, String operationalDate) {
  return database
      .customSelect(
        'SELECT * FROM days WHERE operational_date = ?',
        variables: [Variable.withString(operationalDate)],
      )
      .getSingle();
}
