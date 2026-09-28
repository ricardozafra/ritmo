// Feature: ritmo, Property 11: No máximo uma dispensa ativa, com histórico monotônico
//
// Para qualquer sequência de criações e revogações em um dia aberto, existe
// no máximo uma dispensa ativa, o histórico nunca encolhe e somente a ativa
// produz efeito sobre elegibilidade de selo e recorrência.
//
// **Validates: Requirements RF-02.10, RF-02.25, RF-02.26, RF-02.28, RD-11**

import 'dart:math';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/data/db/database.dart' as data;
import 'package:ritmo/domain/day/seal_eligibility.dart' as seal;
import 'package:ritmo/domain/day/waiver_policy.dart' as waiver;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

enum _WaiverAction { createMorning, createDay, createNight, revoke }

extension on _WaiverAction {
  seal.Pillar? get pillar => switch (this) {
    _WaiverAction.createMorning => seal.Pillar.morning,
    _WaiverAction.createDay => seal.Pillar.day,
    _WaiverAction.createNight => seal.Pillar.night,
    _WaiverAction.revoke => null,
  };
}

const List<_WaiverAction> _canonicalSequence = <_WaiverAction>[
  _WaiverAction.createMorning,
  _WaiverAction.createDay,
  _WaiverAction.revoke,
  _WaiverAction.createDay,
];

final Generator<List<_WaiverAction>> _anyWaiverSequence = any.simple(
  generate: (random, size) {
    if (random.nextInt(4) == 0) return List.of(_canonicalSequence);
    final length = 1 + random.nextInt(max(1, min(size + 1, 24)));
    return List.generate(
      length,
      (_) => _WaiverAction.values[random.nextInt(_WaiverAction.values.length)],
    );
  },
  shrink: (value) sync* {
    if (!_sameActions(value, _canonicalSequence)) {
      yield List.of(_canonicalSequence);
    }
  },
);

bool _sameActions(List<_WaiverAction> left, List<_WaiverAction> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

typedef _StoredWaiver = ({
  String id,
  seal.Pillar pillar,
  String reasonText,
  int? revokedAt,
});

seal.Pillar _parsePillar(String value) => switch (value) {
  'morning' => seal.Pillar.morning,
  'day' => seal.Pillar.day,
  'night' => seal.Pillar.night,
  _ => throw StateError('Pilar persistido inválido: $value'),
};

Future<Map<String, _StoredWaiver>> _readHistory(
  data.RitmoDatabase database,
  OperationalDate date,
) async {
  final rows = await database
      .customSelect(
        'SELECT id, pillar, reason_text, revoked_at FROM pillar_waivers '
        'WHERE date = ? ORDER BY rowid',
        variables: [Variable<String>(date.iso)],
      )
      .get();
  return <String, _StoredWaiver>{
    for (final row in rows)
      row.read<String>('id'): (
        id: row.read<String>('id'),
        pillar: _parsePillar(row.read<String>('pillar')),
        reasonText: row.read<String>('reason_text'),
        revokedAt: row.readNullable<int>('revoked_at'),
      ),
  };
}

Iterable<waiver.PillarWaiver> _asDomainHistory(
  Map<String, _StoredWaiver> history,
  OperationalDate date,
) => history.values.map(
  (stored) => waiver.PillarWaiver(
    id: stored.id,
    date: date,
    pillar: stored.pillar,
    reasonText: stored.reasonText,
    revokedAt: stored.revokedAt == null
        ? null
        : tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, stored.revokedAt!),
  ),
);

seal.PillarStatus _onlyPillarIncomplete(seal.Pillar pillar) =>
    seal.PillarStatus(
      morningCompleted: pillar != seal.Pillar.morning,
      dayCompleted: pillar != seal.Pillar.day,
      nightCompleted: pillar != seal.Pillar.night,
    );

