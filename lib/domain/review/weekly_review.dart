import 'package:timezone/timezone.dart' as tz;

import '../time/operational_calendar.dart';

/// Estado de uma Revisão Semanal (RF-08.22, RF-08.23).
///
/// `draft` é editável com autosave; `finalized` é imutável (read-only).
enum WeeklyReviewState { draft, finalized }

/// Revisão Semanal de domínio, indexada pela semana operacional (RD-23).
///
/// As três respostas são opcionais e cada uma aceita no máximo 5000 caracteres
/// Unicode. `audio` e as avaliações de checkpoint pertencem à Fase 3 e não
/// fazem parte deste modelo textual.
final class WeeklyReview {
  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.state,
    required this.createdAt,
    this.answerFulfilled,
    this.answerFailed,
    this.answerLesson,
    this.autosavedAt,
    this.finalizedAt,
  });

  final String id;
  final OperationalDate weekStart;
  final WeeklyReviewState state;
  final String? answerFulfilled;
  final String? answerFailed;
  final String? answerLesson;
  final tz.TZDateTime createdAt;
  final tz.TZDateTime? autosavedAt;
  final tz.TZDateTime? finalizedAt;

  bool get isDraft => state == WeeklyReviewState.draft;
  bool get isFinalized => state == WeeklyReviewState.finalized;

  /// As três respostas estão preenchidas — pré-condição para finalizar.
  bool get isComplete =>
      _filled(answerFulfilled) &&
      _filled(answerFailed) &&
      _filled(answerLesson);

  static bool _filled(String? value) =>
      value != null && value.trim().isNotEmpty;
}

/// Campo editável da revisão, usado pelo autosave por campo (RF-08.22).
enum WeeklyReviewField { fulfilled, failed, lesson }
