import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../core/result.dart';
import '../../data/repositories/day_repository.dart';
import '../../data/repositories/study_block_repository.dart';
import '../../data/repositories/today_repository.dart';
import '../../domain/day/today_view.dart';
import '../controllers/today_controller.dart';
import '../today/today_note_editor.dart';
import '../today/today_projection.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => TodayRepository(ref.watch(ritmoDatabaseProvider)),
);

final todayNoteEditorFactoryProvider = Provider<TodayNoteEditorFactory>(
  (ref) => TodayNoteEditorFactory(ref.watch(ritmoDatabaseProvider)),
);

final todayChangesProvider = StreamProvider<void>(
  (ref) => ref.watch(todayRepositoryProvider).watchChanges(),
);

final todayControllerProvider = Provider<TodayController>(
  (ref) => TodayController(
    ref.watch(ritmoDatabaseProvider),
    ref.watch(todayRepositoryProvider),
    withClock: (operation) async {
      final runtime = await ref.read(boundaryRuntimeProvider.future);
      return runtime.runWithClock(operation);
    },
    onChanged: () => ref.invalidate(todayViewProvider),
  ),
);

final todayViewProvider = FutureProvider<TodayView>((ref) async {
  final database = ref.watch(ritmoDatabaseProvider);
  final repository = ref.watch(todayRepositoryProvider);
  final runtimeFuture = ref.watch(boundaryRuntimeProvider.future);
  final changes = ref.watch(todayChangesProvider);
  final boundaryRevision = ref.watch(boundaryRevisionProvider);

  if (changes case AsyncError(:final error, :final stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  if (boundaryRevision case AsyncError(:final error, :final stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }

  final runtime = await runtimeFuture;
  final clock = runtime.clock;
  final now = clock.nowInBusinessZone();
  final currentDate = clock.operationalDateNow();
  final pendingBoundary = runtime.pendingEditBoundary;
  final date = pendingBoundary?.closedDate ?? currentDate;
  final days = DayRepository(
    database,
    businessLocation: clock.businessLocation,
  );

  await OrphanBlockCloser(database).closeExpired(now: now);

  final materialized = await days.ensureDayMaterialized(date);
  if (materialized case Failure<dynamic, DayViolation>(:final failure)) {
    throw StateError('${failure.code}: ${failure.message}');
  }

  final snapshot = await repository.loadSnapshot(date);
  final view = const TodayProjection().project(
    snapshot: snapshot,
    clock: clock,
    now: now,
  );

  DateTime? nextDeadline;
  for (final candidate in <DateTime>[
    clock.blockDeadline(currentDate),
    if (snapshot.linkedStudyBlock case final block? when block.endedAt == null)
      block.blockDeadline,
  ]) {
    if (candidate.isAfter(now) &&
        (nextDeadline == null || candidate.isBefore(nextDeadline))) {
      nextDeadline = candidate;
    }
  }
  if (nextDeadline != null) {
    final delay = nextDeadline.difference(now);
    final timer = Timer(delay + const Duration(milliseconds: 50), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }

  return view;
});
