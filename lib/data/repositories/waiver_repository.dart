import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/day/eligible_day.dart';
import '../../domain/day/seal_eligibility.dart';
import '../../domain/day/waiver_policy.dart' as domain;
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';
import 'pillar_entries_repository.dart';

/// Persistência da dispensa de pilar e da sua revogação positiva.
///
/// A revogação por conclusão acontece em uma única transação: `revoked_at` e a
/// conclusão do pilar são gravados juntos, e o efeito da dispensa sobre selo e
/// recorrência desaparece no mesmo commit, porque ela deixa de ser a dispensa
/// ativa do dia (RF-02.24, RF-02.25, RD-26). Nada é apagado: a dispensa
/// revogada continua legível no histórico (RF-02.26, RF-02.28).
final class WaiverRepository {
  WaiverRepository(
    this._database, {
    GuardedDayWriter? writer,
    PillarEntriesRepository? pillars,
    tz.Location? businessLocation,
    domain.WaiverPolicy policy = const domain.WaiverPolicy(),
  }) : _writer = writer ?? GuardedDayWriter(_database),
       _pillars = pillars ?? PillarEntriesRepository(_database),
       _businessLocation = businessLocation ?? ensureBusinessLocation(),
       // `policy` é parte da API nomeada pública; `_policy` não pode substituí-lo.
       // ignore: prefer_initializing_formals
       _policy = policy;

  final db.RitmoDatabase _database;
  final GuardedDayWriter _writer;
  final PillarEntriesRepository _pillars;
  final tz.Location _businessLocation;
  final domain.WaiverPolicy _policy;

  /// Histórico completo da data, com as revogadas preservadas (RF-02.28).
  Future<List<domain.PillarWaiver>> historyFor(OperationalDate date) async {
    final rows =
        await (_database.select(_database.pillarWaivers)
              ..where((waiver) => waiver.date.equals(date.iso))
              ..orderBy([(waiver) => OrderingTerm(expression: waiver.rowId)]))
            .get();
    return rows.map(_asDomain).toList();
  }

  Future<domain.PillarWaiver?> activeWaiverFor(OperationalDate date) async {
    final row = await _readActiveRow(date);
    return row == null ? null : _asDomain(row);
  }

  /// Cria a dispensa da data em uma única transação guardada.
  ///
  /// O histórico persistido alimenta a política: dispensas revogadas não
  /// bloqueiam a nova dispensa ativa nem contam na recorrência, e permanecem no
  /// histórico do dia (RF-02.10, RF-02.25, RF-02.26, RF-02.28).
  Future<Result<domain.PillarWaiver, BusinessViolation>> create({
    required String id,
    required OperationalDate date,
    required Pillar pillar,
    required String reasonText,
    bool recurrenceConfirmed = false,
  }) async {
    try {
      final guarded = await _writer.write<domain.PillarWaiver>(
        operationalDate: date.iso,
        write: () => _create(
          id: id,
          date: date,
          pillar: pillar,
          reasonText: reasonText,
          recurrenceConfirmed: recurrenceConfirmed,
        ),
      );
      return guarded.fold(
        onSuccess: Result<domain.PillarWaiver, BusinessViolation>.success,
        onFailure: Result<domain.PillarWaiver, BusinessViolation>.failure,
      );
    } on _WaiverRejected catch (rejected) {
      return Result<domain.PillarWaiver, BusinessViolation>.failure(
        rejected.failure,
      );
    }
  }

  /// Retira a dispensa ativa e conclui o pilar na mesma transação.
  ///
  /// [completion] descreve a conclusão ordinária do pilar tal como o usuário a
  /// realizou; se ela não concluir o pilar, nada é gravado. A guarda diária
  /// roda dentro da transação e rejeita dia encerrado (RF-02.27, RD-26).
  Future<Result<domain.RevokeOutcome, BusinessViolation>> revokeForCompletion({
    required OperationalDate date,
    required Pillar pillar,
    required tz.TZDateTime at,
    required bool confirmed,
    required db.PillarEntriesCompanion completion,
  }) => _writeRevocation(
    date: date,
    pillar: pillar,
    at: at,
    confirmed: confirmed,
    complete: () => _completePillar(date, pillar, completion),
  );

