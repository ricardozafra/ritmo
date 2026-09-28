// Feature: ritmo, Property 7: Congelamento é absorvente
//
// Para qualquer dia com `closed_at` preenchido e para qualquer Revisão Semanal
// `finalized`, todo comando ordinário de escrita é rejeitado e o estado
// persistido permanece idêntico byte a byte. As únicas mutações aceitas em dia
// encerrado são a aplicação e a remoção de feriado, que alteram exclusivamente
// `effective_result`, `mute_cause` e `previous_result`.
//
// **Validates: Requirements RF-01.27, RF-02.6, RF-02.27, RF-05.32, RF-08.23,
// RF-08.26**

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/db/guarded_writer.dart';
import 'package:ritmo/domain/day/day_state_machine.dart' as domain;
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

/// A propriedade quantifica somente estados que já alcançaram `closed_at`.
/// Estados abertos sorteados pelo gerador compartilhado são fechados sem
/// alterar sua classificação, preservando toda a variedade válida do fixture.
final Generator<DayStateFixture> anyFrozenDayState = any.simple(
  generate: (random, size) {
    final candidate = anyDayState(random, size).value;
    if (candidate.closedAt != null) return candidate;
    return (
      date: candidate.date,
      baseResult: candidate.baseResult,
      effectiveResult: candidate.effectiveResult,
      closedAt: canonicalCalendar
          .operationalClose(candidate.date)
          .toCivilDateTime(),
      sealTimestamp: candidate.sealTimestamp,
      muteCause: candidate.muteCause,
      previousResult: candidate.previousResult,
    );
  },
  shrink: (value) sync* {
    final canonical = anyDayState(Random(0), 0).value;
    final closedCanonical = (
      date: canonical.date,
      baseResult: canonical.baseResult,
      effectiveResult: canonical.effectiveResult,
      closedAt: canonicalCalendar
          .operationalClose(canonical.date)
          .toCivilDateTime(),
      sealTimestamp: canonical.sealTimestamp,
      muteCause: canonical.muteCause,
      previousResult: canonical.previousResult,
    );
    if (value != closedCanonical) yield closedCanonical;
  },
);

