import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/change_initiatives_repository.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/pillar_entries_repository.dart';
import 'package:ritmo/domain/day/change_initiative.dart' as domain;
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

void main() {
  late RitmoDatabase database;
  late ChangeInitiativesRepository initiatives;

  setUp(() {
    database = RitmoDatabase(NativeDatabase.memory());
    initiatives = ChangeInitiativesRepository(database);
  });

  tearDown(() => database.close());

  test(
    'activating another initiative preserves history with only one active',
    () async {
      _success(
        await initiatives.createAndActivate(id: 'first', name: 'Primeira'),
      );
      _success(
        await initiatives.createAndActivate(id: 'second', name: 'Segunda'),
      );

      expect((await initiatives.active())?.id, 'second');
      final all = await initiatives.all();
      expect(all, hasLength(2));
      expect(all.where((initiative) => initiative.active), hasLength(1));
      expect((await initiatives.findById('first'))?.active, isFalse);
    },
  );

  test(
    'a duplicate identifier does not deactivate the current initiative',
    () async {
      _success(
        await initiatives.createAndActivate(id: 'first', name: 'Primeira'),
      );

      final duplicate = await initiatives.createAndActivate(
        id: 'first',
        name: 'Nome repetido',
      );

      expect(_failureCode(duplicate), 'change_initiative_already_exists');
      expect((await initiatives.active())?.id, 'first');
    },
  );

  test(
    'DayEntry captures the active initiative when it is first recorded',
    () async {
      final date = OperationalDate(2026, 5, 4);
      final days = DayRepository(database);
      final pillars = PillarEntriesRepository(database);
      await days.ensureDayMaterialized(date);
      _success(
        await initiatives.createAndActivate(id: 'first', name: 'Primeira'),
      );

      final firstEntry = _daySuccess(
        await pillars.recordDay(date, toggleOn: true),
      );
      _success(
        await initiatives.createAndActivate(id: 'second', name: 'Segunda'),
      );
      final updatedEntry = _daySuccess(
        await pillars.recordDay(date, toggleOn: false),
      );

      expect(firstEntry.changeInitiativeId, 'first');
      expect(updatedEntry.changeInitiativeId, 'first');
      expect((await initiatives.active())?.id, 'second');
    },
  );
}

domain.ChangeInitiative _success(
  Result<domain.ChangeInitiative, BusinessViolation> result,
) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

DayEntry _daySuccess(Result<DayEntry, DayViolation> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);

String? _failureCode<T>(Result<T, BusinessViolation> result) =>
    result.fold(onSuccess: (_) => null, onFailure: (failure) => failure.code);
