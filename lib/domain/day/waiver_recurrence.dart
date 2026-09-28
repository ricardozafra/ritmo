import '../time/operational_calendar.dart';
import 'eligible_day.dart';
import 'pillar_waiver.dart';

export 'pillar_waiver.dart' show Pillar, PillarWaiver;

/// Veredito da recorrência de dispensa (RF-02.13, RF-02.14).
enum RecurrenceVerdict {
  /// Primeira dispensa da recorrência daquele pilar: aceita sem diálogo.
  first,

  /// Segunda ou posterior: exige diálogo citando a Regra do Retorno antes de
  /// persistir.
  requiresReturnRuleDialog,
}

/// Histórico consultado pela recorrência: dispensas conhecidas e a projeção
/// diária que classifica cada data como útil ou `mute`.
///
/// [days] deve cobrir a janela relevante do passado. Datas ausentes de [days]
/// são classificadas apenas pelo calendário civil (fim de semana é `mute`),
/// de modo que um feriado manual não informado seria tratado como dia útil.
/// Consumidores que precisam do resultado correto sob feriados devem fornecer
/// a projeção completa (RF-05.15).
final class WaiverHistory {
  const WaiverHistory({
    this.waivers = const <PillarWaiver>[],
    this.days = const <EligibleDay>[],
  });

  final Iterable<PillarWaiver> waivers;
  final Iterable<EligibleDay> days;

  /// Dispensa ativa da data, se houver. Revogadas nunca são retornadas
  /// (RF-02.12, RF-02.25).
  PillarWaiver? activeWaiverOn(OperationalDate date) {
    for (final waiver in waivers) {
      if (waiver.date == date && waiver.isActive) return waiver;
    }
    return null;
  }

  EligibleDay? dayOn(OperationalDate date) {
    for (final day in days) {
      if (day.date == date) return day;
    }
    return null;
  }

  /// Datas que a recorrência pula sem interromper a cadeia: dias `mute` e
  /// qualquer data que não seja dia útil (RF-02.12, RF-05.15).
  bool isSkippedByRecurrence(OperationalDate date) {
    final day = dayOn(date);
    if (day != null) return day.isMute || !day.isWorkday;
    return date.isWeekend;
  }

  /// Data mais antiga conhecida; limita a caminhada para trás.
  OperationalDate? get earliestKnownDate {
    OperationalDate? earliest;
    for (final day in days) {
      if (earliest == null || day.date < earliest) earliest = day.date;
    }
    for (final waiver in waivers) {
      if (earliest == null || waiver.date < earliest) earliest = waiver.date;
    }
    return earliest;
  }
}

/// Resultado completo da avaliação: além do veredito, expõe a cadeia anterior
/// encontrada, útil para o diálogo e para diagnósticos.
final class RecurrenceAssessment {
  const RecurrenceAssessment({
    required this.verdict,
    required this.previousChainLength,
    this.chainStartDate,
  });

  final RecurrenceVerdict verdict;

  /// Quantidade de dias úteis imediatamente anteriores, na sequência de dias
  /// úteis, com dispensa ativa do mesmo pilar.
  final int previousChainLength;

  /// Data mais antiga da cadeia anterior; `null` quando não há cadeia.
  final OperationalDate? chainStartDate;

  bool get requiresReturnRuleDialog =>
      verdict == RecurrenceVerdict.requiresReturnRuleDialog;

  /// Posição da dispensa avaliada na recorrência: 1 é a primeira.
  int get position => previousChainLength + 1;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceAssessment &&
      other.verdict == verdict &&
      other.previousChainLength == previousChainLength &&
      other.chainStartDate == chainStartDate;

  @override
  int get hashCode => Object.hash(verdict, previousChainLength, chainStartDate);

  @override
  String toString() =>
      'RecurrenceAssessment(${verdict.name}, cadeia anterior '
      '$previousChainLength, início ${chainStartDate?.iso})';
}

/// Recorrência de dispensa: pura, determinística e sem I/O (RF-02.12 a
/// RF-02.15).
///
/// Caminha para trás a partir da data avaliada sobre a sequência de dias
/// úteis, pulando dias `mute` sem interromper a cadeia. A cadeia daquele pilar
/// é encerrada no primeiro dia útil que apresente dispensa ativa de outro
/// pilar ou nenhuma dispensa ativa daquele pilar — inclusive quando o dia útil
/// está selado sem essa dispensa (RF-02.15).
final class WaiverRecurrence {
  const WaiverRecurrence();

  RecurrenceAssessment assess(
    Pillar pillar,
    OperationalDate date,
    WaiverHistory history,
  ) {
    final bound = history.earliestKnownDate;
    var chainLength = 0;
    OperationalDate? chainStartDate;

    if (bound != null && bound < date) {
      var cursor = date.previous;
      while (cursor >= bound) {
        if (history.isSkippedByRecurrence(cursor)) {
          cursor = cursor.previous;
          continue;
        }
        // Os três cortes de RF-02.15 se resolvem sobre a dispensa ativa do
        // dia útil: dispensa ativa de outro pilar, nenhuma dispensa ativa
        // daquele pilar e dia útil selado sem essa dispensa. O selo só mantém
        // a cadeia quando o próprio dia carrega a dispensa ativa do pilar
        // (RF-02.16).
        final active = history.activeWaiverOn(cursor);
        final coversPillar = active != null && active.pillar == pillar;
        if (!coversPillar) break;
        chainLength++;
        chainStartDate = cursor;
        cursor = cursor.previous;
      }
    }

    return RecurrenceAssessment(
      verdict: chainLength >= 1
          ? RecurrenceVerdict.requiresReturnRuleDialog
          : RecurrenceVerdict.first,
      previousChainLength: chainLength,
      chainStartDate: chainStartDate,
    );
  }

  RecurrenceVerdict verdict(
    Pillar pillar,
    OperationalDate date,
    WaiverHistory history,
  ) => assess(pillar, date, history).verdict;
}
