import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/metrics/metrics_calculator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  const calculator = MetricsCalculator();
  final activation = OperationalDate(2026, 1, 5);

  test('calcula 3/4 e exclui o quinto dia ainda aberto', () {
    final days = [
      _day(5, sealed: true),
      _day(6, sealed: true),
      _day(7, sealed: true),
      _day(8),
      _day(9, sealed: true, closed: false),
    ];

    expect(
      calculator.rate(days, activation),
      Rate(numerator: 3, denominator: 4),
    );
  });

  test('exclui datas pré-ativação, dias mute e dias não úteis', () {
    final days = [
      _day(2, sealed: true),
      _day(5, sealed: true),
      _day(6, sealed: true, mute: true),
      _day(10, sealed: true, workday: false),
    ];

    expect(
      calculator.rate(days, activation),
      Rate(numerator: 1, denominator: 1),
    );
  });

  test('dia encerrado selado conta integralmente sem dados de pilar', () {
    final projectedDay = _day(5, sealed: true);

    expect(
      calculator.rate([projectedDay], activation),
      Rate(numerator: 1, denominator: 1),
    );
  });

  test('retorna 0/0 quando não há dia elegível encerrado', () {
    expect(calculator.rate([_day(5, closed: false)], activation), Rate.zero);
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
