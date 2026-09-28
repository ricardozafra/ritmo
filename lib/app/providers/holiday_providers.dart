import 'package:riverpod/riverpod.dart';

import '../../data/repositories/holiday_recalculation.dart';
import '../../data/repositories/protocol_reconciler.dart';
import '../../domain/holidays/holiday_recalculation.dart';
import '../controllers/holiday_controller.dart';
import 'metrics_providers.dart';
import 'protocol_providers.dart';

final protocolReconcilerProvider = Provider<ProtocolReconciler>(
  (ref) => ProtocolReconciler(ref.watch(ritmoDatabaseProvider)),
);

final holidayRecalculationProvider = Provider<HolidayRecalculation>((ref) {
  final service = HolidayRecalculation(
    ref.watch(ritmoDatabaseProvider),
    protocolReconciler: ref.watch(protocolReconcilerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Evento interno para consumidores futuros, inclusive o scheduler da Fase 2.
/// O MVP apenas publica a alteração e não conhece gateways de notificação.
final holidayChangesProvider = StreamProvider<HolidayChangedEvent>(
  (ref) => ref.watch(holidayRecalculationProvider).changes,
);

final holidayControllerProvider = Provider<HolidayController>(
  (ref) => HolidayController(ref.watch(holidayRecalculationProvider), () {
    ref.invalidate(metricsInputProvider);
    ref.invalidate(metricsRateProvider);
    ref.invalidate(protocolForThisLaunchProvider);
  }),
);
