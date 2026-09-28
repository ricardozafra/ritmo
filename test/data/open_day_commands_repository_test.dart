import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/open_day_commands_repository.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late RitmoDatabase database;
  late OpenDayCommandsRepository commands;
  late tz.Location location;
  final date = OperationalDate(2026, 5, 4);
  const calendar = OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(3, 0),
    nightEndTime: LocalTimeOfDay(1, 0),
  );

  setUp(() async {
    database = RitmoDatabase(NativeDatabase.memory());
    location = ensureBusinessLocation();
    final clock = SystemOperationalClock(
      calendar: calendar,
      businessLocation: location,
    );
    commands = OpenDayCommandsRepository(database, clock: clock);
    await DayRepository(
      database,
      businessLocation: location,
    ).ensureDayMaterialized(date);
  });

  tearDown(() => database.close());

  test('morning and day fields can be undone while open and unsealed', () async {
    final at = tz.TZDateTime(location, 2026, 5, 4, 9);
    expect(_success(await commands.setWorkout(date, done: true, at: at)).workoutDone, isTrue);
    expect(_success(await commands.setWorkout(date, done: false)).workoutDone, isFalse);
  });
}

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Expected success, got ${failure.code}: ${failure.message}',
  ),
);
