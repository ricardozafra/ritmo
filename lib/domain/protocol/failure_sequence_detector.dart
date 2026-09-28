import '../day/eligible_day.dart';
import '../time/operational_calendar.dart';

/// Sequência de pelo menos dois dias úteis encerrados e não selados.
final class FailureSequence {
  const FailureSequence._({
    required this.generationId,
    required this.startDate,
    required this.endDate,
    required this.length,
  });

  final String generationId;
  final OperationalDate startDate;
  final OperationalDate endDate;
  final int length;

  @override
  bool operator ==(Object other) =>
      other is FailureSequence &&
      other.generationId == generationId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.length == length;

  @override
  int get hashCode => Object.hash(generationId, startDate, endDate, length);

  @override
  String toString() =>
      'FailureSequence($generationId, ${startDate.iso}..${endDate.iso}, '
      'length: $length)';
}

/// Detecta sequências de falha sem consultar relógio, estado global ou I/O.
final class FailureSequenceDetector {
  const FailureSequenceDetector();

  /// Retorna as sequências em ordem cronológica, sem modificar [timeline].
  List<FailureSequence> detect(
    List<EligibleDay> timeline,
    OperationalDate activationDate,
  ) {
    final ordered = List<EligibleDay>.of(timeline)
      ..sort((left, right) => left.date.compareTo(right.date));
    final sequences = <FailureSequence>[];
    OperationalDate? startDate;
    OperationalDate? endDate;
    var length = 0;

    void finishSequence() {
      if (length >= 2) {
        final start = startDate!;
        sequences.add(
          FailureSequence._(
            generationId: 'seq:${start.iso}',
            startDate: start,
            endDate: endDate!,
            length: length,
          ),
        );
      }
      startDate = null;
      endDate = null;
      length = 0;
    }

    for (final day in ordered) {
      if (day.date < activationDate) continue;
      if (day.isMute || !day.isWorkday) continue;

      // Um dia útil aberto ainda não é falha; um selado encerra a cadeia.
      if (!day.isClosed || day.isSealed) {
        finishSequence();
        continue;
      }

      startDate ??= day.date;
      endDate = day.date;
      length++;
    }
    finishSequence();

    return List<FailureSequence>.unmodifiable(sequences);
  }
}
