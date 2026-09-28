import '../../core/result.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/weekly_contact_suggestion_repository.dart';
import '../../domain/people/contact.dart';
import '../../domain/people/weekly_contact_suggestion.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';

/// Coordena a progressão semanal de sugestões de contato (RF-07.7 a RF-07.12,
/// RF-07.15). A semana operacional e o instante vêm do relógio oficial; a
/// ordem semanal vem de `ContactOrdering`. Nada é premiado, pontuado ou
/// penalizado, e a escolha manual e o ato de pular não têm penalidade.
final class WeeklySuggestionController {
  WeeklySuggestionController(
    this._suggestions,
    this._contacts, {
    required Future<OperationalClock> Function() loadClock,
    this.onChanged,
    ContactOrdering ordering = const ContactOrdering(),
    // `loadClock`/`ordering` compõem a API nomeada pública; os campos privados
    // os mantêm internos.
    // ignore: prefer_initializing_formals
  }) : _loadClock = loadClock,
       // ignore: prefer_initializing_formals
       _ordering = ordering;

  final WeeklyContactSuggestionRepository _suggestions;
  final ContactRepository _contacts;
  final Future<OperationalClock> Function() _loadClock;
  final ContactOrdering _ordering;
  final void Function()? onChanged;

  /// Garante que a semana vigente tenha uma sugestão `pending` quando ainda há
  /// contatos não registrados; idempotente e nunca reinicia a ordem.
  Future<Result<void, RitmoFailure>> ensureCurrent() =>
      _run((clock, weekStart, ordered) async {
        await _suggestions.ensureCurrentSuggestion(
          weekStart: weekStart,
          orderedContacts: ordered,
          at: clock.nowInBusinessZone(),
        );
      });

  /// Marca a ponte com [contactId] como realizada e registra o toque na data
  /// operacional vigente (RF-07.9).
  Future<Result<void, RitmoFailure>> markDone(String contactId) =>
      _run((clock, weekStart, ordered) async {
        final ok = await _suggestions.markDone(
          weekStart: weekStart,
          contactId: contactId,
          touchedOn: clock.operationalDateNow(),
        );
        if (!ok) throw const _NoActiveSuggestion();
      });

  /// Pula a sugestão vigente e avança ao próximo contato, sem penalidade
  /// (RF-07.10, RF-07.11).
  Future<Result<void, RitmoFailure>> skip(String contactId) =>
      _run((clock, weekStart, ordered) async {
        final ok = await _suggestions.skip(
          weekStart: weekStart,
          contactId: contactId,
          orderedContacts: ordered,
          at: clock.nowInBusinessZone(),
        );
        if (!ok) throw const _NoActiveSuggestion();
      });

  /// Escolha manual de um contato sem penalidade (RF-07.12).
  Future<Result<void, RitmoFailure>> chooseManually(String contactId) =>
      _run((clock, weekStart, ordered) async {
        await _suggestions.chooseManually(
          weekStart: weekStart,
          contactId: contactId,
          touchedOn: clock.operationalDateNow(),
        );
      });

  Future<Result<void, RitmoFailure>> _run(
    Future<void> Function(
      OperationalClock clock,
      OperationalDate weekStart,
      List<Contact> ordered,
    )
    operation,
  ) async {
    try {
      final clock = await _loadClock();
      final weekStart = operationalWeekStart(clock.operationalDateNow());
      final contacts = await _contacts.watchAll().first;
      final ordered = _ordering.weeklyOrder(contacts);
      await operation(clock, weekStart, ordered);
      onChanged?.call();
      return const Result<void, RitmoFailure>.success(null);
    } on _NoActiveSuggestion {
      return const Result<void, RitmoFailure>.failure(
        ContactViolation(
          code: 'weekly_suggestion_not_active',
          message: 'Não há sugestão vigente para esta ação.',
        ),
      );
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    }
  }
}

/// Sinaliza, dentro de [_run], que a linha esperada não estava `pending`.
final class _NoActiveSuggestion implements Exception {
  const _NoActiveSuggestion();
}
