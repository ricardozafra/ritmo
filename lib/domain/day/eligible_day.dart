import '../time/operational_calendar.dart';

/// Projeção mínima compartilhada por regras derivadas sobre o histórico diário.
///
/// Não contém registros de pilares: em particular, não expõe `NightKind`.
final class EligibleDay {
  const EligibleDay({
    required this.date,
    required this.isWorkday,
    required this.isClosed,
    required this.isSealed,
    required this.isMute,
  });

  final OperationalDate date;
  final bool isWorkday;
  final bool isClosed;
  final bool isSealed;
  final bool isMute;
}
