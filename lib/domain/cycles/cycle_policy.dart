import '../time/operational_calendar.dart';

/// Estado persistido de um ciclo.
enum CycleState { active, archived }

/// Competência acompanhada por um checkpoint.
enum Competency { st, in_, ca }

/// Ciclo de desenvolvimento usado pelas regras puras de domínio.
final class Cycle {
  const Cycle({
    required this.id,
    required this.name,
    required this.purposeText,
    required this.startDate,
    required this.endDate,
    required this.state,
  });

  final String id;
  final String name;
  final String purposeText;
  final OperationalDate startDate;
  final OperationalDate endDate;
  final CycleState state;
}

/// Marco datado de uma competência pertencente a um ciclo.
final class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.cycleId,
    required this.competency,
    required this.date,
    required this.status,
  });

  final String id;
  final String cycleId;
  final Competency competency;
  final OperationalDate date;

  /// Valor persistido do status.
  ///
  /// O schema ainda não define um conjunto fechado de estados, por isso o
  /// domínio preserva o valor sem inventar uma enumeração nesta fase.
  final String status;
}

/// Regras derivadas de checkpoints, sem relógio, persistência ou efeitos.
final class CyclePolicy {
  const CyclePolicy();

  /// Retorna o checkpoint estritamente futuro mais próximo do ciclo ativo.
  ///
  /// Checkpoints de outros ciclos são ignorados. Empates de data são
  /// resolvidos por [Checkpoint.id], sem modificar a lista recebida.
  Checkpoint? nextFutureCheckpoint(
    Cycle cycle,
    List<Checkpoint> checkpoints,
    OperationalDate today,
  ) {
    if (cycle.state != CycleState.active) return null;

    Checkpoint? next;
    for (final checkpoint in checkpoints) {
      if (checkpoint.cycleId != cycle.id || checkpoint.date <= today) {
        continue;
      }

      final current = next;
      if (current == null ||
          checkpoint.date < current.date ||
          (checkpoint.date == current.date &&
              checkpoint.id.compareTo(current.id) < 0)) {
        next = checkpoint;
      }
    }
    return next;
  }

  /// Dias civis corridos entre [today] e um checkpoint futuro.
  ///
  /// [today] deve ser obtido no fuso oficial pela camada chamadora. Datas no
  /// presente ou no passado não produzem countdown vencido.
  int? countdownDays(Checkpoint? next, OperationalDate today) {
    if (next == null || next.date <= today) return null;

    final todayCivil = DateTime.utc(today.year, today.month, today.day);
    final checkpointCivil = DateTime.utc(
      next.date.year,
      next.date.month,
      next.date.day,
    );
    return checkpointCivil.difference(todayCivil).inDays;
  }

  /// Deriva o estado visual posterior ao último checkpoint de um ciclo ativo.
  ///
  /// Não arquiva o ciclo, não cria outro ciclo e não fabrica uma data quando o
  /// ciclo não possui checkpoints.
  bool awaitingClosure(
    Cycle cycle,
    List<Checkpoint> checkpoints,
    OperationalDate today,
  ) {
    if (cycle.state != CycleState.active) return false;

    OperationalDate? lastDate;
    for (final checkpoint in checkpoints) {
      if (checkpoint.cycleId != cycle.id) continue;
      final current = lastDate;
      if (current == null || checkpoint.date > current) {
        lastDate = checkpoint.date;
      }
    }

    return lastDate != null && today > lastDate;
  }

  /// Decide se o convite de Encerramento de Ciclo deve ser apresentado junto à
  /// Revisão Semanal (RF-06.9, RF-06.17).
  ///
  /// Verdadeiro somente quando o ciclo está visualmente "aguardando
  /// encerramento" ([awaitingClosure]) e ainda não houve convite nesta semana
  /// operacional ([alreadyInvitedThisWeek] falso). No máximo um convite por
  /// semana operacional; o adiamento apenas marca a semana como já convidada e
  /// nunca torna o convite obrigatório. Regra pura: a semana e o histórico de
  /// convites são resolvidos pela camada chamadora.
  bool shouldOfferClosureInvite(
    Cycle cycle,
    List<Checkpoint> checkpoints,
    OperationalDate today, {
    required bool alreadyInvitedThisWeek,
  }) {
    if (alreadyInvitedThisWeek) return false;
    return awaitingClosure(cycle, checkpoints, today);
  }
}

/// Nível Gartner de uma autoavaliação de competência (RF-06.6, RD-22).
enum GartnerLevel {
  bd('BD'),
  b('B'),
  i('I'),
  a('A'),
  e('E');

  const GartnerLevel(this.wireValue);

  /// Forma persistida na coluna `gartner_level`.
  final String wireValue;

  static GartnerLevel? fromWire(String value) {
    for (final level in values) {
      if (level.wireValue == value) return level;
    }
    return null;
  }
}

/// Avaliação final de um checkpoint do ciclo que está sendo encerrado
/// (RF-06.11). Fica associada ao checkpoint por identificador (RF-06.14).
final class FinalEvaluationDraft {
  const FinalEvaluationDraft({
    required this.checkpointId,
    required this.level,
    this.notes,
  });

  final String checkpointId;
  final GartnerLevel level;
  final String? notes;
}

/// Checkpoint do novo ciclo a ser criado no encerramento (RF-06.11).
final class NewCheckpointDraft {
  const NewCheckpointDraft({required this.competency, required this.date});

