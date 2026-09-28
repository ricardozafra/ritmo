import '../../domain/day/day_state_machine.dart';
import '../../domain/time/operational_calendar.dart';

enum RitmoDayCellState { unavailable, open, sealed, closedUnsealed, mute }

final class RitmoMonth {
  factory RitmoMonth(int year, int month) {
    OperationalDate(year, month, 1);
    return RitmoMonth._(year, month);
  }

  factory RitmoMonth.fromDate(OperationalDate date) =>
      RitmoMonth._(date.year, date.month);

  const RitmoMonth._(this.year, this.month);

  final int year;
  final int month;

  OperationalDate get firstDay => OperationalDate(year, month, 1);

  RitmoMonth get previous =>
      month == 1 ? RitmoMonth(year - 1, 12) : RitmoMonth(year, month - 1);

  RitmoMonth get next =>
      month == 12 ? RitmoMonth(year + 1, 1) : RitmoMonth(year, month + 1);

  int get dayCount => next.firstDay.previous.day;

  @override
  bool operator ==(Object other) =>
      other is RitmoMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() =>
      '${month.toString().padLeft(2, '0')}/${year.toString().padLeft(4, '0')}';
}

abstract final class OperationalDateCodec {
  static OperationalDate? tryParse(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    try {
      final date = OperationalDate(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.iso == value ? date : null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

final class RitmoDayCell {
  const RitmoDayCell({
    required this.date,
    required this.state,
    required this.hasPersistedDay,
  });

  final OperationalDate date;
  final RitmoDayCellState state;
  final bool hasPersistedDay;
}

final class RitmoMonthView {
  RitmoMonthView({required this.month, required Iterable<RitmoDayCell> cells})
    : cells = List.unmodifiable(cells);

  final RitmoMonth month;
  final List<RitmoDayCell> cells;

  int get leadingEmptyCells => month.firstDay.weekday - 1;
}

final class RitmoDayDetailView {
  const RitmoDayDetailView({
    required this.operationalDate,
    required this.baseResult,
    required this.effectiveResult,
    required this.closedAt,
    required this.sealTimestamp,
    required this.muteCause,
    required this.previousResult,
  });

  final OperationalDate operationalDate;
  final DayResult baseResult;
  final DayResult effectiveResult;
  final DateTime? closedAt;
  final DateTime? sealTimestamp;
  final MuteCause? muteCause;
  final DayResult? previousResult;

  bool get isOpen => closedAt == null;
}

final class RitmoProjection {
  const RitmoProjection();

  RitmoMonthView projectMonth({
    required RitmoMonth month,
    required Iterable<Day> days,
  }) {
    final byDate = <String, Day>{};
    for (final day in days) {
      if (day.operationalDate.year != month.year ||
          day.operationalDate.month != month.month) {
        throw ArgumentError(
          'O dia ${day.operationalDate.iso} não pertence ao mês $month.',
        );
      }
      if (byDate.containsKey(day.operationalDate.iso)) {
        throw StateError('Dia duplicado: ${day.operationalDate.iso}.');
      }
      byDate[day.operationalDate.iso] = day;
    }

    return RitmoMonthView(
      month: month,
      cells: <RitmoDayCell>[
        for (var dayNumber = 1; dayNumber <= month.dayCount; dayNumber++)
          _cell(OperationalDate(month.year, month.month, dayNumber), byDate),
      ],
    );
  }

  RitmoDayDetailView projectDay(Day day) => RitmoDayDetailView(
    operationalDate: day.operationalDate,
    baseResult: day.baseResult,
    effectiveResult: day.effectiveResult,
    closedAt: day.closedAt,
    sealTimestamp: day.sealTimestamp,
    muteCause: day.muteCause,
    previousResult: day.previousResult,
  );

  RitmoDayCell _cell(OperationalDate date, Map<String, Day> byDate) {
    final day = byDate[date.iso];
    return RitmoDayCell(
      date: date,
      state: _state(day),
      hasPersistedDay: day != null,
    );
  }

  RitmoDayCellState _state(Day? day) {
    if (day == null) return RitmoDayCellState.unavailable;
    if (day.isMute) return RitmoDayCellState.mute;
    if (day.baseResult == DayResult.sealed) {
      return RitmoDayCellState.sealed;
    }
    if (!day.isOpen) return RitmoDayCellState.closedUnsealed;
    return RitmoDayCellState.open;
  }
}
