// Feature: ritmo, Property 4: Invariante do bloco de Estudo
//
// Para qualquer sequência de comandos sobre blocos de Estudo, e para qualquer
// instante de retorno do aplicativo, todo `StudyBlock` persistido satisfaz
// `started_at <= block_deadline`, `ended_at == null` ou
// `started_at <= ended_at <= block_deadline`, mantém a `operational_date` de
// origem, e todo bloco órfão recebe `ended_at == block_deadline` sem qualquer
// evento de reconciliação manual.
//
// **Validates: Requirements RF-01.12, RF-01.14, RF-01.15, RF-01.22, RD-9,
// RD-10, RNF-04.5, RNF-04.6**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/study_block_repository.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

/// Origem imutável de um bloco: o que nunca pode ser reatribuído nem reescrito.
typedef _Origin = ({String date, int startedAt, int deadline});

void main() {
  Glados3<StudyBlockSequenceFixture, OperationalCalendar, OperationalDate>(
    anyStudyBlockSeq,
    anySettings,
    anyOperationalDate,
    RitmoGlados.ci(),
  ).test('Propriedade 4: invariante do bloco de Estudo', (
    StudyBlockSequenceFixture sequence,
    OperationalCalendar calendar,
    OperationalDate date,
  ) async {
    final location = ensureBusinessLocation();
    final clock = SystemOperationalClock(
      calendar: calendar,
      businessLocation: location,
    );
    final database = RitmoDatabase(NativeDatabase.memory());
    final origins = <String, _Origin>{};

    final next = date.next;
    final open = clock.operationalOpen(date);
    final deadline = clock.blockDeadline(date);
    final startInstant = _midpoint(open, deadline);
    final nextDeadline = clock.blockDeadline(next);
    final baseContext =
        'data ${date.iso}, fechamento ${calendar.dayCloseTime}, '
        'deadline ${calendar.nightEndTime}, '
        'sequência ${sequence.map((action) => action.name).join(' > ')}';

    try {
      final days = DayRepository(database, businessLocation: location);
      final blocks = StudyBlockRepository(database, clock: clock);
      final orphanCloser = OrphanBlockCloser(database);
      _success(await days.ensureDayMaterialized(date));
      _success(await days.ensureDayMaterialized(next));

      // RD-10: o modelo não tem estado, duração acumulada nem qualquer coluna
      // de reconciliação manual de timer.
      final columns =
          (await database.customSelect('PRAGMA table_info(study_blocks)').get())
              .map((row) => row.data['name'] as String)
              .toSet();
      expect(columns, {
        'id',
        'operational_date',
        'started_at',
        'block_deadline',
        'ended_at',
      }, reason: baseContext);

      /// Confere as invariantes sobre tudo que está persistido, em qualquer
      /// data, depois de cada passo (RD-9, RNF-04.6).
      Future<void> expectInvariants(String step) async {
        final rows = await database.select(database.studyBlocks).get();
        for (final row in rows) {
          final origin = origins[row.id];
          final context = '$baseContext / $step / bloco ${row.id}';

          expect(origin, isNotNull, reason: context);
          expect(row.operationalDate, origin!.date, reason: context);
          expect(row.startedAt, origin.startedAt, reason: context);
          expect(row.blockDeadline, origin.deadline, reason: context);
          expect(row.startedAt <= row.blockDeadline, isTrue, reason: context);

          final endedAt = row.endedAt;
          if (endedAt != null) {
            expect(endedAt >= row.startedAt, isTrue, reason: context);
            expect(endedAt <= row.blockDeadline, isTrue, reason: context);
          }
        }
      }

      /// Retorno do aplicativo: fecha silenciosamente apenas o que já venceu,
      /// exatamente no deadline persistido (RF-01.15, RF-01.22, RNF-04.5).
      Future<void> expectReturnAt(tz.TZDateTime at) async {
        final context = '$baseContext / retorno em $at';
        final before = await database.select(database.studyBlocks).get();
        final expired = before
            .where((row) => row.endedAt == null)
            .where((row) => row.blockDeadline <= at.millisecondsSinceEpoch)
            .map((row) => row.id)
            .toSet();

        final closed = await orphanCloser.closeExpired(now: at);
        final repeated = await orphanCloser.closeExpired(now: at);
        final after = await database.select(database.studyBlocks).get();

        expect(closed, expired.length, reason: context);
        expect(repeated, 0, reason: context);
        for (final row in after) {
          final wasOpen =
              before
                  .firstWhere((candidate) => candidate.id == row.id)
                  .endedAt ==
              null;
          if (expired.contains(row.id)) {
            expect(
              row.endedAt,
              row.blockDeadline,
              reason: '$context / ${row.id}',
            );
          } else if (wasOpen) {
            expect(row.endedAt, isNull, reason: '$context / ${row.id}');
          }
        }
        await expectInvariants('retorno em $at');
      }

      Future<void> startBlock(String id) async {
        final block = _success(
          await blocks.start(
            id: id,
            operationalDate: date,
            startedAt: startInstant,
          ),
        );
        origins[id] = (
          date: date.iso,
          startedAt: block.startedAt.millisecondsSinceEpoch,
          deadline: block.blockDeadline.millisecondsSinceEpoch,
        );
        expect(block.blockDeadline, deadline, reason: baseContext);
      }

      /// Bloco de controle em outra data: nada do que acontece na data gerada
      /// pode alcançar, fechar ou reatribuir a origem dele.
      final controlStart = _midpoint(clock.operationalOpen(next), nextDeadline);
      final control = _success(
        await blocks.start(
          id: 'control-next-day',
          operationalDate: next,
          startedAt: controlStart,
        ),
      );
      origins['control-next-day'] = (
        date: next.iso,
        startedAt: control.startedAt.millisecondsSinceEpoch,
        deadline: control.blockDeadline.millisecondsSinceEpoch,
      );

      // RF-01.12/RD-9: iniciar no deadline ou depois dele não persiste nada.
      final rowsBefore = await database.select(database.studyBlocks).get();
      for (final rejectedStart in <tz.TZDateTime>[
        deadline,
        deadline.add(const Duration(minutes: 1)),
      ]) {
        final rejected = await blocks.start(
          id: 'rejected-$rejectedStart',
          operationalDate: date,
          startedAt: rejectedStart,
        );
        expect(
          _failureCode(rejected),
          'study_deadline_reached',
          reason: '$baseContext / início em $rejectedStart',
        );
      }
      expect(
        (await database.select(database.studyBlocks).get()).length,
        rowsBefore.length,
        reason: baseContext,
      );
      await expectInvariants('antes da sequência');

      String? draftId;
      var counter = 0;
      for (final action in sequence) {
        switch (action) {
          case StudyAction.start:
          case StudyAction.restart:
            expect(draftId, isNull, reason: '$baseContext / ${action.name}');
            draftId = 'study-${counter++}';
            await startBlock(draftId);

          case StudyAction.complete:
            final id = draftId!;
            final at = _midpoint(startInstant, deadline);
            final ended = _success(await blocks.finish(id, at: at));
            expect(ended.endedAt, at, reason: '$baseContext / complete');
            draftId = null;

          case StudyAction.cancel:
          case StudyAction.replaceWithRecovery:
            // O bloco desvinculado é rascunho de cumprimento: é descartado sem
            // tocar em nenhuma outra data (RF-01.24, RF-01.29).
            final id = draftId ?? 'study-${counter - 1}';
            final removed = await (database.delete(
              database.studyBlocks,
            )..where((row) => row.id.equals(id))).go();
            expect(removed, 1, reason: '$baseContext / ${action.name}');
            origins.remove(id);
            draftId = null;

          case StudyAction.orphan:
            // Nenhuma ação: o bloco permanece aberto até o retorno seguinte.
            expect(draftId, isNotNull, reason: '$baseContext / orphan');

          case StudyAction.resumeAfterDeadline:
            await expectReturnAt(deadline.add(const Duration(minutes: 90)));
            draftId = null;
        }
        await expectInvariants(action.name);
      }

      // Qualquer instante de retorno: antes, sobre e depois de cada deadline.
      for (final at in <tz.TZDateTime>[
        open,
        startInstant,
        deadline.subtract(const Duration(milliseconds: 1)),
        deadline,
        deadline.add(const Duration(minutes: 90)),
        nextDeadline.add(const Duration(milliseconds: 1)),
      ]) {
        await expectReturnAt(at);
      }

      // Depois do último deadline nenhum bloco continua órfão e o controle
      // preservou a data em que foi iniciado.
      final finalRows = await database.select(database.studyBlocks).get();
      expect(
        finalRows.where((row) => row.endedAt == null),
        isEmpty,
        reason: baseContext,
      );
      final finalControl = await blocks.findById('control-next-day');
      expect(finalControl!.operationalDate, next, reason: baseContext);
      expect(finalControl.endedAt, nextDeadline, reason: baseContext);
    } finally {
      await database.close();
    }
  });
}

/// Instante intermediário alinhado ao milissegundo, a unidade persistida.
tz.TZDateTime _midpoint(tz.TZDateTime from, tz.TZDateTime to) =>
    from.add(Duration(milliseconds: to.difference(from).inMilliseconds ~/ 2));

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode<T>(Result<T, BusinessViolation> result) =>
    result.fold(onSuccess: (_) => null, onFailure: (failure) => failure.code);
