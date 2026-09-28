import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../domain/holidays/holiday_recalculation.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';
import 'protocol_reconciler.dart';

/// Relatório neutro de uma operação confirmada de feriado.
final class RecalcReport {
  const RecalcReport({
    required this.date,
    required this.operation,
    required this.holidayChanged,
    required this.protocols,
    required this.message,
  });

  final OperationalDate date;
  final HolidayOperation operation;
  final bool holidayChanged;
  final ReconcileReport protocols;
  final String message;
}

/// Upsert, reclassificação e protocolos em uma única transação (RD-26).
final class HolidayRecalculation {
  HolidayRecalculation(
    this._database, {
    ProtocolReconciler? protocolReconciler,
    HolidayReclassifier? reclassifier,
    OperationalClock? clock,
  }) : _protocols = protocolReconciler ?? ProtocolReconciler(_database),
       _reclassifier = reclassifier ?? HolidayReclassifier(_database),
       _clock = clock ?? SystemOperationalClock();

  final db.RitmoDatabase _database;
  final ProtocolReconciler _protocols;
  final HolidayReclassifier _reclassifier;
  final OperationalClock _clock;
  final StreamController<HolidayChangedEvent> _changes =
      StreamController<HolidayChangedEvent>.broadcast(sync: true);

  Stream<HolidayChangedEvent> get changes => _changes.stream;

  RecalcPreview preview(OperationalDate date, HolidayOperation operation) {
    final applying = operation == HolidayOperation.apply;
    return RecalcPreview(
      date: date,
      operation: operation,
      title: applying ? 'Confirmar feriado' : 'Confirmar remoção do feriado',
      message: applying
          ? 'A data ficará fora das métricas e os protocolos poderão ser '
                'recalculados. Os registros existentes serão preservados.'
          : 'A data voltará às métricas conforme o resultado preservado, e os '
                'protocolos poderão ser recalculados. Nenhum registro será apagado.',
    );
  }

  Future<Result<RecalcReport, HolidayViolation>> apply(
    OperationalDate date, {
    String? reasonText,
  }) => _change(date, HolidayOperation.apply, reasonText);

  Future<Result<RecalcReport, HolidayViolation>> remove(
    OperationalDate date, {
    String? reasonText,
  }) => _change(date, HolidayOperation.remove, reasonText);

  Future<Result<RecalcReport, HolidayViolation>> _change(
    OperationalDate date,
    HolidayOperation operation,
    String? rawReason,
  ) async {
    if (date.isWeekend && operation == HolidayOperation.apply) {
      return const Result<RecalcReport, HolidayViolation>.failure(
        HolidayViolation(
          code: 'holiday_weekend_not_supported',
          message: 'Fins de semana já ficam fora das métricas.',
        ),
      );
    }

    final reason = _normalizeReason(rawReason);
    if (reason case Failure<String?, HolidayViolation>(:final failure)) {
      return Result<RecalcReport, HolidayViolation>.failure(failure);
    }
    final acceptedReason = (reason as Success<String?, HolidayViolation>).value;
    final occurredAt = _clock.nowInBusinessZone().millisecondsSinceEpoch;

    final result = await ProtocolReconciler.runExclusive(
      () => _database.transaction(() async {
        final day =
            await (_database.select(_database.days)
                  ..where((row) => row.operationalDate.equals(date.iso)))
                .getSingleOrNull();
        if (day == null) {
          return const Result<RecalcReport, HolidayViolation>.failure(
            HolidayViolation(
              code: 'holiday_day_not_found',
              message: 'A data operacional informada não está disponível.',
            ),
          );
        }

        final holiday =
            await (_database.select(_database.holidays)
                  ..where((row) => row.operationalDate.equals(date.iso)))
                .getSingleOrNull();
        final metadataChanges = operation == HolidayOperation.apply
            ? holiday?.active != true
            : holiday?.active == true;
        final classificationChanges = operation == HolidayOperation.apply
            ? day.muteCause != 'holiday'
            : day.muteCause == 'holiday';

        if (operation == HolidayOperation.apply && metadataChanges) {
          await _upsertApplied(date, occurredAt, acceptedReason);
        } else if (operation == HolidayOperation.remove && metadataChanges) {
          await _markRemoved(date, occurredAt, acceptedReason);
        }

        if (classificationChanges) {
          final reclassified = operation == HolidayOperation.apply
              ? await _reclassifier.apply(date.iso)
              : await _reclassifier.remove(date.iso);
          if (reclassified case Failure<void, DayViolation>(:final failure)) {
            return Result<RecalcReport, HolidayViolation>.failure(
              HolidayViolation(code: failure.code, message: failure.message),
            );
          }
        }

        final protocolReport = await _protocols.reconcileWithinTransaction(
          from: date,
          reason: classificationChanges
              ? ProtocolReconcileReason.holidayMutation
              : ProtocolReconcileReason.normalProgress,
        );
        final changed = metadataChanges || classificationChanges;
        return Result<RecalcReport, HolidayViolation>.success(
          RecalcReport(
            date: date,
            operation: operation,
            holidayChanged: changed,
            protocols: protocolReport,
            message: changed
                ? 'Alteração concluída. Os registros anteriores foram preservados.'
                : 'A data já estava com essa classificação; nada foi apagado.',
          ),
        );
      }),
    );

    if (result case Success<RecalcReport, HolidayViolation>(
      :final value,
    ) when value.holidayChanged) {
      _changes.add(
        HolidayChangedEvent(
          date: date,
          operation: operation,
          occurredAtMillisecondsSinceEpoch: occurredAt,
        ),
      );
    }
    return result;
  }

  Result<String?, HolidayViolation> _normalizeReason(String? raw) {
    final normalized = raw?.trim();
    final value = normalized == null || normalized.isEmpty ? null : normalized;
    if (value != null && value.runes.length > Limits.shortTextMaxRunes) {
      return const Result<String?, HolidayViolation>.failure(
        HolidayViolation(
          code: 'holiday_reason_too_long',
          message: 'O motivo opcional deve ter no máximo 500 caracteres.',
        ),
      );
    }
    return Result<String?, HolidayViolation>.success(value);
  }

  Future<void> _upsertApplied(
    OperationalDate date,
    int occurredAt,
    String? reason,
  ) => _database.customInsert(
    'INSERT INTO holidays (operational_date, active, created_at, removed_at, '
    'apply_reason_text, remove_reason_text) VALUES (?, 1, ?, NULL, ?, NULL) '
    'ON CONFLICT(operational_date) DO UPDATE SET active = 1, '
    'created_at = excluded.created_at, removed_at = NULL, '
    'apply_reason_text = excluded.apply_reason_text, remove_reason_text = NULL',
    variables: [
      Variable.withString(date.iso),
      Variable.withInt(occurredAt),
      Variable<String>(reason),
    ],
    updates: {_database.holidays},
  );

  Future<void> _markRemoved(
    OperationalDate date,
    int occurredAt,
    String? reason,
  ) => _database.customUpdate(
    'UPDATE holidays SET active = 0, removed_at = ?, '
    'remove_reason_text = ? WHERE operational_date = ? AND active = 1',
    variables: [
      Variable.withInt(occurredAt),
      Variable<String>(reason),
      Variable.withString(date.iso),
    ],
    updates: {_database.holidays},
  );

  Future<void> dispose() => _changes.close();
}
