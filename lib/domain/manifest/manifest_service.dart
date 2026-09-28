import '../../core/limits.dart';
import '../../core/result.dart';
import '../time/operational_clock.dart';

/// Cópia local editável do manifesto.
final class Manifest {
  const Manifest({
    required this.id,
    required this.contentMarkdown,
    required this.assetVersion,
    required this.firstCopiedAt,
    this.lastEditedAt,
  });

  final String id;
  final String contentMarkdown;
  final String assetVersion;
  final DateTime firstCopiedAt;
  final DateTime? lastEditedAt;
}

/// Conteúdo e versão do manifesto distribuído com o aplicativo.
final class ManifestAsset {
  const ManifestAsset({required this.contentMarkdown, required this.version});

  final String contentMarkdown;
  final String version;
}

/// Porta injetável para leitura do asset empacotado.
abstract interface class ManifestAssetLoader {
  Future<ManifestAsset> load();
}

/// Porta de persistência da única cópia local do manifesto.
abstract interface class ManifestRepository {
  Future<Manifest?> findById(String id);

  /// Insere [manifest] somente quando a chave ainda não existe e retorna a
  /// linha que prevaleceu.
  Future<Manifest> insertIfAbsent(Manifest manifest);

  Future<Manifest> saveEdit({
    required String id,
    required String contentMarkdown,
    required DateTime editedAt,
  });
}

/// Coordena a cópia local editável e o fallback de leitura do manifesto.
final class ManifestService {
  ManifestService(
    this._repository,
    this._assetLoader, {
    this.limitPolicy = const LimitPolicy(),
    OperationalClock? clock,
  }) : _clock = clock ?? SystemOperationalClock();

  static const String manifestId = 'manifest';

  final ManifestRepository _repository;
  final ManifestAssetLoader _assetLoader;
  final LimitPolicy limitPolicy;
  final OperationalClock _clock;

  /// Copia o asset somente quando a cópia local está ausente.
  ///
  /// A decisão final de inserção pertence ao repositório para que chamadas
  /// concorrentes nunca substituam uma linha que já exista.
  Future<Manifest> ensureLocalCopy() async {
    final existing = await _repository.findById(manifestId);
    if (existing != null) return existing;

    final asset = await _assetLoader.load();
    return _repository.insertIfAbsent(
      Manifest(
        id: manifestId,
        contentMarkdown: asset.contentMarkdown,
        assetVersion: asset.version,
        firstCopiedAt: _clock.nowInBusinessZone(),
      ),
    );
  }

  /// Lê a cópia local e usa o asset apenas como fallback, sem persistir.
  Future<String> readForDisplay() async {
    try {
      final local = await _repository.findById(manifestId);
      if (local != null) return local.contentMarkdown;
    } on Object {
      // A leitura do asset mantém a Pedra disponível se o armazenamento local
      // estiver temporariamente indisponível.
    }

    return (await _assetLoader.load()).contentMarkdown;
  }

  /// Persiste uma edição válida, preservando a versão e a data da cópia.
  Future<Result<Manifest, LimitViolation>> save(String markdown) async {
    final validation = limitPolicy.assertManifestSize(markdown);
    if (validation case Failure<void, LimitViolation>(:final failure)) {
      return Result.failure(failure);
    }

    await ensureLocalCopy();
    final saved = await _repository.saveEdit(
      id: manifestId,
      contentMarkdown: markdown,
      editedAt: _clock.nowInBusinessZone(),
    );
    return Result.success(saved);
  }
}
