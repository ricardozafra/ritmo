import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/limits.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/change_initiative.dart';

void main() {
  test('creates an active initiative with normalized required fields', () {
    final result = ChangeInitiative.create(
      id: ' initiative-1 ',
      name: ' Mudança deliberada ',
    );

    final initiative = _success(result);
    expect(initiative.id, 'initiative-1');
    expect(initiative.name, 'Mudança deliberada');
    expect(initiative.active, isTrue);
  });

  test('rejects blank identifiers and names', () {
    expect(
      _failureCode(ChangeInitiative.create(id: ' ', name: 'Válida')),
      'change_initiative_id_empty',
    );
    expect(
      _failureCode(ChangeInitiative.create(id: 'initiative-1', name: '  ')),
      'change_initiative_name_empty',
    );
  });

  test('rejects names beyond the editable-name limit without truncation', () {
    final name = List.filled(Limits.editableNameMaxRunes + 1, 'á').join();

    final result = ChangeInitiative.create(id: 'initiative-1', name: name);

    final failure = result.fold<BusinessViolation?>(
      onSuccess: (_) => null,
      onFailure: (value) => value,
    );
    expect(failure, isA<LimitViolation>());
    expect((failure! as LimitViolation).actual, name.runes.length);
  });
}

T _success<T>(Result<T, BusinessViolation> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode<T>(Result<T, BusinessViolation> result) =>
    result.fold(onSuccess: (_) => null, onFailure: (failure) => failure.code);
