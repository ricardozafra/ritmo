import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/time/operational_calendar.dart';
import '../../app/providers/cycle_providers.dart';

/// Editor do ciclo ativo: finalidade, período e checkpoints (RF-06.13, RD-21).
///
/// Habilitado somente na Fase 3. Ciclos arquivados são read-only (RD-20). A
/// edição preserva os identificadores dos checkpoints, mantendo avaliações e
/// histórico associados (RF-06.14).
class CycleEditorScreen extends ConsumerWidget {
  const CycleEditorScreen({super.key});

  static const screenKey = ValueKey<String>('cycle-editor-screen');
  static const emptyKey = ValueKey<String>('cycle-editor-empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCycleProvider);
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Editar ciclo')),
      body: SafeArea(
        child: active.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar o ciclo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          data: (value) => value == null
              ? const Center(
                  key: emptyKey,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhum ciclo ativo para editar.'),
                  ),
                )
              : _CycleEditorForm(cycle: value),
        ),
      ),
    );
  }
}

class _CycleEditorForm extends ConsumerStatefulWidget {
  const _CycleEditorForm({required this.cycle});

  final CycleWithCheckpoints cycle;

  @override
  ConsumerState<_CycleEditorForm> createState() => _CycleEditorFormState();
}

class _CycleEditorFormState extends ConsumerState<_CycleEditorForm> {
  static const saveButtonKey = ValueKey<String>('cycle-editor-save');

  late TextEditingController _purpose;
  late OperationalDate _startDate;
  late OperationalDate _endDate;
  late List<CheckpointEdit> _checkpoints;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.cycle);
  }

  @override
  void didUpdateWidget(covariant _CycleEditorForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycle.cycle.id != widget.cycle.cycle.id) {
      _hydrate(widget.cycle);
    }
  }

  void _hydrate(CycleWithCheckpoints value) {
    _purpose = TextEditingController(text: value.cycle.purposeText);
    _startDate = value.cycle.startDate;
    _endDate = value.cycle.endDate;
    _checkpoints = value.checkpoints
        .map(
          (checkpoint) => CheckpointEdit(
            id: checkpoint.id,
            competency: checkpoint.competency,
            date: checkpoint.date,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  bool get _readOnly => widget.cycle.cycle.state == CycleState.archived;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        if (_readOnly)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Ciclo arquivado. Disponível somente para leitura.'),
            ),
          ),
        Text('Finalidade', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _purpose,
          enabled: !_readOnly && !_saving,
          maxLines: 5,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(Limits.cyclePurposeMaxRunes),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Descreva a finalidade do ciclo',
          ),
        ),
        const SizedBox(height: 24),
        Text('Período', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateRow(
          label: 'Início',
          value: _startDate,
          enabled: !_readOnly && !_saving,
          onPick: (picked) => setState(() => _startDate = picked),
        ),
        _DateRow(
          label: 'Fim',
          value: _endDate,
          enabled: !_readOnly && !_saving,
          onPick: (picked) => setState(() => _endDate = picked),
        ),
        const SizedBox(height: 24),
        Text('Checkpoints', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var index = 0; index < _checkpoints.length; index++)
          _CheckpointRow(
            edit: _checkpoints[index],
            enabled: !_readOnly && !_saving,
            onCompetencyChanged: (competency) => setState(() {
              _checkpoints[index] = CheckpointEdit(
                id: _checkpoints[index].id,
                competency: competency,
                date: _checkpoints[index].date,
              );
            }),
            onDatePicked: (picked) => setState(() {
              _checkpoints[index] = CheckpointEdit(
                id: _checkpoints[index].id,
                competency: _checkpoints[index].competency,
                date: picked,
              );
            }),
          ),
        const SizedBox(height: 24),
        if (!_readOnly)
          FilledButton(
            key: saveButtonKey,
            onPressed: _saving ? null : _save,
            child: const Text('Salvar ciclo'),
          ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final controller = ref.read(cycleControllerProvider);
    final cycleId = widget.cycle.cycle.id;

    final purposeResult = await controller.updatePurposeAndPeriod(
      cycleId: cycleId,
      purposeText: _purpose.text,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (purposeResult case Failure<void, RitmoFailure>(:final failure)) {
      _showError(failure.message);
      if (mounted) setState(() => _saving = false);
      return;
    }

    for (final edit in _checkpoints) {
      final result = await controller.updateCheckpoint(
        cycleId: cycleId,
        edit: edit,
      );
      if (result case Failure<void, RitmoFailure>(:final failure)) {
        _showError(failure.message);
        if (mounted) setState(() => _saving = false);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ciclo atualizado.')));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
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
    final initial = DateTime.utc(value.year, value.month, value.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.utc(2100),
    );
    if (picked != null) {
      onPick(OperationalDate(picked.year, picked.month, picked.day));
    }
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({
    required this.edit,
    required this.enabled,
    required this.onCompetencyChanged,
    required this.onDatePicked,
  });

  final CheckpointEdit edit;
  final bool enabled;
  final ValueChanged<Competency> onCompetencyChanged;
  final ValueChanged<OperationalDate> onDatePicked;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: DropdownButton<Competency>(
              value: edit.competency,
              isExpanded: true,
              onChanged: enabled
                  ? (competency) {
                      if (competency != null) onCompetencyChanged(competency);
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
            child: Text(edit.date.iso),
          ),
        ],
      ),
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final initial = DateTime.utc(
      edit.date.year,
      edit.date.month,
      edit.date.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(2020),
      lastDate: DateTime.utc(2100),
    );
    if (picked != null) {
      onDatePicked(OperationalDate(picked.year, picked.month, picked.day));
    }
  }
}
