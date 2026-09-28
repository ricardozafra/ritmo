import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation/app_router.dart';
import '../../app/providers/weekly_review_providers.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/time/operational_calendar.dart';

/// Histórico cronológico de Revisões Semanais (RF-08.19 a RF-08.21, RF-08.24).
///
/// Lista por semana operacional, da mais recente à mais antiga, com estado
/// vazio neutro e sem busca ou filtro. O detalhe é somente leitura.
class WeeklyReviewHistoryScreen extends ConsumerWidget {
  const WeeklyReviewHistoryScreen({super.key});

  static const screenKey = ValueKey<String>('weekly-review-history-screen');
  static const emptyKey = ValueKey<String>('weekly-review-history-empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(weeklyReviewHistoryProvider);
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Histórico de Revisões')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () => ref.invalidate(weeklyReviewHistoryProvider),
          ),
          data: (reviews) => reviews.isEmpty
              ? const _EmptyHistory()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ReviewTile(review: reviews[index]),
                ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Center(
    key: WeeklyReviewHistoryScreen.emptyKey,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Nenhuma revisão registrada ainda.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    final finalized = review.isFinalized;
    return Card(
      child: ListTile(
        leading: Icon(
          finalized ? Icons.lock_outline : Icons.edit_note_outlined,
        ),
        title: Text('Semana de ${_formatDate(review.weekStart)}'),
        subtitle: Text(finalized ? 'Finalizada' : 'Rascunho'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(
          AppRoute.reviewDetailName,
          pathParameters: {'id': review.id},
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Não foi possível carregar o histórico.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(OperationalDate date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
