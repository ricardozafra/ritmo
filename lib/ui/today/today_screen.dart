import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controllers/today_controller.dart';
import '../../app/editor_registry.dart';
import '../../app/providers/boundary_providers.dart';
import '../../app/providers/today_providers.dart';
import '../../core/copy.dart';
import '../../core/limits.dart';
import '../../core/result.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/seal_eligibility.dart';
import '../../domain/day/today_view.dart';
import '../../domain/time/operational_calendar.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  static const screenKey = ValueKey<String>('today-screen');

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  final TextEditingController _dayNoteController = TextEditingController();
  final FocusNode _dayNoteFocus = FocusNode();
  EditorRegistration? _dayNoteRegistration;
  OperationalDate? _editableNoteDate;
  String _persistedDayNote = '';
  String? _registeredDayNoteDate;
  String? _dayNoteOperationalDate;
  String? _dayNoteSnapshotKey;

  TodayController get _controller => ref.read(todayControllerProvider);

  @override
  void initState() {
    super.initState();
    _dayNoteController.addListener(_syncDayNoteEditor);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayViewProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayNoteRegistration?.dispose();
    _dayNoteFocus.dispose();
    _dayNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncView = ref.watch(todayViewProvider);
    final timezoneDiverges = switch (asyncView) {
      AsyncData<TodayView>(:final value) => value.deviceZoneDiverges,
      _ => false,
    };

    return Scaffold(
      key: TodayScreen.screenKey,
      appBar: AppBar(
        title: const Text('Hoje'),
        actions: <Widget>[
          if (timezoneDiverges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message: Copy.businessTimezoneNotice,
                child: Semantics(
                  label: Copy.businessTimezoneNotice,
                  child: Icon(Icons.schedule),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: asyncView.when(
          loading: () => Center(
            child: Semantics(
              label: 'Carregando o dia operacional',
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) =>
              _ErrorView(onRetry: () => ref.invalidate(todayViewProvider)),
          data: (view) => switch (view) {
            MuteTodayView() => _buildMuteDay(view),
            WorkdayTodayView() => _buildWorkday(view),
          },
        ),
      ),
    );
  }

  Widget _buildMuteDay(MuteTodayView view) {
    _deactivateDayNoteEditor();
    return _MuteDayView(message: view.message);
  }

  Widget _buildWorkday(WorkdayTodayView view) {
    _synchronizeNote(view);
    final editable = view.canEdit;
    final pendingBoundary = switch (ref.watch(boundaryRuntimeProvider)) {
      AsyncData<BoundaryRuntime>(:final value) => value.pendingEditBoundary,
      _ => null,
    };
    final wasAutosavedAtBoundary =
        view.mode == TodayMode.closed &&
        pendingBoundary?.closedDate == view.operationalDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        _CycleHeader(view: view),
        const SizedBox(height: 12),
        if (view.mode == TodayMode.closed)
          _NoticeCard(
            icon: Icons.lock_outline,
            message: Copy.closedDayReadOnly,
            actionLabel: wasAutosavedAtBoundary
                ? 'Ir para o dia operacional atual'
                : null,
            onAction: wasAutosavedAtBoundary ? _showCurrentDay : null,
          ),
        if (view.mode == TodayMode.openSealed)
          const _NoticeCard(
            icon: Icons.verified_outlined,
            message: 'Dia selado. Os registros estão disponíveis para leitura.',
          ),
        _MorningCard(
          view: view,
          onWorkoutChanged: editable
              ? (value) => _setWorkout(view, value)
              : null,
          onBriefingManual: editable ? () => _completeBriefing(view) : null,
          onBriefingCleared: editable ? () => _clearBriefing(view) : null,
          onPlayBriefing: editable ? _showMissingBriefingAsset : null,
        ),
        const SizedBox(height: 12),
        _DayCard(
          view: view,
          noteController: _dayNoteController,
          noteFocus: _dayNoteFocus,
          onToggleChanged: editable
              ? (value) => _setDayToggle(view, value)
              : null,
          onSaveNote: editable ? () => _saveDayNote(view) : null,
          onRemoveNote: editable ? () => _removeDayNote(view) : null,
        ),
        const SizedBox(height: 12),
        _NightCard(
          view: view,
          onStartStudy: editable ? () => _startStudy(view) : null,
          onFinishStudy: editable ? () => _finishStudy(view) : null,
          onCancelStudy: editable ? () => _cancelStudy(view) : null,
          onRecovery: editable ? () => _chooseRecovery(view) : null,
          onRemoveChoice: editable ? () => _removeNightChoice(view) : null,
        ),
        const SizedBox(height: 12),
        _WaiverCard(
          view: view,
          onCreate: editable && view.activeWaiver == null
              ? () => _createWaiver(view)
              : null,
        ),
        const SizedBox(height: 12),
        _SealSection(
          view: view,
          onSeal: view.canSeal ? () => _seal(view) : null,
          onReopen: view.canReopen ? () => _reopen(view) : null,
        ),
      ],
    );
  }

  void _synchronizeNote(WorkdayTodayView view) {
    final note = view.entries.day?.note ?? '';
    final key = '${view.operationalDate.iso}\u0000$note';
    final dateChanged = _dayNoteOperationalDate != view.operationalDate.iso;
    if (dateChanged) _disposeDayNoteRegistration();

    _dayNoteOperationalDate = view.operationalDate.iso;
    _editableNoteDate = view.canEdit ? view.operationalDate : null;
    _persistedDayNote = note;

    if (_dayNoteSnapshotKey != key &&
        (dateChanged || !_dayNoteFocus.hasFocus)) {
      _dayNoteController.value = TextEditingValue(
        text: note,
        selection: TextSelection.collapsed(offset: note.length),
      );
      _dayNoteSnapshotKey = key;
    }
    _syncDayNoteEditor();
  }

  void _syncDayNoteEditor() {
    if (!mounted) return;
    final date = _editableNoteDate;
    final hasPendingEdit =
        date != null && _dayNoteController.text != _persistedDayNote;
    if (!hasPendingEdit) {
      _disposeDayNoteRegistration();
      return;
    }
    if (_dayNoteRegistration != null && _registeredDayNoteDate == date.iso) {
      return;
    }

    _disposeDayNoteRegistration();
    final editor = ref
        .read(todayNoteEditorFactoryProvider)
        .create(operationalDate: date, readText: () => _dayNoteController.text);
    _dayNoteRegistration = ref.read(editorRegistryProvider).register(editor);
    _registeredDayNoteDate = date.iso;
  }

  void _deactivateDayNoteEditor() {
    _editableNoteDate = null;
    _dayNoteOperationalDate = null;
    _persistedDayNote = '';
    _disposeDayNoteRegistration();
  }

  void _disposeDayNoteRegistration() {
    _dayNoteRegistration?.dispose();
    _dayNoteRegistration = null;
    _registeredDayNoteDate = null;
  }

  Future<void> _showCurrentDay() async {
    final runtime = await ref.read(boundaryRuntimeProvider.future);
    runtime.showCurrentDay();
  }

  Future<void> _setWorkout(WorkdayTodayView view, bool done) async {
    final revokesWaiver =
        done &&
        view.activeWaiver?.pillar == Pillar.morning &&
        view.entries.morning?.briefingDone == true;
    if (revokesWaiver && !await _confirmWaiverRevocation(Pillar.morning)) {
      return;
    }
    await _present(
      _controller.setWorkout(
        view.operationalDate,
        done: done,
        revokeWaiver: revokesWaiver,
      ),
    );
  }

  Future<void> _completeBriefing(WorkdayTodayView view) async {
    final revokesWaiver =
        view.activeWaiver?.pillar == Pillar.morning &&
        view.entries.morning?.workoutDone == true;
    if (revokesWaiver && !await _confirmWaiverRevocation(Pillar.morning)) {
      return;
    }
    await _present(
      _controller.setBriefing(
        view.operationalDate,
        done: true,
        mode: BriefingCompletion.manual,
        revokeWaiver: revokesWaiver,
      ),
    );
  }

  Future<void> _clearBriefing(WorkdayTodayView view) =>
      _present(_controller.setBriefing(view.operationalDate, done: false));

  Future<void> _setDayToggle(WorkdayTodayView view, bool on) async {
    final revokesWaiver = on && view.activeWaiver?.pillar == Pillar.day;
    if (revokesWaiver && !await _confirmWaiverRevocation(Pillar.day)) return;
    await _present(
      _controller.setDayToggle(
        view.operationalDate,
        on: on,
        revokeWaiver: revokesWaiver,
      ),
    );
  }

  Future<void> _saveDayNote(WorkdayTodayView view) async {
    final result = await _controller.setDayNote(
      view.operationalDate,
      note: _dayNoteController.text,
    );
    final succeeded = await _presentResult(result);
    if (succeeded) {
      final normalized = _dayNoteController.text.trim();
      _persistedDayNote = normalized.isEmpty ? '' : normalized;
      _disposeDayNoteRegistration();
      _dayNoteFocus.unfocus();
      _dayNoteSnapshotKey = null;
    }
  }

  Future<void> _removeDayNote(WorkdayTodayView view) async {
    final result = await _controller.setDayNote(view.operationalDate);
    final succeeded = await _presentResult(result);
    if (succeeded) {
      _persistedDayNote = '';
      _dayNoteController.clear();
      _disposeDayNoteRegistration();
      _dayNoteFocus.unfocus();
      _dayNoteSnapshotKey = null;
    }
  }

  Future<void> _startStudy(WorkdayTodayView view) =>
      _present(_controller.startStudy(view.operationalDate));

  Future<void> _finishStudy(WorkdayTodayView view) async {
    final revokesWaiver = view.activeWaiver?.pillar == Pillar.night;
    if (revokesWaiver && !await _confirmWaiverRevocation(Pillar.night)) {
      return;
    }
    await _present(
      _controller.finishStudy(
        view.operationalDate,
        revokeWaiver: revokesWaiver,
      ),
    );
  }

  Future<void> _cancelStudy(WorkdayTodayView view) =>
      _present(_controller.cancelStudy(view.operationalDate));

  Future<void> _chooseRecovery(WorkdayTodayView view) async {
    final note = await _showRecoveryDialog();
    if (note == null) return;
    final revokesWaiver = view.activeWaiver?.pillar == Pillar.night;
    if (revokesWaiver && !await _confirmWaiverRevocation(Pillar.night)) {
      return;
    }
    await _present(
      _controller.chooseRecovery(
        view.operationalDate,
        note: note,
        revokeWaiver: revokesWaiver,
      ),
    );
  }

  Future<void> _removeNightChoice(WorkdayTodayView view) =>
      _present(_controller.removeNightChoice(view.operationalDate));

  Future<void> _seal(WorkdayTodayView view) =>
      _present(_controller.sealDay(view.operationalDate));

  Future<void> _reopen(WorkdayTodayView view) async {
    final confirmed = await _confirm(
      title: Copy.reopenDay,
      message:
          'O dia voltará ao estado editável e poderá ser selado novamente.',
      confirmLabel: Copy.reopenDay,
    );
    if (confirmed) {
      await _present(_controller.reopenDay(view.operationalDate));
    }
  }

  Future<void> _createWaiver(WorkdayTodayView view) async {
    final request = await _showWaiverDialog();
    if (request == null) return;

    var result = await _controller.createWaiver(
      view.operationalDate,
      pillar: request.$1,
      reasonText: request.$2,
    );
    final failure = result.fold<RitmoFailure?>(
      onSuccess: (_) => null,
      onFailure: (value) => value,
    );
    if (failure?.code == 'waiver_return_rule_dialog_required') {
      final confirmed = await _confirm(
        title: Copy.returnRuleName,
        message:
            'Esta dispensa continua uma recorrência do mesmo pilar. '
            'Confirme conscientemente segundo a ${Copy.returnRuleName}.',
        confirmLabel: 'Confirmar dispensa',
      );
      if (!confirmed) return;
      result = await _controller.createWaiver(
        view.operationalDate,
        pillar: request.$1,
        reasonText: request.$2,
        recurrenceConfirmed: true,
      );
    }
    await _presentResult(result);
  }

  Future<bool> _confirmWaiverRevocation(Pillar pillar) => _confirm(
    title: 'Retirar dispensa',
    message:
        'A conclusão de ${_pillarName(pillar)} retirará a dispensa ativa e '
        'preservará seu histórico. Deseja continuar?',
    confirmLabel: 'Retirar e concluir',
  );

  Future<String?> _showRecoveryDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Recuperação'),
        content: TextField(
          controller: controller,
          maxLength: Limits.shortTextMaxRunes,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Nota opcional',
            alignLabelWithHint: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Confirmar Recuperação'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<(Pillar, String)?> _showWaiverDialog() async {
    final reasonController = TextEditingController();
    var pillar = Pillar.morning;
    final value = await showDialog<(Pillar, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Criar dispensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<Pillar>(
                initialValue: pillar,
                decoration: const InputDecoration(labelText: 'Pilar'),
                items: Pillar.values
                    .map(
                      (value) => DropdownMenuItem<Pillar>(
                        value: value,
                        child: Text(_pillarName(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setDialogState(() => pillar = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLength: Limits.shortTextMaxRunes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (pillar, reasonController.text)),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    return value;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _present(Future<Result<void, RitmoFailure>> operation) async {
    await _presentResult(await operation);
  }

  Future<bool> _presentResult(Result<void, RitmoFailure> result) async {
    if (!mounted) return false;
    return result.fold(
      onSuccess: (_) => true,
      onFailure: (failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
        return false;
      },
    );
  }

  void _showMissingBriefingAsset() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('O MP3 local do briefing ainda não foi fornecido.'),
        ),
      );
  }
}

class _CycleHeader extends StatelessWidget {
  const _CycleHeader({required this.view});

  final WorkdayTodayView view;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              view.purposeText,
              style: textTheme.titleMedium,
              semanticsLabel: 'Finalidade do ciclo: ${view.purposeText}',
            ),
            const SizedBox(height: 8),
            if (view.awaitingClosure)
              const Text(Copy.awaitingCycleClosure)
            else if (view.countdownDays case final days?)
              Text(
                '$days ${days == 1 ? 'dia' : 'dias'} para o próximo checkpoint',
              ),
            const SizedBox(height: 4),
            Text(
              'Data operacional ${view.operationalDate.iso}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MorningCard extends StatelessWidget {
  const _MorningCard({
    required this.view,
    required this.onWorkoutChanged,
    required this.onBriefingManual,
    required this.onBriefingCleared,
    required this.onPlayBriefing,
  });

  final WorkdayTodayView view;
  final ValueChanged<bool>? onWorkoutChanged;
  final VoidCallback? onBriefingManual;
  final VoidCallback? onBriefingCleared;
  final VoidCallback? onPlayBriefing;

  @override
  Widget build(BuildContext context) {
    final morning = view.entries.morning;
    final editable = view.canEdit;
    return _PillarCard(
      title: 'Manhã / Corpo',
      completed: view.pillarStatus.morningCompleted,
      waived: view.activeWaiver?.pillar == Pillar.morning,
      child: editable
          ? Column(
              children: <Widget>[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: morning?.workoutDone ?? false,
                  onChanged: (value) {
                    if (value != null) onWorkoutChanged?.call(value);
                  },
                  title: const Text(Copy.workoutLabel),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    morning?.briefingDone == true
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                  ),
                  title: const Text('Briefing de metas do ciclo'),
                  subtitle: morning?.briefingDone == true
                      ? Text(
                          morning?.briefingMode == BriefingCompletion.automatic
                              ? 'Concluído ao fim do MP3'
                              : 'Concluído manualmente',
                        )
                      : const Text('MP3 local ou conclusão manual imediata'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (morning?.briefingDone != true)
                      OutlinedButton.icon(
                        onPressed: onPlayBriefing,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Ouvir MP3'),
                      ),
                    if (morning?.briefingDone != true)
                      FilledButton.tonal(
                        onPressed: onBriefingManual,
                        child: const Text('Concluir manualmente'),
                      ),
                    if (morning?.briefingDone == true)
                      TextButton(
                        onPressed: onBriefingCleared,
                        child: const Text('Desmarcar briefing'),
                      ),
                  ],
                ),
              ],
            )
          : Column(
              children: <Widget>[
                _ReadOnlyStatus(
                  label: Copy.workoutLabel,
                  completed: morning?.workoutDone ?? false,
                ),
                _ReadOnlyStatus(
                  label: 'Briefing de metas do ciclo',
                  completed: morning?.briefingDone ?? false,
                ),
              ],
            ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.view,
    required this.noteController,
    required this.noteFocus,
    required this.onToggleChanged,
    required this.onSaveNote,
    required this.onRemoveNote,
  });

  final WorkdayTodayView view;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onSaveNote;
  final VoidCallback? onRemoveNote;

  @override
  Widget build(BuildContext context) {
    final entry = view.entries.day;
    final initiative = view.visibleInitiative?.name;
    return _PillarCard(
      title: 'Dia / Presente',
      completed: view.pillarStatus.dayCompleted,
      waived: view.activeWaiver?.pillar == Pillar.day,
      child: view.canEdit
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  initiative == null
                      ? 'Nenhuma iniciativa de mudança está ativa.'
                      : 'Iniciativa: $initiative',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: entry?.toggleOn ?? false,
                  onChanged: onToggleChanged,
                  title: const Text(Copy.dayToggle),
                ),
                TextField(
                  controller: noteController,
                  focusNode: noteFocus,
                  maxLength: Limits.shortTextMaxRunes,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nota opcional sobre problema complexo',
                    alignLabelWithHint: true,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: onSaveNote,
                      child: const Text('Salvar nota'),
                    ),
                    if ((entry?.note ?? '').isNotEmpty)
                      TextButton(
                        onPressed: onRemoveNote,
                        child: const Text('Remover nota'),
                      ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  initiative == null
                      ? 'Nenhuma iniciativa de mudança está ativa.'
                      : 'Iniciativa: $initiative',
                ),
                _ReadOnlyStatus(
                  label: Copy.dayToggle,
                  completed: entry?.toggleOn ?? false,
                ),
                if ((entry?.note ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(entry!.note!),
                ],
              ],
            ),
    );
  }
}

class _NightCard extends StatelessWidget {
  const _NightCard({
    required this.view,
    required this.onStartStudy,
    required this.onFinishStudy,
    required this.onCancelStudy,
    required this.onRecovery,
    required this.onRemoveChoice,
  });

  final WorkdayTodayView view;
  final VoidCallback? onStartStudy;
  final VoidCallback? onFinishStudy;
  final VoidCallback? onCancelStudy;
  final VoidCallback? onRecovery;
  final VoidCallback? onRemoveChoice;

  @override
  Widget build(BuildContext context) {
    final night = view.entries.night;
    final block = view.linkedStudyBlock;
    final activeStudy =
        night?.kind == NightKind.study && block?.endedAt == null;
    final completedStudy =
        night?.kind == NightKind.study && block?.endedAt != null;
    final recovery = night?.kind == NightKind.recovery;
    final window = view.nightWindowState;

    return _PillarCard(
      title: 'Noite / Futuro',
      completed: view.pillarStatus.nightCompleted,
      waived: view.activeWaiver?.pillar == Pillar.night,
      child: !view.canEdit
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ReadOnlyStatus(
                  label: recovery
                      ? 'Recuperação'
                      : completedStudy
                      ? 'Estudo'
                      : 'Pilar da Noite',
                  completed: view.pillarStatus.nightCompleted,
                ),
                if (recovery && (night?.recoveryNote ?? '').isNotEmpty)
                  Text(night!.recoveryNote!),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (window.copy case final copy?) ...<Widget>[
                  Text(copy),
                  const SizedBox(height: 8),
                ],
                if (!window.hasActions && night?.kind == null)
                  const Text('A janela de registros noturnos está encerrada.'),
                if (activeStudy) ...<Widget>[
                  const Text('Estudo em andamento'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: onFinishStudy,
                        child: const Text('Encerrar Estudo'),
                      ),
                      OutlinedButton(
                        onPressed: onCancelStudy,
                        child: const Text('Cancelar Estudo'),
                      ),
                      if (window.allowsRecovery)
                        TextButton(
                          onPressed: onRecovery,
                          child: const Text('Substituir por Recuperação'),
                        ),
                    ],
                  ),
                ] else if (completedStudy) ...<Widget>[
                  const Text('Estudo concluído'),
                  const SizedBox(height: 8),
                  _NightReplacementActions(
                    allowsStudy: window.allowsStudy,
                    allowsRecovery: window.allowsRecovery,
                    onStudy: onStartStudy,
                    onRecovery: onRecovery,
                    onRemove: onRemoveChoice,
                  ),
                ] else if (recovery) ...<Widget>[
                  const Text('Recuperação confirmada'),
                  if ((night?.recoveryNote ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(night!.recoveryNote!),
                  ],
                  const SizedBox(height: 8),
                  _NightReplacementActions(
                    allowsStudy: window.allowsStudy,
                    allowsRecovery: false,
                    onStudy: onStartStudy,
                    onRecovery: onRecovery,
                    onRemove: onRemoveChoice,
                  ),
                ] else if (night?.kind == null) ...<Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      if (window.allowsStudy)
                        FilledButton.tonal(
                          onPressed: onStartStudy,
                          child: const Text('Iniciar Estudo'),
                        ),
                      if (window.allowsRecovery)
                        FilledButton.tonal(
                          onPressed: onRecovery,
                          child: const Text('Escolher Recuperação'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _NightReplacementActions extends StatelessWidget {
  const _NightReplacementActions({
    required this.allowsStudy,
    required this.allowsRecovery,
    required this.onStudy,
    required this.onRecovery,
    required this.onRemove,
  });

  final bool allowsStudy;
  final bool allowsRecovery;
  final VoidCallback? onStudy;
  final VoidCallback? onRecovery;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (allowsStudy)
          TextButton(onPressed: onStudy, child: const Text('Novo Estudo')),
        if (allowsRecovery)
          TextButton(
            onPressed: onRecovery,
            child: const Text('Escolher Recuperação'),
          ),
        OutlinedButton(
          onPressed: onRemove,
          child: const Text('Remover escolha'),
        ),
      ],
    );
  }
}

class _WaiverCard extends StatelessWidget {
  const _WaiverCard({required this.view, required this.onCreate});

  final WorkdayTodayView view;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final waiver = view.activeWaiver;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Dispensa', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (waiver != null) ...<Widget>[
              Text('${_pillarName(waiver.pillar)} — ${waiver.reasonText}'),
              const SizedBox(height: 4),
              const Text(
                'O pilar continua editável. Ao concluí-lo, a retirada da '
                'dispensa será confirmada.',
              ),
            ] else ...<Widget>[
              const Text('Nenhuma dispensa ativa nesta data.'),
              if (onCreate != null) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onCreate,
                  child: const Text('Criar dispensa'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SealSection extends StatelessWidget {
  const _SealSection({
    required this.view,
    required this.onSeal,
    required this.onReopen,
  });

  final WorkdayTodayView view;
  final VoidCallback? onSeal;
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    if (view.mode == TodayMode.closed) return const SizedBox.shrink();
    if (view.mode == TodayMode.openSealed) {
      return FilledButton.tonal(
        onPressed: onReopen,
        child: const Text(Copy.reopenDay),
      );
    }

    final missing = view.uncoveredIncompletePillars;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (missing.isNotEmpty)
              Text(
                'Ainda falta concluir ou dispensar: '
                '${missing.map(_pillarName).join(', ')}.',
              )
            else
              const Text('Os pilares necessários estão cobertos.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onSeal, child: const Text(Copy.sealDay)),
          ],
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.title,
    required this.completed,
    required this.waived,
    required this.child,
  });

  final String title;
  final bool completed;
  final bool waived;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (waived)
                    const Chip(label: Text('Dispensado'))
                  else
                    Icon(
                      completed
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      semanticLabel: completed ? 'Concluído' : 'Pendente',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyStatus extends StatelessWidget {
  const _ReadOnlyStatus({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
      ),
      title: Text(label),
      trailing: Text(completed ? 'Concluído' : 'Pendente'),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'A ação e seu rótulo devem ser informados em conjunto.',
       );

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(message),
        trailing: onAction == null
            ? null
            : TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ),
    );
  }
}

class _MuteDayView extends StatelessWidget {
  const _MuteDayView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Não foi possível carregar o dia operacional.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

String _pillarName(Pillar pillar) => switch (pillar) {
  Pillar.morning => 'Manhã / Corpo',
  Pillar.day => 'Dia / Presente',
  Pillar.night => 'Noite / Futuro',
};
