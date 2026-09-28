import '../time/operational_calendar.dart';
import 'contact.dart';

/// Estado persistido de uma sugestão semanal (RD-19).
enum SuggestionStatus { pending, done, skipped }

/// Registro persistido de um contato dentro da progressão de uma semana.
final class WeeklyContactSuggestion {
  const WeeklyContactSuggestion({
    required this.weekStart,
    required this.contactId,
    required this.status,
    required this.createdAtMillisecondsSinceEpoch,
  });

  final OperationalDate weekStart;
  final String contactId;
  final SuggestionStatus status;
  final int createdAtMillisecondsSinceEpoch;
}

/// Segunda-feira operacional que nomeia a semana de [date] (RF-07.5).
///
/// A semana operacional é renovada na abertura operacional de segunda; a data
/// operacional de segunda-feira é o `week_start`. Puro: recua até a segunda
/// pela contagem ISO de dia da semana (1 = segunda ... 7 = domingo).
OperationalDate operationalWeekStart(OperationalDate date) =>
    date.addDays(1 - date.weekday);

/// Apresentação imutável da sugestão vigente e da progressão da semana.
final class WeeklySuggestionView {
  const WeeklySuggestionView({
    required this.weekStart,
    required this.suggestedContact,
    required this.exhausted,
    required this.hasContacts,
  });

  /// Nenhum contato cadastrado: a interface mostra o convite único (RF-07.13).
  const WeeklySuggestionView.empty(this.weekStart)
    : suggestedContact = null,
      exhausted = false,
      hasContacts = false;

  final OperationalDate weekStart;

  /// Contato sugerido nesta semana; nulo quando não há sugestão vigente.
  final Contact? suggestedContact;

  /// Todos os contatos da ordem já foram visitados ou adiados (RF-07.11).
  final bool exhausted;

  /// Existe ao menos um contato cadastrado.
  final bool hasContacts;
}

/// Regras puras da progressão semanal, sem relógio, persistência ou efeitos.
///
/// A sugestão vigente é o primeiro contato da ordem semanal que ainda não foi
/// registrado (`pending`, `done` ou `skipped`) nesta semana. Um contato criado
/// no meio da semana entra ao final da ordem e, portanto, não substitui uma
/// sugestão já persistida (RF-07.8, RF-07.17). Quando todos os contatos da
/// ordem já possuem registro, a semana está esgotada e não reinicia (RF-07.11).
final class WeeklySuggestionProgression {
  const WeeklySuggestionProgression();

  /// Deriva a apresentação a partir da ordem semanal e das linhas persistidas
  /// da semana [weekStart]. [orderedContacts] deve vir de `ContactOrdering`.
  WeeklySuggestionView project({
    required OperationalDate weekStart,
    required List<Contact> orderedContacts,
    required List<WeeklyContactSuggestion> weekRows,
  }) {
    if (orderedContacts.isEmpty) {
      return WeeklySuggestionView.empty(weekStart);
    }

    final recorded = <String>{
      for (final row in weekRows)
        if (row.weekStart == weekStart) row.contactId,
    };

    for (final contact in orderedContacts) {
      if (!recorded.contains(contact.id)) {
        return WeeklySuggestionView(
          weekStart: weekStart,
          suggestedContact: contact,
          exhausted: false,
          hasContacts: true,
        );
      }
    }

    return WeeklySuggestionView(
      weekStart: weekStart,
      suggestedContact: null,
      exhausted: true,
      hasContacts: true,
    );
  }

  /// Próximo contato a receber uma sugestão `pending`, ignorando os já
  /// registrados na semana. Nulo quando a ordem está esgotada. Usado pelo
  /// repositório para materializar/avançar sem reiniciar a semana.
  Contact? nextUnrecorded({
    required List<Contact> orderedContacts,
    required Iterable<String> recordedContactIds,
  }) {
    final recorded = recordedContactIds.toSet();
    for (final contact in orderedContacts) {
      if (!recorded.contains(contact.id)) return contact;
    }
    return null;
  }
}
