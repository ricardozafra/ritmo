import 'package:drift/drift.dart';

import '../../domain/day/eligible_day.dart';
import '../../domain/time/operational_calendar.dart';
import '../db/database.dart';

final class MetricsInput {
  MetricsInput({
    required this.activationDate,
    required Iterable<EligibleDay> days,
  }) : days = List.unmodifiable(days);

  final OperationalDate? activationDate;
  final List<EligibleDay> days;
}

/// Leitura reativa mínima para métricas; não consulta registros de pilares.
final class MetricsRepository {
  const MetricsRepository(this._database);

  final RitmoDatabase _database;

  Stream<MetricsInput> watchInput() => _database
      .customSelect(
        'SELECT s.activation_date, d.operational_date, d.base_result, '
        'd.effective_result, d.closed_at '
        'FROM settings s LEFT JOIN days d ON 1 = 1 '
        'WHERE s.id = 1 ORDER BY d.operational_date',
        readsFrom: {_database.settings, _database.days},
      )
      .watch()
      .map(_toInput);

  MetricsInput _toInput(List<QueryRow> rows) {
    final activationText = rows.isEmpty
        ? null
        : rows.first.readNullable<String>('activation_date');
    final days = <EligibleDay>[];
    for (final row in rows) {
      final dateText = row.readNullable<String>('operational_date');
      if (dateText == null) continue;
      final date = _parseDate(dateText);
      final effectiveResult = row.read<String>('effective_result');
      final isMute = effectiveResult == 'mute';
      days.add(
        EligibleDay(
          date: date,
          isWorkday: !date.isWeekend && !isMute,
          isClosed: row.readNullable<int>('closed_at') != null,
          isSealed: row.read<String>('base_result') == 'sealed',
          isMute: isMute,
        ),
      );
    }
    return MetricsInput(
      activationDate: activationText == null
          ? null
          : _parseDate(activationText),
      days: days,
    );
  }

  OperationalDate _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Data operacional inválida', value);
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
