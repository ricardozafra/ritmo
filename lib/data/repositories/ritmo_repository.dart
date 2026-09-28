import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/day/day_state_machine.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;

/// Consultas históricas somente leitura da tela Ritmo.
final class RitmoRepository {
  RitmoRepository(this._database, {tz.Location? businessLocation})
    : _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _businessLocation;

  Stream<List<Day>> watchMonth(OperationalDate monthStart) {
    if (monthStart.day != 1) {
      throw ArgumentError.value(
        monthStart,
        'monthStart',
        'deve ser o primeiro dia do mês',
      );
    }
    final nextMonth = monthStart.month == 12
        ? OperationalDate(monthStart.year + 1, 1, 1)
        : OperationalDate(monthStart.year, monthStart.month + 1, 1);

    return _database
        .customSelect(
          'SELECT operational_date, base_result, effective_result, closed_at, '
          'seal_timestamp, mute_cause, previous_result '
          'FROM days WHERE operational_date >= ? AND operational_date < ? '
          'ORDER BY operational_date',
          variables: [
            Variable.withString(monthStart.iso),
            Variable.withString(nextMonth.iso),
          ],
          readsFrom: {_database.days},
        )
        .watch()
        .map((rows) => List<Day>.unmodifiable(rows.map(_dayFromQueryRow)));
  }

  Stream<Day?> watchDay(OperationalDate date) => _database
      .customSelect(
        'SELECT operational_date, base_result, effective_result, closed_at, '
        'seal_timestamp, mute_cause, previous_result '
        'FROM days WHERE operational_date = ? LIMIT 1',
        variables: [Variable.withString(date.iso)],
        readsFrom: {_database.days},
      )
      .watchSingleOrNull()
      .map((row) => row == null ? null : _dayFromQueryRow(row));

  Day _dayFromQueryRow(QueryRow row) => Day(
    operationalDate: _date(row.read<String>('operational_date')),
    baseResult: _result(
      row.read<String>('base_result'),
      allowMute: false,
      field: 'days.base_result',
    ),
    effectiveResult: _result(
      row.read<String>('effective_result'),
      allowMute: true,
      field: 'days.effective_result',
    ),
    closedAt: _instant(row.readNullable<int>('closed_at')),
    sealTimestamp: _instant(row.readNullable<int>('seal_timestamp')),
    muteCause: _muteCause(row.readNullable<String>('mute_cause')),
    previousResult: switch (row.readNullable<String>('previous_result')) {
      null => null,
      final value => _result(
        value,
        allowMute: false,
        field: 'days.previous_result',
      ),
    },
  );

  DayResult _result(
    String value, {
    required bool allowMute,
    required String field,
  }) {
    final result = switch (value) {
      'sealed' => DayResult.sealed,
      'unsealed' => DayResult.unsealed,
      'mute' => DayResult.mute,
      _ => throw StateError('Resultado persistido inválido em $field: $value.'),
    };
    if (!allowMute && result == DayResult.mute) {
      throw StateError('Resultado mute inválido em $field.');
    }
    return result;
  }

  MuteCause? _muteCause(String? value) => switch (value) {
    null => null,
    'weekend' => MuteCause.weekend,
    'holiday' => MuteCause.holiday,
    _ => throw StateError('Causa mute persistida inválida: $value.'),
  };

  OperationalDate _date(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw StateError('Data operacional persistida inválida: $value.');
    }
    try {
      return OperationalDate(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } on FormatException {
      throw StateError('Data operacional persistida inválida: $value.');
    } on ArgumentError {
      throw StateError('Data operacional persistida inválida: $value.');
    }
  }

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : tz.TZDateTime.fromMillisecondsSinceEpoch(
          _businessLocation,
          millisecondsSinceEpoch,
        );
}
