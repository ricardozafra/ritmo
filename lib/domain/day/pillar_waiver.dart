import 'package:timezone/timezone.dart' as tz;

import '../time/operational_calendar.dart';
import 'seal_eligibility.dart' show Pillar;

export 'seal_eligibility.dart' show Pillar;

/// Dispensa auditável de um pilar em uma data operacional.
///
/// Uma dispensa com [revokedAt] preenchido permanece no histórico para
/// auditoria, mas não é ativa: não cobre o pilar no selo nem participa da
/// recorrência (RF-02.25).
final class PillarWaiver {
  const PillarWaiver({
    required this.id,
    required this.date,
    required this.pillar,
    required this.reasonText,
    this.recurrenceConfirmed = false,
    this.revokedAt,
  });

  final String id;
  final OperationalDate date;
  final Pillar pillar;
  final String reasonText;
  final bool recurrenceConfirmed;
  final tz.TZDateTime? revokedAt;

  bool get isActive => revokedAt == null;

  /// Cópia revogada em [at], preservando identidade, pilar, motivo e a marca da
  /// Regra do Retorno para auditoria (RF-02.25, RF-02.28).
  PillarWaiver revoked(tz.TZDateTime at) => PillarWaiver(
    id: id,
    date: date,
    pillar: pillar,
    reasonText: reasonText,
    recurrenceConfirmed: recurrenceConfirmed,
    revokedAt: at,
  );
}
