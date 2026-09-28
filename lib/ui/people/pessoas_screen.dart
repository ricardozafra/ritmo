import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation/app_router.dart';
import 'contact_list.dart';
import 'mentorship_cards.dart';
import 'weekly_suggestion_card.dart';

/// Tela Pessoas da Fase 2 (RF-07): sugestão semanal, mentoria e contatos.
///
/// Compõe componentes independentes já testados. Mentoria e Contatos
/// permanecem módulos separados (RF-07.18); a tela apenas os apresenta lado a
/// lado, sem inferir vínculo entre eles.
class PessoasScreen extends StatelessWidget {
  const PessoasScreen({super.key});

  static const screenKey = ValueKey<String>('pessoas-screen');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      key: PessoasScreen.screenKey,
      appBar: AppBar(title: const Text('Pessoas')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            Text('Ponte da semana', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const WeeklySuggestionCard(),
            const SizedBox(height: 24),
            Text('Mentoria', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const MentorshipCards(),
            const SizedBox(height: 24),
            Text('Contatos', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const ContactList(),
            const SizedBox(height: 24),
            Text('Revisão Semanal', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                key: const ValueKey<String>('pessoas-review-entry'),
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('Abrir a Revisão da semana'),
                subtitle: const Text(
                  'Três perguntas guiadas, com autosave e finalização.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRoute.reviewName),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                key: const ValueKey<String>('pessoas-review-history-entry'),
                leading: const Icon(Icons.history_outlined),
                title: const Text('Histórico de Revisões'),
                subtitle: const Text(
                  'Revisões anteriores por semana, somente leitura.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRoute.reviewHistoryName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
