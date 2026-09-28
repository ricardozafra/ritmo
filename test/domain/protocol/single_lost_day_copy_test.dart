import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/protocol/single_lost_day_copy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  const deriver = SingleLostDayCopyDeriver();
  final activation = OperationalDate(2026, 1, 5);

  test('disponibiliza a copy literal em cinza neutro para um único dia', () {
    final presentation = deriver.derive([_day(5)], activation);

    expect(presentation, isNotNull);
    expect(presentation!.text, Copy.singleLostDay);
    expect(presentation.color, FailureCopyColor.neutralGray);
  });

  test('não disponibiliza a copy sem falha ou com duas falhas correntes', () {
    expect(deriver.derive([_day(5, sealed: true)], activation), isNull);
    expect(deriver.derive([_day(5), _day(6)], activation), isNull);
  });

  test('dia selado encerra a sequência anterior', () {
    final presentation = deriver.derive([
      _day(5),
      _day(6, sealed: true),
      _day(7),
    ], activation);

    expect(presentation?.text, Copy.singleLostDay);
  });

  test(
    'ignora pré-ativação, mute e dia aberto sem interromper a sequência',
    () {
      final input = [
        _day(4),
        _day(5),
        _day(6, mute: true, workday: false),
        _day(7, closed: false),
      ];

      final presentation = deriver.derive(input.reversed.toList(), activation);

      expect(presentation?.text, Copy.singleLostDay);
      expect(input.map((day) => day.date.day), [4, 5, 6, 7]);
    },
  );
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