void main() {
  Glados<List<_WaiverAction>>(_anyWaiverSequence, RitmoGlados.ci()).test(
    'Propriedade 11: no máximo uma dispensa ativa, com histórico monotônico',
    (actions) async {
      final database = data.RitmoDatabase(NativeDatabase.memory());
      final date = OperationalDate(2026, 3, 9);
      const policy = waiver.WaiverPolicy();
      var previousHistory = <String, _StoredWaiver>{};
      final everRevoked = <String>{};
      var createAttempt = 0;

      try {
        await database.customStatement(
          'INSERT INTO days '
          '(operational_date, base_result, effective_result) '
          "VALUES (?, 'unsealed', 'unsealed')",
          [date.iso],
        );

        for (var step = 0; step < actions.length; step++) {
          final action = actions[step];
          final before = await _readHistory(database, date);
          final activeBefore = before.values
              .where((stored) => stored.revokedAt == null)
              .toList();
          final canCreate = activeBefore.isEmpty;

          if (action.pillar case final pillar?) {
            createAttempt++;
            final id = 'waiver-$createAttempt';
            final reason = 'Motivo ${action.name}';
            final policyResult = policy.create(
              waiver.CreateWaiver(
                id: id,
                date: date,
                pillar: pillar,
                reasonText: reason,
              ),
              waiver.DayContext(waivers: _asDomainHistory(before, date)),
            );
            expect(
              policyResult.isSuccess,
              canCreate,
              reason: 'política divergente no passo $step: $actions',
            );

            final insertion = database.customStatement(
              'INSERT INTO pillar_waivers '
              '(id, date, pillar, reason_text) VALUES (?, ?, ?, ?)',
              [id, date.iso, pillar.name, reason],
            );
            if (canCreate) {
              await insertion;
            } else {
              await expectLater(insertion, throwsA(isA<Exception>()));
            }
          } else if (activeBefore.isNotEmpty) {
            await database.customStatement(
              'UPDATE pillar_waivers SET revoked_at = ? WHERE id = ?',
              [step + 1, activeBefore.single.id],
            );
          }

          final after = await _readHistory(database, date);
          final activeAfter = after.values
              .where((stored) => stored.revokedAt == null)
              .toList();
          final expectedTotal =
              before.length + (action.pillar != null && canCreate ? 1 : 0);
          final context = 'passo $step (${action.name}) de $actions';

          expect(activeAfter.length, lessThanOrEqualTo(1), reason: context);
          expect(after.length, expectedTotal, reason: context);
          expect(after.length, greaterThanOrEqualTo(previousHistory.length));
          expect(after.keys.toSet().containsAll(previousHistory.keys), isTrue);

          for (final previous in previousHistory.values) {
            final retained = after[previous.id];
            expect(retained, isNotNull, reason: context);
            expect(retained!.pillar, previous.pillar, reason: context);
            expect(retained.reasonText, previous.reasonText, reason: context);
            if (previous.revokedAt != null) {
              expect(retained.revokedAt, previous.revokedAt, reason: context);
            }
          }

          everRevoked.addAll(
            after.values
                .where((stored) => stored.revokedAt != null)
                .map((stored) => stored.id),
          );
          expect(
            everRevoked.every((id) => after[id]?.revokedAt != null),
            isTrue,
            reason: context,
          );

          final active = activeAfter.isEmpty ? null : activeAfter.single;
          final activeForSeal = active == null
              ? null
              : seal.PillarWaiver(pillar: active.pillar);
          for (final missing in seal.Pillar.values) {
            expect(
              seal.sealEligible(_onlyPillarIncomplete(missing), activeForSeal),
              active?.pillar == missing,
              reason: '$context; pilar incompleto ${missing.name}',
            );
          }

          final domainHistory = _asDomainHistory(after, date).toList();
          final recurrenceEffect = domainHistory.where((item) => item.isActive);
          expect(recurrenceEffect.length, activeAfter.length, reason: context);
          expect(
            recurrenceEffect.map((item) => item.id).toSet(),
            activeAfter.map((item) => item.id).toSet(),
            reason: context,
          );
          expect(
            waiver.DayContext(waivers: domainHistory).hasActiveWaiverOn(date),
            active != null,
            reason: context,
          );

          previousHistory = after;
        }
      } finally {
        await database.close();
      }
    },
  );
}
