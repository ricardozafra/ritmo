import 'dart:async';

import '../core/copy.dart';
import '../core/result.dart';
import '../data/db/database.dart' as db;
import '../data/repositories/day_repository.dart';
import '../data/repositories/protocol_reconciler.dart';
import '../data/repositories/study_block_repository.dart';
import '../domain/day/day_state_machine.dart';
import '../domain/time/operational_calendar.dart';
import '../domain/time/operational_clock.dart';
import 'editor_registry.dart';
import 'schedule_reconciler.dart';

/// Contrato consumido pelo observer de lifecycle e timer.
abstract interface class BoundaryCrossingPort {
  Future<Iterable<OperationalDate>> pendingBoundaries({
    required OperationalDate before,
  });

  Future<BoundaryResult> crossBoundary(
    OperationalDate closing, {
    DayEditSnapshot? snapshot,
  });
}

/// Estado pós-commit consumido pela UI.
final class BoundaryUiState {
  const BoundaryUiState({
    required this.closedDate,
    required this.currentDate,
    required this.isPreviousDayReadOnly,
    required this.notice,
  });

  static const String readOnlyNotice = Copy.closedDayReadOnly;

  final OperationalDate closedDate;
  final OperationalDate currentDate;
  final bool isPreviousDayReadOnly;
  final String? notice;
}

/// Resultado auditável de uma travessia confirmada.
final class BoundaryResult {
  const BoundaryResult({
    required this.closedDate,
    required this.closedAtMillisecondsSinceEpoch,
    required this.closedNow,
    required this.snapshotPersisted,
    required this.orphanBlocksClosed,
    required this.protocols,
    required this.uiState,
  });

  final OperationalDate closedDate;
  final int closedAtMillisecondsSinceEpoch;
  final bool closedNow;
  final bool snapshotPersisted;
  final int orphanBlocksClosed;
  final ReconcileReport protocols;
  final BoundaryUiState uiState;
}

/// Erro de invariante ao tentar atravessar uma data inválida.
final class BoundaryCrossingException implements Exception {
  const BoundaryCrossingException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'BoundaryCrossingException($code): $message';
}

/// Fecha uma data operacional com todos os efeitos no mesmo commit.
final class BoundaryCrossingService implements BoundaryCrossingPort {
  BoundaryCrossingService(
    this._database, {
    OperationalClock? clock,
    DayRepository? days,
    OrphanBlockCloser? orphanBlocks,
    ProtocolReconciler? protocols,
    this.scheduleReconciler = const NoOpScheduleReconciler(),
  }) : _clock = clock ?? SystemOperationalClock(),
       _days = days ?? DayRepository(_database),
       _orphanBlocks = orphanBlocks ?? OrphanBlockCloser(_database),
       _protocols = protocols ?? ProtocolReconciler(_database);

  final db.RitmoDatabase _database;
  final OperationalClock _clock;
  final DayRepository _days;
  final OrphanBlockCloser _orphanBlocks;
  final ProtocolReconciler _protocols;
  final ScheduleReconciler scheduleReconciler;
  final StreamController<BoundaryUiState> _uiStates =
      StreamController<BoundaryUiState>.broadcast(sync: true);

  Stream<BoundaryUiState> get uiStates => _uiStates.stream;

  @override
  Future<Iterable<OperationalDate>> pendingBoundaries({
    required OperationalDate before,
  }) => _days.pendingBoundariesBefore(before);

  @override
  Future<BoundaryResult> crossBoundary(
    OperationalDate closing, {
    DayEditSnapshot? snapshot,
  }) async {
    if (snapshot != null && snapshot.operationalDate != closing) {
      throw const BoundaryCrossingException(
        'boundary_snapshot_date_mismatch',
        'O snapshot deve permanecer vinculado à data operacional original.',
      );
    }

    final transactionResult = await ProtocolReconciler.runExclusive(
      () => _database.transaction(() async {
        final materialized = await _days.ensureDayMaterializedWithinTransaction(
          closing,
        );
        if (materialized case Failure<Day, DayViolation>(:final failure)) {
          throw BoundaryCrossingException(failure.code, failure.message);
        }

        final alreadyClosed =
            await _days.closedAtWithinTransaction(closing) != null;
        var snapshotPersisted = false;
        if (!alreadyClosed && snapshot != null) {
          await snapshot.persist();
          snapshotPersisted = true;
        }

        final expectedClose = _clock.operationalClose(closing);
        final closure = await _days.closeWithinTransaction(
          closing,
          at: expectedClose,
        );
        final orphanBlocksClosed = await _orphanBlocks.closeAtBoundary(
          closing: closing,
          observedAt: _clock.nowInBusinessZone(),
        );
        final protocolReport = await _protocols.reconcileWithinTransaction(
          from: closing,
        );
        return (
          closure: closure,
          snapshotPersisted: snapshotPersisted,
          orphanBlocksClosed: orphanBlocksClosed,
          protocols: protocolReport,
        );
      }),
    );

    final currentDate = _clock.operationalDateNow();
    final commitEvent = BoundaryCommittedEvent(
      closedDate: closing,
      currentDate: currentDate,
      closedAtMillisecondsSinceEpoch:
          transactionResult.closure.closedAt.millisecondsSinceEpoch,
      closedNow: transactionResult.closure.changed,
    );
    await scheduleReconciler.reconcileAfterBoundary(commitEvent);

    final hadPendingEdit = snapshot != null;
    final uiState = BoundaryUiState(
      closedDate: closing,
      currentDate: currentDate,
      isPreviousDayReadOnly: hadPendingEdit,
      notice: hadPendingEdit ? BoundaryUiState.readOnlyNotice : null,
    );
    if (!_uiStates.isClosed) _uiStates.add(uiState);

    return BoundaryResult(
      closedDate: closing,
      closedAtMillisecondsSinceEpoch:
          transactionResult.closure.closedAt.millisecondsSinceEpoch,
      closedNow: transactionResult.closure.changed,
      snapshotPersisted: transactionResult.snapshotPersisted,
      orphanBlocksClosed: transactionResult.orphanBlocksClosed,
      protocols: transactionResult.protocols,
      uiState: uiState,
    );
  }

  Future<void> dispose() => _uiStates.close();
}
