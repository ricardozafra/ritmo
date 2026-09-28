import 'package:riverpod/riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../controllers/settings_controller.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(ritmoDatabaseProvider)),
);

final settingsSnapshotProvider = StreamProvider<SettingsSnapshot>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final holidaySettingsEntriesProvider =
    StreamProvider<List<HolidaySettingsEntry>>(
      (ref) => ref.watch(settingsRepositoryProvider).watchHolidayEntries(),
    );

final settingsControllerProvider = Provider<SettingsController>((ref) {
  final controller = SettingsController(
    ref.watch(settingsRepositoryProvider),
    () async => ref.read(boundaryRuntimeProvider.future),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Evento interno de mudança de configuração. Na Fase 2 o scheduler de
/// notificações reage a ele para reconciliar os planos (RF-08.15).
final settingsChangesProvider = StreamProvider<SettingsChangedEvent>(
  (ref) => ref.watch(settingsControllerProvider).changes,
);
