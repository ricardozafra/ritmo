import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/review/review_schedule_validator.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/settings_validator.dart';
import '../db/database.dart' as db;

/// Snapshot validado da configuração local singleton.
final class SettingsSnapshot {
  const SettingsSnapshot({
    required this.calendar,
    required this.syncEnabled,
    required this.reviewWeekday,
    required this.reviewTimeMinutes,
    required this.sundayNotificationEnabled,
  });

  final OperationalCalendar calendar;
  final bool syncEnabled;

  /// Dia configurado da Revisão Semanal (RF-08.5).
  final ReviewWeekday reviewWeekday;

  /// Horário da Revisão em minutos desde a meia-noite civil.
  final int reviewTimeMinutes;

  /// Opt-in da notificação dominical; desligado por padrão (RF-08.6).
  final bool sundayNotificationEnabled;

  int get dayCloseTimeMinutes => calendar.dayCloseTime.minutesFromMidnight;
  int get nightEndTimeMinutes => calendar.nightEndTime.minutesFromMidnight;

  /// Horário da Revisão como hora civil.
  LocalTimeOfDay get reviewTime =>
      LocalTimeOfDay.fromMinutes(reviewTimeMinutes);
}

/// Projeção auditável de uma data já materializada e seu feriado manual.
final class HolidaySettingsEntry {
  const HolidaySettingsEntry({
    required this.date,
    required this.isClosed,
    required this.muteCause,
    required this.hasHolidayRecord,
    required this.isHolidayActive,
    required this.createdAtMillisecondsSinceEpoch,
    required this.removedAtMillisecondsSinceEpoch,
    required this.applyReasonText,
    required this.removeReasonText,
  });

  final OperationalDate date;
  final bool isClosed;
  final String? muteCause;
  final bool hasHolidayRecord;
  final bool isHolidayActive;
  final int? createdAtMillisecondsSinceEpoch;
  final int? removedAtMillisecondsSinceEpoch;
  final String? applyReasonText;
  final String? removeReasonText;

  /// Fins de semana mantêm sua classificação normativa e não são editáveis.
  bool get canManageHoliday => !date.isWeekend;
}

/// Leitura e escrita restrita das configurações expostas no MVP.
final class SettingsRepository {
  const SettingsRepository(this._database);

  final db.RitmoDatabase _database;
  static const SettingsValidator _validator = SettingsValidator();

  Future<SettingsSnapshot> load() async {
    final row = await (_database.select(
      _database.settings,
    )..where((candidate) => candidate.id.equals(1))).getSingleOrNull();
    if (row == null) {
      throw StateError('Configuração persistida ausente: settings id=1.');
    }
    return _toSnapshot(row);
  }

  Stream<SettingsSnapshot> watch() =>
      (_database.select(_database.settings)
            ..where((candidate) => candidate.id.equals(1)))
          .watchSingle()
          .map(_toSnapshot);

  /// Persiste apenas as fronteiras configuráveis e força o sync desligado.
  Future<SettingsSnapshot> saveCalendar(OperationalCalendar calendar) {
    final validation = _validator.validate(
      dayCloseTime: calendar.dayCloseTime,
      nightEndTime: calendar.nightEndTime,
    );
    if (validation case Failure<OperationalCalendar, ConfigViolation>(
      :final failure,
    )) {
      throw ArgumentError('${failure.code}: ${failure.message}');
    }

    return _database.transaction(() async {
      final changed =
          await (_database.update(
            _database.settings,
          )..where((candidate) => candidate.id.equals(1))).write(
            db.SettingsCompanion(
              dayCloseTimeMin: Value(calendar.dayCloseTime.minutesFromMidnight),
              nightEndTimeMin: Value(calendar.nightEndTime.minutesFromMidnight),
              syncEnabled: const Value(false),
            ),
          );
      if (changed != 1) {
        throw StateError('Configuração persistida ausente: settings id=1.');
      }

      final persisted = await (_database.select(
        _database.settings,
      )..where((candidate) => candidate.id.equals(1))).getSingle();
      return _toSnapshot(persisted);
    });
  }

