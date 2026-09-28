import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/cycle_providers.dart';
import '../../domain/cycles/cycle_policy.dart';

/// Evolução por competência (RF-06.7): mostra, para cada competência avaliada,
/// a sequência de níveis Gartner por data de checkpoint. Sem gamificação — não
/// há pontuação, ranking, medalha ou sequência premiada, apenas o histórico
/// literal das autoavaliações.
class CompetencyEvolutionCard extends ConsumerWidget {
  const CompetencyEvolutionCard({super.key});

  static const cardKey = ValueKey<String>('competency-evolution-card');
  static const emptyKey = ValueKey<String>('competency-evolution-empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evolution = ref.watch(competencyEvolutionProvider);
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Evolução por competência',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            evolution.when(
              loading: () => const Text('Carregando avaliações...'),
              error: (error, stackTrace) =>
                  const Text('A evolução não está disponível neste momento.'),
              data: (groups) => groups.isEmpty
                  ? const Text(
                      key: emptyKey,
                      'Nenhuma autoavaliação registrada ainda.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final group in groups)
                          _CompetencyRow(group: group),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetencyRow extends StatelessWidget {
  const _CompetencyRow({required this.group});

  final CompetencyEvolution group;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sequence = group.evaluations
        .map(
          (evaluation) =>
              '${evaluation.date.iso}: ${evaluation.level.wireValue}',
        )
        .join('  →  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_label(group.competency), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(sequence, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _label(Competency competency) => switch (competency) {
    Competency.st => 'Strategic Thinking',
    Competency.in_ => 'Innovative',
    Competency.ca => 'Change Advocate',
  };
}
