import 'package:riverpod/riverpod.dart';

import '../../data/repositories/weekly_review_repository.dart';
import '../../domain/review/weekly_review.dart';
import '../controllers/weekly_review_controller.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;
import 'weekly_suggestion_providers.dart' show currentWeekStartProvider;

final weeklyReviewRepositoryProvider = Provider<WeeklyReviewRepository>(
  (ref) => WeeklyReviewRepository(ref.watch(ritmoDatabaseProvider)),
);

final weeklyReviewControllerProvider = Provider<WeeklyReviewController>(
  (ref) => WeeklyReviewController(
    ref.watch(weeklyReviewRepositoryProvider),
    loadClock: () async =>
        (await ref.read(boundaryRuntimeProvider.future)).clock,
  ),
);

/// Revisão da semana operacional vigente; nula enquanto não houver draft.
final currentWeeklyReviewProvider = StreamProvider<WeeklyReview?>((ref) async* {
  final weekStart = await ref.watch(currentWeekStartProvider.future);
  yield* ref.watch(weeklyReviewRepositoryProvider).watchWeek(weekStart);
});

/// Histórico cronológico de revisões (RF-08.19), da mais recente à mais antiga.
final weeklyReviewHistoryProvider = StreamProvider<List<WeeklyReview>>(
  (ref) => ref.watch(weeklyReviewRepositoryProvider).watchHistory(),
);

/// Detalhe read-only de uma revisão por identificador.
final weeklyReviewByIdProvider = StreamProvider.family<WeeklyReview?, String>(
  (ref, id) => ref.watch(weeklyReviewRepositoryProvider).watchById(id),
);
