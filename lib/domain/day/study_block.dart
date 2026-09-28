import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../time/operational_calendar.dart';

// A taxonomia de falhas é selada em `core/result.dart`; reexportada aqui para
// que o ciclo de vida do bloco continue expondo sua própria violação.
export '../../core/result.dart' show StudyBlockViolation;

/// Bloco de Estudo sem estado, duração acumulada ou reconciliação manual.
final class StudyBlock {
  const StudyBlock({
    required this.id,
    required this.operationalDate,
    required this.startedAt,
    required this.blockDeadline,
    this.endedAt,
  });

  final String id;
  final OperationalDate operationalDate;
  final tz.TZDateTime startedAt;
  final tz.TZDateTime blockDeadline;
  final tz.TZDateTime? endedAt;

  bool get isOrphan => endedAt == null;

  static Result<StudyBlock, StudyBlockViolation> start({
    required String id,
    required OperationalDate operationalDate,
    required tz.TZDateTime startedAt,
    required tz.TZDateTime blockDeadline,
  }) {
    if (!startedAt.isBefore(blockDeadline)) {
      return const Result.failure(
        StudyBlockViolation(
          code: 'study_deadline_reached',
          message: 'O expediente de estudo já encerrou.',
        ),
      );
    }
    return Result.success(
      StudyBlock(
        id: id,
        operationalDate: operationalDate,
        startedAt: startedAt,
        blockDeadline: blockDeadline,
      ),
    );
  }

  Result<StudyBlock, StudyBlockViolation> endAt(tz.TZDateTime at) {
    if (endedAt != null) return Result.success(this);
    if (at.isBefore(startedAt)) {
      return const Result.failure(
        StudyBlockViolation(
          code: 'study_end_before_start',
          message: 'O fim do estudo não pode anteceder seu início.',
        ),
      );
    }
    return Result.success(
      _withEnd(at.isBefore(blockDeadline) ? at : blockDeadline),
    );
  }

  StudyBlock closeAtDeadline() =>
      endedAt == null ? _withEnd(blockDeadline) : this;

  StudyBlock _withEnd(tz.TZDateTime value) => StudyBlock(
    id: id,
    operationalDate: operationalDate,
    startedAt: startedAt,
    blockDeadline: blockDeadline,
    endedAt: value,
  );
}
