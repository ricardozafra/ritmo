import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/time/operational_calendar.dart';
import 'database.dart';

/// Corpo de escrita executado no mesmo contexto transacional da guarda.
typedef TransactionalWrite<T> = Future<T> Function();

/// Protege mutações de revisões semanais.
///
/// A leitura do estado e [write] compartilham a mesma transação. Assim, uma
/// revisão finalizada não pode ser alterada por uma decisão tomada sobre um
/// estado obsoleto.
final class GuardedWriter {
  GuardedWriter(this._database);

  final RitmoDatabase _database;

  Future<Result<T, ReviewViolation>> writeReview<T>({
    required String reviewId,
    required TransactionalWrite<T> write,
  }) {
    return _database.transaction(() async {
      final guard = await assertMutableReview(reviewId);
      if (guard case Failure<void, ReviewViolation>(:final failure)) {
        return Result<T, ReviewViolation>.failure(failure);
      }

      // A guarda deve permanecer imediatamente antes da mutação.
      return Result<T, ReviewViolation>.success(await write());
    });
  }

  /// Deve ser chamado dentro da transação que realizará a escrita.
  Future<Result<void, ReviewViolation>> assertMutableReview(
    String reviewId,
  ) async {
    final row = await _database
        .customSelect(
          'SELECT state FROM weekly_reviews WHERE id = ? LIMIT 1',
          variables: [Variable.withString(reviewId)],
        )
        .getSingleOrNull();

    if (row == null) {
      return const Result<void, ReviewViolation>.failure(
        ReviewViolation(
          code: 'review_not_found',
          message: 'A revisão informada não existe.',
        ),
      );
    }

    if (row.read<String>('state') == 'finalized') {
      return const Result<void, ReviewViolation>.failure(
        ReviewViolation(
          code: 'review_finalized',
          message: 'A revisão finalizada está disponível somente para leitura.',
        ),
      );
    }

    return const Result<void, ReviewViolation>.success(null);
  }
}

/// Porta obrigatória para toda escrita ordinária vinculada a um dia.
final class GuardedDayWriter {
  GuardedDayWriter(this._database);

  final RitmoDatabase _database;

  Future<Result<T, DayViolation>> write<T>({
    required String operationalDate,
    required TransactionalWrite<T> write,
  }) {
    return _database.transaction(() async {
      final guard = await assertMutable(operationalDate);
      if (guard case Failure<void, DayViolation>(:final failure)) {
        return Result<T, DayViolation>.failure(failure);
      }

      // A guarda deve permanecer imediatamente antes da mutação.
      return Result<T, DayViolation>.success(await write());
    });
  }

  /// Verifica o `closed_at` no mesmo snapshot transacional da mutação.
  ///
  /// Este método existe para composições transacionais; chamadores devem
  /// preferir [write], que garante seu posicionamento imediatamente antes da
  /// escrita.
  Future<Result<void, DayViolation>> assertMutable(
    String operationalDate,
  ) async {
    final row = await _database
        .customSelect(
          'SELECT closed_at FROM days WHERE operational_date = ? LIMIT 1',
          variables: [Variable.withString(operationalDate)],
        )
        .getSingleOrNull();

    if (row == null) {
      return const Result<void, DayViolation>.failure(
        DayViolation(
          code: 'day_not_found',
          message: 'A data operacional informada não existe.',
        ),
      );
    }

    if (row.readNullable<int>('closed_at') != null) {
      return const Result<void, DayViolation>.failure(
        DayViolation(
          code: 'day_closed',
          message: 'O dia encerrado está disponível somente para leitura.',
        ),
      );
    }

    return const Result<void, DayViolation>.success(null);
  }
}

/// Exceção deliberada à guarda diária para classificação por feriado.
///
/// Esta classe não recebe callback de escrita e altera exclusivamente
/// `effective_result`, `mute_cause` e `previous_result`. Registros ordinários,
/// resultado base, selo, lifecycle e data operacional ficam fora desta API.
final class HolidayReclassifier {
  HolidayReclassifier(this._database);

  final RitmoDatabase _database;

  Future<Result<void, DayViolation>> apply(String operationalDate) {
    return _database.transaction(() async {
      final day = await _readDay(operationalDate);
      if (day == null) return _missingDay();

      if (day.muteCause == 'holiday') {
        return const Result<void, DayViolation>.success(null);
      }
      final previousResult = day.effectiveResult == 'mute'
          ? day.baseResult
          : day.effectiveResult;

      await _database.customUpdate(
        'UPDATE days SET effective_result = ?, mute_cause = ?, '
        'previous_result = ? WHERE operational_date = ?',
        variables: [
          Variable.withString('mute'),
          Variable.withString('holiday'),
          Variable.withString(previousResult),
          Variable.withString(operationalDate),
        ],
        updates: {_database.days},
      );
      return const Result<void, DayViolation>.success(null);
    });
  }

  Future<Result<void, DayViolation>> remove(String operationalDate) {
    return _database.transaction(() async {
      final day = await _readDay(operationalDate);
      if (day == null) return _missingDay();
      if (day.muteCause != 'holiday' || day.previousResult == null) {
        return const Result<void, DayViolation>.failure(
          DayViolation(
            code: 'day_not_holiday',
            message: 'A data operacional não está classificada como feriado.',
          ),
        );
      }

      if (_date(operationalDate).isWeekend) {
        await _database.customUpdate(
          'UPDATE days SET effective_result = ?, mute_cause = ?, '
          'previous_result = NULL WHERE operational_date = ?',
          variables: [
            Variable.withString('mute'),
            Variable.withString('weekend'),
            Variable.withString(operationalDate),
          ],
          updates: {_database.days},
        );
      } else {
        await _database.customUpdate(
          'UPDATE days SET effective_result = ?, mute_cause = NULL '
          'WHERE operational_date = ?',
          variables: [
            Variable.withString(day.previousResult!),
            Variable.withString(operationalDate),
          ],
          updates: {_database.days},
        );
      }
      return const Result<void, DayViolation>.success(null);
    });
  }

  OperationalDate _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw StateError('Data operacional persistida inválida: $iso.');
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<_DayClassification?> _readDay(String operationalDate) async {
    final row = await _database
        .customSelect(
          'SELECT base_result, effective_result, mute_cause, previous_result '
          'FROM days WHERE operational_date = ? LIMIT 1',
          variables: [Variable.withString(operationalDate)],
        )
        .getSingleOrNull();
    if (row == null) return null;

    return _DayClassification(
      baseResult: row.read<String>('base_result'),
      effectiveResult: row.read<String>('effective_result'),
      muteCause: row.readNullable<String>('mute_cause'),
      previousResult: row.readNullable<String>('previous_result'),
    );
  }

  Result<void, DayViolation> _missingDay() {
    return const Result<void, DayViolation>.failure(
      DayViolation(
        code: 'day_not_found',
        message: 'A data operacional informada não existe.',
      ),
    );
  }
}

final class _DayClassification {
  const _DayClassification({
    required this.baseResult,
    required this.effectiveResult,
    required this.muteCause,
    required this.previousResult,
  });

  final String baseResult;
  final String effectiveResult;
  final String? muteCause;
  final String? previousResult;
}
