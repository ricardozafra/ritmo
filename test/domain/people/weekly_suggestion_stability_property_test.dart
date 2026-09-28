// Feature: ritmo, Property 38: A sugestão persistida é estável na semana
//
// Para qualquer sugestão persistida para uma week_start e qualquer sequência
// de criações ou edições de contatos dentro da mesma semana, o contact_id da
// sugestão vigente permanece o mesmo até a próxima abertura operacional de
// segunda-feira.
//
// **Validates: Requirements RF-07.7, RF-07.8, RF-07.17**

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/weekly_contact_suggestion_repository.dart';
import 'package:ritmo/domain/people/contact.dart';
import 'package:ritmo/domain/people/weekly_contact_suggestion.dart' as domain;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _MutationAction = ({
  bool isNewContact,
  bool hasTouchDate,
  int contactIndex,
});

typedef _StabilityFixture = ({
  OperationalDate weekStart,
  int initialContactsCount,
  List<_MutationAction> mutations,
});

final Generator<_StabilityFixture> _anyStabilityFixture = any.simple(
  generate: (random, size) {
    final monday = anyOperationalDate(random, size).value;
    final weekStart = monday.addDays(1 - monday.weekday);

    final initialCount = 1 + random.nextInt(6);
    final mutationCount = 1 + random.nextInt(10);
    final mutations = List.generate(mutationCount, (_) {
      return (
        isNewContact: random.nextBool(),
        hasTouchDate: random.nextBool(),
        contactIndex: random.nextInt(initialCount),
      );
    });

    return (
      weekStart: weekStart,
      initialContactsCount: initialCount,
      mutations: mutations,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  const ordering = ContactOrdering();

  Glados<_StabilityFixture>(
    _anyStabilityFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 38: A sugestão persistida é estável na semana', (
    fixture,
  ) async {
    final database = db.RitmoDatabase(NativeDatabase.memory());
    final repository = WeeklyContactSuggestionRepository(database);
    final location = ensureBusinessLocation();
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(
      location,
      1767225600000,
    );

    try {
      final contacts = <Contact>[];
      for (var i = 0; i < fixture.initialContactsCount; i++) {
        final contact = Contact(
          id: 'initial-$i',
          name: 'Contato $i',
          createdAt: at.add(Duration(seconds: i)),
          lastTouchDate: OperationalDate(2026, 1, 1).addDays(i),
        );
        contacts.add(contact);
        await database
            .into(database.contacts)
            .insert(
              db.ContactsCompanion.insert(
                id: contact.id,
                name: contact.name,
                createdAt: contact.createdAt.millisecondsSinceEpoch,
              ),
            );
      }

      // Ordena e garante a sugestão inicial
      final initialOrder = ordering.weeklyOrder(contacts);
      await repository.ensureCurrentSuggestion(
        weekStart: fixture.weekStart,
        orderedContacts: initialOrder,
        at: at,
      );

      // Obtém o contact_id da sugestão vigente inicial
      final rowsInitial = await (database.select(
        database.weeklyContactSuggestions,
      )..where((r) => r.weekStart.equals(fixture.weekStart.iso))).get();
      final pendingInitial = rowsInitial.firstWhere(
        (r) => r.status == domain.SuggestionStatus.pending.name,
      );
      final initialContactId = pendingInitial.contactId;

      // Executa sequência de mutações (criações ou edições) dentro da mesma semana
      for (var m = 0; m < fixture.mutations.length; m++) {
        final mutation = fixture.mutations[m];
        if (mutation.isNewContact) {
          // Novo contato, possivelmente sem lastTouchDate (o que iria para o topo da ordem)
          final newContact = Contact(
            id: 'new-$m',
            name: 'Novo Contato $m',
            createdAt: at.add(Duration(seconds: 100 + m)),
            lastTouchDate: mutation.hasTouchDate
                ? fixture.weekStart.addDays(-1)
                : null,
          );
          contacts.add(newContact);
          await database
              .into(database.contacts)
              .insert(
                db.ContactsCompanion.insert(
                  id: newContact.id,
                  name: newContact.name,
                  createdAt: newContact.createdAt.millisecondsSinceEpoch,
                ),
              );
        } else {
          // Edição de contato existente
          final targetIdx = mutation.contactIndex % contacts.length;
          final existing = contacts[targetIdx];
          final updated = Contact(
            id: existing.id,
            name: '${existing.name} (editado)',
            createdAt: existing.createdAt,
            lastTouchDate: existing.lastTouchDate,
          );
          contacts[targetIdx] = updated;
          await (database.update(database.contacts)
                ..where((r) => r.id.equals(existing.id)))
              .write(db.ContactsCompanion(name: Value(updated.name)));
        }

        // Recalcula a nova ordem semanal
        final updatedOrder = ordering.weeklyOrder(contacts);

        // Re-garante a sugestão vigente
        await repository.ensureCurrentSuggestion(
          weekStart: fixture.weekStart,
          orderedContacts: updatedOrder,
          at: at.add(Duration(minutes: m + 1)),
        );

        // A sugestão vigente (pending) DEVE permanecer para o mesmo contact_id!
        final rowsAfter = await (database.select(
          database.weeklyContactSuggestions,
        )..where((r) => r.weekStart.equals(fixture.weekStart.iso))).get();
        final pendingAfter = rowsAfter.where(
          (r) => r.status == domain.SuggestionStatus.pending.name,
        );

        expect(pendingAfter.length, equals(1));
        expect(pendingAfter.first.contactId, equals(initialContactId));
      }
    } finally {
      await database.close();
    }
  });

  group('Propriedade 38: Teste determinístico de adição com carência máxima', () {
    test(
      'novo contato com lastTouchDate nula não rouba a sugestão já persistida',
      () async {
        final database = db.RitmoDatabase(NativeDatabase.memory());
        final repository = WeeklyContactSuggestionRepository(database);
        final location = ensureBusinessLocation();
        final at = tz.TZDateTime.fromMillisecondsSinceEpoch(
          location,
          1767225600000,
        );
        final weekStart = OperationalDate(2026, 3, 9);

        try {
          final c1 = Contact(
            id: 'c1',
            name: 'Primeiro',
            createdAt: at,
            lastTouchDate: OperationalDate(2026, 2, 1),
          );
          await database
              .into(database.contacts)
              .insert(
                db.ContactsCompanion.insert(
                  id: c1.id,
                  name: c1.name,
                  createdAt: c1.createdAt.millisecondsSinceEpoch,
                ),
              );

          await repository.ensureCurrentSuggestion(
            weekStart: weekStart,
            orderedContacts: [c1],
            at: at,
          );

          // Adiciona c2 que tem touch nulo (maior prioridade em ordem limpa)
          final c2 = Contact(
            id: 'c2',
            name: 'Prioritário',
            createdAt: at.add(const Duration(seconds: 1)),
            lastTouchDate: null,
          );
          await database
              .into(database.contacts)
              .insert(
                db.ContactsCompanion.insert(
                  id: c2.id,
                  name: c2.name,
                  createdAt: c2.createdAt.millisecondsSinceEpoch,
                ),
              );

          final newOrder = ordering.weeklyOrder([c1, c2]);
          expect(
            newOrder.first.id,
            equals('c2'),
          ); // Na nova ordem pura, c2 é o primeiro

          // Mas ensureCurrentSuggestion NÃO substitui c1 pois c1 já está persistido como pending na semana
          await repository.ensureCurrentSuggestion(
            weekStart: weekStart,
            orderedContacts: newOrder,
            at: at.add(const Duration(hours: 1)),
          );

          final rows = await (database.select(
            database.weeklyContactSuggestions,
          )..where((r) => r.weekStart.equals(weekStart.iso))).get();
          final pending = rows.where(
            (r) => r.status == domain.SuggestionStatus.pending.name,
          );
          expect(pending.length, equals(1));
          expect(pending.first.contactId, equals('c1'));
        } finally {
          await database.close();
        }
      },
    );
  });
}