  final Competency competency;
  final OperationalDate date;
}

/// Campos do novo ciclo definidos no fluxo de Encerramento (RF-06.11, RF-06.12).
final class NewCycleDraft {
  const NewCycleDraft({
    required this.name,
    required this.purposeText,
    required this.startDate,
    required this.endDate,
    required this.checkpoints,
  });

  final String name;
  final String purposeText;
  final OperationalDate startDate;
  final OperationalDate endDate;
  final List<NewCheckpointDraft> checkpoints;
}

/// Motivo pelo qual um [NewCycleDraft] não pode iniciar um novo ciclo.
enum NewCycleDraftIssue {
  emptyName,
  emptyPurpose,
  invalidPeriod,
  noCheckpoints,
  checkpointOutOfPeriod,
}

/// Regras puras de validação do novo ciclo do Encerramento, sem relógio,
/// persistência ou efeitos.
final class CycleClosurePolicy {
  const CycleClosurePolicy();

  /// Valida o [draft] do novo ciclo. Retorna `null` quando aceito, ou o
  /// primeiro problema encontrado.
  ///
  /// Exige nome e finalidade não vazios (após aparar espaços), período com
  /// início anterior ou igual ao fim, ao menos um checkpoint e todos os
  /// checkpoints dentro do período `[startDate, endDate]`.
  NewCycleDraftIssue? validateNewCycle(NewCycleDraft draft) {
    if (draft.name.trim().isEmpty) return NewCycleDraftIssue.emptyName;
    if (draft.purposeText.trim().isEmpty) {
      return NewCycleDraftIssue.emptyPurpose;
    }
    if (draft.endDate < draft.startDate) {
      return NewCycleDraftIssue.invalidPeriod;
    }
    if (draft.checkpoints.isEmpty) return NewCycleDraftIssue.noCheckpoints;
    for (final checkpoint in draft.checkpoints) {
      if (checkpoint.date < draft.startDate ||
          checkpoint.date > draft.endDate) {
        return NewCycleDraftIssue.checkpointOutOfPeriod;
      }
    }
    return null;
  }
}

/// Autoavaliação persistida de uma competência, já associada ao checkpoint
/// (RF-06.5, RF-06.6, RD-22).
final class CheckpointEvaluation {
  const CheckpointEvaluation({
    required this.id,
    required this.checkpointId,
    required this.competency,
    required this.date,
    required this.level,
    this.notes,
  });

  final String id;
  final String checkpointId;
  final Competency competency;

  /// Data exata do checkpoint avaliado; ordena a evolução por competência.
  final OperationalDate date;
  final GartnerLevel level;
  final String? notes;
}

/// Evolução de uma competência: suas avaliações em ordem cronológica, sem
/// pontuação, ranking ou qualquer mecânica de recompensa (RF-06.7,
/// Restrição 6.1).
final class CompetencyEvolution {
  const CompetencyEvolution({
    required this.competency,
    required this.evaluations,
  });

  final Competency competency;

  /// Avaliações da competência, da mais antiga para a mais recente.
  final List<CheckpointEvaluation> evaluations;
}

/// Regras puras da autoavaliação e da evolução por competência (RF-06.5 a
/// RF-06.7). Sem relógio, persistência ou efeitos.
final class CheckpointEvaluationPolicy {
  const CheckpointEvaluationPolicy();

  /// Checkpoints do ciclo ativo cujo mês civil coincide com o de [reviewDate]
  /// (RF-06.5). A Revisão inclui a autoavaliação da competência somente para
  /// esses checkpoints.
  ///
  /// [reviewDate] é a data operacional que ancora a Revisão (a segunda-feira
  /// operacional `week_start`). A comparação é por ano e mês civis.
  List<Checkpoint> checkpointsForReviewMonth(
    List<Checkpoint> checkpoints,
    OperationalDate reviewDate,
  ) => <Checkpoint>[
    for (final checkpoint in checkpoints)
      if (checkpoint.date.year == reviewDate.year &&
          checkpoint.date.month == reviewDate.month)
        checkpoint,
  ];

  /// Agrupa [evaluations] por competência, cada grupo ordenado por data do
  /// checkpoint (mais antiga primeiro) e, em empate, por identificador estável.
  /// Retorna somente as competências que possuem ao menos uma avaliação, na
  /// ordem `ST, IN, CA`.
  List<CompetencyEvolution> evolutionByCompetency(
    List<CheckpointEvaluation> evaluations,
  ) {
    final grouped = <Competency, List<CheckpointEvaluation>>{};
    for (final evaluation in evaluations) {
      grouped
          .putIfAbsent(evaluation.competency, () => <CheckpointEvaluation>[])
          .add(evaluation);
    }
    final result = <CompetencyEvolution>[];
    for (final competency in Competency.values) {
      final group = grouped[competency];
      if (group == null || group.isEmpty) continue;
      group.sort((left, right) {
        final byDate = left.date.compareTo(right.date);
        return byDate != 0 ? byDate : left.id.compareTo(right.id);
      });
      result.add(
        CompetencyEvolution(
          competency: competency,
          evaluations: List<CheckpointEvaluation>.unmodifiable(group),
        ),
      );
    }
    return List<CompetencyEvolution>.unmodifiable(result);
  }
}
