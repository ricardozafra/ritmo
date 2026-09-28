import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/boundary_crossing_service.dart';
import 'package:ritmo/app/boundary_observer.dart';
import 'package:ritmo/app/editor_registry.dart';
import 'package:ritmo/app/schedule_reconciler.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/study_block_repository.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

void main() {
  test(
    'reabertura recupera várias fronteiras em ordem e fecha órfão no deadline',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ritmo_missed_boundaries_',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}ritmo.sqlite',
      );
      final activation = OperationalDate(2026, 5, 4); // segunda-feira
      final reopenedOn = activation.addDays(5); // sábado operacional
      var currentInstant = DateTime.utc(2000);
      final clock = SystemOperationalClock(deviceInstant: () => currentInstant);
      final startedAt = clock
          .operationalOpen(activation)
          .add(const Duration(hours: 1));
      currentInstant = startedAt.toUtc();
      late int persistedDeadline;

      try {
        final firstSession = RitmoDatabase(NativeDatabase(file));
        try {
          final materialized = await DayRepository(
            firstSession,
          ).ensureDayMaterialized(activation);
          expect(materialized.isSuccess, isTrue);
          final started = await StudyBlockRepository(firstSession, clock: clock)
              .start(
                id: 'orphan-across-restart',
                operationalDate: activation,
                startedAt: startedAt,
              );
          expect(started.isSuccess, isTrue);
          final row =
              await (firstSession.select(
                    firstSession.studyBlocks,
                  )..where((block) => block.id.equals('orphan-across-restart')))
                  .getSingle();
          persistedDeadline = row.blockDeadline;
          expect(row.endedAt, isNull);
        } finally {
          await firstSession.close();
        }

        currentInstant = clock
            .operationalOpen(reopenedOn)
            .add(const Duration(hours: 1))
            .toUtc();
        final secondSession = RitmoDatabase(NativeDatabase(file));
        final schedule = _RecordingScheduleReconciler();
        final service = BoundaryCrossingService(
          secondSession,
          clock: clock,
          scheduleReconciler: schedule,
        );
        final observer = BoundaryObserver(clock, service, EditorRegistry());

        try {
          await observer.onResumed();

          final expectedDates = <OperationalDate>[];
          var cursor = activation;
          while (cursor < reopenedOn) {
            expectedDates.add(cursor);
            cursor = cursor.next;
          }
          expect(
            schedule.events.map((event) => event.closedDate).toList(),
            expectedDates,
            reason: 'cada commit deve respeitar a ordem operacional crescente',
          );
          expect(schedule.events.every((event) => event.closedNow), isTrue);

          final days =
              await (secondSession.select(secondSession.days)..orderBy([
                    (day) => OrderingTerm(expression: day.operationalDate),
                  ]))
                  .get();
          expect(
            days.map((day) => day.operationalDate).toList(),
            expectedDates.map((date) => date.iso).toList(),
          );
          final closureMultiplicity = await secondSession
              .customSelect(
                'SELECT operational_date, COUNT(*) AS row_count, '
                'COUNT(closed_at) AS closed_count '
                'FROM days GROUP BY operational_date '
                'ORDER BY operational_date',
              )
              .get();
          expect(closureMultiplicity, hasLength(expectedDates.length));
          for (var index = 0; index < days.length; index++) {
            final expectedClosedAt = clock
                .operationalClose(expectedDates[index])
                .millisecondsSinceEpoch;
            expect(
              days[index].closedAt,
              expectedClosedAt,
              reason: 'closed_at oficial de ${expectedDates[index].iso}',
            );
            expect(
              closureMultiplicity[index].read<int>('row_count'),
              1,
              reason: 'uma linha lógica para ${expectedDates[index].iso}',
            );
            expect(
              closureMultiplicity[index].read<int>('closed_count'),
              1,
              reason: 'um closed_at lógico para ${expectedDates[index].iso}',
            );
          }

          final recoveredBlock =
              await (secondSession.select(
                    secondSession.studyBlocks,
                  )..where((block) => block.id.equals('orphan-across-restart')))
                  .getSingle();
          expect(recoveredBlock.operationalDate, activation.iso);
          expect(recoveredBlock.blockDeadline, persistedDeadline);
          expect(recoveredBlock.endedAt, persistedDeadline);

          final firstClosedAt = <String, int?>{
            for (final day in days) day.operationalDate: day.closedAt,
          };
          final committedEvents = schedule.events.length;
          await observer.onResumed();

          final afterSecondResume =
              await (secondSession.select(secondSession.days)..orderBy([
                    (day) => OrderingTerm(expression: day.operationalDate),
                  ]))
                  .get();
          expect(
            <String, int?>{
              for (final day in afterSecondResume)
                day.operationalDate: day.closedAt,
            },
            firstClosedAt,
            reason: 'uma nova retomada não regrava nenhum closed_at',
          );
          expect(schedule.events, hasLength(committedEvents));
          expect(await service.pendingBoundaries(before: reopenedOn), isEmpty);
          final blockAfterSecondResume =
              await (secondSession.select(
                    secondSession.studyBlocks,
                  )..where((block) => block.id.equals('orphan-across-restart')))
                  .getSingle();
          expect(blockAfterSecondResume.operationalDate, activation.iso);
          expect(blockAfterSecondResume.endedAt, persistedDeadline);
        } finally {
          await observer.dispose();
          await service.dispose();
          await secondSession.close();
        }
      } finally {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      }
    },
  );
}

final class _RecordingScheduleReconciler implements ScheduleReconciler {
  final List<BoundaryCommittedEvent> events = [];

  @override
  Future<void> reconcileAfterBoundary(BoundaryCommittedEvent event) async {
    events.add(event);
  }
}
