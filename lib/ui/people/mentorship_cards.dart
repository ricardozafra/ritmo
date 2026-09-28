import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/mentorship_providers.dart';
import '../../app/providers/ritmo_providers.dart';
import '../../core/limits.dart';
import '../../core/result.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/people/mentorship.dart';
import '../../domain/time/operational_calendar.dart';

/// Lista reativa dos três cartões fixos de mentoria (RF-07.1).
///
/// Componente reutilizável, sem rota própria: a tela Pessoas que o hospeda é
/// habilitada apenas na tarefa 20.9.
class MentorshipCards extends ConsumerWidget {
  const MentorshipCards({super.key});

  static const listKey = ValueKey<String>('mentorship-cards');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(mentorshipCardsProvider);
    return cards.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Não foi possível carregar a mentoria.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(mentorshipCardsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (views) {
        // Data operacional corrente para ancorar o seletor de data no fuso
        // oficial, sem recorrer ao relógio do aparelho.
        final today = ref.watch(ritmoCurrentOperationalDateProvider).value;
        return Column(
          key: listKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final view in views) ...<Widget>[
              _MentorshipCard(view: view, today: today),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MentorshipCard extends ConsumerStatefulWidget {
  const _MentorshipCard({required this.view, required this.today});

  final MentorshipCardView view;
  final OperationalDate? today;

  @override
  ConsumerState<_MentorshipCard> createState() => _MentorshipCardState();
}

class _MentorshipCardState extends ConsumerState<_MentorshipCard> {
  bool _busy = false;

  MentorshipCardView get _view => widget.view;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = _view.mentorName;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _competencyLabel(_view.competency),
                    style: textTheme.titleMedium,
                  ),
                ),
                if (_view.showRecencyBadge) _RecencyBadge(view: _view),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name == null || name.isEmpty
                  ? 'Mentor não definido'
                  : 'Mentor: $name',
            ),
            const SizedBox(height: 4),
            Text(
              _view.lastMeetingDate == null
                  ? 'Último encontro não registrado'
                  : 'Último encontro: ${_formatDate(_view.lastMeetingDate!)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _busy ? null : _editName,
                  child: const Text('Editar mentor'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _editDate,
                  child: const Text('Registrar encontro'),
                ),
                if (_view.lastMeetingDate != null)
                  TextButton(
                    onPressed: _busy ? null : _clearDate,
                    child: const Text('Limpar data'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _view.mentorName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar mentor'),
        content: TextField(
          controller: controller,
          maxLength: Limits.editableNameMaxRunes,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(Limits.editableNameMaxRunes),
          ],
          decoration: const InputDecoration(labelText: 'Nome do mentor'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    await _run(
      () => ref
          .read(mentorshipControllerProvider)
          .setMentorName(_view.id, name: result),
    );
  }

  Future<void> _editDate() async {
    // Ancora o seletor na data operacional corrente (fuso oficial); nunca no
    // relógio do aparelho. Sem essa âncora, evita registrar encontro.
    final today = widget.today;
    if (today == null) {
      _showMessage('Aguarde a data operacional carregar para registrar.');
      return;
    }
    final last = _view.lastMeetingDate;
    final initial = DateTime(
      (last ?? today).year,
      (last ?? today).month,
      (last ?? today).day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 1, 12, 31),
      helpText: 'Data do último encontro',
    );
    if (picked == null || !mounted) return;
    await _run(
      () => ref
          .read(mentorshipControllerProvider)
          .setLastMeetingDate(
            _view.id,
            date: OperationalDate(picked.year, picked.month, picked.day),
          ),
    );
  }

  Future<void> _clearDate() => _run(
    () => ref
        .read(mentorshipControllerProvider)
        .setLastMeetingDate(_view.id, date: null),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

class _RecencyBadge extends StatelessWidget {
  const _RecencyBadge({required this.view});

  final MentorshipCardView view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = view.daysSinceLastMeeting;
    final label = days == null
        ? 'Sem encontro recente'
        : 'Há $days dias sem encontro';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.schedule_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _competencyLabel(Competency competency) => switch (competency) {
  Competency.st => 'Strategic Thinking',
  Competency.in_ => 'Innovative',
  Competency.ca => 'Change Advocate',
};

String _formatDate(OperationalDate date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
