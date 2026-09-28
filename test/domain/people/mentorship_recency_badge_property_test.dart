// Feature: ritmo, Property 41: Badge de recência de mentoria
//
// Para qualquer par (data operacional de hoje, last_meeting_date), o alerta
// visual suave é exibido se e somente se transcorreram mais de 30 dias, e em
// nenhum caso uma notificação é agendada ou entregue.
//
// **Validates: Requirements RF-07.3, RF-07.21**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/people/mentorship.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _MentorshipBadgeFixture = ({
  OperationalDate today,
  OperationalDate? lastMeetingDate,
  Competency competency,
  String? mentorName,
});

final Generator<_MentorshipBadgeFixture> _anyMentorshipBadgeFixture = any
    .simple(
      generate: (random, size) {
        final today = anyOperationalDate(random, size).value;
        final hasDate = random.nextBool();
        OperationalDate? lastMeetingDate;
        if (hasDate) {
          final offsetDays = random.nextInt(100) - random.nextInt(100);
          lastMeetingDate = today.addDays(offsetDays);
        }
        final comp =
            Competency.values[random.nextInt(Competency.values.length)];
        final mentorName = random.nextBool()
            ? 'Mentor ${random.nextInt(1000)}'
            : null;
        return (
          today: today,
          lastMeetingDate: lastMeetingDate,
          competency: comp,
          mentorName: mentorName,
        );
      },
      shrink: (fixture) sync* {},
    );

void main() {
  Glados<_MentorshipBadgeFixture>(
    _anyMentorshipBadgeFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 41: Badge de recência de mentoria', (fixture) {
    const projection = MentorshipProjection();
    final mentorship = Mentorship(
      id: 'm-1',
      competency: fixture.competency,
      mentorName: fixture.mentorName,
      lastMeetingDate: fixture.lastMeetingDate,
    );

    final cards = projection.project(
      today: fixture.today,
      mentorships: [mentorship],
    );

    expect(cards, hasLength(1));
    final card = cards.first;

    if (fixture.lastMeetingDate == null) {
      expect(card.daysSinceLastMeeting, isNull);
      expect(card.showRecencyBadge, isFalse);
    } else {
      final fromCivil = DateTime.utc(
        fixture.lastMeetingDate!.year,
        fixture.lastMeetingDate!.month,
        fixture.lastMeetingDate!.day,
      );
      final toCivil = DateTime.utc(
        fixture.today.year,
        fixture.today.month,
        fixture.today.day,
      );
      final expectedDays = toCivil.difference(fromCivil).inDays;

      expect(card.daysSinceLastMeeting, equals(expectedDays));
      if (expectedDays > mentorshipRecencyThresholdDays) {
        expect(card.showRecencyBadge, isTrue);
      } else {
        expect(card.showRecencyBadge, isFalse);
      }
    }
  });

  group('Propriedade 41: Casos de borda de recência', () {
    const projection = MentorshipProjection();
    final today = OperationalDate(2026, 3, 15);

    test('30 dias exatos não exibe o badge', () {
      final last = today.addDays(-30);
      final cards = projection.project(
        today: today,
        mentorships: [
          Mentorship(
            id: 'm-30',
            competency: Competency.st,
            lastMeetingDate: last,
          ),
        ],
      );
      expect(cards.first.daysSinceLastMeeting, equals(30));
      expect(cards.first.showRecencyBadge, isFalse);
    });

    test('31 dias exibe o badge', () {
      final last = today.addDays(-31);
      final cards = projection.project(
        today: today,
        mentorships: [
          Mentorship(
            id: 'm-31',
            competency: Competency.st,
            lastMeetingDate: last,
          ),
        ],
      );
      expect(cards.first.daysSinceLastMeeting, equals(31));
      expect(cards.first.showRecencyBadge, isTrue);
    });

    test('data futura resulta em dias negativos e não exibe badge', () {
      final last = today.addDays(5);
      final cards = projection.project(
        today: today,
        mentorships: [
          Mentorship(
            id: 'm-future',
            competency: Competency.ca,
            lastMeetingDate: last,
          ),
        ],
      );
      expect(cards.first.daysSinceLastMeeting, equals(-5));
      expect(cards.first.showRecencyBadge, isFalse);
    });
  });
}
