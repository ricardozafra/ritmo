import 'package:riverpod/riverpod.dart';

import '../../data/db/database.dart';
import '../../data/repositories/metrics_repository.dart';
import '../../domain/metrics/metrics_calculator.dart';

final ritmoDatabaseProvider = Provider<RitmoDatabase>((ref) {
  final database = RitmoDatabase.production();
  ref.onDispose(database.close);
  return database;
});

final metricsRepositoryProvider = Provider<MetricsRepository>(
  (ref) => MetricsRepository(ref.watch(ritmoDatabaseProvider)),
);

final metricsCalculatorProvider = Provider<MetricsCalculator>(
  (ref) => const MetricsCalculator(),
);

final metricsInputProvider = StreamProvider<MetricsInput>(
  (ref) => ref.watch(metricsRepositoryProvider).watchInput(),
);

/// Provider derivado: ausência de ativação significa histórico ainda vazio.
final metricsRateProvider = Provider<AsyncValue<Rate>>(
  (ref) => ref.watch(metricsInputProvider).whenData((input) {
    final activationDate = input.activationDate;
    if (activationDate == null) return Rate.zero;
    return ref
        .watch(metricsCalculatorProvider)
        .rate(input.days, activationDate);
  }),
);
