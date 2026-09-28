import '../cycles/cycle_policy.dart' show Competency;
import '../time/operational_calendar.dart';

/// Cartão fixo de mentoria de uma competência (RF-07.1, RF-07.2).
///
/// Entidade separada de `Contact`: não possui vínculo, FK ou sincronização
/// com o rodízio de contatos (RF-07.18, RF-07.19).
final class Mentorship {
  const Mentorship({
    required this.id,
    required this.competency,
    this.mentorName,
    this.lastMeetingDate,
  });

  final String id;
  final Competency competency;
  final String? mentorName;
  final OperationalDate? lastMeetingDate;
}

/// Limite normativo do alerta de recência da mentoria (RF-07.3).
///
/// O alerta suave aparece somente quando transcorreram **mais** de 30 dias
/// desde o último encontro; exatamente 30 dias ainda não dispara.
const int mentorshipRecencyThresholdDays = 30;

/// Projeção imutável de um cartão de mentoria para a interface.
final class MentorshipCardView {
  const MentorshipCardView({
    required this.id,
    required this.competency,
    required this.mentorName,
    required this.lastMeetingDate,
    required this.daysSinceLastMeeting,
    required this.showRecencyBadge,
  });

  final String id;
  final Competency competency;
  final String? mentorName;
  final OperationalDate? lastMeetingDate;

  /// Dias civis corridos desde o último encontro; nulo quando não há data.
  final int? daysSinceLastMeeting;

  /// Alerta visual suave, único lembrete automático de mentor (RF-07.21).
  final bool showRecencyBadge;
}

/// Regras puras de apresentação da mentoria, sem relógio, IO ou notificação.
final class MentorshipProjection {
  const MentorshipProjection();

  /// Ordena os cartões de forma estável por competência (ST, IN, CA) e calcula
  /// o alerta de recência relativo a [today]. Nunca agenda nem entrega
  /// notificações: o badge é exclusivamente visual (RF-07.3, RF-07.21).
  List<MentorshipCardView> project({
    required OperationalDate today,
    required Iterable<Mentorship> mentorships,
  }) {
    final cards = mentorships.map((m) => _card(today, m)).toList()
      ..sort(
        (a, b) => _competencyOrder(
          a.competency,
        ).compareTo(_competencyOrder(b.competency)),
      );
    return List<MentorshipCardView>.unmodifiable(cards);
  }

  MentorshipCardView _card(OperationalDate today, Mentorship mentorship) {
    final last = mentorship.lastMeetingDate;
    final days = last == null ? null : _daysBetween(last, today);
    return MentorshipCardView(
      id: mentorship.id,
      competency: mentorship.competency,
      mentorName: mentorship.mentorName,
      lastMeetingDate: last,
      daysSinceLastMeeting: days,
      showRecencyBadge: days != null && days > mentorshipRecencyThresholdDays,
    );
  }

  /// Dias civis corridos de [from] até [to], no fuso oficial. Datas futuras
  /// produzem valor negativo e, portanto, nunca acionam o alerta.
  int _daysBetween(OperationalDate from, OperationalDate to) {
    final fromCivil = DateTime.utc(from.year, from.month, from.day);
    final toCivil = DateTime.utc(to.year, to.month, to.day);
    return toCivil.difference(fromCivil).inDays;
  }

  int _competencyOrder(Competency competency) => switch (competency) {
    Competency.st => 0,
    Competency.in_ => 1,
    Competency.ca => 2,
  };
}
