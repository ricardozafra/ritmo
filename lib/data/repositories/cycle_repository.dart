import 'package:drift/drift.dart';

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/time/operational_calendar.dart';
import '../db/database.dart' as db;

/// Ciclo ativo com seus checkpoints, para leitura e edição na Fase 3.
final class CycleWithCheckpoints {
  const CycleWithCheckpoints({required this.cycle, required this.checkpoints});

  final Cycle cycle;
  final List<Checkpoint> checkpoints;
}

/// Edição de um checkpoint existente (competência e data exata, RD-21).
final class CheckpointEdit {
  const CheckpointEdit({
    required this.id,
    required this.competency,
    required this.date,
  });

  final String id;
  final Competency competency;
  final OperationalDate date;
}

/// Avaliação final de um checkpoint gravada no Encerramento (RF-06.11). O [id]
/// já vem gerado pela camada de aplicação.
final class FinalEvaluationRecord {
  const FinalEvaluationRecord({
    required this.id,
    required this.checkpointId,
    required this.level,
    this.weeklyReviewId,
    this.notes,
  });

  final String id;
  final String checkpointId;
  final GartnerLevel level;
  final String? weeklyReviewId;
  final String? notes;
}

/// Checkpoint do novo ciclo, com identificador já gerado.
final class NewCheckpointRecord {
  const NewCheckpointRecord({
    required this.id,
    required this.competency,
    required this.date,
  });

  final String id;
  final Competency competency;
  final OperationalDate date;
}

/// Novo ciclo a ser ativado no Encerramento, com identificadores já gerados.
final class NewCycleRecord {
  const NewCycleRecord({
    required this.id,
    required this.name,
    required this.purposeText,
    required this.startDate,
    required this.endDate,
    required this.checkpoints,
  });

  final String id;
  final String name;
  final String purposeText;
  final OperationalDate startDate;
  final OperationalDate endDate;
  final List<NewCheckpointRecord> checkpoints;
}

/// Leitura e edição de ciclos, checkpoints e convites de encerramento (RF-06.9
/// a RF-06.14, RF-06.20, RD-20, RD-21).
///
/// Ciclos `archived` são read-only (RD-20): a edição é rejeitada com
/// `CycleViolation`. A tabela `cycle_closure_invites` (PK `{cycle_id,
/// week_start}`) limita o convite a um por semana operacional.
final class CycleRepository {
  CycleRepository(this._database, {LimitPolicy? limitPolicy})
    : _limitPolicy = limitPolicy ?? const LimitPolicy();

  final db.RitmoDatabase _database;
  final LimitPolicy _limitPolicy;

  /// Fluxo do ciclo ativo e seus checkpoints; nulo enquanto não houver ciclo
  /// ativo.
  Stream<CycleWithCheckpoints?> watchActive() => _database
      .customSelect(
        "SELECT id FROM cycles WHERE state = 'active' LIMIT 1",
        readsFrom: {_database.cycles, _database.checkpoints},
      )
      .watch()
      .asyncMap((_) => loadActive());

  /// Carrega o ciclo ativo e seus checkpoints, ou `null` quando não existe.
  Future<CycleWithCheckpoints?> loadActive() async {
    final cycleRow =
        await (_database.select(_database.cycles)
              ..where((row) => row.state.equals('active'))
              ..limit(1))
            .getSingleOrNull();
    if (cycleRow == null) return null;

    final checkpointRows =
        await (_database.select(_database.checkpoints)
              ..where((row) => row.cycleId.equals(cycleRow.id))
              ..orderBy([(row) => OrderingTerm(expression: row.date)]))
            .get();

    return CycleWithCheckpoints(
      cycle: _toCycle(cycleRow),
      checkpoints: List<Checkpoint>.unmodifiable(
        checkpointRows.map(_toCheckpoint),
      ),
    );
  }

