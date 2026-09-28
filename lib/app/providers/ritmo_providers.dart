import 'package:riverpod/riverpod.dart';

import '../../data/repositories/ritmo_repository.dart';
import '../../domain/time/operational_calendar.dart';
import '../ritmo/ritmo_projection.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart';

final ritmoRepositoryProvider = Provider<RitmoRepository>(
  (ref) => RitmoRepository(ref.watch(ritmoDatabaseProvider)),
);

final ritmoProjectionProvider = Provider<RitmoProjection>(
  (ref) => const RitmoProjection(),
);

final ritmoCurrentOperationalDateProvider = FutureProvider<OperationalDate>((
  ref,
) async {
  final boundaryRevision = ref.watch(boundaryRevisionProvider);
  if (boundaryRevision case AsyncError(:final error, :final stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }

  final runtime = await ref.watch(boundaryRuntimeProvider.future);
  return runtime.clock.operationalDateNow();
});

final ritmoMonthProvider = StreamProvider.family<RitmoMonthView, RitmoMonth>((
  ref,
  month,
) {
  final projection = ref.watch(ritmoProjectionProvider);
  return ref
      .watch(ritmoRepositoryProvider)
      .watchMonth(month.firstDay)
      .map((days) => projection.projectMonth(month: month, days: days));
});

final ritmoDayDetailProvider =
    StreamProvider.family<RitmoDayDetailView?, OperationalDate>((ref, date) {
      final projection = ref.watch(ritmoProjectionProvider);
      return ref
          .watch(ritmoRepositoryProvider)
          .watchDay(date)
          .map((day) => day == null ? null : projection.projectDay(day));
    });
