import '../day/eligible_day.dart';
import '../time/operational_calendar.dart';

/// Razão não gamificada entre dias selados e dias elegíveis.
final class Rate {
  factory Rate({required int numerator, required int denominator}) {
    if (numerator < 0 || denominator < 0 || numerator > denominator) {
      throw ArgumentError('Taxa inválida: $numerator/$denominator');
    }
    return Rate._(numerator, denominator);
  }

  const Rate._(this.numerator, this.denominator);

  static const zero = Rate._(0, 0);

  final int numerator;
  final int denominator;

  @override
  bool operator ==(Object other) =>
      other is Rate &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}

/// Calcula métricas puramente a partir do lifecycle e resultado dos dias.
final class MetricsCalculator {
  const MetricsCalculator();

  Rate rate(List<EligibleDay> timeline, OperationalDate activationDate) {
    var numerator = 0;
    var denominator = 0;
    for (final day in timeline) {
      final eligible =
          day.date >= activationDate &&
          day.isWorkday &&
          day.isClosed &&
          !day.isMute;
      if (!eligible) continue;
      denominator++;
      if (day.isSealed) numerator++;
    }
    return Rate(numerator: numerator, denominator: denominator);
  }
}
