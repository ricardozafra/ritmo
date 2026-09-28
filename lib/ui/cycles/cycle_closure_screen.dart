import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/cycle_providers.dart';
import '../../app/providers/manifest_providers.dart';
import '../../core/limits.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/time/operational_calendar.dart';
import '../manifest/safe_manifest_markdown.dart';

/// Fluxo de Encerramento de Ciclo (RF-06.11, RF-06.12, RF-06.14).
///
/// Reúne, em uma tela guiada: a releitura do manifesto, a avaliação final de
/// cada checkpoint do ciclo que se encerra e os campos do novo ciclo. Concluir
/// arquiva o ciclo anterior como read-only e ativa o novo. Habilitado somente
/// na Fase 3.
class CycleClosureScreen extends ConsumerWidget {
  const CycleClosureScreen({super.key});

  static const screenKey = ValueKey<String>('cycle-closure-screen');
  static const emptyKey = ValueKey<String>('cycle-closure-empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCycleProvider);
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Encerramento de Ciclo')),
      body: SafeArea(
        child: active.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Não foi possível carregar o ciclo.'),
            ),
          ),
          data: (value) => value == null
              ? const Center(
                  key: emptyKey,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhum ciclo ativo para encerrar.'),
                  ),
                )
              : _ClosureForm(active: value),
        ),
      ),
    );
  }
}

class _ClosureForm extends ConsumerStatefulWidget {
  const _ClosureForm({required this.active});

  final CycleWithCheckpoints active;

  @override
  ConsumerState<_ClosureForm> createState() => _ClosureFormState();
}

class _ClosureFormState extends ConsumerState<_ClosureForm> {
  static const concludeButtonKey = ValueKey<String>('cycle-closure-conclude');

  late Map<String, GartnerLevel> _levels;
  late Map<String, TextEditingController> _notes;

  late TextEditingController _name;
  late TextEditingController _purpose;
  late OperationalDate _startDate;
  late OperationalDate _endDate;
  late List<NewCheckpointDraft> _newCheckpoints;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _levels = <String, GartnerLevel>{
      for (final checkpoint in widget.active.checkpoints)
        checkpoint.id: GartnerLevel.i,
    };
    _notes = <String, TextEditingController>{
      for (final checkpoint in widget.active.checkpoints)
        checkpoint.id: TextEditingController(),
    };
    _name = TextEditingController();
    _purpose = TextEditingController();
    _startDate = widget.active.cycle.endDate;
    _endDate = widget.active.cycle.endDate;
    _newCheckpoints = <NewCheckpointDraft>[
      NewCheckpointDraft(
        competency: Competency.st,
        date: widget.active.cycle.endDate,
      ),
    ];
  }

  @override
  void dispose() {
    for (final controller in _notes.values) {
      controller.dispose();
    }
    _name.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text('Releitura do manifesto', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _ManifestReview(),
        const SizedBox(height: 24),
        Text('Avaliação final', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final checkpoint in widget.active.checkpoints)
          _EvaluationRow(
            competencyLabel: _competencyLabel(checkpoint.competency),
            level: _levels[checkpoint.id]!,
            notesController: _notes[checkpoint.id]!,
            enabled: !_saving,
            onLevelChanged: (level) =>
                setState(() => _levels[checkpoint.id] = level),
          ),
        const SizedBox(height: 24),
        Text('Novo ciclo', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          enabled: !_saving,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(Limits.editableNameMaxRunes),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Nome do ciclo',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _purpose,
          enabled: !_saving,
          maxLines: 4,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(Limits.cyclePurposeMaxRunes),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Finalidade',
          ),
        ),
        _DateRow(
          label: 'Início',
          value: _startDate,
          enabled: !_saving,
          onPick: (picked) => setState(() => _startDate = picked),
        ),
        _DateRow(
          label: 'Fim',
          value: _endDate,
          enabled: !_saving,
          onPick: (picked) => setState(() => _endDate = picked),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _newCheckpoints.length; index++)
          _NewCheckpointRow(
            draft: _newCheckpoints[index],
            enabled: !_saving,
            onCompetencyChanged: (competency) => setState(() {
              _newCheckpoints[index] = NewCheckpointDraft(
                competency: competency,
                date: _newCheckpoints[index].date,
              );
            }),
            onDatePicked: (picked) => setState(() {
              _newCheckpoints[index] = NewCheckpointDraft(
                competency: _newCheckpoints[index].competency,
                date: picked,
              );
            }),
            onRemove: _newCheckpoints.length > 1
                ? () => setState(() => _newCheckpoints.removeAt(index))
                : null,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _newCheckpoints.add(
                      NewCheckpointDraft(
                        competency: Competency.st,
                        date: _endDate,
                      ),
                    );
                  }),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar checkpoint'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: concludeButtonKey,
          onPressed: _saving ? null : _conclude,
          child: const Text('Concluir encerramento'),
        ),
      ],
    );
  }

  Future<void> _conclude() async {
    setState(() => _saving = true);
    final controller = ref.read(cycleControllerProvider);

    final evaluations = <FinalEvaluationDraft>[
      for (final checkpoint in widget.active.checkpoints)
        FinalEvaluationDraft(
          checkpointId: checkpoint.id,
          level: _levels[checkpoint.id]!,
          notes: _notes[checkpoint.id]!.text.isEmpty
              ? null
              : _notes[checkpoint.id]!.text,
        ),
    ];
    final draft = NewCycleDraft(
      name: _name.text,
      purposeText: _purpose.text,
      startDate: _startDate,
      endDate: _endDate,
      checkpoints: _newCheckpoints,
    );

    final result = await controller.completeClosure(
      closingCycleId: widget.active.cycle.id,
      finalEvaluations: evaluations,
      newCycle: draft,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ciclo encerrado. Novo ciclo ativo.')),
        );
        Navigator.of(context).maybePop();
      },
      onFailure: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  String _competencyLabel(Competency competency) => switch (competency) {
    Competency.st => 'Strategic Thinking',
    Competency.in_ => 'Innovative',
    Competency.ca => 'Change Advocate',
  };
}

