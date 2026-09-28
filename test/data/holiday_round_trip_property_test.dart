// Feature: ritmo, Property 21: Round trip de feriado restaura o resultado anterior
//
// Para qualquer dia e qualquer motivo opcional, aplicar feriado e removê-lo
// restaura o resultado efetivo e preserva lifecycle, selo e registros
// ordinários, mantendo a alteração de feriado auditável e não destrutiva.
//
// **Validates: Requirements RF-05.13, RF-05.17, RF-05.18, RF-05.27,
// RF-05.28, RD-16**

import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

typedef _HolidayRoundTripFixture = ({
  OperationalDate date,
  String baseResult,
  bool closed,
  bool workoutDone,
  bool briefingDone,
  bool toggleOn,
  bool blockEnded,
  bool waiverRevoked,
  String? applyReason,
  String? removeReason,
});

final Generator<_HolidayRoundTripFixture> _anyHolidayRoundTrip = any.simple(
  generate: (random, size) {
    var date = anyOperationalDate(random, size).value;
    while (date.isWeekend) {
      date = date.next;
    }
    return (
      date: date,
      baseResult: random.nextBool() ? 'sealed' : 'unsealed',
      closed: random.nextBool(),
      workoutDone: random.nextBool(),
      briefingDone: random.nextBool(),
      toggleOn: random.nextBool(),
      blockEnded: random.nextBool(),
      waiverRevoked: random.nextBool(),
      applyReason: _optionalReason(random, size),
      removeReason: _optionalReason(random, size),
    );
  },
  shrink: (fixture) sync* {
    final canonical = (
      date: canonicalOperationalDate,
      baseResult: 'unsealed',
      closed: false,
      workoutDone: false,
      briefingDone: false,
      toggleOn: false,
      blockEnded: false,
      waiverRevoked: false,
      applyReason: null,
      removeReason: null,
    );
    if (fixture != canonical) yield canonical;
  },
);

String? _optionalReason(Random random, int size) {
  if (random.nextInt(4) == 0) return null;
  if (random.nextInt(8) == 0) return '   ';
  const alphabet = <String>['a', 'Z', ' ', 'á', 'ç', '界', '🙂'];
  final length = 1 + random.nextInt(max(1, min(500, size + 1)));
  final value = List.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
  return random.nextBool() ? value : '  $value  ';
}

void main() {
  Glados<_HolidayRoundTripFixture>(_anyHolidayRoundTrip, RitmoGlados.ci()).test(
    'Propriedade 21: Round trip de feriado restaura o resultado anterior',
    (fixture) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      var clockRead = 0;
      final firstInstant = DateTime.utc(2030, 1, 1, 12);
      final recalculation = HolidayRecalculation(
        database,
        clock: SystemOperationalClock(
          deviceInstant: () => firstInstant.add(Duration(seconds: clockRead++)),
        ),
      );
      final context =
          '${fixture.date.iso}/${fixture.baseResult}/closed=${fixture.closed}/'
          'apply=${fixture.applyReason}/remove=${fixture.removeReason}';

      try {
        await _seed(database, fixture);
        final beforeDay = await _row(
          database,
          'days',
          'operational_date',
          fixture.date.iso,
        );
        final beforeOrdinary = await _ordinaryDump(database);

        final apply = _value(
          await recalculation.apply(
            fixture.date,
            reasonText: fixture.applyReason,
          ),
          context,
        );
        expect(apply.holidayChanged, isTrue, reason: context);

        final mutedDay = await _row(
          database,
          'days',
          'operational_date',
          fixture.date.iso,
        );
        expect(mutedDay['effective_result'], 'mute', reason: context);
        expect(mutedDay['mute_cause'], 'holiday', reason: context);
        expect(
          mutedDay['previous_result'],
          fixture.baseResult,
          reason: context,
        );
        _expectPreservedDay(beforeDay, mutedDay, context);
        expect(await _ordinaryDump(database), beforeOrdinary, reason: context);

        final remove = _value(
          await recalculation.remove(
            fixture.date,
            reasonText: fixture.removeReason,
          ),
          context,
        );
        expect(remove.holidayChanged, isTrue, reason: context);

        final restoredDay = await _row(
          database,
          'days',
          'operational_date',
          fixture.date.iso,
        );
        expect(
          restoredDay['effective_result'],
          beforeDay['effective_result'],
          reason: context,
        );
        expect(restoredDay['mute_cause'], isNull, reason: context);
        expect(
          restoredDay['previous_result'],
          beforeDay['effective_result'],
          reason: context,
        );
        _expectPreservedDay(beforeDay, restoredDay, context);
        expect(await _ordinaryDump(database), beforeOrdinary, reason: context);

        final holiday = await database.select(database.holidays).getSingle();
        expect(holiday.operationalDate, fixture.date.iso, reason: context);
        expect(holiday.active, isFalse, reason: context);
        expect(
          holiday.createdAt,
          firstInstant.millisecondsSinceEpoch,
          reason: context,
        );
        expect(
          holiday.removedAt,
          firstInstant.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
          reason: context,
        );
        expect(
          holiday.applyReasonText,
          _normalized(fixture.applyReason),
          reason: context,
        );
        expect(
          holiday.removeReasonText,
          _normalized(fixture.removeReason),
          reason: context,
        );
      } finally {
        await recalculation.dispose();
        await database.close();
      }
    },
  );
}