  /// Retira a dispensa noturna e registra Recuperação no mesmo commit.
  ///
  /// Um bloco anteriormente ligado é desvinculado antes da exclusão e só é
  /// apagado quando também pertence à data operacional informada.
  Future<Result<domain.RevokeOutcome, BusinessViolation>> revokeForRecovery({
    required OperationalDate date,
    required tz.TZDateTime at,
    required bool confirmed,
    String? note,
  }) => _writeRevocation(
    date: date,
    pillar: Pillar.night,
    at: at,
    confirmed: confirmed,
    complete: () => _completeRecovery(date, note: note),
  );

  /// Retira a dispensa noturna ao concluir o Estudo ligado à mesma data.
  ///
  /// O instante persistido nunca ultrapassa o deadline do bloco. O vínculo e a
  /// data operacional existentes são preservados.
  Future<Result<domain.RevokeOutcome, BusinessViolation>>
  revokeForStudyCompletion({
    required OperationalDate date,
    required tz.TZDateTime at,
    required bool confirmed,
  }) => _writeRevocation(
    date: date,
    pillar: Pillar.night,
    at: at,
    confirmed: confirmed,
    complete: () => _completeStudy(date, at: at),
  );

  Future<Result<domain.RevokeOutcome, BusinessViolation>> _writeRevocation({
    required OperationalDate date,
    required Pillar pillar,
    required tz.TZDateTime at,
    required bool confirmed,
    required Future<void> Function() complete,
  }) async {
    try {
      final guarded = await _writer.write<domain.RevokeOutcome>(
        operationalDate: date.iso,
        write: () => _revoke(
          date: date,
          pillar: pillar,
          at: at,
          confirmed: confirmed,
          complete: complete,
        ),
      );
      return guarded.fold(
        onSuccess: Result<domain.RevokeOutcome, BusinessViolation>.success,
        onFailure: Result<domain.RevokeOutcome, BusinessViolation>.failure,
      );
    } on _WaiverRejected catch (rejected) {
      // A exceção atravessa a transação para desfazer escritas parciais.
      return Result<domain.RevokeOutcome, BusinessViolation>.failure(
        rejected.failure,
      );
    }
  }

  Future<domain.PillarWaiver> _create({
    required String id,
    required OperationalDate date,
    required Pillar pillar,
    required String reasonText,
    required bool recurrenceConfirmed,
  }) async {
    await _assertUnsealed(date);

    final decision = _policy.create(
      domain.CreateWaiver(
        id: id,
        date: date,
        pillar: pillar,
        reasonText: reasonText,
        recurrenceConfirmed: recurrenceConfirmed,
      ),
      domain.DayContext(
        waivers: await _readWaiversThrough(date),
        days: await _readTimelineThrough(date),
      ),
    );
    final created = switch (decision) {
      Success<domain.PillarWaiver, WaiverViolation>(:final value) => value,
      Failure<domain.PillarWaiver, WaiverViolation>(:final failure) =>
        throw _WaiverRejected(failure),
    };

    // O índice único parcial é a última barreira contra uma segunda ativa.
    await _database
        .into(_database.pillarWaivers)
        .insert(
          db.PillarWaiversCompanion.insert(
            id: created.id,
            date: created.date.iso,
            pillar: created.pillar.name,
            reasonText: created.reasonText,
            recurrenceConfirmed: Value(created.recurrenceConfirmed),
          ),
        );
    return created;
  }

