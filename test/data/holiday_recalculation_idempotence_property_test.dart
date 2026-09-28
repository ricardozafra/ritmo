// Feature: ritmo, Property 22: Recálculo idempotente e não destrutivo
//
// Para qualquer linha do tempo e sequência de operações de feriado, repetir o
// recálculo não altera o estado, bancos com a mesma entrada convergem para o
// mesmo resultado e nenhum registro protegido é apagado.
//
// **Validates: Requirements RF-05.16, RF-05.36, RNF-04.10, RNF-05.5**

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

typedef _DaySeed = ({String result, bool closed});
typedef _HolidayAction = ({int dayIndex, bool apply});
typedef _Scenario = ({
  OperationalDate activationDate,
  List<_DaySeed> timeline,
  List<_HolidayAction> actions,
});

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (Random random, int size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final dayCount = 4 + random.nextInt(max(1, min(5, size ~/ 10 + 1)));
    final actionCount = 1 + random.nextInt(max(1, min(8, size ~/ 8 + 1)));
    return (
      activationDate: activation,
      timeline: List.generate(
        dayCount,
        (_) => (
          result: random.nextBool() ? 'sealed' : 'unsealed',
          closed: random.nextBool(),
        ),
      ),
      actions: List.generate(
        actionCount,
        (_) => (dayIndex: random.nextInt(dayCount), apply: random.nextBool()),
      ),
    );
  },
  shrink: (_) sync* {
    yield (
      activationDate: canonicalOperationalDate,
      timeline: const [
        (result: 'unsealed', closed: true),
        (result: 'unsealed', closed: true),
        (result: 'sealed', closed: true),
        (result: 'unsealed', closed: false),
      ],
      actions: const [(dayIndex: 1, apply: true), (dayIndex: 1, apply: false)],
    );
  },
);
void main() {
  Glados<_Scenario>(_anyScenario, RitmoGlados.ci()).test(
    'Propriedade 22: Recálculo idempotente e não destrutivo',
    (_Scenario scenario) async {
      final firstDatabase = RitmoDatabase(NativeDatabase.memory());
      final secondDatabase = RitmoDatabase(NativeDatabase.memory());
      final dates = _workdays(
        scenario.activationDate,
        scenario.timeline.length,
      );
      final fixedInstant = DateTime.utc(2031, 6, 30, 15);
      final first = HolidayRecalculation(
        firstDatabase,
        clock: SystemOperationalClock(deviceInstant: () => fixedInstant),
      );
      final second = HolidayRecalculation(
        secondDatabase,
        clock: SystemOperationalClock(deviceInstant: () => fixedInstant),
      );

      try {
        await _seed(firstDatabase, scenario, dates);
        await _seed(secondDatabase, scenario, dates);
        expect(await _state(firstDatabase), await _state(secondDatabase));

        for (var step = 0; step < scenario.actions.length; step++) {
          final action = scenario.actions[step];
          final date = dates[action.dayIndex];
          final context =
              'passo $step/${action.apply ? 'aplicar' : 'remover'}/'
              '${date.iso}; timeline=${scenario.timeline}';
          final keysBefore = await _protectedKeys(firstDatabase);
          final ordinaryBefore = await _ordinaryState(firstDatabase);
          final staticDaysBefore = await _staticDayState(firstDatabase);

          _success(await _execute(first, date, action.apply), context);
          _success(await _execute(second, date, action.apply), context);

          final stateAfterFirstRun = await _state(firstDatabase);
          expect(
            stateAfterFirstRun,
            await _state(secondDatabase),
            reason: '$context/determinismo',
          );
          _expectNoDeletion(
            keysBefore,
            await _protectedKeys(firstDatabase),
            context,
          );
          expect(
            await _ordinaryState(firstDatabase),
            ordinaryBefore,
            reason: '$context/registros ordinários',
          );
          expect(
            await _staticDayState(firstDatabase),
            staticDaysBefore,
            reason: '$context/campos estáticos dos dias',
          );

          final repeated = _success(
            await _execute(first, date, action.apply),
            context,
          );
          expect(repeated.holidayChanged, isFalse, reason: context);
          expect(repeated.protocols.changedNothing, isTrue, reason: context);
          expect(
            await _state(firstDatabase),
            stateAfterFirstRun,
            reason: '$context/idempotência',
          );
        }
      } finally {
        await first.dispose();
        await second.dispose();
        await firstDatabase.close();
        await secondDatabase.close();
      }
    },
  );
}

Future<Result<RecalcReport, HolidayViolation>> _execute(
  HolidayRecalculation recalculation,
  OperationalDate date,
  bool apply,
) => apply
    ? recalculation.apply(date, reasonText: 'Motivo auditável')
    : recalculation.remove(date, reasonText: 'Motivo auditável');

