import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/data/db/database.dart';

void main() {
  test(
    'RD-11: concurrent inserts keep one active waiver per day',
    () => _withSharedDatabase((first, second) async {
      await _insertOpenDay(first, '2026-05-04');

      final results = await _raceInserts([
        () => first.customStatement(
          'INSERT INTO pillar_waivers '
          '(id, date, pillar, reason_text) VALUES (?, ?, ?, ?)',
          ['waiver-1', '2026-05-04', 'morning', 'Consulta'],
        ),
        () => second.customStatement(
          'INSERT INTO pillar_waivers '
          '(id, date, pillar, reason_text) VALUES (?, ?, ?, ?)',
          ['waiver-2', '2026-05-04', 'day', 'Imprevisto'],
        ),
      ]);

      _expectOneUniqueWinner(results);
      expect(
        await _count(
          first,
          'pillar_waivers',
          'date = ? AND revoked_at IS NULL',
          ['2026-05-04'],
        ),
        1,
      );
    }),
  );

  test(
    'RD-14: concurrent inserts keep one live protocol per generation',
    () => _withSharedDatabase((first, second) async {
      await _insertOpenDay(first, '2026-05-04');
      await _insertOpenDay(first, '2026-05-05');
      const sql = 'INSERT INTO protocol_alarms '
          '(id, generation_id, start_date, end_date, sequence_length, state) '
          'VALUES (?, ?, ?, ?, ?, ?)';
      final results = await _raceInserts([
        () => first.customStatement(sql, [
          'protocol-1',
          'seq:2026-05-04',
          '2026-05-04',
          '2026-05-05',
          2,
          'pending',
        ]),
        () => second.customStatement(sql, [
          'protocol-2',
          'seq:2026-05-04',
          '2026-05-04',
          '2026-05-05',
          2,
          'answered',
        ]),
      ]);

      _expectOneUniqueWinner(results);
      expect(
        await _count(
          first,
          'protocol_alarms',
          "generation_id = ? AND state <> 'invalidated'",
          ['seq:2026-05-04'],
        ),
        1,
      );
    }),
  );

  test(
    'RD-25: concurrent inserts keep one active change initiative',
    () => _withSharedDatabase((first, second) async {
      const sql = 'INSERT INTO change_initiatives (id, name, active) '
          'VALUES (?, ?, 1)';
      final results = await _raceInserts([
        () => first.customStatement(sql, ['initiative-1', 'Primeira']),
        () => second.customStatement(sql, ['initiative-2', 'Segunda']),
      ]);

      _expectOneUniqueWinner(results);
      expect(
        await _count(first, 'change_initiatives', 'active = 1'),
        1,
      );
    }),
  );

  test(
    'RD-20: concurrent inserts keep one active cycle',
    () => _withSharedDatabase((first, second) async {
      await first.customStatement(
        "UPDATE cycles SET state = 'archived' WHERE state = 'active'",
      );
      const sql = 'INSERT INTO cycles '
          '(id, name, purpose_text, start_date, end_date, state) '
          "VALUES (?, ?, ?, ?, ?, 'active')";
      final results = await _raceInserts([
        () => first.customStatement(sql, [
          'cycle-1',
          'Primeiro',
          'Finalidade 1',
          '2027-07-01',
          '2028-06-30',
        ]),
        () => second.customStatement(sql, [
          'cycle-2',
          'Segundo',
          'Finalidade 2',
          '2027-07-01',
          '2028-06-30',
        ]),
      ]);

      _expectOneUniqueWinner(results);
      expect(await _count(first, 'cycles', "state = 'active'"), 1);
    }),
  );
}

Future<void> _withSharedDatabase(
  Future<void> Function(RitmoDatabase first, RitmoDatabase second) body,
) async {
  final directory = await Directory.systemTemp.createTemp('ritmo_constraints_');
  final file = File(
    '${directory.path}${Platform.pathSeparator}ritmo.sqlite',
  );
  final first = RitmoDatabase(NativeDatabase(file));
  RitmoDatabase? second;

  try {
    await first.customSelect('SELECT 1').getSingle();
    second = RitmoDatabase(NativeDatabase(file));
    await second.customSelect('SELECT 1').getSingle();
    await body(first, second);
  } finally {
    await second?.close();
    await first.close();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}

Future<List<Object?>> _raceInserts(
  List<Future<void> Function()> inserts,
) async {
  final start = Completer<void>();
  final attempts = inserts.map((insert) async {
    await start.future;
    try {
      await insert();
      return null;
    } catch (error) {
      return error;
    }
  }).toList(growable: false);

  start.complete();
  return Future.wait(attempts);
}
void _expectOneUniqueWinner(List<Object?> results) {
  expect(results.where((result) => result == null), hasLength(1));
  final failures = results.whereType<Object>().toList(growable: false);
  expect(failures, hasLength(1));
  expect(failures.single.toString(), contains('UNIQUE constraint failed'));
}

Future<int> _count(
  RitmoDatabase database,
  String table,
  String predicate, [
  List<Object> variables = const [],
]) async {
  final row = await database
      .customSelect(
        'SELECT count(*) AS count FROM $table WHERE $predicate',
        variables: variables.map(Variable<Object>.new).toList(),
      )
      .getSingle();
  return row.read<int>('count');
}

Future<void> _insertOpenDay(
  RitmoDatabase database,
  String operationalDate,
) {
  return database.customStatement(
    'INSERT INTO days '
    '(operational_date, base_result, effective_result) '
    "VALUES (?, 'unsealed', 'unsealed')",
    [operationalDate],
  );
}
