import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/seal_eligibility.dart';
import '../../domain/day/study_block.dart' as domain;
import '../../domain/time/night_window.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';

/// Comandos ordinários reversíveis disponíveis somente em `open/unsealed`.
///
/// Operações noturnas atualizam a entrada e o bloco na mesma transação. Um
/// bloco cancelado ou removido é rascunho de cumprimento e é descartado após
/// ser desvinculado, sem alterar ou inferir sua data operacional.
final class OpenDayCommandsRepository {
  OpenDayCommandsRepository(
    this._database, {
    OperationalClock? clock,
    GuardedDayWriter? writer,
  }) : _clock = clock ?? SystemOperationalClock(),
       _writer = writer ?? GuardedDayWriter(_database);

  final db.RitmoDatabase _database;
  final OperationalClock _clock;
  final GuardedDayWriter _writer;

  Future<Result<MorningEntry, BusinessViolation>> setWorkout(
    OperationalDate date, {
    required bool done,
    tz.TZDateTime? at,
  }) {
    if (done && at == null) {
      return Future.value(
        _failure(
          code: 'workout_instant_required',
          message: 'Informe o instante de conclusão do treino.',
        ),
      );
    }
    return _writeEntry(
      date,
      Pillar.morning,
      db.PillarEntriesCompanion(
        workoutDone: Value(done),
        workoutAt: Value(done ? at!.millisecondsSinceEpoch : null),
      ),
      () async => (await _entries(date)).morning!,
    );
  }

  Future<Result<MorningEntry, BusinessViolation>> setBriefing(
    OperationalDate date, {
    required bool done,
    BriefingCompletion? mode,
    tz.TZDateTime? at,
  }) {
    if (done && (mode == null || at == null)) {
      return Future.value(
        _failure(
          code: 'briefing_completion_required',
          message: 'Informe como e quando o briefing foi concluído.',
        ),
      );
    }
    return _writeEntry(
      date,
      Pillar.morning,
      db.PillarEntriesCompanion(
        briefingDone: Value(done),
        briefingMode: Value(done ? mode!.name : null),
        briefingAt: Value(done ? at!.millisecondsSinceEpoch : null),
      ),
      () async => (await _entries(date)).morning!,
    );
  }

  Future<Result<DayEntry, BusinessViolation>> setDayToggle(
    OperationalDate date, {
    required bool on,
  }) => _writeEntry(
    date,
    Pillar.day,
    db.PillarEntriesCompanion(toggleOn: Value(on)),
    () async => (await _entries(date)).day!,
  );

  Future<Result<DayEntry, BusinessViolation>> setDayNote(
    OperationalDate date, {
    String? note,
  }) => _writeEntry(
    date,
    Pillar.day,
    db.PillarEntriesCompanion(noteText: Value(note)),
    () async => (await _entries(date)).day!,
  );

  Future<Result<domain.StudyBlock, BusinessViolation>> startStudy({
    required String id,
    required OperationalDate date,
    required tz.TZDateTime startedAt,
  }) async {
    final candidate = domain.StudyBlock.start(
      id: id,
      operationalDate: date,
      startedAt: startedAt,
      blockDeadline: _clock.blockDeadline(date),
    );
    if (candidate case Failure<domain.StudyBlock, domain.StudyBlockViolation>(
      :final failure,
    )) {
      return Result.failure(failure);
    }
    final block =
        (candidate as Success<domain.StudyBlock, domain.StudyBlockViolation>)
            .value;

    return _writeOpenUnsealed(date, () async {
      final current = (await _entries(date)).night;
      await _clearNightAndDeleteBlock(date, current?.studyBlockId);
      await _database
          .into(_database.studyBlocks)
          .insert(
            db.StudyBlocksCompanion.insert(
              id: block.id,
              operationalDate: date.iso,
              startedAt: block.startedAt.millisecondsSinceEpoch,
              blockDeadline: block.blockDeadline.millisecondsSinceEpoch,
            ),
          );
      await _upsertEntry(
        date,
        Pillar.night,
        db.PillarEntriesCompanion(
          nightKind: const Value('study'),
          recoveryNote: const Value(null),
          studyBlockId: Value(block.id),
        ),
      );
      return block;
    });
  }

