import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/protocol/failure_sequence_detector.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  const detector = FailureSequenceDetector();
  final activation = OperationalDate(2026, 1, 1);

  test('detecta a sequência e deriva a geração da primeira data', () {
    final sequence = detector.detect(
      [_day(5), _day(6), _day(7)],
      activation,
    ).single;

    expect(sequence.generationId, 'seq:2026-01-05');
    expect(sequence.startDate, OperationalDate(2026, 1, 5));
    expect(sequence.endDate, OperationalDate(2026, 1, 7));
    expect(sequence.length, 3);
  });

  test('ignora dias mute entre sexta e a segunda útil seguinte', () {
    final sequence = detector.detect(
      [
        _day(2),
        _day(3, mute: true, workday: false),
        _day(4, mute: true, workday: false),
        _day(5),
      ],
      activation,
    ).single;

    expect(sequence.startDate, OperationalDate(2026, 1, 2));
    expect(sequence.endDate, OperationalDate(2026, 1, 5));
    expect(sequence.length, 2);
  });

  test('ignora pré-ativação e dia selado parte sequências', () {
    final sequences = detector.detect(
      [
        _day(5),
        _day(6),
        _day(7, sealed: true),
        _day(8),
        _day(9),
      ],
      OperationalDate(2026, 1, 6),
    );

    expect(sequences, hasLength(1));
    expect(sequences.single.generationId, 'seq:2026-01-08');
    expect(sequences.single.length, 2);
  });

  test('é determinístico para a mesma timeline sem alterar a entrada', () {
    final input = [_day(7), _day(5), _day(6)];
    final originalOrder = input.map((day) => day.date).toList();

    final first = detector.detect(input, activation);
    final second = detector.detect(input, activation);

    expect(first, second);
    expect(input.map((day) => day.date), originalOrder);
    expect(first.single.generationId, 'seq:2026-01-05');
    expect(first.single.endDate, OperationalDate(2026, 1, 7));
  });

  test('dia aberto não conta como falha nem apaga sequência já encerrada', () {
    final sequences = detector.detect(
      [_day(5), _day(6), _day(7, closed: false)],
      activation,
    );

    expect(sequences, hasLength(1));
    expect(sequences.single.length, 2);
    expect(sequences.single.endDate, OperationalDate(2026, 1, 6));
  });
}

EligibleDay _day(
  int day, {
  bool sealed = false,
  bool closed = true,
  bool mute = false,
  bool workday = true,
}) => EligibleDay(
  date: OperationalDate(2026, 1, day),
  isWorkday: workday,
  isClosed: closed,
  isSealed: sealed,
  isMute: mute,
);
