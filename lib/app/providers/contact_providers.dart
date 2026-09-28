import 'package:riverpod/riverpod.dart';

import '../../data/repositories/contact_repository.dart';
import '../../domain/people/contact.dart';
import '../controllers/contact_controller.dart';
import 'boundary_providers.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepository(ref.watch(ritmoDatabaseProvider)),
);

final contactOrderingProvider = Provider<ContactOrdering>(
  (ref) => const ContactOrdering(),
);

final contactControllerProvider = Provider<ContactController>(
  (ref) => ContactController(
    ref.watch(contactRepositoryProvider),
    loadClock: () async =>
        (await ref.read(boundaryRuntimeProvider.future)).clock,
  ),
);

/// Fluxo reativo dos contatos cadastrados, sem ordem de negócio aplicada.
final contactRowsProvider = StreamProvider<List<Contact>>(
  (ref) => ref.watch(contactRepositoryProvider).watchAll(),
);

/// Contatos na ordem semanal de carência (RF-07.5, RF-07.6). A ordenação é
/// pura e determinística; recalcula ao vivo quando a lista muda.
final contactWeeklyOrderProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final ordering = ref.watch(contactOrderingProvider);
  return ref
      .watch(contactRowsProvider)
      .whenData((contacts) => ordering.weeklyOrder(contacts));
});
