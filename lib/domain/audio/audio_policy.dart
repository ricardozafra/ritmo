import '../../core/limits.dart';

/// Tipos de áudio local suportados pelo Ritmo (RD-37).
enum AudioKind {
  dayNote('day_note'),
  weeklyReview('weekly_review');

  const AudioKind(this.wireValue);
  final String wireValue;

  static AudioKind? fromWire(String value) {
    for (final kind in values) {
      if (kind.wireValue == value) return kind;
    }
    return null;
  }
}

/// Regras de integridade, limites e encerramento gracioso de áudio (RD-35, RD-37, RNF-05.2, RNF-05.3).
final class AudioPolicy {
  const AudioPolicy();

  /// Teto de duração em milissegundos (RD-35).
  int maxDurationMsFor(AudioKind kind) => switch (kind) {
    AudioKind.dayNote => Limits.dayNoteMaxDurationMs,
    AudioKind.weeklyReview => Limits.weeklyReviewMaxDurationMs,
  };

  /// Estimativa conservadora de bytes necessários antes de iniciar a gravação.
  int estimatedBytesFor(AudioKind kind) => switch (kind) {
    AudioKind.dayNote => Limits.dayNoteEstimatedBytes,
    AudioKind.weeklyReview => Limits.weeklyReviewEstimatedBytes,
  };

  /// Verifica se o espaço livre disponível é suficiente (RNF-05.3, RNF-05.4).
  bool hasSufficientSpace({
    required int freeBytes,
    required int requiredBytes,
  }) => freeBytes >= requiredBytes;

  /// Encerramento gracioso no limite: se a gravação atingir ou exceder o
  /// limite máximo permitido, a duração é limitada ao teto, preservando o
  /// arquivo válido (RNF-05.2, RD-35).
  int clampDuration(AudioKind kind, int durationMs) {
    if (durationMs <= 0) return 0;
    final maxMs = maxDurationMsFor(kind);
    return durationMs > maxMs ? maxMs : durationMs;
  }
}