  Future<domain.RevokeOutcome> _revoke({
    required OperationalDate date,
    required Pillar pillar,
    required tz.TZDateTime at,
    required bool confirmed,
    required Future<void> Function() complete,
  }) async {
    await _assertUnsealed(date);

    final activeRow = await _readActiveRow(date);
    if (activeRow == null) {
      throw const _WaiverRejected(
        WaiverViolation(
          code: 'waiver_not_active',
          message: 'Não há dispensa ativa nesta data operacional.',
        ),
      );
    }

    final active = _asDomain(activeRow);
    final decision = _policy.revokeForCompletion(
      active,
      domain.DayContext(activeWaiver: active),
      completing: pillar,
      at: at,
      confirmed: confirmed,
    );
    final outcome = switch (decision) {
      Success<domain.RevokeOutcome, WaiverViolation>(:final value) => value,
      Failure<domain.RevokeOutcome, WaiverViolation>(:final failure) =>
        throw _WaiverRejected(failure),
    };

    final revoked =
        await (_database.update(_database.pillarWaivers)..where(
              (waiver) =>
                  waiver.id.equals(active.id) & waiver.revokedAt.isNull(),
            ))
            .write(
              db.PillarWaiversCompanion(
                revokedAt: Value(at.millisecondsSinceEpoch),
              ),
            );
    if (revoked != 1) {
      throw const _WaiverRejected(
        WaiverViolation(
          code: 'waiver_not_active',
          message: 'Não há dispensa ativa nesta data operacional.',
        ),
      );
    }

    await complete();

    // Lido após a revogação: a conclusão precisa valer sem a dispensa.
    final status = await _pillars.statusForDate(date);
    if (!_completed(status, pillar)) {
      throw const _WaiverRejected(
        WaiverViolation(
          code: 'waiver_completion_incomplete',
          message: 'Conclua o pilar para retirar a dispensa.',
        ),
      );
    }

    return outcome;
  }

  Future<void> _completeRecovery(OperationalDate date, {String? note}) async {
    final night =
        await (_database.select(_database.pillarEntries)..where(
              (entry) =>
                  entry.operationalDate.equals(date.iso) &
                  entry.pillar.equals(Pillar.night.name),
            ))
            .getSingleOrNull();
    final blockId = night?.studyBlockId;

    await _completePillar(
      date,
      Pillar.night,
      db.PillarEntriesCompanion(
        nightKind: const Value('recovery'),
        recoveryNote: Value(note),
        studyBlockId: const Value(null),
      ),
    );

    if (blockId != null) {
      await (_database.delete(_database.studyBlocks)..where(
            (block) =>
                block.id.equals(blockId) &
                block.operationalDate.equals(date.iso),
          ))
          .go();
    }
  }

  Future<void> _completeStudy(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) async {
    final night =
        await (_database.select(_database.pillarEntries)..where(
              (entry) =>
                  entry.operationalDate.equals(date.iso) &
                  entry.pillar.equals(Pillar.night.name),
            ))
            .getSingleOrNull();
    final blockId = night?.studyBlockId;
    if (night?.nightKind != 'study' || blockId == null) {
      throw const _WaiverRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }

    final block =
        await (_database.select(_database.studyBlocks)..where(
              (row) =>
                  row.id.equals(blockId) & row.operationalDate.equals(date.iso),
            ))
            .getSingleOrNull();
    if (block == null || block.endedAt != null) {
      throw const _WaiverRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }

    final startedAt = tz.TZDateTime.fromMillisecondsSinceEpoch(
      _businessLocation,
      block.startedAt,
    );
    if (at.isBefore(startedAt)) {
      throw const _WaiverRejected(
        StudyBlockViolation(
          code: 'study_end_before_start',
          message: 'O fim do estudo não pode anteceder seu início.',
        ),
      );
    }

    final deadline = tz.TZDateTime.fromMillisecondsSinceEpoch(
      _businessLocation,
      block.blockDeadline,
    );
    final endedAt = at.isBefore(deadline) ? at : deadline;
    final ended =
        await (_database.update(_database.studyBlocks)..where(
              (row) =>
                  row.id.equals(blockId) &
                  row.operationalDate.equals(date.iso) &
                  row.endedAt.isNull(),
            ))
            .write(
              db.StudyBlocksCompanion(
                endedAt: Value(endedAt.millisecondsSinceEpoch),
              ),
            );
    if (ended != 1) {
      throw const _WaiverRejected(
        StudyBlockViolation(
          code: 'study_block_not_active',
          message: 'Não há estudo ativo neste dia.',
        ),
      );
    }
  }

