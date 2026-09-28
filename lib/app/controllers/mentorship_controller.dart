import 'package:drift/drift.dart';

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../data/repositories/mentorship_repository.dart';
import '../../domain/time/operational_calendar.dart';

/// Edita os cartões fixos de mentoria: nome do mentor e data do último
/// encontro (RF-07.2). Nunca cria, remove ou reordena cartões, e nunca agenda
/// notificações — o alerta de recência é puramente visual (RF-07.21).
final class MentorshipController {
  MentorshipController(
    this._repository, {
    this.onChanged,
    this.limitPolicy = const LimitPolicy(),
  });

  final MentorshipRepository _repository;
  final void Function()? onChanged;
  final LimitPolicy limitPolicy;

  /// Define o nome do mentor, aceitando no máximo 120 caracteres Unicode
  /// (RF-04.28). Texto vazio limpa o nome.
  Future<Result<void, RitmoFailure>> setMentorName(
    String id, {
    required String? name,
  }) async {
    final normalized = _normalizeName(name);
    if (normalized case Failure<String?, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final value = (normalized as Success<String?, RitmoFailure>).value;
    return _write(
      () => _repository.updateCard(id: id, mentorName: Value(value)),
    );
  }

  /// Define a data do último encontro; `null` limpa a data.
  Future<Result<void, RitmoFailure>> setLastMeetingDate(
    String id, {
    required OperationalDate? date,
  }) => _write(
    () => _repository.updateCard(id: id, lastMeetingDate: Value(date?.iso)),
  );

  Future<Result<void, RitmoFailure>> _write(
    Future<bool> Function() operation,
  ) async {
    try {
      final changed = await operation();
      if (!changed) {
        return const Result<void, RitmoFailure>.failure(
          MentorshipViolation(
            code: 'mentorship_not_found',
            message: 'O cartão de mentoria informado não existe.',
          ),
        );
      }
      onChanged?.call();
      return const Result<void, RitmoFailure>.success(null);
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  Result<String?, RitmoFailure> _normalizeName(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const Result<String?, RitmoFailure>.success(null);
    }
    final clamped = limitPolicy.clampRunes(
      trimmed,
      Limits.editableNameMaxRunes,
    );
    final violation = clamped.violation;
    return violation == null
        ? Result<String?, RitmoFailure>.success(trimmed)
        : Result<String?, RitmoFailure>.failure(violation);
  }
}
