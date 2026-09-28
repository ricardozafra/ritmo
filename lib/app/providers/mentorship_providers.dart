import 'package:riverpod/riverpod.dart';

import '../../data/repositories/mentorship_repository.dart';
import '../../domain/people/mentorship.dart';
import '../controllers/mentorship_controller.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;
import 'ritmo_providers.dart' show ritmoCurrentOperationalDateProvider;

final mentorshipRepositoryProvider = Provider<MentorshipRepository>(
  (ref) => MentorshipRepository(ref.watch(ritmoDatabaseProvider)),
);

final mentorshipProjectionProvider = Provider<MentorshipProjection>(
  (ref) => const MentorshipProjection(),
);

final mentorshipControllerProvider = Provider<MentorshipController>(
  (ref) => MentorshipController(ref.watch(mentorshipRepositoryProvider)),
);

/// Fluxo reativo dos cartões persistidos, ordenados por competência.
final mentorshipRowsProvider = StreamProvider<List<Mentorship>>(
  (ref) => ref.watch(mentorshipRepositoryProvider).watchAll(),
);

/// Cartões de mentoria já projetados com o alerta de recência relativo à data
/// operacional corrente. O badge é derivado da mesma âncora temporal do resto
/// do app (fronteira operacional), nunca do relógio do aparelho, e reage tanto
/// a edições quanto à virada da data operacional.
final mentorshipCardsProvider = FutureProvider<List<MentorshipCardView>>((
  ref,
) async {
  final today = await ref.watch(ritmoCurrentOperationalDateProvider.future);
  final mentorships = await ref.watch(mentorshipRowsProvider.future);
  final projection = ref.watch(mentorshipProjectionProvider);
  return projection.project(today: today, mentorships: mentorships);
});
