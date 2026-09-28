import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/limits.dart';
import 'package:ritmo/core/result.dart';

void main() {
  const policy = LimitPolicy();

  group('Limits', () {
    test('declara os limites normativos em uma única fonte', () {
      expect(Limits.editableNameMaxRunes, 120);
      expect(Limits.shortTextMaxRunes, 500);
      expect(Limits.protocolTextMaxRunes, 2000);
      expect(Limits.weeklyReviewAnswerMaxRunes, 5000);
      expect(Limits.checkpointNotesMaxRunes, 2000);
      expect(Limits.cyclePurposeMaxRunes, 1000);
      expect(Limits.manifestMaxUtf8Bytes, 1048576);
    });
  });

  group('LimitPolicy.clampRunes', () {
    test('aceita conteúdo no limite sem alteração', () {
      final result = policy.clampRunes('ritmo', 5);

      expect(result.accepted, 'ritmo');
      expect(result.rejected, isEmpty);
      expect(result.exceeded, isFalse);
      expect(result.violation, isNull);
    });

    test('bloqueia somente o excedente e o expõe explicitamente', () {
      final result = policy.clampRunes('ritmo', 3);

      expect(result.accepted, 'rit');
      expect(result.rejected, 'mo');
      expect(result.original, 'ritmo');
      expect(result.wasClamped, isTrue);
      expect(result.violation?.actual, 5);
      expect(result.violation?.maximum, 3);
    });

    test('conta emoji fora do BMP como um rune', () {
      final result = policy.clampRunes('A😀B', 2);

      expect(result.accepted, 'A😀');
      expect(result.rejected, 'B');
      expect(result.acceptedRunes, 2);
    });

    test('conta marcas combinantes como code points separados', () {
      final result = policy.clampRunes('e\u0301x', 2);

      expect(result.accepted, 'e\u0301');
      expect(result.rejected, 'x');
      expect(result.acceptedRunes, 2);
    });

    test('não impõe mínimo implícito', () {
      final empty = policy.clampRunes('', 0);
      final blocked = policy.clampRunes('a', 0);

      expect(empty.accepted, isEmpty);
      expect(empty.exceeded, isFalse);
      expect(blocked.accepted, isEmpty);
      expect(blocked.rejected, 'a');
    });

    test('rejeita configuração negativa em vez de inventar um mínimo', () {
      expect(() => policy.clampRunes('a', -1), throwsArgumentError);
    });
  });

  group('LimitPolicy.assertManifestSize', () {
    test('aceita exatamente 1 MiB em bytes UTF-8', () {
      final markdown = List.filled(524288, 'á').join();
      final result = policy.assertManifestSize(markdown);

      expect(result, isA<Success<void, LimitViolation>>());
    });

    test('rejeita acima de 1 MiB e informa bytes, não runes', () {
      final markdown = '${List.filled(524288, 'á').join()}a';
      final result = policy.assertManifestSize(markdown);

      expect(result, isA<Failure<void, LimitViolation>>());
      final violation = (result as Failure<void, LimitViolation>).failure;
      expect(violation.actual, Limits.manifestMaxUtf8Bytes + 1);
      expect(violation.maximum, Limits.manifestMaxUtf8Bytes);
      expect(violation.unit, LimitUnit.utf8Bytes);
    });
  });
}
