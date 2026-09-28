import '../../core/result.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/people/weekly_contact_suggestion.dart'
    show operationalWeekStart;
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';

/// Coordena a edição do ciclo ativo e o adiamento do convite de encerramento
/// (RF-06.13, RF-06.9, RF-06.17). A semana operacional vem do relógio oficial.
final class CycleController {
  CycleController(
    this._repository, {
    required Future<OperationalClock> Function() loadClock,
    this.onChanged,
    // `loadClock` compõe a API nomeada pública; `_loadClock` a mantém interna.
    // ignore: prefer_initializing_formals
  }) : _loadClock = loadClock;

  final CycleRepository _repository;
  final Future<OperationalClock> Function() _loadClock;
  final void Function()? onChanged;
  static const CycleClosurePolicy _closurePolicy = CycleClosurePolicy();

  int _idCounter = 0;

  /// Edita finalidade e período do ciclo ativo.
  Future<Result<void, RitmoFailure>> updatePurposeAndPeriod({
    required String cycleId,
    required String purposeText,
    required OperationalDate startDate,
    required OperationalDate endDate,
  }) => _run(
    () => _repository.updatePurposeAndPeriod(
      cycleId: cycleId,
      purposeText: purposeText,
      startDate: startDate,
      endDate: endDate,
    ),
  );

  /// Edita a competência e a data de um checkpoint do ciclo ativo.
  Future<Result<void, RitmoFailure>> updateCheckpoint({
    required String cycleId,
    required CheckpointEdit edit,
  }) => _run(() => _repository.updateCheckpoint(cycleId: cycleId, edit: edit));

  /// Grava a autoavaliação de um checkpoint na Revisão (RF-06.5, RF-06.6).
  /// Vincula-a opcionalmente à revisão que a originou (RD-22).
  Future<Result<void, RitmoFailure>> saveSelfEvaluation({
    required String checkpointId,
    required GartnerLevel level,
    String? weeklyReviewId,
    String? notes,
  }) async {
    try {
      final clock = await _loadClock();
      final micros = clock.nowInBusinessZone().microsecondsSinceEpoch;
      final result = await _repository.saveSelfEvaluation(
        newId: _nextId('checkpoint-eval', micros),
        checkpointId: checkpointId,
        level: level,
        weeklyReviewId: weeklyReviewId,
        notes: notes,
      );
      return result.fold(
        onSuccess: (_) {
          onChanged?.call();
          return const Result<void, RitmoFailure>.success(null);
        },
        onFailure: Result<void, RitmoFailure>.failure,
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  /// Adia o convite de Encerramento de Ciclo, marcando a semana operacional
  /// vigente como já convidada (RF-06.10, RF-06.17). Não envia push.
  Future<Result<void, RitmoFailure>> deferClosureInvite(String cycleId) async {
    try {
      final clock = await _loadClock();
      final weekStart = operationalWeekStart(clock.operationalDateNow());
      await _repository.recordInvite(cycleId: cycleId, weekStart: weekStart);
      onChanged?.call();
      return const Result<void, RitmoFailure>.success(null);
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  /// Conclui o Encerramento de Ciclo: grava as avaliações finais, arquiva o
  /// ciclo atual e ativa o novo (RF-06.11, RF-06.12, RF-06.14). Valida o novo
  /// ciclo antes de qualquer efeito.
  Future<Result<void, RitmoFailure>> completeClosure({
    required String closingCycleId,
    required List<FinalEvaluationDraft> finalEvaluations,
    required NewCycleDraft newCycle,
  }) async {
    final issue = _closurePolicy.validateNewCycle(newCycle);
    if (issue != null) {
      return Result<void, RitmoFailure>.failure(
        CycleViolation(
          code: 'new_cycle_invalid',
          message: _issueMessage(issue),
        ),
      );
    }

    try {
      final clock = await _loadClock();
      final micros = clock.nowInBusinessZone().microsecondsSinceEpoch;

      final evaluations = <FinalEvaluationRecord>[
        for (final draft in finalEvaluations)
          FinalEvaluationRecord(
            id: _nextId('checkpoint-eval', micros),
            checkpointId: draft.checkpointId,
            level: draft.level,
            notes: draft.notes,
          ),
      ];
      final newCycleId = _nextId('cycle', micros);
      final record = NewCycleRecord(
        id: newCycleId,
        name: newCycle.name,
        purposeText: newCycle.purposeText,
        startDate: newCycle.startDate,
        endDate: newCycle.endDate,
        checkpoints: <NewCheckpointRecord>[
          for (final checkpoint in newCycle.checkpoints)
            NewCheckpointRecord(
              id: _nextId('checkpoint', micros),
              competency: checkpoint.competency,
              date: checkpoint.date,
            ),
        ],
      );

      final result = await _repository.completeClosure(
        closingCycleId: closingCycleId,
        finalEvaluations: evaluations,
        newCycle: record,
      );
      return result.fold(
        onSuccess: (_) {
          onChanged?.call();
          return const Result<void, RitmoFailure>.success(null);
        },
        onFailure: Result<void, RitmoFailure>.failure,
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  String _issueMessage(NewCycleDraftIssue issue) => switch (issue) {
    NewCycleDraftIssue.emptyName => 'Informe o nome do novo ciclo.',
    NewCycleDraftIssue.emptyPurpose => 'Informe a finalidade do novo ciclo.',
    NewCycleDraftIssue.invalidPeriod =>
      'O início do período deve ser anterior ou igual ao fim.',
    NewCycleDraftIssue.noCheckpoints =>
      'O novo ciclo deve ter ao menos um checkpoint.',
    NewCycleDraftIssue.checkpointOutOfPeriod =>
      'Os checkpoints devem ficar dentro do período do ciclo.',
  };

  String _nextId(String prefix, int micros) =>
      '$prefix-$micros-${_idCounter++}';

  Future<Result<void, RitmoFailure>> _run(
    Future<Result<void, CycleViolation>> Function() operation,
  ) async {
    try {
      final result = await operation();
      return result.fold(
        onSuccess: (_) {
          onChanged?.call();
          return const Result<void, RitmoFailure>.success(null);
        },
        onFailure: Result<void, RitmoFailure>.failure,
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }
}
