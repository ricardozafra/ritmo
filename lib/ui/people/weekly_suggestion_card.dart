import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/contact_providers.dart';
import '../../app/providers/weekly_suggestion_providers.dart';
import '../../core/copy.dart';
import '../../core/result.dart';
import '../../domain/people/contact.dart';
import '../../domain/people/weekly_contact_suggestion.dart';

/// Cartão da sugestão semanal de contato (RF-07.7 a RF-07.15).
///
/// Componente reutilizável, sem rota própria: a tela Pessoas que o hospeda é
/// habilitada apenas na tarefa 20.9.
class WeeklySuggestionCard extends ConsumerWidget {
  const WeeklySuggestionCard({super.key});

  static const cardKey = ValueKey<String>('weekly-suggestion-card');
  static const emptyKey = ValueKey<String>('weekly-suggestion-empty');
  static const exhaustedKey = ValueKey<String>('weekly-suggestion-exhausted');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(weeklySuggestionViewProvider);
    return suggestion.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Não foi possível carregar a sugestão da semana.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(weeklySuggestionViewProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (view) => _content(context, ref, view),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    WeeklySuggestionView view,
  ) {
    if (!view.hasContacts) return const _EmptySuggestion();
    if (view.exhausted) return const _ExhaustedSuggestion();

    final contact = view.suggestedContact;
    if (contact == null) return const _ExhaustedSuggestion();
    return _ActiveSuggestion(contact: contact);
  }
}

class _EmptySuggestion extends StatelessWidget {
  const _EmptySuggestion();

  @override
  Widget build(BuildContext context) => const Card(
    key: WeeklySuggestionCard.emptyKey,
    child: ListTile(
      leading: Icon(Icons.group_add_outlined),
      title: Text('Nenhuma ponte esta semana'),
      subtitle: Text('Cadastre um contato para receber uma sugestão.'),
    ),
  );
}

class _ExhaustedSuggestion extends StatelessWidget {
  const _ExhaustedSuggestion();

  @override
  Widget build(BuildContext context) => const Card(
    key: WeeklySuggestionCard.exhaustedKey,
    child: ListTile(
      leading: Icon(Icons.done_all_outlined),
      title: Text(Copy.weeklyBridgesExhausted),
    ),
  );
}

class _ActiveSuggestion extends ConsumerStatefulWidget {
  const _ActiveSuggestion({required this.contact});

  final Contact contact;

  @override
  ConsumerState<_ActiveSuggestion> createState() => _ActiveSuggestionState();
}

class _ActiveSuggestionState extends ConsumerState<_ActiveSuggestion> {
  bool _busy = false;

  Contact get _contact => widget.contact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      key: WeeklySuggestionCard.cardKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ponte da semana', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            // Copy literal exigida pela especificação (RF-07.14).
            Text(Copy.contactSuggestionIntent, style: textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(_contact.name, style: textTheme.titleLarge),
            if (_contact.contextNote case final note?
                when note.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(note),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: _busy ? null : _markDone,
                  child: const Text('Ponte realizada'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _skip,
                  child: const Text('Pular'),
                ),
                TextButton(
                  onPressed: _busy ? null : _chooseManually,
                  child: const Text('Escolher outro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDone() => _run(
    () => ref.read(weeklySuggestionControllerProvider).markDone(_contact.id),
  );

  Future<void> _skip() => _run(
    () => ref.read(weeklySuggestionControllerProvider).skip(_contact.id),
  );

  Future<void> _chooseManually() async {
    final ordered =
        ref.read(contactWeeklyOrderProvider).value ?? const <Contact>[];
    if (ordered.isEmpty || !mounted) return;

    final chosen = await showModalBottomSheet<Contact>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const ListTile(title: Text('Escolher contato')),
            for (final contact in ordered)
              ListTile(
                title: Text(contact.name),
                onTap: () => Navigator.pop(sheetContext, contact),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _run(
      () => ref
          .read(weeklySuggestionControllerProvider)
          .chooseManually(chosen.id),
    );
  }

  Future<void> _run(
    Future<Result<void, RitmoFailure>> Function() operation,
  ) async {
    setState(() => _busy = true);
    try {
      final result = await operation();
      if (!mounted) return;
      result.fold<void>(
        onSuccess: (_) {},
        onFailure: (failure) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
