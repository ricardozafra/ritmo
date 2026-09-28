// Feature: ritmo, Property 25: Transações são tudo ou nada
//
// Para cada operação atômica declarada e ponto de interrupção anterior ao
// commit, o banco retorna exatamente ao estado anterior. Interrupções após o
// commit preservam todos os efeitos, sem corromper texto ou metadados válidos.
//
// **Validates: Requirements RD-26, RNF-05.5, RNF-05.8**

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/data/repositories/waiver_repository.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

enum _AtomicOperation {
  dailyClose,
  boundarySnapshot,
  sealDay,
  protocolCreation,
  holidayRecalculation,
  waiverRevocation,
}

typedef _AtomicCase = ({
  OperationalDate activationDate,
  _AtomicOperation operation,
  String preservedText,
});

final Generator<_AtomicCase> _anyAtomicCase = any.simple(
  generate: (random, size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    return (
      activationDate: activation,
      operation: _AtomicOperation
          .values[random.nextInt(_AtomicOperation.values.length)],
      preservedText: 'texto-valido-${random.nextInt(1 << 31)}',
    );
  },
  shrink: (value) sync* {
    final canonical = (
      activationDate: canonicalOperationalDate,
      operation: _AtomicOperation.boundarySnapshot,
      preservedText: 'texto-valido-canonico',
    );
    if (value != canonical) yield canonical;
  },
);

void main() {
  Glados2<_AtomicCase, FailurePointFixture>(
    _anyAtomicCase,
    anyFailurePoint,
    RitmoGlados.ci(),
  ).test('Propriedade 25: Transações são tudo ou nada', (
    _AtomicCase atomicCase,
    FailurePointFixture failurePoint,
  ) async {
    final harness = _AtomicHarness(atomicCase);
    await harness.open();
    try {
      final before = await harness.dump();
      final protectedBefore = await harness.protectedManifest();
      await harness.installFailure(failurePoint);
      final context =
          '${atomicCase.operation.name}/${failurePoint.stage.name}/'
          '${failurePoint.writeIndex}/${atomicCase.activationDate.iso}';

      if (failurePoint.stage == FailureStage.afterCommit) {
        await harness.execute();
        // Simula a interrupção do chamador quando o commit já ficou visível.
        try {
          throw StateError('interrupção injetada após o commit');
        } on StateError {
          // O banco já confirmou a operação e não deve desfazê-la.
        }
        await harness.expectCommitted(reason: context);
        expect(await harness.dump(), isNot(before), reason: context);
      } else {
        await expectLater(harness.execute(), throwsA(anything));
        expect(await harness.dump(), before, reason: context);
      }

      expect(
        await harness.protectedManifest(),
        protectedBefore,
        reason: '$context/texto e metadados protegidos',
      );
    } finally {
      await harness.close();
    }
  });
}

final class _AtomicHarness {
  _AtomicHarness(this.atomicCase)
    : activation = atomicCase.activationDate,
      target = atomicCase.activationDate.next;

  final _AtomicCase atomicCase;
  final OperationalDate activation;
  final OperationalDate target;
  late final db.RitmoDatabase database;
  late final SystemOperationalClock clock;
  late DateTime _currentInstant;

  int get expectedClose =>
      clock.operationalClose(target).millisecondsSinceEpoch;
  int get operationAt => clock
      .operationalOpen(target)
      .add(const Duration(hours: 18))
      .millisecondsSinceEpoch;
  int get orphanDeadline => clock
      .operationalClose(target)
      .subtract(const Duration(hours: 1))
      .millisecondsSinceEpoch;

  Future<void> open() async {
    database = db.RitmoDatabase(NativeDatabase.memory());
    _currentInstant = DateTime.utc(2000);
    clock = SystemOperationalClock(deviceInstant: () => _currentInstant);
    _currentInstant = clock
        .operationalClose(target)
        .add(const Duration(minutes: 5))
        .toUtc();
    await database.customStatement(
      'UPDATE settings SET activation_date = ? WHERE id = 1',
      [activation.iso],
    );
    await database.customStatement(
      'INSERT INTO manifests '
      '(id, content_markdown, asset_version, first_copied_at, last_edited_at) '
      "VALUES ('manifest-protected', ?, 'v1', 10, 20)",
      [atomicCase.preservedText],
    );
    await _seedOperation();
  }

  Future<void> close() => database.close();

  List<String> get _writeTargets => switch (atomicCase.operation) {
    _AtomicOperation.dailyClose => const [
      'UPDATE OF closed_at ON days',
      'UPDATE OF ended_at ON study_blocks',
      'INSERT ON protocol_alarms',
    ],
    _AtomicOperation.boundarySnapshot => const [
      'INSERT ON pillar_entries',
      'UPDATE OF closed_at ON days',
      'UPDATE OF ended_at ON study_blocks',
      'INSERT ON protocol_alarms',
    ],
    _AtomicOperation.sealDay => const ['UPDATE OF base_result ON days'],
    _AtomicOperation.protocolCreation => const ['INSERT ON protocol_alarms'],
    _AtomicOperation.holidayRecalculation => const [
      'INSERT ON holidays',
      'UPDATE OF effective_result ON days',
      'UPDATE OF state ON protocol_alarms',
    ],
    _AtomicOperation.waiverRevocation => const [
      'UPDATE OF revoked_at ON pillar_waivers',
      'INSERT ON pillar_entries',
      'UPDATE OF toggle_on ON pillar_entries',
    ],
  };