  Future<void> _completePillar(
    OperationalDate date,
    Pillar pillar,
    db.PillarEntriesCompanion completion,
  ) async {
    Value<String?> changeInitiativeId = const Value.absent();
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
        changeInitiativeId = Value(activeInitiative?.id);
      }
    }

    await _database
        .into(_database.pillarEntries)
        .insert(
          db.PillarEntriesCompanion.insert(
            operationalDate: date.iso,
            pillar: pillar.name,
            changeInitiativeId: changeInitiativeId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final persistedCompletion = pillar == Pillar.day
        ? completion.copyWith(changeInitiativeId: const Value.absent())
        : completion;
    await (_database.update(_database.pillarEntries)..where(
          (entry) =>
              entry.operationalDate.equals(date.iso) &
              entry.pillar.equals(pillar.name),
        ))
        .write(persistedCompletion);
  }

  bool _completed(PillarStatus status, Pillar pillar) => switch (pillar) {
    Pillar.morning => status.morningCompleted,
    Pillar.day => status.dayCompleted,
    Pillar.night => status.nightCompleted,
  };

  /// Dia selado é somente leitura até a reabertura explícita (RF-02.4).
  ///
  /// O dia encerrado já foi rejeitado pela guarda diária desta transação
  /// (RF-02.27).
  Future<void> _assertUnsealed(OperationalDate date) async {
    final day = await (_database.select(
      _database.days,
    )..where((row) => row.operationalDate.equals(date.iso))).getSingle();
    if (day.effectiveResult == 'mute') {
      throw const _WaiverRejected(
        DayViolation(
          code: 'day_mute',
          message: 'Esta ação não está disponível para este dia.',
        ),
      );
    }
    if (day.baseResult == 'sealed') {
      throw const _WaiverRejected(
        DayViolation(
          code: 'day_sealed',
          message: 'Reabra o dia antes de alterar seus registros.',
        ),
      );
    }
  }

  Future<List<domain.PillarWaiver>> _readWaiversThrough(
    OperationalDate date,
  ) async {
    final rows = await (_database.select(
      _database.pillarWaivers,
    )..where((waiver) => waiver.date.isSmallerOrEqualValue(date.iso))).get();
    return rows.map(_asDomain).toList();
  }

  /// Projeção diária até a data, necessária para que a recorrência distinga
  /// dias úteis de dias `mute` (RF-02.12, RF-05.15).
  Future<List<EligibleDay>> _readTimelineThrough(OperationalDate date) async {
    final rows =
        await (_database.select(_database.days)..where(
              (row) => row.operationalDate.isSmallerOrEqualValue(date.iso),
            ))
            .get();
    return rows.map((row) {
      final parsed = _parseDate(row.operationalDate);
      final isMute = row.effectiveResult == 'mute';
      return EligibleDay(
        date: parsed,
        isWorkday: !parsed.isWeekend && !isMute,
        isClosed: row.closedAt != null,
        isSealed: row.baseResult == 'sealed',
        isMute: isMute,
      );
    }).toList();
  }

  Future<db.PillarWaiver?> _readActiveRow(OperationalDate date) =>
      (_database.select(_database.pillarWaivers)..where(
            (waiver) =>
                waiver.date.equals(date.iso) & waiver.revokedAt.isNull(),
          ))
          .getSingleOrNull();

  domain.PillarWaiver _asDomain(db.PillarWaiver row) => domain.PillarWaiver(
    id: row.id,
    date: _parseDate(row.date),
    pillar: _pillar(row.pillar),
    reasonText: row.reasonText,
    recurrenceConfirmed: row.recurrenceConfirmed,
    revokedAt: row.revokedAt == null
        ? null
        : tz.TZDateTime.fromMillisecondsSinceEpoch(
            _businessLocation,
            row.revokedAt!,
          ),
  );

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Pillar _pillar(String value) => switch (value) {
    'morning' => Pillar.morning,
    'day' => Pillar.day,
    'night' => Pillar.night,
    _ => throw StateError('Pilar persistido inválido: $value'),
  };
}

/// Rejeição de regra levada por exceção para desfazer a transação em curso.
final class _WaiverRejected implements Exception {
  const _WaiverRejected(this.failure);

  final BusinessViolation failure;
}
