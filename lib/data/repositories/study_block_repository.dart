import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/day/study_block.dart' as domain;
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';

/// Persistência do ciclo de vida de StudyBlock.
final class StudyBlockRepository {
  StudyBlockRepository(
    this._database, {
    OperationalClock? clock,
    GuardedDayWriter? writer,
  }) : _clock = clock ?? SystemOperationalClock(),
       _writer = writer ?? GuardedDayWriter(_database);

  final db.RitmoDatabase _database;
  final OperationalClock _clock;
  final GuardedDayWriter _writer;

  /// Inicia um bloco na data recebida, sem inferir nem reatribuir sua origem.
  Future<Result<domain.StudyBlock, BusinessViolation>> start({
    required String id,
    required OperationalDate operationalDate,
    required tz.TZDateTime startedAt,
  }) async {
    final candidate = domain.StudyBlock.start(
      id: id,
      operationalDate: operationalDate,
      startedAt: startedAt,
      blockDeadline: _clock.blockDeadline(operationalDate),
    );
    if (candidate case Failure<domain.StudyBlock, domain.StudyBlockViolation>(
      :final failure,
    )) {
      return Result.failure(failure);
    }
    final block =
        (candidate as Success<domain.StudyBlock, domain.StudyBlockViolation>)
            .value;
    final guarded = await _writer.write<domain.StudyBlock>(
      operationalDate: operationalDate.iso,
      write: () async {
        await _database
            .into(_database.studyBlocks)
            .insert(
              db.StudyBlocksCompanion.insert(
                id: id,
                operationalDate: operationalDate.iso,
                startedAt: startedAt.millisecondsSinceEpoch,
                blockDeadline: block.blockDeadline.millisecondsSinceEpoch,
              ),
            );
        return block;
      },
    );
    return guarded.fold(
      onSuccess: (value) => Result.success(value),
      onFailure: (failure) => Result.failure(failure),
    );
  }

  /// Encerra normalmente; uma entrega tardia converge para o deadline.
  Future<Result<domain.StudyBlock, BusinessViolation>> finish(
    String id, {
    required tz.TZDateTime at,
  }) async {
    final initial = await _read(id);
    if (initial == null) return _notFound();
    final transition = initial.endAt(at);
    if (transition case Failure<domain.StudyBlock, domain.StudyBlockViolation>(
      :final failure,
    )) {
      return Result.failure(failure);
    }
    final ended =
        (transition as Success<domain.StudyBlock, domain.StudyBlockViolation>)
            .value;
    if (!initial.isOrphan) return Result.success(initial);

    final guarded = await _writer.write<domain.StudyBlock>(
      operationalDate: initial.operationalDate.iso,
      write: () async {
        await (_database.update(
          _database.studyBlocks,
        )..where((row) => row.id.equals(id) & row.endedAt.isNull())).write(
          db.StudyBlocksCompanion(
            endedAt: Value(ended.endedAt!.millisecondsSinceEpoch),
          ),
        );
        return (await _read(id))!;
      },
    );
    return guarded.fold(
      onSuccess: (value) => Result.success(value),
      onFailure: (failure) => Result.failure(failure),
    );
  }

  /// Gatilho automático do timer: encerra exatamente no deadline persistido.
  Future<Result<domain.StudyBlock, domain.StudyBlockViolation>> closeAtDeadline(
    String id,
  ) async {
    return _database.transaction(() async {
      final block = await _read(id);
      if (block == null) return _notFoundSpecific();
      await (_database.update(
        _database.studyBlocks,
      )..where((row) => row.id.equals(id) & row.endedAt.isNull())).write(
        db.StudyBlocksCompanion(
          endedAt: Value(block.blockDeadline.millisecondsSinceEpoch),
        ),
      );
      return Result.success((await _read(id))!);
    });
  }

  Future<domain.StudyBlock?> findById(String id) => _read(id);

  Future<domain.StudyBlock?> _read(String id) async {
    final row = await (_database.select(
      _database.studyBlocks,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return domain.StudyBlock(
      id: row.id,
      operationalDate: _parseDate(row.operationalDate),
      startedAt: _instant(row.startedAt),
      blockDeadline: _instant(row.blockDeadline),
      endedAt: row.endedAt == null ? null : _instant(row.endedAt!),
    );
  }

  Result<domain.StudyBlock, BusinessViolation> _notFound() =>
      const Result.failure(
        domain.StudyBlockViolation(
          code: 'study_block_not_found',
          message: 'O bloco de estudo informado não existe.',
        ),
      );

  Result<domain.StudyBlock, domain.StudyBlockViolation> _notFoundSpecific() =>
      const Result.failure(
        domain.StudyBlockViolation(
          code: 'study_block_not_found',
          message: 'O bloco de estudo informado não existe.',
        ),
      );

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  tz.TZDateTime _instant(int millisecondsSinceEpoch) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(
        _clock.businessLocation,
        millisecondsSinceEpoch,
      );
}

/// Reconciliação silenciosa executada na abertura e no cruzamento de fronteira.
///
/// Apenas blocos cujo deadline persistido já chegou são fechados. O UPDATE não
/// toca `operational_date` e é idempotente por selecionar somente órfãos.
final class OrphanBlockCloser {
  const OrphanBlockCloser(this._database);

  final db.RitmoDatabase _database;

  Future<int> closeExpired({required tz.TZDateTime now}) {
    return _database.customUpdate(
      'UPDATE study_blocks SET ended_at = block_deadline '
      'WHERE ended_at IS NULL AND block_deadline <= ?',
      variables: [Variable.withInt(now.millisecondsSinceEpoch)],
      updates: {_database.studyBlocks},
    );
  }

  /// Fecha expirados no deadline e qualquer bloco da data encerrada no
  /// instante em que a fronteira foi observada, sem ultrapassar o deadline nem
  /// produzir fim anterior ao início. O `block_deadline` permanece imutável.
  Future<int> closeAtBoundary({
    required OperationalDate closing,
    required tz.TZDateTime observedAt,
  }) {
    final observed = observedAt.millisecondsSinceEpoch;
    return _database.customUpdate(
      'UPDATE study_blocks SET ended_at = '
      'CASE WHEN block_deadline <= ? THEN block_deadline '
      'WHEN started_at > ? THEN started_at ELSE ? END '
      'WHERE ended_at IS NULL '
      'AND (block_deadline <= ? OR operational_date = ?)',
      variables: [
        Variable.withInt(observed),
        Variable.withInt(observed),
        Variable.withInt(observed),
        Variable.withInt(observed),
        Variable.withString(closing.iso),
      ],
      updates: {_database.studyBlocks},
    );
  }
}
