import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/controllers/holiday_controller.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/holiday_recalculation.dart';
import 'package:ritmo/domain/holidays/holiday_recalculation.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

void main() {
  test('invalidates derived reads only after a committed change', () async {
    final database = RitmoDatabase(NativeDatabase.memory());
    final date = OperationalDate(2026, 1, 5);
    final service = HolidayRecalculation(
      database,
      clock: SystemOperationalClock(
        deviceInstant: () => DateTime.utc(2026, 1, 5, 12),
      ),
    );
    var invalidations = 0;
    final controller = HolidayController(service, () => invalidations++);
    await database.customStatement(
      "UPDATE settings SET activation_date = '2026-01-05' WHERE id = 1",
    );
    await database.customStatement(
      "INSERT INTO days (operational_date, base_result, effective_result) "
      "VALUES ('2026-01-05', 'unsealed', 'unsealed')",
    );

    final unconfirmed = await controller.apply(date, confirmed: false);
    expect(unconfirmed, isA<Failure<RecalcReport, HolidayViolation>>());
    expect(
      (unconfirmed as Failure<RecalcReport, HolidayViolation>).failure.code,
      'holiday_confirmation_required',
    );
    expect(invalidations, 0);

    controller.preview(date, HolidayOperation.apply);
    final first = await controller.apply(date, confirmed: true);
    controller.preview(date, HolidayOperation.apply);
    final repeated = await controller.apply(date, confirmed: true);
    controller.preview(date, HolidayOperation.remove);
    final removed = await controller.remove(date, confirmed: true);

    expect(first, isA<Success<RecalcReport, HolidayViolation>>());
    expect(repeated, isA<Success<RecalcReport, HolidayViolation>>());
    expect(removed, isA<Success<RecalcReport, HolidayViolation>>());
    expect(invalidations, 2);

    await service.dispose();
    await database.close();
  });

  test('exposes the neutral preview before confirmation', () async {
    final database = RitmoDatabase(NativeDatabase.memory());
    final service = HolidayRecalculation(database);
    final controller = HolidayController(service, () {});
    final preview = controller.preview(
      OperationalDate(2026, 1, 5),
      HolidayOperation.apply,
    );

    expect(preview.title, 'Confirmar feriado');
    expect(preview.message, contains('preservados'));

    await service.dispose();
    await database.close();
  });
}