void main() {
  Glados2<DayStateFixture, UnicodeTextFixture>(
    anyFrozenDayState,
    anyUnicodeText,
    RitmoGlados.ci(),
  ).test('Propriedade 7: congelamento é absorvente', (
    DayStateFixture fixture,
    UnicodeTextFixture noteFixture,
  ) async {
    final day = _dayOf(fixture);
    final expectedUnchangedDay = _dayOf(fixture);
    final note = String.fromCharCodes(noteFixture.text.runes.take(50));
    final iso = fixture.date.iso;
    final context =
        'dia $iso, base ${fixture.baseResult.name}, '
        'efetivo ${fixture.effectiveResult.name}, '
        'mute ${fixture.muteCause?.name}, encerrado true';

    // 1. Domínio: em dia encerrado, todo comando ordinário é rejeitado com
    // motivo neutro e o estado presente permanece intacto (RF-01.27, RF-02.6).
    const machine = domain.DayStateMachine();
    final sealContext = domain.SealContext(
      isEligible: true,
      now: day.closedAt!,
    );
    final ordinary = <domain.DayCommand>[
      const domain.SealDay(),
      const domain.ReopenDay(),
      domain.CloseDay(day.closedAt!.add(const Duration(hours: 1))),
    ];
    for (final command in ordinary) {
      final result = machine.apply(day, command, sealContext);
      expect(result.isFailure, isTrue, reason: '$context / $command');
      expect(
        _violationCode(result),
        anyOf('day_closed', 'day_already_closed'),
        reason: '$context / $command',
      );
      _expectSameDay(day, expectedUnchangedDay, reason: '$context / $command');
    }

    final database = RitmoDatabase(NativeDatabase.memory());
    try {
      await _seedDay(database, fixture);
      await database.customStatement(
        'INSERT INTO pillar_entries (operational_date, pillar, workout_done, '
        "briefing_done) VALUES (?, 'morning', 1, 1)",
        [iso],
      );
      await database.customStatement(
        'INSERT INTO weekly_reviews (id, week_start, answer_fulfilled, state, '
        "created_at, finalized_at) VALUES ('review-1', ?, 'Cumpri', "
        "'finalized', 100, 120)",
        [iso],
      );

      final dayWriter = GuardedDayWriter(database);
      final reviewWriter = GuardedWriter(database);

      // 2. Persistência: a guarda diária decide pelo `closed_at` e nada mais.
      final beforeDayWrites = await _dump(database);
      final attempts = <String, TransactionalWrite<void>>{
        'inserir pilar': () => database.customStatement(
          'INSERT INTO pillar_entries (operational_date, pillar, toggle_on) '
          "VALUES (?, 'day', 1)",
          [iso],
        ),
        'editar nota': () => database.customStatement(
          'UPDATE pillar_entries SET note_text = ? WHERE operational_date = ? '
          "AND pillar = 'morning'",
          [note, iso],
        ),
        'remover pilar': () => database.customStatement(
          "DELETE FROM pillar_entries WHERE operational_date = ? AND pillar = 'morning'",
          [iso],
        ),
      };

      if (day.isFrozen) {
        for (final attempt in attempts.entries) {
          var invoked = false;
          final result = await dayWriter.write<void>(
            operationalDate: iso,
            write: () async {
              invoked = true;
              await attempt.value();
            },
          );

          expect(invoked, isFalse, reason: '$context / ${attempt.key}');
          expect(
            _violationCode(result),
            'day_closed',
            reason: '$context / ${attempt.key}',
          );
          expect(
            await _dump(database),
            beforeDayWrites,
            reason: '$context / ${attempt.key}',
          );
        }
      } else {
        // Contraprova: enquanto `closed_at` é nulo a mesma escrita passa, logo
        // a rejeição acima vem do congelamento e não da guarda em si.
        final result = await dayWriter.write<void>(
          operationalDate: iso,
          write: attempts['inserir pilar']!,
        );
        expect(result.isSuccess, isTrue, reason: context);
      }

      // 3. Revisão finalizada é igualmente absorvente (RF-08.23, RF-08.26).
      final beforeReviewWrite = await _dump(database);
      var reviewInvoked = false;
      final reviewResult = await reviewWriter.writeReview<void>(
        reviewId: 'review-1',
        write: () async {
          reviewInvoked = true;
          await database.customStatement(
            "UPDATE weekly_reviews SET answer_fulfilled = ?, state = 'draft', "
            "finalized_at = NULL WHERE id = 'review-1'",
            [note],
          );
        },
      );

      expect(reviewInvoked, isFalse, reason: context);
      expect(_violationCode(reviewResult), 'review_finalized', reason: context);
      expect(await _dump(database), beforeReviewWrite, reason: context);

      // 4. Única exceção em dia encerrado: reclassificação por feriado, restrita
      // a `effective_result`, `mute_cause` e `previous_result` (RF-05.32).
      if (day.isFrozen) {
        final reclassifier = HolidayReclassifier(database);
        final before = await _dump(database);
        final beforeDay = await _dayRow(database, iso);

        final result = fixture.muteCause == FixtureMuteCause.holiday
            ? await reclassifier.remove(iso)
            : await reclassifier.apply(iso);
        final afterDay = await _dayRow(database, iso);

        expect(result.isSuccess, isTrue, reason: context);
        const reclassifiable = {
          'effective_result',
          'mute_cause',
          'previous_result',
        };
        for (final column in beforeDay.keys) {
          if (reclassifiable.contains(column)) continue;
          expect(
            afterDay[column],
            beforeDay[column],
            reason: '$context / coluna $column',
          );
        }
        // Registros ordinários e a revisão permanecem intactos.
        const ordinaryTables = ['pillar_entries', 'weekly_reviews'];
        expect(
          _tablesOf(await _dump(database), ordinaryTables),
          _tablesOf(before, ordinaryTables),
          reason: context,
        );
      }
    } finally {
      await database.close();
    }
  });
}