  /// Menor data que o relógio vigente pode apresentar sem reabrir um dia.
  ///
  /// A ativação ancora o primeiro dia. Depois disso, o último dia encerrado
  /// avança a âncora para seu sucessor, mesmo quando o novo horário puro ainda
  /// apontaria para trás.
  Future<OperationalDate?> loadOperationalDateFloor() async {
    final row = await _database
        .customSelect(
          'SELECT activation_date, '
          '(SELECT MAX(operational_date) FROM days WHERE closed_at IS NOT NULL) '
          'AS last_closed_date '
          'FROM settings WHERE id = 1',
          readsFrom: {_database.settings, _database.days},
        )
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Configuração persistida ausente: settings id=1.');
    }

    final activation = _parseNullableDate(
      row.readNullable<String>('activation_date'),
      'settings.activation_date',
    );
    final lastClosed = _parseNullableDate(
      row.readNullable<String>('last_closed_date'),
      'days.operational_date',
    );
    final afterLastClosed = lastClosed?.next;
    if (activation == null) return afterLastClosed;
    if (afterLastClosed == null) return activation;
    return activation >= afterLastClosed ? activation : afterLastClosed;
  }

  Stream<List<HolidaySettingsEntry>> watchHolidayEntries() => _database
      .customSelect(
        'SELECT d.operational_date, d.closed_at, d.mute_cause, '
        'h.operational_date AS holiday_record_date, '
        'h.active AS holiday_active, h.created_at, h.removed_at, '
        'h.apply_reason_text, h.remove_reason_text '
        'FROM days d LEFT JOIN holidays h '
        'ON h.operational_date = d.operational_date '
        'ORDER BY d.operational_date DESC',
        readsFrom: {_database.days, _database.holidays},
      )
      .watch()
      .map(
        (rows) =>
            List<HolidaySettingsEntry>.unmodifiable(rows.map(_toHolidayEntry)),
      );

  SettingsSnapshot _toSnapshot(db.Setting row) {
    final validated = _validator.validateMinutes(
      dayCloseTimeMinutes: row.dayCloseTimeMin,
      nightEndTimeMinutes: row.nightEndTimeMin,
    );
    final reviewWeekday = ReviewWeekday.fromWire(row.reviewWeekday);
    if (reviewWeekday == null) {
      throw StateError(
        'review_weekday persistido inválido: ${row.reviewWeekday}.',
      );
    }
    return validated.fold(
      onSuccess: (calendar) => SettingsSnapshot(
        calendar: calendar,
        syncEnabled: row.syncEnabled,
        reviewWeekday: reviewWeekday,
        reviewTimeMinutes: row.reviewTimeMin,
        sundayNotificationEnabled: row.sundayNotificationEnabled,
      ),
      onFailure: (failure) => throw StateError(
        'Configuração de horários persistida inválida '
        '(day_close_time_min=${row.dayCloseTimeMin}, '
        'night_end_time_min=${row.nightEndTimeMin}): '
        '${failure.code} — ${failure.message}',
      ),
    );
  }

  HolidaySettingsEntry _toHolidayEntry(QueryRow row) {
    final holidayRecordDate = row.readNullable<String>('holiday_record_date');
    return HolidaySettingsEntry(
      date: _parseDate(
        row.read<String>('operational_date'),
        'days.operational_date',
      ),
      isClosed: row.readNullable<int>('closed_at') != null,
      muteCause: row.readNullable<String>('mute_cause'),
      hasHolidayRecord: holidayRecordDate != null,
      isHolidayActive: row.readNullable<int>('holiday_active') == 1,
      createdAtMillisecondsSinceEpoch: row.readNullable<int>('created_at'),
      removedAtMillisecondsSinceEpoch: row.readNullable<int>('removed_at'),
      applyReasonText: row.readNullable<String>('apply_reason_text'),
      removeReasonText: row.readNullable<String>('remove_reason_text'),
    );
  }

  OperationalDate? _parseNullableDate(String? value, String field) =>
      value == null ? null : _parseDate(value, field);

  OperationalDate _parseDate(String value, String field) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw StateError('$field inválido: $value.');
    }
    try {
      return OperationalDate(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } on Object catch (error) {
      throw StateError('$field inválido: $value ($error).');
    }
  }
}
