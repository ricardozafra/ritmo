import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/day/day_state_machine.dart' as domain;
import '../../domain/day/seal_eligibility.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;

/// Única porta de criação de dias operacionais.
///
/// A ativação e a primeira materialização são confirmadas na mesma transação.
/// Repetições convergem pela chave primária `operational_date`.
final class DayRepository {
  DayRepository(db.RitmoDatabase database, {tz.Location? businessLocation})
    : _database = database,
      _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _businessLocation;
  static const domain.DayStateMachine _stateMachine = domain.DayStateMachine();

  Future<Result<domain.Day, DayViolation>> sealDay(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) {
    return _database.transaction(() async {
      final persisted = await _readDay(date.iso);
      if (persisted == null) return _dayNotMaterialized();

      final current = _toDomain(persisted, date);
      final status = await _readPillarStatus(date.iso);
      final activeWaiver = await _readActiveWaiver(date.iso);
      final transition = _stateMachine.apply(
        current,
        const domain.SealDay(),
        domain.SealContext(
          isEligible: sealEligible(status, activeWaiver),
          now: at,
          uncoveredIncompletePillars: uncoveredIncompletePillars(
            status,
            activeWaiver,
          ),
        ),
      );
      if (transition case Failure<domain.Day, DayViolation>(:final failure)) {
        return Result<domain.Day, DayViolation>.failure(failure);
      }
      final updated = (transition as Success<domain.Day, DayViolation>).value;
      await _persistDay(updated);
      return Result<domain.Day, DayViolation>.success(updated);
    });
  }

  Future<Result<domain.Day, DayViolation>> reopenDay(OperationalDate date) {
    return _database.transaction(() async {
      final persisted = await _readDay(date.iso);
      if (persisted == null) return _dayNotMaterialized();

      final current = _toDomain(persisted, date);
      final transition = _stateMachine.apply(
        current,
        const domain.ReopenDay(),
        domain.SealContext(
          isEligible: true,
          now: current.sealTimestamp ?? tz.TZDateTime(_businessLocation, 1970),
        ),
      );
      if (transition case Failure<domain.Day, DayViolation>(:final failure)) {
        return Result<domain.Day, DayViolation>.failure(failure);
      }
      final updated = (transition as Success<domain.Day, DayViolation>).value;
      await _persistDay(updated);
      return Result<domain.Day, DayViolation>.success(updated);
    });
  }

  Future<Result<domain.Day, DayViolation>> ensureDayMaterialized(
    OperationalDate date,
  ) =>
      _database.transaction(() => ensureDayMaterializedWithinTransaction(date));