  Future<void> installFailure(FailurePointFixture point) async {
    if (point.stage == FailureStage.afterCommit) return;
    final targets = _writeTargets;
    final index = switch (point.stage) {
      FailureStage.beforeWrite => point.writeIndex % targets.length,
      FailureStage.afterFirstWrite =>
        targets.length == 1 ? 0 : 1 + point.writeIndex % (targets.length - 1),
      FailureStage.beforeCommit => targets.length - 1,
      FailureStage.afterCommit => throw StateError('inalcançável'),
    };
    final timing = point.stage == FailureStage.beforeWrite ? 'BEFORE' : 'AFTER';
    await database.customStatement(
      'CREATE TRIGGER fail_atomic_operation $timing ${targets[index]} BEGIN '
      "SELECT RAISE(ABORT, 'falha transacional injetada'); END",
    );
  }

  Future<void> execute() async {
    switch (atomicCase.operation) {
      case _AtomicOperation.dailyClose:
      case _AtomicOperation.boundarySnapshot:
        final service = BoundaryCrossingService(database, clock: clock);
        try {
          await service.crossBoundary(
            target,
            snapshot: atomicCase.operation == _AtomicOperation.boundarySnapshot
                ? _AtomicSnapshot(database, target, atomicCase.preservedText)
                : null,
          );
        } finally {
          await service.dispose();
        }
      case _AtomicOperation.sealDay:
        _success(
          await DayRepository(database).sealDay(
            target,
            at: clock.toBusinessZone(
              DateTime.fromMillisecondsSinceEpoch(operationAt, isUtc: true),
            ),
          ),
        );
      case _AtomicOperation.protocolCreation:
        await ProtocolReconciler(database).reconcileProtocols(from: target);
      case _AtomicOperation.holidayRecalculation:
        final recalculation = HolidayRecalculation(database, clock: clock);
        try {
          _success(
            await recalculation.apply(
              target,
              reasonText: atomicCase.preservedText,
            ),
          );
        } finally {
          await recalculation.dispose();
        }
      case _AtomicOperation.waiverRevocation:
        _success(
          await WaiverRepository(database).revokeForCompletion(
            date: target,
            pillar: Pillar.day,
            at: clock.toBusinessZone(
              DateTime.fromMillisecondsSinceEpoch(operationAt, isUtc: true),
            ),
            confirmed: true,
            completion: const db.PillarEntriesCompanion(toggleOn: Value(true)),
          ),
        );
    }
  }

  Future<void> expectCommitted({required String reason}) async {
    final day = await (database.select(
      database.days,
    )..where((row) => row.operationalDate.equals(target.iso))).getSingle();
    switch (atomicCase.operation) {
      case _AtomicOperation.dailyClose:
      case _AtomicOperation.boundarySnapshot:
        expect(day.closedAt, expectedClose, reason: reason);
        final block = await (database.select(
          database.studyBlocks,
        )..where((row) => row.id.equals('orphan-atomic'))).getSingle();
        expect(block.endedAt, orphanDeadline, reason: reason);
        final protocols = await database.select(database.protocolAlarms).get();
        expect(protocols, hasLength(1), reason: reason);
        expect(protocols.single.state, 'pending', reason: reason);
        final snapshots = await _count(
          'pillar_entries',
          "operational_date = '${target.iso}' AND pillar = 'day'",
        );
        expect(
          snapshots,
          atomicCase.operation == _AtomicOperation.boundarySnapshot ? 1 : 0,
          reason: reason,
        );
      case _AtomicOperation.sealDay:
        expect(day.baseResult, 'sealed', reason: reason);
        expect(day.effectiveResult, 'sealed', reason: reason);
        expect(day.sealTimestamp, operationAt, reason: reason);
      case _AtomicOperation.protocolCreation:
        final protocols = await database.select(database.protocolAlarms).get();
        expect(protocols, hasLength(1), reason: reason);
        expect(protocols.single.sequenceLength, 2, reason: reason);
        expect(protocols.single.state, 'pending', reason: reason);
      case _AtomicOperation.holidayRecalculation:
        final holiday = await (database.select(
          database.holidays,
        )..where((row) => row.operationalDate.equals(target.iso))).getSingle();
        expect(holiday.active, isTrue, reason: reason);
        expect(day.effectiveResult, 'mute', reason: reason);
        expect(day.muteCause, 'holiday', reason: reason);
        final protocols = await database.select(database.protocolAlarms).get();
        expect(protocols.single.state, 'invalidated', reason: reason);
      case _AtomicOperation.waiverRevocation:
        final waiver = await (database.select(
          database.pillarWaivers,
        )..where((row) => row.id.equals('waiver-atomic'))).getSingle();
        expect(waiver.revokedAt, operationAt, reason: reason);
        final entry =
            await (database.select(database.pillarEntries)..where(
                  (row) =>
                      row.operationalDate.equals(target.iso) &
                      row.pillar.equals('day'),
                ))
                .getSingle();
        expect(entry.toggleOn, isTrue, reason: reason);
    }
  }

