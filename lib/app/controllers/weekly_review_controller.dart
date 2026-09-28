import '../../core/limits.dart';
import '../../core/result.dart';
import '../../data/repositories/weekly_review_repository.dart';
import '../../domain/people/weekly_contact_suggestion.dart'
    show operationalWeekStart;
import '../../domain/review/weekly_review.dart';
import '../../domain/time/operational_clock.dart';

/// Coordena o fluxo textual da Revisão Semanal (RF-08.1, RF-08.2, RF-08.22,
/// RF-08.23). A semana operacional e os instantes vêm do relógio oficial. Nada
/// finaliza implicitamente: a finalização é sempre explícita (RF-08.25).
final class WeeklyReviewController {
  WeeklyReviewController(
    this._repository, {
    required Future<OperationalClock> Function() loadClock,
    this.onChanged,
    this.limitPolicy = const LimitPolicy(),
    // `loadClock` compõe a API nomeada pública; `_loadClock` a mantém interna.
    // ignore: prefer_initializing_formals
  }) : _loadClock = loadClock;

  final WeeklyReviewRepository _repository;
  final Future<OperationalClock> Function() _loadClock;
  final void Function()? onChanged;
  final LimitPolicy limitPolicy;

  int _idCounter = 0;

  /// Garante que exista uma revisão `draft` para a semana vigente e a retorna.
  Future<Result<WeeklyReview, RitmoFailure>> ensureCurrentDraft() async {
    try {
      final clock = await _loadClock();
      final now = clock.nowInBusinessZone();
      final weekStart = operationalWeekStart(clock.operationalDateNow());
      final review = await _repository.ensureDraft(
        id: _nextId(now.microsecondsSinceEpoch),
        weekStart: weekStart,
        createdAt: now,
      );
      onChanged?.call();
      return Result<WeeklyReview, RitmoFailure>.success(review);
    } on Object catch (error) {
      return Result<WeeklyReview, RitmoFailure>.failure(
        DatabaseFailure(cause: error),
      );
    }
  }

  /// Autosava um campo da revisão em `draft` (RF-08.22). Texto vazio limpa o
  /// campo; acima de 5000 caracteres, rejeita sem gravar.
  Future<Result<void, RitmoFailure>> autosave(
    String id, {
    required WeeklyReviewField field,
    required String? value,
  }) async {
    final normalized = _normalizeAnswer(value);
    if (normalized case Failure<String?, RitmoFailure>(:final failure)) {
      return Result<void, RitmoFailure>.failure(failure);
    }
    final accepted = (normalized as Success<String?, RitmoFailure>).value;
    try {
      final clock = await _loadClock();
      final result = await _repository.autosaveField(
        id: id,
        field: field,
        value: accepted,
        at: clock.nowInBusinessZone(),
      );
      return result.fold(
        onSuccess: (_) {
          onChanged?.call();
          return const Result<void, RitmoFailure>.success(null);
        },
        onFailure: Result<void, RitmoFailure>.failure,
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  /// Finaliza a revisão, tornando-a read-only (RF-08.23). Exige as três
  /// respostas preenchidas; a finalização nunca é implícita.
  Future<Result<void, RitmoFailure>> finalize(WeeklyReview review) async {
    if (!review.isComplete) {
      return const Result<void, RitmoFailure>.failure(
        ReviewViolation(
          code: 'review_incomplete',
          message: 'Responda as três perguntas antes de finalizar.',
        ),
      );
    }
    try {
      final clock = await _loadClock();
      final result = await _repository.finalize(
        id: review.id,
        at: clock.nowInBusinessZone(),
      );
      return result.fold(
        onSuccess: (_) {
          onChanged?.call();
          return const Result<void, RitmoFailure>.success(null);
        },
        onFailure: Result<void, RitmoFailure>.failure,
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }

  Result<String?, RitmoFailure> _normalizeAnswer(String? raw) {
    final value = raw ?? '';
    if (value.isEmpty) {
      return const Result<String?, RitmoFailure>.success(null);
    }
    final clamped = limitPolicy.clampRunes(
      value,
      Limits.weeklyReviewAnswerMaxRunes,
    );
    final violation = clamped.violation;
    return violation == null
        ? Result<String?, RitmoFailure>.success(value)
        : Result<String?, RitmoFailure>.failure(violation);
  }

  String _nextId(int microseconds) => 'review-$microseconds-${_idCounter++}';
}
