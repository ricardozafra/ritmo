// Feature: ritmo, Property 26: Unicidade por chave lógica sob mudança de fuso
// e relógio
//
// Para qualquer sequência de reaberturas, avanços/recuos do relógio e mudanças
// do fuso do aparelho, o fuso oficial continua classificando as datas e cada
// chave lógica possui no máximo uma linha viva. Fechamentos já confirmados
// preservam um único `closed_at` no instante oficial.
//
// **Validates: Requirements RNF-04.3, RNF-04.4, RD-2**

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/boundary_observer.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/protocol_reconciler.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../generators/shared.dart';

typedef _ReopenStep = ({
  int dayOffset,
  int minuteOffset,
  DeviceZoneFixture deviceZone,
});

typedef _Scenario = ({
  OperationalDate activationDate,
  List<_ReopenStep> reopens,
});

final Generator<_Scenario> _anyScenario = any.simple(
  generate: (random, size) {
    var activation = anyOperationalDate(random, size).value;
    while (activation.weekday != DateTime.monday) {
      activation = activation.next;
    }
    final firstZone = anyDeviceZone(random, size).value;
    final secondZone = anyDeviceZone(random, size).value;
    final randomCount = 2 + random.nextInt(5);
    return (
      activationDate: activation,
      reopens: [
        (dayOffset: 0, minuteOffset: 9 * 60, deviceZone: firstZone),
        (dayOffset: 2, minuteOffset: 5, deviceZone: secondZone),
        for (var index = 0; index < randomCount; index++)
          (
            dayOffset: random.nextInt(9) - 1,
            minuteOffset:
                random.nextInt(361) -
                180 +
                (anyDeviceZone(random, size).value.clockMovedForward ? 60 : 0),
            deviceZone: anyDeviceZone(random, size).value,
          ),
      ],
    );
  },
  shrink: (scenario) sync* {
    final official = anyDeviceZone(Random(0), 0).value;
    final canonical = (
      activationDate: canonicalOperationalDate,
      reopens: <_ReopenStep>[
        (dayOffset: 0, minuteOffset: 9 * 60, deviceZone: official),
        (dayOffset: 2, minuteOffset: 5, deviceZone: official),
        (dayOffset: 0, minuteOffset: -30, deviceZone: official),
      ],
    );
    if (scenario != canonical) yield canonical;
  },
);

void main() {
  Glados<_Scenario>(_anyScenario, RitmoGlados.ci()).test(
    'Propriedade 26: Unicidade por chave lógica sob mudança de fuso e relógio',
    (_Scenario scenario) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      var instant = DateTime.utc(2000);
      var deviceZone = scenario.reopens.first.deviceZone;
      final clock = SystemOperationalClock(
        deviceInstant: () => instant,
        deviceOffset: (_) => deviceZone.offset,
        deviceZoneId: () => deviceZone.zoneId,
      );
      final officialClock = SystemOperationalClock(
        deviceInstant: () => instant,
      );
      var maxSeen = scenario.activationDate;

      try {
        await database.customStatement(
          'UPDATE settings SET activation_date = ? WHERE id = 1',
          [scenario.activationDate.iso],
        );
        await database.customStatement(
          'INSERT INTO contacts (id, name, created_at) '
          "VALUES ('contact-logical', 'Contato', 1)",
        );

        for (var index = 0; index < scenario.reopens.length; index++) {
          final step = scenario.reopens[index];
          deviceZone = step.deviceZone;
          instant = clock
              .operationalOpen(scenario.activationDate.addDays(step.dayOffset))
              .add(Duration(minutes: step.minuteOffset))
              .toUtc();

          final current = clock.operationalDateNow();
          expect(current, officialClock.operationalDateNow());
          expect(
            clock.deviceZoneDiverges,
            deviceZone.zoneId != kBusinessTimeZone,
          );

          if (current >= scenario.activationDate) {
            final materialized = await DayRepository(
              database,
            ).ensureDayMaterialized(current);
            expect(materialized.isSuccess, isTrue);
            if (current > maxSeen) maxSeen = current;
          }

          final service = BoundaryCrossingService(database, clock: clock);
          final observer = BoundaryObserver(clock, service, EditorRegistry());
          try {
            await observer.onResumed();
          } finally {
            await observer.dispose();
            await service.dispose();
          }

          await ProtocolReconciler(database).reconcileProtocols(from: current);
          await _repeatLogicalWrites(
            database,
            activation: scenario.activationDate,
            reopenIndex: index,
          );
          await _expectNoDuplicateLogicalKeys(database);
        }

        final expectedDates = <String>[];
        var cursor = scenario.activationDate;
        while (cursor <= maxSeen) {
          expectedDates.add(cursor.iso);
          cursor = cursor.next;
        }
        final days =
            await (database.select(database.days)..orderBy([
                  (row) => OrderingTerm(expression: row.operationalDate),
                ]))
                .get();
        expect(days.map((day) => day.operationalDate).toList(), expectedDates);
        for (final day in days.where(
          (row) => row.operationalDate.compareTo(maxSeen.iso) < 0,
        )) {
          final date = _parseDate(day.operationalDate);
          expect(
            day.closedAt,
            clock.operationalClose(date).millisecondsSinceEpoch,
            reason: 'closed_at de ${day.operationalDate}',
          );
        }
        await _expectNoDuplicateLogicalKeys(database);
      } finally {
        await database.close();
      }
    },
  );
}

