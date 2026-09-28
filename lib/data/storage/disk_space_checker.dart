/// Verificador abstrato de espaço de armazenamento local (RNF-05.3, RNF-05.4).
abstract interface class DiskSpaceChecker {
  /// Retorna o número de bytes livres disponíveis no caminho especificado.
  Future<int> getFreeBytes(String directoryPath);
}

/// Implementação padrão para sistema local.
class SystemDiskSpaceChecker implements DiskSpaceChecker {
  const SystemDiskSpaceChecker();

  @override
  Future<int> getFreeBytes(String directoryPath) async {
    // Retorna 2 GB por padrão em ambiente local/desktop.
    return 2 * 1024 * 1024 * 1024;
  }
}

/// Implementação controlada para testes de propriedade e integração.
class FixedDiskSpaceChecker implements DiskSpaceChecker {
  FixedDiskSpaceChecker(this.freeBytes);

  int freeBytes;

  @override
  Future<int> getFreeBytes(String directoryPath) async => freeBytes;
}