class _ManifestReview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(manifestPresentationProvider);
    return presentation.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Text('Não foi possível carregar o manifesto.'),
      data: (value) => SafeManifestMarkdown(markdown: value.markdown),
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  const _EvaluationRow({
    required this.competencyLabel,
    required this.level,
    required this.notesController,
    required this.enabled,
    required this.onLevelChanged,
  });

  final String competencyLabel;
  final GartnerLevel level;
  final TextEditingController notesController;
  final bool enabled;
  final ValueChanged<GartnerLevel> onLevelChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  competencyLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              DropdownButton<GartnerLevel>(
                value: level,
                onChanged: enabled
                    ? (value) {
                        if (value != null) onLevelChanged(value);
                      }
                    : null,
                items: <DropdownMenuItem<GartnerLevel>>[
                  for (final option in GartnerLevel.values)
                    DropdownMenuItem(
                      value: option,
                      child: Text(option.wireValue),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            enabled: enabled,
            maxLines: 2,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(Limits.checkpointNotesMaxRunes),
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Notas (opcional)',
            ),
          ),
        ],
      ),
    ),
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final OperationalDate value;
  final bool enabled;
  final ValueChanged<OperationalDate> onPick;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value.iso),
    trailing: const Icon(Icons.calendar_today_outlined),
    enabled: enabled,
    onTap: enabled ? () => _pick(context) : null,
  );

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(value.year, value.month, value.day),
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.utc(2100),
    );
    if (picked != null) {
      onPick(OperationalDate(picked.year, picked.month, picked.day));
    }
  }
}

class _NewCheckpointRow extends StatelessWidget {
  const _NewCheckpointRow({
    required this.draft,
    required this.enabled,
    required this.onCompetencyChanged,
    required this.onDatePicked,
    required this.onRemove,
  });

  final NewCheckpointDraft draft;
  final bool enabled;
  final ValueChanged<Competency> onCompetencyChanged;
  final ValueChanged<OperationalDate> onDatePicked;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DropdownButton<Competency>(
              value: draft.competency,
              isExpanded: true,
              onChanged: enabled
                  ? (value) {
                      if (value != null) onCompetencyChanged(value);
                    }
                  : null,
              items: const <DropdownMenuItem<Competency>>[
                DropdownMenuItem(
                  value: Competency.st,
                  child: Text('Strategic Thinking'),
                ),
                DropdownMenuItem(
                  value: Competency.in_,
                  child: Text('Innovative'),
                ),
                DropdownMenuItem(
                  value: Competency.ca,
                  child: Text('Change Advocate'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: enabled ? () => _pick(context) : null,
            child: Text(draft.date.iso),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remover checkpoint',
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(
        draft.date.year,
        draft.date.month,
        draft.date.day,
      ),
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.utc(2100),
    );
    if (picked != null) {
      onDatePicked(OperationalDate(picked.year, picked.month, picked.day));
    }
  }
}