Future<void> _repeatLogicalWrites(
  RitmoDatabase database, {
  required OperationalDate activation,
  required int reopenIndex,
}) async {
  await database.customStatement(
    'INSERT OR IGNORE INTO pillar_waivers '
    '(id, date, pillar, reason_text) VALUES (?, ?, ?, ?)',
    ['waiver-reopen-$reopenIndex', activation.iso, 'day', 'Motivo preservado'],
  );
  await database.customStatement(
    'INSERT OR IGNORE INTO weekly_contact_suggestions '
    '(week_start, contact_id, status, created_at) '
    "VALUES (?, 'contact-logical', 'pending', ?)",
    [activation.iso, reopenIndex + 1],
  );
  await database.customStatement(
    'INSERT OR IGNORE INTO weekly_reviews '
    "(id, week_start, state, created_at) VALUES (?, ?, 'draft', ?)",
    ['review-reopen-$reopenIndex', activation.iso, reopenIndex + 1],
  );
  await database.customStatement(
    'INSERT OR IGNORE INTO notification_plans '
    '(idempotency_key, kind, planned_at, state) '
    "VALUES (?, 'weekly_review_sunday', ?, 'planned')",
    ['review:${activation.iso}', reopenIndex + 1],
  );
}

Future<void> _expectNoDuplicateLogicalKeys(RitmoDatabase database) async {
  final checks = <String>[
    'SELECT operational_date FROM days GROUP BY operational_date '
        'HAVING count(*) > 1',
    'SELECT date FROM pillar_waivers WHERE revoked_at IS NULL GROUP BY date '
        'HAVING count(*) > 1',
    "SELECT generation_id FROM protocol_alarms WHERE state <> 'invalidated' "
        'GROUP BY generation_id HAVING count(*) > 1',
    'SELECT week_start, contact_id FROM weekly_contact_suggestions '
        'GROUP BY week_start, contact_id HAVING count(*) > 1',
    'SELECT week_start FROM weekly_reviews GROUP BY week_start '
        'HAVING count(*) > 1',
    'SELECT idempotency_key FROM notification_plans '
        'GROUP BY idempotency_key HAVING count(*) > 1',
  ];
  for (final query in checks) {
    expect(await database.customSelect(query).get(), isEmpty, reason: query);
  }

  expect(await _count(database, 'pillar_waivers', 'revoked_at IS NULL'), 1);
  expect(await _count(database, 'weekly_contact_suggestions', '1 = 1'), 1);
  expect(await _count(database, 'weekly_reviews', '1 = 1'), 1);
  expect(await _count(database, 'notification_plans', '1 = 1'), 1);
}

Future<int> _count(RitmoDatabase database, String table, String where) async {
  final row = await database
      .customSelect('SELECT count(*) AS total FROM $table WHERE $where')
      .getSingle();
  return row.read<int>('total');
}

OperationalDate _parseDate(String iso) {
  final parts = iso.split('-');
  return OperationalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
