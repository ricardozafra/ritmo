import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/weekly_review_providers.dart';
import '../../core/copy.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/time/operational_calendar.dart';
import '../navigation/route_unavailable_screen.dart';

/// Detalhe somente leitura de uma Revisão Semanal (RF-08.20, RF-08.26).
///
/// Exibe as três respostas persistidas. Áudio e avaliações de checkpoint são
/// da Fase 3 e, quando não houver, não são apresentados. Nenhuma ação de
/// edição está disponível, mesmo para rascunhos abertos por engano.
class WeeklyReviewDetailScreen extends ConsumerWidget {
  const WeeklyReviewDetailScreen({required this.reviewId, super.key});

  static const screenKey = ValueKey<String>('weekly-review-detail-screen');

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(weeklyReviewByIdProvider(reviewId));
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Revisão')),
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const RouteUnavailableScreen(),
          data: (value) =>
              value == null ? const RouteUnavailableScreen() : _detail(value),
        ),
      ),
    );
  }

  Widget _detail(WeeklyReview review) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    children: <Widget>[
      _Header(review: review),
      const SizedBox(height: 16),
      _Answer(
        question: Copy.reviewFulfilledQuestion,
        answer: review.answerFulfilled,
      ),
      const SizedBox(height: 16),
      _Answer(question: Copy.reviewFailedQuestion, answer: review.answerFailed),
      const SizedBox(height: 16),
      _Answer(question: Copy.reviewLessonQuestion, answer: review.answerLesson),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.review});

  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Semana de ${_formatDate(review.weekStart)}',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          review.isFinalized ? 'Finalizada' : 'Rascunho',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.question, required this.answer});

  final String question;
  final String? answer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filled = answer != null && answer!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(question, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              filled ? answer! : 'Sem resposta registrada.',
              style: filled
                  ? null
                  : textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(OperationalDate date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