  /// Corpo de materialização para operações que já controlam a transação.
  Future<Result<domain.Day, DayViolation>>
  ensureDayMaterializedWithinTransaction(OperationalDate date) async {
    var settings = await _readSettings();
    final activationDate = settings.activationDate;

    if (activationDate == null) {
      await (_database.update(
        _database.settings,
      )..where((row) => row.id.equals(1) & row.activationDate.isNull())).write(
        db.SettingsCompanion(activationDate: Value<String?>(date.iso)),
      );
      settings = await _readSettings();
    }

    final persistedActivation = settings.activationDate!;
    if (date.iso.compareTo(persistedActivation) < 0) {
      return const Result<domain.Day, DayViolation>.failure(
        DayViolation(
          code: 'day_before_activation',
          message: 'Esta data é anterior ao primeiro uso do Ritmo.',
        ),
      );
    }

    final existing = await _readDay(date.iso);
    if (existing != null) {
      return Result<domain.Day, DayViolation>.success(
        _toDomain(existing, date),
      );
    }
    final activeHoliday =
        await (_database.select(_database.holidays)..where(
              (holiday) =>
                  holiday.operationalDate.equals(date.iso) &
                  holiday.active.equals(true),
            ))
            .getSingleOrNull();
    final isWeekend = date.isWeekend;
    final isHoliday = !isWeekend && activeHoliday != null;

    await _database
        .into(_database.days)
        .insert(
          db.DaysCompanion.insert(
            operationalDate: date.iso,
            baseResult: domain.DayResult.unsealed.name,
            effectiveResult: isWeekend || isHoliday
                ? domain.DayResult.mute.name
                : domain.DayResult.unsealed.name,
            muteCause: isWeekend
                ? Value(domain.MuteCause.weekend.name)
                : isHoliday
                ? Value(domain.MuteCause.holiday.name)
                : const Value.absent(),
            previousResult: isHoliday
                ? Value(domain.DayResult.unsealed.name)
                : const Value.absent(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    final materialized = await _readDay(date.iso);
    return Result<domain.Day, DayViolation>.success(
      _toDomain(materialized!, date),
    );
  }

  /// Datas desde a ativação que ainda não existem ou permanecem abertas.
  Future<List<OperationalDate>> pendingBoundariesBefore(
    OperationalDate before,
  ) async {
    final activationIso = (await _readSettings()).activationDate;
    if (activationIso == null || activationIso.compareTo(before.iso) >= 0) {
      return const [];
    }

    final rows = await _database
        .customSelect(
          'SELECT operational_date, closed_at FROM days '
          'WHERE operational_date >= ? AND operational_date < ?',
          variables: [
            Variable.withString(activationIso),
            Variable.withString(before.iso),
          ],
          readsFrom: {_database.days},
        )
        .get();
    final closedByDate = <String, int?>{
      for (final row in rows)
        row.read<String>('operational_date'): row.readNullable<int>(
          'closed_at',
        ),
    };
    final parts = activationIso.split('-');
    var cursor = OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final pending = <OperationalDate>[];
    while (cursor < before) {
      if (!closedByDate.containsKey(cursor.iso) ||
          closedByDate[cursor.iso] == null) {
        pending.add(cursor);
      }
      cursor = cursor.next;
    }
    return pending;
  }

  /// Retorna o fechamento persistido, ou `null` quando o dia está aberto.
  /// Requer que [date] já esteja materializada na transação corrente.
  Future<tz.TZDateTime?> closedAtWithinTransaction(OperationalDate date) async {
    final persisted = await _readDay(date.iso);
    if (persisted == null) {
      throw StateError('A data ${date.iso} ainda não foi materializada.');
    }
    return _instant(persisted.closedAt);
  }

  /// Fecha uma data uma única vez e preserva o primeiro `closed_at`.
  Future<({bool changed, tz.TZDateTime closedAt})> closeWithinTransaction(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) async {
    final changed =
        await (_database.update(_database.days)..where(
              (row) =>
                  row.operationalDate.equals(date.iso) & row.closedAt.isNull(),
            ))
            .write(
              db.DaysCompanion(closedAt: Value(at.millisecondsSinceEpoch)),
            );
    final persisted = await _readDay(date.iso);
    final closedAt = persisted == null ? null : _instant(persisted.closedAt);
    if (closedAt == null) {
      throw StateError('Não foi possível encerrar a data ${date.iso}.');
    }
    return (changed: changed == 1, closedAt: closedAt);
  }

  Future<PillarStatus> _readPillarStatus(String date) async {
    final entries = await (_database.select(
      _database.pillarEntries,
    )..where((entry) => entry.operationalDate.equals(date))).get();
    db.PillarEntry? entry(String pillar) {
      for (final candidate in entries) {
        if (candidate.pillar == pillar) return candidate;
      }
      return null;
    }

    final morning = entry(Pillar.morning.name);
    final daily = entry(Pillar.day.name);
    final night = entry(Pillar.night.name);
    var nightCompleted = night?.nightKind == 'recovery';
    if (!nightCompleted &&
        night?.nightKind == 'study' &&
        night?.studyBlockId != null) {
      final block =
          await (_database.select(_database.studyBlocks)
                ..where((block) => block.id.equals(night!.studyBlockId!)))
              .getSingleOrNull();
      nightCompleted = block?.endedAt != null;
    }
    return PillarStatus(
      morningCompleted:
          morning?.workoutDone == true && morning?.briefingDone == true,
      dayCompleted: daily?.toggleOn == true,
      nightCompleted: nightCompleted,
    );
  }

  Future<PillarWaiver?> _readActiveWaiver(String date) async {
    final waiver =
        await (_database.select(_database.pillarWaivers)..where(
              (waiver) => waiver.date.equals(date) & waiver.revokedAt.isNull(),
            ))
            .getSingleOrNull();
    return waiver == null ? null : PillarWaiver(pillar: _pillar(waiver.pillar));
  }

  Future<void> _persistDay(domain.Day day) async {
    await (_database.update(_database.days)
          ..where((row) => row.operationalDate.equals(day.operationalDate.iso)))
        .write(
          db.DaysCompanion(
            baseResult: Value(day.baseResult.name),
            effectiveResult: Value(day.effectiveResult.name),
            closedAt: Value(day.closedAt?.millisecondsSinceEpoch),
            sealTimestamp: Value(day.sealTimestamp?.millisecondsSinceEpoch),
            muteCause: Value(day.muteCause?.name),
            previousResult: Value(day.previousResult?.name),
          ),
        );
  }

  Result<domain.Day, DayViolation> _dayNotMaterialized() =>
      const Result<domain.Day, DayViolation>.failure(
        DayViolation(
          code: 'day_not_materialized',
          message: 'A data operacional ainda não está disponível.',
        ),
      );

  Pillar _pillar(String value) => switch (value) {
    'morning' => Pillar.morning,
    'day' => Pillar.day,
    'night' => Pillar.night,
    _ => throw StateError('Pilar persistido inválido: $value'),
  };

  Future<db.Setting> _readSettings() => (_database.select(
    _database.settings,
  )..where((row) => row.id.equals(1))).getSingle();

  Future<db.Day?> _readDay(String operationalDate) =>
      (_database.select(_database.days)
            ..where((day) => day.operationalDate.equals(operationalDate)))
          .getSingleOrNull();

  domain.Day _toDomain(db.Day persisted, OperationalDate date) => domain.Day(
    operationalDate: date,
    baseResult: _dayResult(persisted.baseResult),
    effectiveResult: _dayResult(persisted.effectiveResult),
    closedAt: _instant(persisted.closedAt),
    sealTimestamp: _instant(persisted.sealTimestamp),
    muteCause: switch (persisted.muteCause) {
      'weekend' => domain.MuteCause.weekend,
      'holiday' => domain.MuteCause.holiday,
      _ => null,
    },
    previousResult: persisted.previousResult == null
        ? null
        : _dayResult(persisted.previousResult!),
  );

  domain.DayResult _dayResult(String value) => switch (value) {
    'sealed' => domain.DayResult.sealed,
    'unsealed' => domain.DayResult.unsealed,
    'mute' => domain.DayResult.mute,
    _ => throw StateError('Resultado diário persistido inválido: $value'),
  };

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : tz.TZDateTime.fromMillisecondsSinceEpoch(
          _businessLocation,
          millisecondsSinceEpoch,
        );
}
