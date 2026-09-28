import 'dart:convert';

import 'result.dart';

/// Fonte única dos limites de conteúdo do Ritmo.
abstract final class Limits {
  static const int editableNameMaxRunes = 120;
  static const int shortTextMaxRunes = 500;
  static const int protocolTextMaxRunes = 2000;
  static const int weeklyReviewAnswerMaxRunes = 5000;
  static const int checkpointNotesMaxRunes = 2000;
  static const int cyclePurposeMaxRunes = 1000;
  static const int manifestMaxUtf8Bytes = 1024 * 1024;
  static const int dayNoteMaxDurationMs = 5 * 60 * 1000;
  static const int weeklyReviewMaxDurationMs = 30 * 60 * 1000;
  static const int dayNoteEstimatedBytes = 5 * 1024 * 1024;
  static const int weeklyReviewEstimatedBytes = 30 * 1024 * 1024;
}

/// Resultado explícito da tentativa de aceitar uma entrada textual.
///
/// [accepted] preserva o prefixo válido e [rejected] mantém visível exatamente
/// o excedente bloqueado; portanto, a operação nunca trunca silenciosamente.
final class ClampResult {
  const ClampResult({
    required this.original,
    required this.accepted,
    required this.rejected,
    required this.maxRunes,
  });

  final String original;
  final String accepted;
  final String rejected;
  final int maxRunes;

  String get value => accepted;
  bool get exceeded => rejected.isNotEmpty;
  bool get wasClamped => exceeded;
  int get acceptedRunes => accepted.runes.length;
  int get rejectedRunes => rejected.runes.length;

  LimitViolation? get violation => exceeded
      ? LimitViolation(
          actual: original.runes.length,
          maximum: maxRunes,
          unit: LimitUnit.runes,
        )
      : null;
}

class LimitPolicy {
  const LimitPolicy();

  ClampResult clampRunes(String input, int maxRunes) {
    if (maxRunes < 0) {
      throw ArgumentError.value(maxRunes, 'maxRunes', 'não pode ser negativo');
    }

    final runes = input.runes.toList(growable: false);

    final acceptedCount = runes.length < maxRunes ? runes.length : maxRunes;

    return ClampResult(
      original: input,
      accepted: String.fromCharCodes(runes.take(acceptedCount)),
      rejected: String.fromCharCodes(runes.skip(acceptedCount)),
      maxRunes: maxRunes,
    );
  }

  Result<void, LimitViolation> assertManifestSize(String markdown) {
    final byteLength = utf8.encode(markdown).length;
    if (byteLength <= Limits.manifestMaxUtf8Bytes) {
      return const Result<void, LimitViolation>.success(null);
    }

    return Result<void, LimitViolation>.failure(
      LimitViolation(
        actual: byteLength,
        maximum: Limits.manifestMaxUtf8Bytes,
        unit: LimitUnit.utf8Bytes,
      ),
    );
  }
}