import 'package:riverpod/riverpod.dart';

import '../../data/assets/flutter_manifest_asset_loader.dart';
import '../../data/repositories/manifest_repository.dart';
import '../../domain/manifest/manifest_service.dart';
import '../../domain/time/operational_clock.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;

enum ManifestDisplayOrigin { local, assetFallback }

/// Conteúdo-fonte exibido pela Pedra e sua proveniência.
///
/// Somente uma cópia [local] pode entrar no modo de edição. O fallback do
/// asset permanece estritamente read-only para nunca substituir uma edição
/// persistida que esteja temporariamente indisponível.
final class ManifestPresentation {
  const ManifestPresentation({required this.markdown, required this.origin});

  final String markdown;
  final ManifestDisplayOrigin origin;

  bool get isEditable => origin == ManifestDisplayOrigin.local;
}

final manifestAssetLoaderProvider = Provider<ManifestAssetLoader>(
  (ref) => FlutterManifestAssetLoader(),
);

final manifestRepositoryProvider = Provider<ManifestRepository>(
  (ref) => DriftManifestRepository(ref.watch(ritmoDatabaseProvider)),
);

final manifestClockProvider = Provider<OperationalClock>(
  (ref) => SystemOperationalClock(),
);

final manifestServiceProvider = Provider<ManifestService>(
  (ref) => ManifestService(
    ref.watch(manifestRepositoryProvider),
    ref.watch(manifestAssetLoaderProvider),
    clock: ref.watch(manifestClockProvider),
  ),
);

/// Garante a cópia local no primeiro acesso e degrada para o asset sem escrita.
final manifestPresentationProvider = FutureProvider<ManifestPresentation>((
  ref,
) async {
  final service = ref.watch(manifestServiceProvider);
  try {
    final local = await service.ensureLocalCopy();
    return ManifestPresentation(
      markdown: local.contentMarkdown,
      origin: ManifestDisplayOrigin.local,
    );
  } on Object {
    final fallback = await service.readForDisplay();
    return ManifestPresentation(
      markdown: fallback,
      origin: ManifestDisplayOrigin.assetFallback,
    );
  }
});