RecalcReport _value(
  Result<RecalcReport, HolidayViolation> result,
  String context,
) {
  expect(
    result,
    isA<Success<RecalcReport, HolidayViolation>>(),
    reason: context,
  );
  return (result as Success<RecalcReport, HolidayViolation>).value;
}

String? _normalized(String? reason) {
  final normalized = reason?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

void _expectPreservedDay(
  Map<String, Object?> before,
  Map<String, Object?> after,
  String context,
) {
  for (final column in <String>[
    'operational_date',
    'base_result',
    'closed_at',
    'seal_timestamp',
  ]) {
    expect(after[column], before[column], reason: '$context/$column');
  }
}

Future<void> _seed(
  RitmoDatabase database,
  _HolidayRoundTripFixture fixture,
) async {
  final iso = fixture.date.iso;
  final sealed = fixture.baseResult == 'sealed';
  await database.customStatement(
    'UPDATE settings SET activation_date = ? WHERE id = 1',
    [iso],
  );
  await database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp) VALUES (?, ?, ?, ?, ?)',
    [
      iso,
      fixture.baseResult,
      fixture.baseResult,
      fixture.closed ? 300 : null,
      sealed ? 250 : null,
    ],
  );
  await database.customStatement(
    'INSERT INTO study_blocks (id, operational_date, started_at, '
    'block_deadline, ended_at) VALUES (?, ?, ?, ?, ?)',
    ['block-1', iso, 100, 200, fixture.blockEnded ? 180 : null],
  );
  await database.customStatement(
    'INSERT INTO pillar_entries (operational_date, pillar, workout_done, '
    'briefing_done, briefing_mode, workout_at, briefing_at) '
    "VALUES (?, 'morning', ?, ?, 'manual', 110, 120)",
    [iso, fixture.workoutDone ? 1 : 0, fixture.briefingDone ? 1 : 0],
  );
  await database.customStatement(
    'INSERT INTO pillar_entries (operational_date, pillar, toggle_on, '
    "note_text) VALUES (?, 'day', ?, 'Nota preservada')",
    [iso, fixture.toggleOn ? 1 : 0],
  );
  await database.customStatement(
    'INSERT INTO pillar_entries (operational_date, pillar, night_kind, '
    "study_block_id) VALUES (?, 'night', 'study', 'block-1')",
    [iso],
  );
  await database.customStatement(
    'INSERT INTO pillar_waivers (id, date, pillar, reason_text, '
    'recurrence_confirmed, revoked_at) VALUES (?, ?, ?, ?, ?, ?)',
    [
      'waiver-1',
      iso,
      'morning',
      'Motivo preservado',
      1,
      fixture.waiverRevoked ? 220 : null,
    ],
  );
}

const _ordinaryTables = <String>[
  'pillar_entries',
  'study_blocks',
  'pillar_waivers',
];

const _orderBy = <String, String>{
  'pillar_entries': 'operational_date, pillar',
  'study_blocks': 'id',
  'pillar_waivers': 'id',
};

Future<Map<String, String>> _ordinaryDump(RitmoDatabase database) async {
  final result = <String, String>{};
  for (final table in _ordinaryTables) {
    final rows = await database
        .customSelect('SELECT * FROM $table ORDER BY ${_orderBy[table]}')
        .get();
    result[table] = rows
        .map((row) {
          final keys = row.data.keys.toList()..sort();
          return keys.map((key) => '$key=${row.data[key]}').join('|');
        })
        .join(';');
  }
  return result;
}

Future<Map<String, Object?>> _row(
  RitmoDatabase database,
  String table,
  String key,
  String value,
) async {
  final row = await database
      .customSelect(
        'SELECT * FROM $table WHERE $key = ?',
        variables: [Variable.withString(value)],
      )
      .getSingle();
  return row.data;
}
