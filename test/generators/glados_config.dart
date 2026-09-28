import 'package:glados/glados.dart';

/// Configuração comum de exploração exigida pelo design do Ritmo.
abstract final class RitmoGlados {
  static const int minimumRuns = 100;
  static const int ciSeed = 0x5249544D; // "RITM"

  static ExploreConfig ci({int runs = minimumRuns}) {
    if (runs < minimumRuns) {
      throw ArgumentError.value(
        runs,
        'runs',
        'propriedades do Ritmo exigem ao menos $minimumRuns iterações',
      );
    }
    return ExploreConfig(numRuns: runs, random: Random(ciSeed));
  }

  /// Para a execução noturna; a semente deve vir do job para ser registrada.
  static ExploreConfig nightly({required int seed, int runs = minimumRuns}) {
    if (runs < minimumRuns) {
      throw ArgumentError.value(
        runs,
        'runs',
        'propriedades do Ritmo exigem ao menos $minimumRuns iterações',
      );
    }
    return ExploreConfig(numRuns: runs, random: Random(seed));
  }
}
