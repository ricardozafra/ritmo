import 'package:riverpod/riverpod.dart';

import '../../data/repositories/protocol_repository.dart';
import '../../domain/protocol/protocol_alarm.dart';
import '../../domain/protocol/protocol_session_gate.dart';
import '../../domain/protocol/single_lost_day_copy.dart';
import '../../domain/time/operational_clock.dart';
import '../controllers/protocol_controller.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart'
    show metricsInputProvider, ritmoDatabaseProvider;

final protocolClockProvider = Provider<OperationalClock>(
  (ref) => SystemOperationalClock(),
);

final protocolRepositoryProvider = Provider<ProtocolRepository>(
  (ref) => ProtocolRepository(ref.watch(ritmoDatabaseProvider)),
);

final protocolHistoryProvider = StreamProvider<List<ProtocolAlarm>>(
  (ref) => ref.watch(protocolRepositoryProvider).watchHistory(),
);

/// Uma instância por abertura do aplicativo: o container é criado na
/// inicialização a frio e descartado com ela (RF-03.10, RF-03.12).
final protocolSessionGateProvider = Provider<ProtocolSessionGate>(
  (ref) => ProtocolSessionGate(),
);

final protocolControllerProvider = Provider<ProtocolController>(
  (ref) => ProtocolController(
    ref.watch(protocolRepositoryProvider),
    ref.watch(protocolSessionGateProvider),
  ),
);

final singleLostDayCopyDeriverProvider = Provider<SingleLostDayCopyDeriver>(
  (ref) => const SingleLostDayCopyDeriver(),
);

/// Copy derivada para a tela Ritmo, sem persistência adicional.
final singleLostDayCopyProvider =
    Provider<AsyncValue<FailureCopyPresentation?>>(
      (ref) => ref.watch(metricsInputProvider).whenData((input) {
        final activationDate = input.activationDate;
        if (activationDate == null) return null;
        return ref
            .watch(singleLostDayCopyDeriverProvider)
            .derive(input.days, activationDate);
      }),
    );

/// Protocolo desta abertura, ou `null` quando não há o que exibir.
///
/// A leitura passa pelo gate, portanto responder ao protocolo exibido não
/// revela outro pendente na mesma sessão (RF-03.11, RF-03.23).
final protocolForThisLaunchProvider = FutureProvider<ProtocolAlarm?>((
  ref,
) async {
  // A fotografia da abertura só é tomada depois que fronteiras perdidas foram
  // recuperadas e os protocolos correspondentes foram reconciliados.
  await ref.watch(boundaryRuntimeProvider.future);
  final pending = await ref
      .watch(protocolRepositoryProvider)
      .pendingProtocols();
  return ref.watch(protocolSessionGateProvider).selectForThisLaunch(pending);
});
