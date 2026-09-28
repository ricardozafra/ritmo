import 'package:riverpod/riverpod.dart';

import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../controllers/cycle_controller.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;
import 'weekly_suggestion_providers.dart' show currentWeekStartProvider;

final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => CycleRepository(ref.watch(ritmoDatabaseProvider)),
);

final cyclePolicyProvider = Provider<CyclePolicy>((ref) => const CyclePolicy());

final checkpointEvaluationPolicyProvider = Provider<CheckpointEvaluationPolicy>(
  (ref) => const CheckpointEvaluationPolicy(),
);

final cycleControllerProvider = Provider<CycleController>(
  (ref) => CycleController(
    ref.watch(cycleRepositoryProvider),
    loadClock: () async =>
        (await ref.read(boundaryRuntimeProvider.future)).clock,
  ),
);

/// Ciclo ativo e seus checkpoints; nulo enquanto não houver ciclo ativo.
final activeCycleProvider = StreamProvider<CycleWithCheckpoints?>(
  (ref) => ref.watch(cycleRepositoryProvider).watchActive(),
);

/// Decisão do convite de Encerramento de Ciclo para a Revisão da semana
/// vigente (RF-06.9, RF-06.17). Devolve o ciclo elegível quando o convite deve
/// ser oferecido, ou `null` quando não deve.
final cycleClosureInviteProvider = FutureProvider<CycleWithCheckpoints?>((
  ref,
) async {
  final active = await ref.watch(activeCycleProvider.future);
  if (active == null) return null;

  final today = (await ref.watch(
    boundaryRuntimeProvider.future,
  )).clock.operationalDateNow();
  final weekStart = await ref.watch(currentWeekStartProvider.future);
  final alreadyInvited = await ref
      .watch(cycleRepositoryProvider)
      .hasInviteForWeek(cycleId: active.cycle.id, weekStart: weekStart);

  final shouldOffer = ref
      .watch(cyclePolicyProvider)
      .shouldOfferClosureInvite(
        active.cycle,
        active.checkpoints,
        today,
        alreadyInvitedThisWeek: alreadyInvited,
      );
  return shouldOffer ? active : null;
});

/// Checkpoints do ciclo ativo cujo mês civil coincide com o da Revisão da
/// semana vigente (RF-06.5). Vazio quando não há autoavaliação a incluir.
final reviewMonthCheckpointsProvider = FutureProvider<List<Checkpoint>>((
  ref,
) async {
  final active = await ref.watch(activeCycleProvider.future);
  if (active == null) return const <Checkpoint>[];
  final weekStart = await ref.watch(currentWeekStartProvider.future);
  return ref
      .watch(checkpointEvaluationPolicyProvider)
      .checkpointsForReviewMonth(active.checkpoints, weekStart);
});

/// Autoavaliação persistida de um checkpoint, para prefill do formulário.
final checkpointEvaluationProvider =
    FutureProvider.family<CheckpointEvaluation?, String>(
      (ref, checkpointId) => ref
          .watch(cycleRepositoryProvider)
          .findEvaluationForCheckpoint(checkpointId),
    );

/// Evolução por competência a partir de todas as autoavaliações (RF-06.7).
final competencyEvolutionProvider = StreamProvider<List<CompetencyEvolution>>((
  ref,
) {
  final policy = ref.watch(checkpointEvaluationPolicyProvider);
  return ref
      .watch(cycleRepositoryProvider)
      .watchEvaluations()
      .map(policy.evolutionByCompetency);
});
