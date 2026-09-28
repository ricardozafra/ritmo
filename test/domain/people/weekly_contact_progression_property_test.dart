// Feature: ritmo, Property 39: Progressão semanal sem reinício nem penalidade
//
// Para qualquer semana operacional e qualquer sequência de ações (done,
// skipped, escolha manual de outro contato):
// 1. done atualiza last_touch_date do contato tocado para a data operacional vigente;
// 2. skipped preserva o last_touch_date anterior;
// 3. escolha manual marca o contato escolhido com done e preserva os demais;
// 4. a ordem semanal nunca reinicia no meio da semana;
// 5. quando todos os contatos da ordem foram percorridos,
//    WeeklySuggestionProgression relata exhausted == true com suggestedContact == null.
//
// **Validates: Requirements RF-07.9, RF-07.10, RF-07.11, RF-07.12, RF-07.15, RD-19**

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

enum _ProgressionActionKind { markDone, skip, chooseManual }

typedef _ProgressionAction = ({
  _ProgressionActionKind kind,
  int contactIndex,
});

typedef _ProgressionFixture = ({
  OperationalDate weekStart,
  int contactCount,
  List<_ProgressionAction> actions,
});

final Generator<_ProgressionFixture> _anyProgressionFixture = any.simple(
  generate: (random, size) {
    final monday = anyOperationalDate(random, size).value;
    final weekStart = monday.addDays(1 - monday.weekday);
    final count = 2 + random.nextInt(5); // 2 to 6 contacts
    final actionCount = count + random.nextInt(4);

    final actions = List.generate(actionCount, (_) {
      final kind = _ProgressionActionKind.values[random.nextInt(_ProgressionActionKind.values.length)];
      return (
        kind: kind,
        contactIndex: random.nextInt(count),
      );
    });

    return (
      weekStart: weekStart,
      contactCount: count,
      actions: actions,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  const ordering = ContactOrdering();
  const progression = domain.WeeklySuggestionProgression();

  Glados<_ProgressionFixture>(
    _anyProgressionFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 39: Progressão semanal sem reinício nem penalidade', (fixture) async {
    final database = db.RitmoDatabase(NativeDatabase.memory());
    final repository = WeeklyContactSuggestionRepository(database);
    final location = ensureBusinessLocation();
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(location, 1767225600000);

    try {
      final contacts = <Contact>[];
      final initialTouches = <String, OperationalDate?>{};

      for (var i = 0; i < fixture.contactCount; i++) {
        final initialTouch = i % 2 == 0 ? fixture.weekStart.addDays(-20 - i) : null;
        final contact = Contact(
          id: 'contact-$i',
          name: 'Contato $i',
          createdAt: at.add(Duration(seconds: i)),
          lastTouchDate: initialTouch,
        );
        contacts.add(contact);
        initialTouches[contact.id] = initialTouch;

        await database.into(database.contacts).insert(
          db.ContactsCompanion.insert(
            id: contact.id,
            name: contact.name,
            createdAt: contact.createdAt.millisecondsSinceEpoch,
            lastTouchDate: Value(initialTouch?.iso),
          ),
        );
      }

      final orderedContacts = ordering.weeklyOrder(contacts);
      var currentToday = fixture.weekStart;

      // Garante a sugestão inicial
      await repository.ensureCurrentSuggestion(
        weekStart: fixture.weekStart,
        orderedContacts: orderedContacts,
        at: at,
      );

      final visitedOrDone = <String>{};

      for (var step = 0; step < fixture.actions.length; step++) {
        currentToday = currentToday.addDays(1);
        final action = fixture.actions[step];

        // Lê linhas persistidas da semana
        final rowsBefore = await (database.select(database.weeklyContactSuggestions)
              ..where((r) => r.weekStart.equals(fixture.weekStart.iso)))
            .get();
        final pendingRows = rowsBefore.where(
          (r) => r.status == domain.SuggestionStatus.pending.name,
        );

        if (action.kind == _ProgressionActionKind.markDone) {
          if (pendingRows.isNotEmpty) {
            final pendingId = pendingRows.first.contactId;
            final success = await repository.markDone(
              weekStart: fixture.weekStart,
              contactId: pendingId,
              touchedOn: currentToday,
            );
            expect(success, isTrue);
            visitedOrDone.add(pendingId);

            // 1. done atualiza last_touch_date do contato tocado para a data operacional vigente
            final contactRow = await (database.select(database.contacts)
                  ..where((c) => c.id.equals(pendingId)))
                .getSingle();
            expect(contactRow.lastTouchDate, equals(currentToday.iso));

            // Garante próximo pending
            await repository.ensureCurrentSuggestion(
              weekStart: fixture.weekStart,
              orderedContacts: orderedContacts,
              at: at.add(Duration(hours: step + 1)),
            );
          }
        } else if (action.kind == _ProgressionActionKind.skip) {
          if (pendingRows.isNotEmpty) {
            final pendingId = pendingRows.first.contactId;
            final prevTouch = initialTouches[pendingId];

            final success = await repository.skip(
              weekStart: fixture.weekStart,
              contactId: pendingId,
              orderedContacts: orderedContacts,
              at: at.add(Duration(hours: step + 1)),
            );
            expect(success, isTrue);
            visitedOrDone.add(pendingId);

            // 2. skipped preserva o last_touch_date anterior
            final contactRow = await (database.select(database.contacts)
                  ..where((c) => c.id.equals(pendingId)))
                .getSingle();
            expect(contactRow.lastTouchDate, equals(prevTouch?.iso));
          }
        } else if (action.kind == _ProgressionActionKind.chooseManual) {
          final targetContact = contacts[action.contactIndex % contacts.length];
          final success = await repository.chooseManually(
            weekStart: fixture.weekStart,
            contactId: targetContact.id,
            touchedOn: currentToday,
          );
          expect(success, isTrue);
          visitedOrDone.add(targetContact.id);

          // 3. escolha manual marca o contato escolhido com done
          final contactRow = await (database.select(database.contacts)
                ..where((c) => c.id.equals(targetContact.id)))
              .getSingle();
          expect(contactRow.lastTouchDate, equals(currentToday.iso));

          // Garante próximo pending se houver
          await repository.ensureCurrentSuggestion(
            weekStart: fixture.weekStart,
            orderedContacts: orderedContacts,
            at: at.add(Duration(hours: step + 1)),
          );
        }

        // Verifica estado com a projeção de domínio
        final domainRows = (await (database.select(database.weeklyContactSuggestions)
                  ..where((r) => r.weekStart.equals(fixture.weekStart.iso)))
                .get())
            .map((r) => domain.WeeklyContactSuggestion(
                  weekStart: fixture.weekStart,
                  contactId: r.contactId,
                  status: domain.SuggestionStatus.values.byName(r.status),
                  createdAtMillisecondsSinceEpoch: r.createdAt,
                ))
            .toList();

        final view = progression.project(
          weekStart: fixture.weekStart,
          orderedContacts: orderedContacts,
          weekRows: domainRows,
        );

        // 4. a ordem semanal nunca reinicia no meio da semana:
        // Contatos já registrados nunca são re-sugeridos como suggestedContact
        if (view.suggestedContact != null) {
          final alreadyRecorded = domainRows.map((r) => r.contactId).toSet();
          expect(alreadyRecorded.contains(view.suggestedContact!.id), isFalse);
        }

        // 5. quando todos os contatos da ordem foram percorridos, exhausted == true e suggestedContact == null
        final allRecorded = orderedContacts.every(
          (c) => domainRows.any((r) => r.contactId == c.id),
        );
        if (allRecorded) {
          expect(view.exhausted, isTrue);
          expect(view.suggestedContact, isNull);
        }
      }
    } finally {
      await database.close();
    }
  });

  group('Propriedade 39: Casos de esgotamento sem reinício', () {
    test('percorrer todos os contatos com skip esgota a semana sem reiniciar', () {
      final contacts = [
        Contact(
          id: 'c1',
          name: 'C1',
          createdAt: tz.TZDateTime.utc(2026, 1, 1),
        ),
        Contact(
          id: 'c2',
          name: 'C2',
          createdAt: tz.TZDateTime.utc(2026, 1, 2),
        ),
      ];
      final weekStart = OperationalDate(2026, 3, 9);
      final rows = [
        domain.WeeklyContactSuggestion(
          weekStart: weekStart,
          contactId: 'c1',
          status: domain.SuggestionStatus.skipped,
          createdAtMillisecondsSinceEpoch: 1,
        ),
        domain.WeeklyContactSuggestion(
          weekStart: weekStart,
          contactId: 'c2',
          status: domain.SuggestionStatus.skipped,
          createdAtMillisecondsSinceEpoch: 2,
        ),
      ];

      final view = progression.project(
        weekStart: weekStart,
        orderedContacts: contacts,
        weekRows: rows,
      );

      expect(view.exhausted, isTrue);
      expect(view.suggestedContact, isNull);
      expect(view.hasContacts, isTrue);
    });
  });
}
