import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';

void main() {
  group('Result', () {
    test('representa sucesso e transforma somente o valor', () {
      const result = Result<int, LimitViolation>.success(21);
      final mapped = result.map((value) => value * 2);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(mapped, isA<Success<int, LimitViolation>>());
      expect((mapped as Success<int, LimitViolation>).value, 42);
    });

    test('preserva falha ao mapear e direciona fold', () {
      const violation = LimitViolation(
        actual: 2,
        maximum: 1,
        unit: LimitUnit.runes,
      );
      const result = Result<int, LimitViolation>.failure(violation);

      final mapped = result.map((value) => value * 2);
      final description = result.fold(
        onSuccess: (value) => '$value',
        onFailure: (failure) => failure.code,
      );

      expect(result.isFailure, isTrue);
      expect(mapped, isA<Failure<int, LimitViolation>>());
      expect((mapped as Failure<int, LimitViolation>).failure, same(violation));
      expect(description, 'limit_exceeded');
    });
  });

  group('RitmoFailure', () {
    test('separa violações de negócio de falhas de infraestrutura', () {
      const business = DayViolation();
      const infrastructure = StorageFailure();

      expect(business, isA<BusinessViolation>());
      expect(infrastructure, isA<InfrastructureFailure>());
      expect(business, isNot(isA<InfrastructureFailure>()));
    });
  });
}