RecalcReport _success(
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

List<OperationalDate> _workdays(OperationalDate start, int count) {
  final dates = <OperationalDate>[];
  var cursor = start;
  while (dates.length < count) {
    if (!cursor.isWeekend) dates.add(cursor);
    cursor = cursor.next;
  }
  return dates;
}

Future<void> _seed(
  RitmoDatabase database,
  _Scenario scenario,
  List<OperationalDate> dates,
) async {
  await database.customStatement(
    'UPDATE settings SET activation_date = ? WHERE id = 1',
    [scenario.activationDate.iso],
  );
  for (var index = 0; index < dates.length; index++) {
    final date = dates[index].iso;
    final seed = scenario.timeline[index];
    final sealed = seed.result == 'sealed';
    await database.customStatement(
      'INSERT INTO days (operational_date, base_result, effective_result, '
      'closed_at, seal_timestamp) VALUES (?, ?, ?, ?, ?)',
      [
        date,
        seed.result,
        seed.result,
        seed.closed ? 500 + index : null,
        sealed ? 400 + index : null,
      ],
    );
    await database.customStatement(
      'INSERT INTO study_blocks (id, operational_date, started_at, '
      'block_deadline, ended_at) VALUES (?, ?, ?, ?, ?)',
      ['block-$index', date, 100, 300, index.isEven ? 250 : null],
    );
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, night_kind, '
      "study_block_id, recovery_note) VALUES (?, 'night', 'study', ?, ?)",
      [date, 'block-$index', 'Nota $index'],
    );
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text, '
      'recurrence_confirmed, revoked_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        'waiver-$index',
        date,
        'morning',
        'Dispensa $index',
        1,
        index.isOdd ? 350 + index : null,
      ],
    );
  }
  await database.customStatement(
    'INSERT INTO weekly_reviews (id, week_start, answer_fulfilled, '
    'answer_failed, answer_lesson, state, created_at) '
    "VALUES ('review-1', ?, 'Cumprido', 'Falhou', 'Aprendizado', 'draft', 50)",
    [scenario.activationDate.iso],
  );
  await ProtocolReconciler(database).reconcileProtocols();
  await database.customStatement(
    "UPDATE protocol_alarms SET state = 'answered', triggered_at = 600, "
    "cause = 'Causa', plan_or_execution = 'execution', adjustment = 'Ajuste' "
    "WHERE state = 'pending'",
  );
}

const _allStateTables = <String, String>{
  'days': 'operational_date',
  'holidays': 'operational_date',
  'pillar_entries': 'operational_date, pillar',
  'study_blocks': 'id',
  'pillar_waivers': 'id',
  'protocol_alarms': 'id',
  'weekly_reviews': 'id',
};

const _protectedKeyQueries = <String, String>{
  'days': 'SELECT operational_date AS record_key FROM days',
  'pillar_entries':
      "SELECT operational_date || '/' || pillar AS record_key FROM pillar_entries",
  'study_blocks': 'SELECT id AS record_key FROM study_blocks',
  'pillar_waivers': 'SELECT id AS record_key FROM pillar_waivers',
  'protocol_alarms': 'SELECT id AS record_key FROM protocol_alarms',
  'weekly_reviews': 'SELECT id AS record_key FROM weekly_reviews',
};

Future<Map<String, String>> _state(RitmoDatabase database) async {
  final state = <String, String>{};
  for (final entry in _allStateTables.entries) {
    state[entry.key] = await _dump(
      database,
      'SELECT * FROM ${entry.key} ORDER BY ${entry.value}',
    );
  }
  return state;
}

Future<Map<String, Set<String>>> _protectedKeys(RitmoDatabase database) async {
  final result = <String, Set<String>>{};
  for (final entry in _protectedKeyQueries.entries) {
    final rows = await database.customSelect(entry.value).get();
    result[entry.key] = rows
        .map((row) => row.read<String>('record_key'))
        .toSet();
  }
  return result;
}

void _expectNoDeletion(
  Map<String, Set<String>> before,
  Map<String, Set<String>> after,
  String context,
) {
  for (final entry in before.entries) {
    expect(
      after[entry.key]!.containsAll(entry.value),
      isTrue,
      reason:
          '$context/${entry.key}: antes=${entry.value}, depois=${after[entry.key]}',
    );
  }
}

Future<String> _ordinaryState(RitmoDatabase database) async => _dump(
  database,
  'SELECT operational_date, pillar, workout_done, briefing_done, '
  'briefing_mode, workout_at, briefing_at, toggle_on, change_initiative_id, '
  'note_text, note_audio_id, night_kind, recovery_note, study_block_id '
  'FROM pillar_entries ORDER BY operational_date, pillar; '
  'SELECT * FROM study_blocks ORDER BY id; '
  'SELECT * FROM pillar_waivers ORDER BY id; '
  'SELECT * FROM weekly_reviews ORDER BY id',
);

Future<String> _staticDayState(RitmoDatabase database) => _dump(
  database,
  'SELECT operational_date, base_result, closed_at, seal_timestamp '
  'FROM days ORDER BY operational_date',
);

Future<String> _dump(RitmoDatabase database, String query) async {
  final statements = query
      .split(';')
      .map((statement) => statement.trim())
      .where((statement) => statement.isNotEmpty);
  final dumps = <String>[];
  for (final statement in statements) {
    final rows = await database.customSelect(statement).get();
    dumps.add(
      rows
          .map((row) {
            final keys = row.data.keys.toList()..sort();
            return keys.map((key) => '$key=${row.data[key]}').join('|');
          })
          .join('\n'),
    );
  }
  return dumps.join('\n--\n');
}