  Future<Result<domain.StudyBlock, BusinessViolation>> finishStudy(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) => _writeOpenUnsealed(date, () async {
    final night = (await _entries(date)).night;
    final blockId = night?.studyBlockId;
    if (night?.kind != NightKind.study || blockId == null) {
      throw const _CommandRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }
    final block = await _readBlock(blockId, date);
    if (block == null || !block.isOrphan) {
      throw const _CommandRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }
    final transition = block.endAt(at);
    if (transition case Failure<domain.StudyBlock, domain.StudyBlockViolation>(
      :final failure,
    )) {
      throw _CommandRejected(failure);
    }
    final ended =
        (transition as Success<domain.StudyBlock, domain.StudyBlockViolation>)
            .value;
    await (_database.update(_database.studyBlocks)..where(
          (row) =>
              row.id.equals(blockId) & row.operationalDate.equals(date.iso),
        ))
        .write(
          db.StudyBlocksCompanion(
            endedAt: Value(ended.endedAt!.millisecondsSinceEpoch),
          ),
        );
    return ended;
  });

  Future<Result<NightEntry, BusinessViolation>> cancelStudy(
    OperationalDate date,
  ) => _writeOpenUnsealed(date, () async {
    final night = (await _entries(date)).night;
    final blockId = night?.studyBlockId;
    if (night?.kind != NightKind.study || blockId == null) {
      throw const _CommandRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }
    final block = await _readBlock(blockId, date);
    if (block == null || !block.isOrphan) {
      throw const _CommandRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Somente um estudo ativo pode ser cancelado.',
        ),
      );
    }
    await _clearNightAndDeleteBlock(date, blockId);
    return (await _entries(date)).night!;
  });

  Future<Result<NightEntry, BusinessViolation>> chooseRecovery(
    OperationalDate date, {
    required tz.TZDateTime at,
    String? note,
  }) async {
    final window = NightWindow(_clock).evaluate(now: at, operationalDate: date);
    if (!window.allowsRecovery) {
      return _failure(
        code: 'night_window_closed',
        message: 'O dia já foi encerrado para registros noturnos.',
      );
    }
    return _writeOpenUnsealed(date, () async {
      final night = (await _entries(date)).night;
      await _clearNightAndDeleteBlock(date, night?.studyBlockId);
      await _upsertEntry(
        date,
        Pillar.night,
        db.PillarEntriesCompanion(
          nightKind: const Value('recovery'),
          recoveryNote: Value(note),
          studyBlockId: const Value(null),
        ),
      );
      return (await _entries(date)).night!;
    });
  }

  Future<Result<NightEntry, BusinessViolation>> removeNightChoice(
    OperationalDate date,
  ) => _writeOpenUnsealed(date, () async {
    final night = (await _entries(date)).night;
    await _clearNightAndDeleteBlock(date, night?.studyBlockId);
    return (await _entries(date)).night!;
  });

  Future<Result<T, BusinessViolation>> _writeEntry<T>(
    OperationalDate date,
    Pillar pillar,
    db.PillarEntriesCompanion changes,
    Future<T> Function() readBack,
  ) => _writeOpenUnsealed(date, () async {
    await _upsertEntry(date, pillar, changes);
    return readBack();
  });

  Future<Result<T, BusinessViolation>> _writeOpenUnsealed<T>(
    OperationalDate date,
    Future<T> Function() write,
  ) {
    return _database.transaction(() async {
      final day =
          await (_database.select(_database.days)
                ..where((row) => row.operationalDate.equals(date.iso)))
              .getSingleOrNull();
      if (day == null) {
        return _failure<T>(
          code: 'day_not_found',
          message: 'A data operacional informada não existe.',
        );
      }
      if (day.effectiveResult == 'mute') {
        return _failure<T>(
          code: 'day_mute',
          message: 'Esta ação não está disponível para este dia.',
        );
      }
      if (day.baseResult == 'sealed') {
        return _failure<T>(
          code: 'day_sealed',
          message: 'Reabra o dia antes de alterar seus registros.',
        );
      }

      final guard = await _writer.assertMutable(date.iso);
      if (guard case Failure<void, DayViolation>(:final failure)) {
        return Result<T, BusinessViolation>.failure(failure);
      }
      try {
        return Result<T, BusinessViolation>.success(await write());
      } on _CommandRejected catch (rejected) {
        return Result<T, BusinessViolation>.failure(rejected.failure);
      }
    });
  }

  Future<void> _upsertEntry(
    OperationalDate date,
    Pillar pillar,
    db.PillarEntriesCompanion changes,
  ) async {
    Value<String?> initiativeId = const Value.absent();
    if (pillar == Pillar.day) {
      final existing =
          await (_database.select(_database.pillarEntries)..where(
                (entry) =>
                    entry.operationalDate.equals(date.iso) &
                    entry.pillar.equals(Pillar.day.name),
              ))
              .getSingleOrNull();
      if (existing == null) {
        final activeInitiative =
            await (_database.select(_database.changeInitiatives)
                  ..where((initiative) => initiative.active.equals(true)))
                .getSingleOrNull();
        initiativeId = Value(activeInitiative?.id);
      }
    }

    await _database
        .into(_database.pillarEntries)
        .insert(
          db.PillarEntriesCompanion.insert(
            operationalDate: date.iso,
            pillar: pillar.name,
            changeInitiativeId: initiativeId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await (_database.update(_database.pillarEntries)..where(
          (entry) =>
              entry.operationalDate.equals(date.iso) &
              entry.pillar.equals(pillar.name),
        ))
        .write(changes);
  }

  Future<void> _clearNightAndDeleteBlock(
    OperationalDate date,
    String? blockId,
  ) async {
    await _upsertEntry(
      date,
      Pillar.night,
      const db.PillarEntriesCompanion(
        nightKind: Value(null),
        recoveryNote: Value(null),
        studyBlockId: Value(null),
      ),
    );
    if (blockId != null) {
      await (_database.delete(_database.studyBlocks)..where(
            (row) =>
                row.id.equals(blockId) & row.operationalDate.equals(date.iso),
          ))
          .go();
    }
  }

  Future<PillarEntriesSnapshot> _entries(OperationalDate date) async {
    final rows = await (_database.select(
      _database.pillarEntries,
    )..where((entry) => entry.operationalDate.equals(date.iso))).get();
    db.PillarEntry? find(Pillar pillar) {
      for (final row in rows) {
        if (row.pillar == pillar.name) return row;
      }
      return null;
    }

    final morning = find(Pillar.morning);
    final daily = find(Pillar.day);
    final night = find(Pillar.night);
    return PillarEntriesSnapshot(
      morning: morning == null
          ? null
          : MorningEntry(
              workoutDone: morning.workoutDone,
              briefingDone: morning.briefingDone,
              briefingMode: switch (morning.briefingMode) {
                'automatic' => BriefingCompletion.automatic,
                'manual' => BriefingCompletion.manual,
                _ => null,
              },
              workoutAt: _instant(morning.workoutAt),
              briefingAt: _instant(morning.briefingAt),
            ),
      day: daily == null
          ? null
          : DayEntry(
              toggleOn: daily.toggleOn,
              changeInitiativeId: daily.changeInitiativeId,
              note: daily.noteText,
              noteAudioId: daily.noteAudioId,
            ),
      night: night == null
          ? null
          : NightEntry(
              kind: switch (night.nightKind) {
                'study' => NightKind.study,
                'recovery' => NightKind.recovery,
                _ => null,
              },
              recoveryNote: night.recoveryNote,
              studyBlockId: night.studyBlockId,
            ),
    );
  }

  Future<domain.StudyBlock?> _readBlock(String id, OperationalDate date) async {
    final row =
        await (_database.select(_database.studyBlocks)..where(
              (block) =>
                  block.id.equals(id) & block.operationalDate.equals(date.iso),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return domain.StudyBlock(
      id: row.id,
      operationalDate: _parseDate(row.operationalDate),
      startedAt: _instant(row.startedAt)!,
      blockDeadline: _instant(row.blockDeadline)!,
      endedAt: _instant(row.endedAt),
    );
  }

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : tz.TZDateTime.fromMillisecondsSinceEpoch(
          _clock.businessLocation,
          millisecondsSinceEpoch,
        );

  Result<T, BusinessViolation> _failure<T>({
    required String code,
    required String message,
  }) => Result<T, BusinessViolation>.failure(
    DayViolation(code: code, message: message),
  );
}

final class _CommandRejected implements Exception {
  const _CommandRejected(this.failure);

  final BusinessViolation failure;
}
