// Feature: ritmo, Property 40: Mentoria e Contatos permanecem separados
//
// Para qualquer conjunto de mentorias e qualquer conjunto de contatos, a ordem
// semanal e a sugestão contêm exclusivamente identificadores de Contact;
// nenhuma mentoria é convertida, vinculada ou sincronizada implicitamente em
// contato.
//
// **Validates: Requirements RF-07.18, RF-07.19, RF-07.20, RF-07.22, RD-17, RD-18**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/people/contact.dart';
import 'package:ritmo/domain/people/mentorship.dart';
import 'package:ritmo/domain/people/weekly_contact_suggestion.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

typedef _SeparationFixture = ({
  List<Mentorship> mentorships,
  List<Contact> contacts,
  OperationalDate weekStart,
  List<WeeklyContactSuggestion> weekRows,
});

final Generator<_SeparationFixture> _anySeparationFixture = any.simple(
  generate: (random, size) {
    final location = ensureBusinessLocation();
    final weekStart = anyOperationalDate(random, size).value;

    final mentorships = <Mentorship>[
      Mentorship(
        id: 'mentor-st-${random.nextInt(100)}',
        competency: Competency.st,
        mentorName: 'Mentor ST ${random.nextInt(50)}',
        lastMeetingDate: random.nextBool()
            ? weekStart.addDays(-random.nextInt(40))
            : null,
      ),
      Mentorship(
        id: 'mentor-in-${random.nextInt(100)}',
        competency: Competency.in_,
        mentorName: 'Mentor IN ${random.nextInt(50)}',
        lastMeetingDate: random.nextBool()
            ? weekStart.addDays(-random.nextInt(40))
            : null,
      ),
      Mentorship(
        id: 'mentor-ca-${random.nextInt(100)}',
        competency: Competency.ca,
        mentorName: 'Mentor CA ${random.nextInt(50)}',
        lastMeetingDate: random.nextBool()
            ? weekStart.addDays(-random.nextInt(40))
            : null,
      ),
    ];

    final contactCount = random.nextInt(8);
    final contacts = List.generate(contactCount, (index) {
      return Contact(
        id: 'contact-$index-${random.nextInt(1000)}',
        name: 'Contato $index',
        createdAt: tz.TZDateTime.fromMillisecondsSinceEpoch(
          location,
          1767225600000 + random.nextInt(1000000),
        ),
        lastTouchDate: random.nextBool()
            ? weekStart.addDays(-random.nextInt(30))
            : null,
      );
    });

    final weekRows = <WeeklyContactSuggestion>[];
    for (final c in contacts) {
      if (random.nextBool()) {
        weekRows.add(
          WeeklyContactSuggestion(
            weekStart: weekStart,
            contactId: c.id,
            status: SuggestionStatus
                .values[random.nextInt(SuggestionStatus.values.length)],
            createdAtMillisecondsSinceEpoch: 1767225600000,
          ),
        );
      }
    }

    return (
      mentorships: mentorships,
      contacts: contacts,
      weekStart: weekStart,
      weekRows: weekRows,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  const ordering = ContactOrdering();
  const progression = WeeklySuggestionProgression();

  Glados<_SeparationFixture>(
    _anySeparationFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 40: Mentoria e Contatos permanecem separados', (fixture) {
    final mentorIds = fixture.mentorships.map((m) => m.id).toSet();
    final contactIds = fixture.contacts.map((c) => c.id).toSet();

    // 1. Ordem semanal contém exclusivamente identificadores de Contact
    final ordered = ordering.weeklyOrder(fixture.contacts);
    final orderedIds = ordered.map((c) => c.id).toSet();

    expect(orderedIds.difference(contactIds), isEmpty);
    expect(orderedIds.intersection(mentorIds), isEmpty);

    // 2. Projeção de sugestão semanal contém exclusivamente identificadores de Contact
    final view = progression.project(
      weekStart: fixture.weekStart,
      orderedContacts: ordered,
      weekRows: fixture.weekRows,
    );

    if (view.suggestedContact != null) {
      expect(contactIds.contains(view.suggestedContact!.id), isTrue);
      expect(mentorIds.contains(view.suggestedContact!.id), isFalse);
    }

    // 3. Quando não há contatos cadastrados, mesmo com mentorias preenchidas,
    // a sugestão é vazia e não sugere mentorias
    if (fixture.contacts.isEmpty) {
      expect(view.hasContacts, isFalse);
      expect(view.suggestedContact, isNull);
    }
  });

  group('Propriedade 40: Casos específicos de separação', () {
    test(
      'contatos vazios com mentorias ativas resulta em tela vazia de contatos',
      () {
        final mentorships = [
          const Mentorship(
            id: 'mentor-st',
            competency: Competency.st,
            mentorName: 'Alice',
          ),
        ];

        final ordered = ordering.weeklyOrder([]);
        expect(ordered, isEmpty);
        expect(mentorships, isNotEmpty);
        expect(
          ordered
              .map((c) => c.id)
              .toSet()
              .intersection(mentorships.map((m) => m.id).toSet()),
          isEmpty,
        );

        final view = progression.project(
          weekStart: OperationalDate(2026, 2, 2),
          orderedContacts: ordered,
          weekRows: [],
        );

        expect(view.hasContacts, isFalse);
        expect(view.suggestedContact, isNull);
        expect(view.exhausted, isFalse);
      },
    );
  });
}
