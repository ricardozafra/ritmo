import 'package:timezone/timezone.dart' as tz;

import 'operational_calendar.dart';
import 'operational_clock.dart';

/// Preserva a fronteira persistida da linha temporal quando os horários mudam.
///
/// A âncora afeta somente a data operacional vigente. Conversões de instantes
/// arbitrários continuam puras e seguem o calendário configurado, permitindo
/// consultas históricas sem distorção.
final class AnchoredOperationalClock implements OperationalClock {
  const AnchoredOperationalClock({
    required this.delegate,
    required this.minimumOperationalDate,
  });

  final OperationalClock delegate;
  final OperationalDate minimumOperationalDate;

  @override
  OperationalCalendar get calendar => delegate.calendar;

  @override
  tz.Location get businessLocation => delegate.businessLocation;

  @override
  tz.TZDateTime nowInBusinessZone() => delegate.nowInBusinessZone();

  @override
  OperationalDate operationalDateNow() {
    final calculated = delegate.operationalDateNow();
    return calculated < minimumOperationalDate
        ? minimumOperationalDate
        : calculated;
  }

  @override
  OperationalDate operationalDateOf(tz.TZDateTime instant) =>
      delegate.operationalDateOf(instant);

  @override
  tz.TZDateTime operationalOpen(OperationalDate date) =>
      delegate.operationalOpen(date);

  @override
  tz.TZDateTime operationalClose(OperationalDate date) =>
      delegate.operationalClose(date);

  @override
  tz.TZDateTime blockDeadline(OperationalDate date) =>
      delegate.blockDeadline(date);

  @override
  tz.TZDateTime resolveCivil(CivilMoment moment) =>
      delegate.resolveCivil(moment);

  @override
  tz.TZDateTime toBusinessZone(DateTime instant) =>
      delegate.toBusinessZone(instant);

  @override
  CivilMoment civilMomentOf(DateTime instant) =>
      delegate.civilMomentOf(instant);

  @override
  bool get deviceZoneDiverges => delegate.deviceZoneDiverges;
}