domain.Day _dayOf(DayStateFixture fixture) => domain.Day(
  operationalDate: fixture.date,
  baseResult: _result(fixture.baseResult)!,
  effectiveResult: _result(fixture.effectiveResult)!,
  closedAt: _instant(fixture.closedAt),
  sealTimestamp: _instant(fixture.sealTimestamp),
  muteCause: switch (fixture.muteCause) {
    null => null,
    FixtureMuteCause.weekend => domain.MuteCause.weekend,
    FixtureMuteCause.holiday => domain.MuteCause.holiday,
  },
  previousResult: _result(fixture.previousResult),
);

domain.DayResult? _result(FixtureDayResult? value) => switch (value) {
  null => null,
  FixtureDayResult.sealed => domain.DayResult.sealed,
  FixtureDayResult.unsealed => domain.DayResult.unsealed,
  FixtureDayResult.mute => domain.DayResult.mute,
};

tz.TZDateTime? _instant(DateTime? value) =>
    value == null ? null : tz.TZDateTime.from(value, tz.UTC);

void _expectSameDay(domain.Day actual, domain.Day expected, {String? reason}) {
  expect(actual.operationalDate, expected.operationalDate, reason: reason);
  expect(actual.baseResult, expected.baseResult, reason: reason);
  expect(actual.effectiveResult, expected.effectiveResult, reason: reason);
  expect(actual.closedAt, expected.closedAt, reason: reason);
  expect(actual.sealTimestamp, expected.sealTimestamp, reason: reason);
  expect(actual.muteCause, expected.muteCause, reason: reason);
  expect(actual.previousResult, expected.previousResult, reason: reason);
}

String? _violationCode<T, F extends RitmoFailure>(Result<T, F> result) =>
    result.fold(onSuccess: (_) => null, onFailure: (failure) => failure.code);

Future<void> _seedDay(RitmoDatabase database, DayStateFixture fixture) {
  return database.customStatement(
    'INSERT INTO days (operational_date, base_result, effective_result, '
    'closed_at, seal_timestamp, mute_cause, previous_result) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      fixture.date.iso,
      fixture.baseResult.name,
      fixture.effectiveResult.name,
      fixture.closedAt?.millisecondsSinceEpoch,
      fixture.sealTimestamp?.millisecondsSinceEpoch,
      fixture.muteCause?.name,
      fixture.previousResult?.name,
    ],
  );
}

const List<String> _watchedTables = ['days', 'pillar_entries', 'weekly_reviews'];

const Map<String, String> _orderBy = {
  'days': 'operational_date',
  'pillar_entries': 'operational_date, pillar',
  'weekly_reviews': 'id',
};

/// Serialização canônica das tabelas observadas: qualquer mudança de valor,
/// linha ou coluna altera a string resultante.
Future<Map<String, String>> _dump(
  RitmoDatabase database, {
  List<String> tables = _watchedTables,
}) async {
  final dump = <String, String>{};
  for (final table in tables) {
    final rows = await database
        .customSelect('SELECT * FROM $table ORDER BY ${_orderBy[table]}')
        .get();
    dump[table] = rows
        .map((row) {
          final keys = row.data.keys.toList()..sort();
          return keys.map((key) => '$key=${row.data[key]}').join('|');
        })
        .join(';');
  }
  return dump;
}

Map<String, String> _tablesOf(Map<String, String> dump, List<String> tables) => {
  for (final table in tables) table: dump[table] ?? '',
};

Future<Map<String, Object?>> _dayRow(
  RitmoDatabase database,
  String operationalDate,
) async {
  final row = await database
      .customSelect(
        'SELECT * FROM days WHERE operational_date = ?',
        variables: [Variable.withString(operationalDate)],
      )
      .getSingle();
  return row.data;
}
