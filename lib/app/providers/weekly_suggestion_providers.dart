import 'package:riverpod/riverpod.dart';

import '../../data/repositories/weekly_contact_suggestion_repository.dart';
import '../../domain/people/contact.dart';
import '../../domain/people/weekly_contact_suggestion.dart';
import '../../domain/time/operational_calendar.dart';
import '../controllers/weekly_suggestion_controller.dart';
import 'boundary_providers.dart';
import 'contact_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;
import 'ritmo_providers.dart' show ritmoCurrentOperationalDateProvider;

final weeklyContactSuggestionRepositoryProvider =
    Provider<WeeklyContactSuggestionRepository>(
      (ref) =>
          WeeklyContactSuggestionRepository(ref.watch(ritmoDatabaseProvider)),
    );

final weeklySuggestionProgressionProvider =
    Provider<WeeklySuggestionProgression>(
      (ref) => const WeeklySuggestionProgression(),
    );

final weeklySuggestionControllerProvider = Provider<WeeklySuggestionController>(
  (ref) => WeeklySuggestionController(
    ref.watch(weeklyContactSuggestionRepositoryProvider),
    ref.watch(contactRepositoryProvider),
    loadClock: () async =>
        (await ref.read(boundaryRuntimeProvider.future)).clock,
  ),
);

/// Segunda-feira operacional que nomeia a semana vigente (RF-07.5).
final currentWeekStartProvider = FutureProvider<OperationalDate>((ref) async {
  final today = await ref.watch(ritmoCurrentOperationalDateProvider.future);
  return operationalWeekStart(today);
});

/// Linhas persistidas da semana vigente.
final currentWeekSuggestionRowsProvider =
    StreamProvider<List<WeeklyContactSuggestion>>((ref) async* {
      final weekStart = await ref.watch(currentWeekStartProvider.future);
      yield* ref
          .watch(weeklyContactSuggestionRepositoryProvider)
          .watchWeek(weekStart);
    });

/// Sugestão vigente da semana, derivada da ordem semanal e das linhas
/// persistidas. Materializa preguiçosamente a primeira sugestão `pending`
/// quando ainda não há registro na semana, sem substituir uma já persistida.
final weeklySuggestionViewProvider = FutureProvider<WeeklySuggestionView>((
  ref,
) async {
  final weekStart = await ref.watch(currentWeekStartProvider.future);
  final orderedResult = ref.watch(contactWeeklyOrderProvider);
  if (orderedResult case AsyncError(:final error, :final stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  final ordered = orderedResult.value ?? const <Contact>[];

  // Materializa a sugestão vigente antes de projetar, tornando o pending
  // persistente e estável durante a semana.
  if (ordered.isNotEmpty) {
    await ref.read(weeklySuggestionControllerProvider).ensureCurrent();
  }

  final rows = await ref.watch(currentWeekSuggestionRowsProvider.future);
  final progression = ref.watch(weeklySuggestionProgressionProvider);
  return progression.project(
    weekStart: weekStart,
    orderedContacts: ordered,
    weekRows: rows,
  );
});