  /// Atualiza finalidade e período do ciclo (RF-06.13). Rejeita ciclo arquivado
  /// (read-only), finalidade acima de 1000 runes e período com início após o
  /// fim.
  Future<Result<void, CycleViolation>> updatePurposeAndPeriod({
    required String cycleId,
    required String purposeText,
    required OperationalDate startDate,
    required OperationalDate endDate,
  }) {
    final purpose = _limitPolicy.clampRunes(
      purposeText,
      Limits.cyclePurposeMaxRunes,
    );
    if (purpose.exceeded) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'cycle_purpose_too_long',
            message: 'A finalidade excede o limite de 1000 caracteres.',
          ),
        ),
      );
    }
    if (endDate < startDate) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'cycle_period_invalid',
            message: 'O início do período deve ser anterior ou igual ao fim.',
          ),
        ),
      );
    }

    return _database.transaction(() async {
      final guard = await _assertActive(cycleId);
      if (guard case Failure<void, CycleViolation>(:final failure)) {
        return Result<void, CycleViolation>.failure(failure);
      }
      await (_database.update(
        _database.cycles,
      )..where((row) => row.id.equals(cycleId))).write(
        db.CyclesCompanion(
          purposeText: Value(purpose.value),
          startDate: Value(startDate.iso),
          endDate: Value(endDate.iso),
        ),
      );
      return const Result<void, CycleViolation>.success(null);
    });
  }

  /// Atualiza a competência e a data de um checkpoint existente (RF-06.13,
  /// RD-21). Preserva o identificador e, portanto, as avaliações associadas
  /// (RF-06.14).
  Future<Result<void, CycleViolation>> updateCheckpoint({
    required String cycleId,
    required CheckpointEdit edit,
  }) => _database.transaction(() async {
    final guard = await _assertActive(cycleId);
    if (guard case Failure<void, CycleViolation>(:final failure)) {
      return Result<void, CycleViolation>.failure(failure);
    }
    final changed =
        await (_database.update(_database.checkpoints)..where(
              (row) => row.id.equals(edit.id) & row.cycleId.equals(cycleId),
            ))
            .write(
              db.CheckpointsCompanion(
                competency: Value(_competencyWire(edit.competency)),
                date: Value(edit.date.iso),
              ),
            );
    if (changed != 1) {
      return const Result<void, CycleViolation>.failure(
        CycleViolation(
          code: 'checkpoint_not_found',
          message: 'O checkpoint informado não pertence ao ciclo ativo.',
        ),
      );
    }
    return const Result<void, CycleViolation>.success(null);
  });

  /// Verdadeiro quando já houve convite de encerramento para [cycleId] na
  /// semana operacional [weekStart].
  Future<bool> hasInviteForWeek({
    required String cycleId,
    required OperationalDate weekStart,
  }) async {
    final row =
        await (_database.select(_database.cycleClosureInvites)..where(
              (r) =>
                  r.cycleId.equals(cycleId) & r.weekStart.equals(weekStart.iso),
            ))
            .getSingleOrNull();
    return row != null;
  }

  /// Registra o convite da semana operacional [weekStart], marcando-a como já
  /// convidada. Idempotente: a PK `{cycle_id, week_start}` garante no máximo um
  /// convite por semana (RF-06.9, RF-06.17).
  Future<void> recordInvite({
    required String cycleId,
    required OperationalDate weekStart,
  }) => _database
      .into(_database.cycleClosureInvites)
      .insert(
        db.CycleClosureInvitesCompanion.insert(
          cycleId: cycleId,
          weekStart: weekStart.iso,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Autoavaliação persistida de um checkpoint, ou `null` quando ainda não há.
  ///
  /// Há no máximo uma autoavaliação por checkpoint; ela é atualizada em vez de
  /// duplicada.
  Future<CheckpointEvaluation?> findEvaluationForCheckpoint(
    String checkpointId,
  ) async {
    final row =
        await (_database.select(_database.checkpointEvals)
              ..where((r) => r.checkpointId.equals(checkpointId))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    final checkpoint = await (_database.select(
      _database.checkpoints,
    )..where((r) => r.id.equals(row.checkpointId))).getSingleOrNull();
    if (checkpoint == null) return null;
    return _toEvaluation(row, checkpoint);
  }

  /// Grava (ou atualiza) a autoavaliação de um checkpoint (RF-06.5, RF-06.6),
  /// opcionalmente vinculada à revisão que a originou (RD-22). Uma
  /// autoavaliação por checkpoint. [newId] é usado apenas na primeira gravação.
  Future<Result<void, CycleViolation>> saveSelfEvaluation({
    required String newId,
    required String checkpointId,
    required GartnerLevel level,
    String? weeklyReviewId,
    String? notes,
  }) {
    final notesClamp = notes == null
        ? null
        : _limitPolicy.clampRunes(notes, Limits.checkpointNotesMaxRunes);
    if (notesClamp != null && notesClamp.exceeded) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'checkpoint_notes_too_long',
            message: 'As notas excedem o limite de 2000 caracteres.',
          ),
        ),
      );
    }

    return _database.transaction(() async {
      final existing =
          await (_database.select(_database.checkpointEvals)
                ..where((r) => r.checkpointId.equals(checkpointId))
                ..limit(1))
              .getSingleOrNull();
      if (existing == null) {
        await _database
            .into(_database.checkpointEvals)
            .insert(
              db.CheckpointEvalsCompanion.insert(
                id: newId,
                checkpointId: checkpointId,
                gartnerLevel: level.wireValue,
                weeklyReviewId: Value(weeklyReviewId),
                notes: Value(notes),
              ),
            );
      } else {
        await (_database.update(
          _database.checkpointEvals,
        )..where((r) => r.id.equals(existing.id))).write(
          db.CheckpointEvalsCompanion(
            gartnerLevel: Value(level.wireValue),
            weeklyReviewId: Value(weeklyReviewId),
            notes: Value(notes),
          ),
        );
      }
      return const Result<void, CycleViolation>.success(null);
    });
  }

  /// Fluxo de todas as autoavaliações, unidas ao checkpoint (competência e
  /// data), ordenadas por data do checkpoint. Base da evolução por competência
  /// (RF-06.7).
  Stream<List<CheckpointEvaluation>> watchEvaluations() => _database
      .customSelect(
        'SELECT e.id AS eval_id, e.checkpoint_id, e.gartner_level, e.notes, '
        'c.competency, c.date '
        'FROM checkpoint_evals e '
        'JOIN checkpoints c ON c.id = e.checkpoint_id '
        'ORDER BY c.date ASC, e.id ASC',
        readsFrom: {_database.checkpointEvals, _database.checkpoints},
      )
      .watch()
      .map(
        (rows) => List<CheckpointEvaluation>.unmodifiable(
          rows.map(_toEvaluationFromJoin),
        ),
      );

  /// Conclui o Encerramento de Ciclo (RF-06.11, RF-06.12, RF-06.14, RD-20).
  ///
  /// Numa única transação: grava as avaliações finais do ciclo que está sendo
  /// encerrado (associadas por `checkpoint_id`, preservando o histórico),
  /// arquiva o ciclo ativo como read-only e ativa o novo ciclo com seus
  /// checkpoints. Arquivar antes de inserir respeita o índice único parcial
  /// `cycle_one_active`. Rejeita quando o ciclo informado não é mais o ativo.
  Future<Result<void, CycleViolation>> completeClosure({
    required String closingCycleId,
    required List<FinalEvaluationRecord> finalEvaluations,
    required NewCycleRecord newCycle,
  }) {
    final purpose = _limitPolicy.clampRunes(
      newCycle.purposeText,
      Limits.cyclePurposeMaxRunes,
    );
    if (purpose.exceeded) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'cycle_purpose_too_long',
            message: 'A finalidade excede o limite de 1000 caracteres.',
          ),
        ),
      );
    }
    if (newCycle.endDate < newCycle.startDate) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'cycle_period_invalid',
            message: 'O início do período deve ser anterior ou igual ao fim.',
          ),
        ),
      );
    }
    if (newCycle.checkpoints.isEmpty) {
      return Future.value(
        const Result.failure(
          CycleViolation(
            code: 'cycle_without_checkpoints',
            message: 'O novo ciclo deve ter ao menos um checkpoint.',
          ),
        ),
      );
    }

    for (final evaluation in finalEvaluations) {
      final notesClamp = evaluation.notes == null
          ? null
          : _limitPolicy.clampRunes(
              evaluation.notes!,
              Limits.checkpointNotesMaxRunes,
            );
      if (notesClamp != null && notesClamp.exceeded) {
        return Future.value(
          const Result.failure(
            CycleViolation(
              code: 'checkpoint_notes_too_long',
              message: 'As notas excedem o limite de 2000 caracteres.',
            ),
          ),
        );
      }
    }

    return _database.transaction(() async {
      final guard = await _assertActive(closingCycleId);
      if (guard case Failure<void, CycleViolation>(:final failure)) {
        return Result<void, CycleViolation>.failure(failure);
      }

      // 1. Avaliações finais do ciclo encerrado, por identificador do
      //    checkpoint (RF-06.14). Upsert idempotente por id da avaliação.
      for (final evaluation in finalEvaluations) {
        await _database
            .into(_database.checkpointEvals)
            .insert(
              db.CheckpointEvalsCompanion.insert(
                id: evaluation.id,
                checkpointId: evaluation.checkpointId,
                gartnerLevel: evaluation.level.wireValue,
                weeklyReviewId: Value(evaluation.weeklyReviewId),
                notes: Value(evaluation.notes),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      // 2. Arquiva o ciclo ativo antes de inserir o novo (índice
      //    cycle_one_active).
      await (_database.update(_database.cycles)
            ..where((row) => row.id.equals(closingCycleId)))
          .write(const db.CyclesCompanion(state: Value('archived')));

      // 3. Ativa o novo ciclo e seus checkpoints (RF-06.12).
      await _database
          .into(_database.cycles)
          .insert(
            db.CyclesCompanion.insert(
              id: newCycle.id,
              name: newCycle.name,
              purposeText: purpose.value,
              startDate: newCycle.startDate.iso,
              endDate: newCycle.endDate.iso,
              state: 'active',
            ),
          );
      for (final checkpoint in newCycle.checkpoints) {
        await _database
            .into(_database.checkpoints)
            .insert(
              db.CheckpointsCompanion.insert(
                id: checkpoint.id,
                cycleId: newCycle.id,
                competency: _competencyWire(checkpoint.competency),
                date: checkpoint.date.iso,
                status: 'pending',
              ),
            );
      }

      return const Result<void, CycleViolation>.success(null);
    });
  }

  Future<Result<void, CycleViolation>> _assertActive(String cycleId) async {
    final row = await (_database.select(
      _database.cycles,
    )..where((r) => r.id.equals(cycleId))).getSingleOrNull();
    if (row == null) {
      return const Result<void, CycleViolation>.failure(
        CycleViolation(
          code: 'cycle_not_found',
          message: 'O ciclo informado não existe.',
        ),
      );
    }
    if (row.state != 'active') {
      return const Result<void, CycleViolation>.failure(
        CycleViolation(
          code: 'cycle_archived',
          message: 'O ciclo arquivado está disponível somente para leitura.',
        ),
      );
    }
    return const Result<void, CycleViolation>.success(null);
  }

  Cycle _toCycle(db.Cycle row) => Cycle(
    id: row.id,
    name: row.name,
    purposeText: row.purposeText,
    startDate: _parseDate(row.startDate, 'cycles.start_date'),
    endDate: _parseDate(row.endDate, 'cycles.end_date'),
    state: switch (row.state) {
      'active' => CycleState.active,
      'archived' => CycleState.archived,
      _ => throw StateError(
        'Estado de ciclo persistido inválido: ${row.state}.',
      ),
    },
  );

  Checkpoint _toCheckpoint(db.Checkpoint row) => Checkpoint(
    id: row.id,
    cycleId: row.cycleId,
    competency: _competency(row.competency),
    date: _parseDate(row.date, 'checkpoints.date'),
    status: row.status,
  );

  Competency _competency(String value) => switch (value) {
    'ST' => Competency.st,
    'IN' => Competency.in_,
    'CA' => Competency.ca,
    _ => throw StateError('Competência persistida inválida: $value.'),
  };

  GartnerLevel _gartner(String value) {
    final level = GartnerLevel.fromWire(value);
    if (level == null) {
      throw StateError('Nível Gartner persistido inválido: $value.');
    }
    return level;
  }

  CheckpointEvaluation _toEvaluation(db.CheckpointEval row, db.Checkpoint cp) =>
      CheckpointEvaluation(
        id: row.id,
        checkpointId: row.checkpointId,
        competency: _competency(cp.competency),
        date: _parseDate(cp.date, 'checkpoints.date'),
        level: _gartner(row.gartnerLevel),
        notes: row.notes,
      );

  CheckpointEvaluation _toEvaluationFromJoin(QueryRow row) =>
      CheckpointEvaluation(
        id: row.read<String>('eval_id'),
        checkpointId: row.read<String>('checkpoint_id'),
        competency: _competency(row.read<String>('competency')),
        date: _parseDate(row.read<String>('date'), 'checkpoints.date'),
        level: _gartner(row.read<String>('gartner_level')),
        notes: row.readNullable<String>('notes'),
      );

  String _competencyWire(Competency competency) => switch (competency) {
    Competency.st => 'ST',
    Competency.in_ => 'IN',
    Competency.ca => 'CA',
  };

  OperationalDate _parseDate(String iso, String field) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw StateError('$field inválido: $iso.');
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