  Future<void> _seedOperation() async {
    switch (atomicCase.operation) {
      case _AtomicOperation.dailyClose:
      case _AtomicOperation.boundarySnapshot:
        await _insertDay(activation, closedAt: _closeOf(activation));
        await _insertDay(target);
        await database.customStatement(
          'INSERT INTO study_blocks '
          '(id, operational_date, started_at, block_deadline) '
          "VALUES ('orphan-atomic', ?, ?, ?)",
          [target.iso, orphanDeadline - 3600000, orphanDeadline],
        );
      case _AtomicOperation.sealDay:
        await _insertDay(target);
        await database.customStatement(
          'INSERT INTO pillar_entries '
          '(operational_date, pillar, workout_done, briefing_done) '
          "VALUES (?, 'morning', 1, 1)",
          [target.iso],
        );
        await database.customStatement(
          'INSERT INTO pillar_entries '
          '(operational_date, pillar, toggle_on) '
          "VALUES (?, 'day', 1)",
          [target.iso],
        );
        await database.customStatement(
          'INSERT INTO pillar_entries '
          '(operational_date, pillar, night_kind) '
          "VALUES (?, 'night', 'recovery')",
          [target.iso],
        );
      case _AtomicOperation.protocolCreation:
        await _insertDay(activation, closedAt: _closeOf(activation));
        await _insertDay(target, closedAt: _closeOf(target));
      case _AtomicOperation.holidayRecalculation:
        await _insertDay(activation, closedAt: _closeOf(activation));
        await _insertDay(target, closedAt: _closeOf(target));
        await ProtocolReconciler(database).reconcileProtocols(from: target);
      case _AtomicOperation.waiverRevocation:
        await _insertDay(target);
        await database.customStatement(
          'INSERT INTO pillar_waivers '
          '(id, date, pillar, reason_text) '
          "VALUES ('waiver-atomic', ?, 'day', ?)",
          [target.iso, atomicCase.preservedText],
        );
    }
  }

  Future<void> _insertDay(OperationalDate date, {int? closedAt}) =>
      database.customStatement(
        'INSERT INTO days '
        '(operational_date, base_result, effective_result, closed_at) '
        "VALUES (?, 'unsealed', 'unsealed', ?)",
        [date.iso, closedAt],
      );

  int _closeOf(OperationalDate date) =>
      clock.operationalClose(date).millisecondsSinceEpoch;

  Future<int> _count(String table, String where) async {
    final row = await database
        .customSelect('SELECT count(*) AS total FROM $table WHERE $where')
        .getSingle();
    return row.read<int>('total');
  }

  Future<String> protectedManifest() async {
    final row = await (database.select(
      database.manifests,
    )..where((entry) => entry.id.equals('manifest-protected'))).getSingle();
    return '${row.contentMarkdown}|${row.assetVersion}|'
        '${row.firstCopiedAt}|${row.lastEditedAt}';
  }

  Future<Map<String, String>> dump() async {
    const orderBy = <String, String>{
      'days': 'operational_date',
      'pillar_entries': 'operational_date, pillar',
      'pillar_waivers': 'id',
      'study_blocks': 'id',
      'protocol_alarms': 'id',
      'holidays': 'operational_date',
      'manifests': 'id',
    };
    final result = <String, String>{};
    for (final entry in orderBy.entries) {
      final rows = await database
          .customSelect('SELECT * FROM ${entry.key} ORDER BY ${entry.value}')
          .get();
      result[entry.key] = rows
          .map((row) {
            final keys = row.data.keys.toList()..sort();
            return keys.map((key) => '$key=${row.data[key]}').join('|');
          })
          .join(';');
    }
    return result;
  }
}

final class _AtomicSnapshot implements DayEditSnapshot {
  const _AtomicSnapshot(this.database, this.operationalDate, this.text);

  final db.RitmoDatabase database;
  @override
  final OperationalDate operationalDate;
  final String text;

  @override
  Future<void> persist() => database.customStatement(
    'INSERT INTO pillar_entries '
    '(operational_date, pillar, toggle_on, note_text) '
    "VALUES (?, 'day', 1, ?)",
    [operationalDate.iso, text],
  );
}

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Esperava sucesso, veio ${failure.code}: ${failure.message}',
  ),
);
