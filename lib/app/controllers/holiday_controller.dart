import '../../core/result.dart';
import '../../data/repositories/holiday_recalculation.dart';
import '../../domain/holidays/holiday_recalculation.dart';
import '../../domain/time/operational_calendar.dart';

typedef DerivedHolidayInvalidator = void Function();

/// Orquestra confirmação e atualização das leituras derivadas após o commit.
final class HolidayController {
  const HolidayController(this._recalculation, this._invalidateDerived);

  final HolidayRecalculation _recalculation;
  final DerivedHolidayInvalidator _invalidateDerived;

  RecalcPreview preview(OperationalDate date, HolidayOperation operation) =>
      _recalculation.preview(date, operation);

  Future<Result<RecalcReport, HolidayViolation>> apply(
    OperationalDate date, {
    required bool confirmed,
    String? reasonText,
  }) => confirmed
      ? _run(() => _recalculation.apply(date, reasonText: reasonText))
      : Future.value(_confirmationRequired());

  Future<Result<RecalcReport, HolidayViolation>> remove(
    OperationalDate date, {
    required bool confirmed,
    String? reasonText,
  }) => confirmed
      ? _run(() => _recalculation.remove(date, reasonText: reasonText))
      : Future.value(_confirmationRequired());

  Result<RecalcReport, HolidayViolation> _confirmationRequired() =>
      const Result.failure(
        HolidayViolation(
          code: 'holiday_confirmation_required',
          message: 'Revise os efeitos antes de confirmar a alteração.',
        ),
      );

  Future<Result<RecalcReport, HolidayViolation>> _run(
    Future<Result<RecalcReport, HolidayViolation>> Function() operation,
  ) async {
    final result = await operation();
    if (result case Success<RecalcReport, HolidayViolation>(
      :final value,
    ) when value.holidayChanged) {
      _invalidateDerived();
    }
    return result;
  }
}
