import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation/app_router.dart';
import '../../app/providers/cycle_providers.dart';
import '../../app/providers/weekly_review_providers.dart';
import '../../core/copy.dart';
import '../../core/limits.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/review/weekly_review.dart';

/// Fluxo textual da Revisão Semanal (RF-08.1, RF-08.2, RF-08.22, RF-08.23).
///
/// É um fluxo apresentado sobre o shell, acessível manualmente inclusive no
/// domingo `mute` (RF-08.10). As três perguntas literais têm autosave por
/// campo, sem timer nem permanência mínima; a finalização é explícita e torna
/// a revisão somente para leitura.
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  static const screenKey = ValueKey<String>('weekly-review-screen');
  static const fulfilledFieldKey = ValueKey<String>('review-fulfilled-field');
  static const failedFieldKey = ValueKey<String>('review-failed-field');
  static const lessonFieldKey = ValueKey<String>('review-lesson-field');
  static const finalizeButtonKey = ValueKey<String>('review-finalize-button');

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  static const _autosaveDebounce = Duration(milliseconds: 600);

  final _controllers = <WeeklyReviewField, TextEditingController>{
    WeeklyReviewField.fulfilled: TextEditingController(),
    WeeklyReviewField.failed: TextEditingController(),
    WeeklyReviewField.lesson: TextEditingController(),
  };
  final _debounces = <WeeklyReviewField, Timer>{};

  String? _reviewId;
  String _syncedKey = '';
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    // Garante o draft da semana vigente sem finalização implícita.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weeklyReviewControllerProvider).ensureCurrentDraft();
    });
  }

  @override
  void dispose() {
    for (final timer in _debounces.values) {
      timer.cancel();
    }
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(currentWeeklyReviewProvider);
    return Scaffold(
      key: WeeklyReviewScreen.screenKey,
      appBar: AppBar(title: const Text('Revisão Semanal')),
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () => ref.invalidate(currentWeeklyReviewProvider),
          ),
          data: (value) => value == null
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(value),
        ),
      ),
    );
  }

  Widget _buildForm(WeeklyReview review) {
    _synchronize(review);
    final readOnly = review.isFinalized;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        if (readOnly)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text(
                'Revisão finalizada. Disponível somente para leitura.',
              ),
            ),
          ),
        const _ClosureInviteCard(),
        _QuestionField(
          fieldKey: WeeklyReviewScreen.fulfilledFieldKey,
          question: Copy.reviewFulfilledQuestion,
          controller: _controllers[WeeklyReviewField.fulfilled]!,
          readOnly: readOnly,
          onChanged: (value) =>
              _scheduleAutosave(review, WeeklyReviewField.fulfilled, value),
        ),
        const SizedBox(height: 16),
        _QuestionField(
          fieldKey: WeeklyReviewScreen.failedFieldKey,
          question: Copy.reviewFailedQuestion,
          controller: _controllers[WeeklyReviewField.failed]!,
          readOnly: readOnly,
          onChanged: (value) =>
              _scheduleAutosave(review, WeeklyReviewField.failed, value),
        ),
        const SizedBox(height: 16),
        _QuestionField(
          fieldKey: WeeklyReviewScreen.lessonFieldKey,
          question: Copy.reviewLessonQuestion,
          controller: _controllers[WeeklyReviewField.lesson]!,
          readOnly: readOnly,
          onChanged: (value) =>
              _scheduleAutosave(review, WeeklyReviewField.lesson, value),
        ),
        const SizedBox(height: 24),
        _SelfEvaluationSection(reviewId: review.id, readOnly: readOnly),
        if (!readOnly)
          FilledButton(
            key: WeeklyReviewScreen.finalizeButtonKey,
            onPressed: _finalizing ? null : () => _finalize(review),
            child: const Text('Finalizar revisão'),
          ),
      ],
    );
  }

  /// Preenche os campos a partir da revisão persistida sem sobrescrever o que
  /// o usuário digita: só ressincroniza quando o registro base muda.
  void _synchronize(WeeklyReview review) {
    _reviewId = review.id;
    final key =
        '${review.id}\u0000${review.state.name}\u0000'
        '${review.answerFulfilled}\u0000${review.answerFailed}\u0000'
        '${review.answerLesson}';
    if (_syncedKey == key) return;
    _syncedKey = key;

    _setText(WeeklyReviewField.fulfilled, review.answerFulfilled);
    _setText(WeeklyReviewField.failed, review.answerFailed);
    _setText(WeeklyReviewField.lesson, review.answerLesson);
  }

  void _setText(WeeklyReviewField field, String? value) {
    final controller = _controllers[field]!;
    final text = value ?? '';
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _scheduleAutosave(
    WeeklyReview review,
    WeeklyReviewField field,
    String value,
  ) {
    if (review.isFinalized) return;
    _debounces[field]?.cancel();
    _debounces[field] = Timer(_autosaveDebounce, () {
      final id = _reviewId;
      if (id == null || !mounted) return;
      ref
          .read(weeklyReviewControllerProvider)
          .autosave(id, field: field, value: value)
          .then((result) {
            if (!mounted) return;
            result.fold<void>(
              onSuccess: (_) {},
              onFailure: (failure) => _showMessage(failure.message),
            );
          });
    });
  }

  Future<void> _finalize(WeeklyReview review) async {
    // Descarrega autosaves pendentes antes de finalizar.
    for (final timer in _debounces.values) {
      timer.cancel();
    }
    _debounces.clear();

    setState(() => _finalizing = true);
    final controller = ref.read(weeklyReviewControllerProvider);
    for (final field in WeeklyReviewField.values) {
      await controller.autosave(
        review.id,
        field: field,
        value: _controllers[field]!.text,
      );
    }

    final latest = await ref
        .read(weeklyReviewRepositoryProvider)
        .watchWeek(review.weekStart)
        .first;
    if (!mounted) {
      return;
    }
    if (latest == null) {
      setState(() => _finalizing = false);
      return;
    }

    final result = await controller.finalize(latest);
    if (!mounted) return;
    setState(() => _finalizing = false);
    result.fold<void>(
      onSuccess: (_) => _showMessage('Revisão finalizada.'),
      onFailure: (failure) => _showMessage(failure.message),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.fieldKey,
    required this.question,
    required this.controller,
    required this.readOnly,
    required this.onChanged,
  });

  final Key fieldKey;
  final String question;
  final TextEditingController controller;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(question, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          readOnly: readOnly,
          maxLength: Limits.weeklyReviewAnswerMaxRunes,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(Limits.weeklyReviewAnswerMaxRunes),
          ],
          maxLines: 5,
          minLines: 3,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
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
          const Text('Não foi possível carregar a revisão.'),
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

/// Convite de Encerramento de Ciclo apresentado junto à Revisão (RF-06.9,
/// RF-06.17). Aparece no máximo uma vez por semana operacional, é adiável e não
/// gera push. Some quando não há convite a oferecer.
class _ClosureInviteCard extends ConsumerWidget {
  const _ClosureInviteCard();

  static const cardKey = ValueKey<String>('cycle-closure-invite-card');
  static const reviewButtonKey = ValueKey<String>('cycle-closure-review');
  static const deferButtonKey = ValueKey<String>('cycle-closure-defer');
  static const closeButtonKey = ValueKey<String>('cycle-closure-start');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invite = ref.watch(cycleClosureInviteProvider);
    return invite.maybeWhen(
      data: (value) =>
          value == null ? const SizedBox.shrink() : _card(context, ref, value),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    CycleWithCheckpoints cycle,
  ) {
    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Encerramento de Ciclo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Este ciclo já passou do último checkpoint. Quando quiser, '
              'revise a finalidade e os checkpoints do ciclo.',
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: <Widget>[
                TextButton(
                  key: deferButtonKey,
                  onPressed: () => _defer(ref, cycle.cycle.id),
                  child: const Text('Adiar'),
                ),
                OutlinedButton(
                  key: reviewButtonKey,
                  onPressed: () => context.pushNamed(AppRoute.cycleEditorName),
                  child: const Text('Revisar ciclo'),
                ),
                FilledButton(
                  key: closeButtonKey,
                  onPressed: () => context.pushNamed(AppRoute.cycleClosureName),
                  child: const Text('Encerrar ciclo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _defer(WidgetRef ref, String cycleId) async {
    await ref.read(cycleControllerProvider).deferClosureInvite(cycleId);
    ref.invalidate(cycleClosureInviteProvider);
  }
}

/// Autoavaliação de competência incluída na Revisão quando esta ocorre no mês
/// civil de um checkpoint (RF-06.5, RF-06.6). Some quando não há checkpoint no
/// mês. Sem gamificação: apenas o nível Gartner e notas opcionais.
class _SelfEvaluationSection extends ConsumerWidget {
  const _SelfEvaluationSection({
    required this.reviewId,
    required this.readOnly,
  });

  static const sectionKey = ValueKey<String>('review-self-evaluation-section');

  final String reviewId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkpoints = ref.watch(reviewMonthCheckpointsProvider);
    return checkpoints.maybeWhen(
      data: (value) => value.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              key: sectionKey,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Autoavaliação',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final checkpoint in value)
                    _SelfEvaluationCard(
                      reviewId: reviewId,
                      checkpoint: checkpoint,
                      readOnly: readOnly,
                    ),
                ],
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _SelfEvaluationCard extends ConsumerStatefulWidget {
  const _SelfEvaluationCard({
    required this.reviewId,
    required this.checkpoint,
    required this.readOnly,
  });

  final String reviewId;
  final Checkpoint checkpoint;
  final bool readOnly;

  @override
  ConsumerState<_SelfEvaluationCard> createState() =>
      _SelfEvaluationCardState();
}

class _SelfEvaluationCardState extends ConsumerState<_SelfEvaluationCard> {
  GartnerLevel _level = GartnerLevel.i;
  final _notes = TextEditingController();
  String _syncedKey = '';
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(
      checkpointEvaluationProvider(widget.checkpoint.id),
    );
    existing.whenData(_synchronize);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _competencyLabel(widget.checkpoint.competency),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                DropdownButton<GartnerLevel>(
                  value: _level,
                  onChanged: widget.readOnly || _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _level = value);
                        },
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
              controller: _notes,
              enabled: !widget.readOnly && !_saving,
              maxLines: 2,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(
                  Limits.checkpointNotesMaxRunes,
                ),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notas (opcional)',
              ),
            ),
            if (!widget.readOnly) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Salvar avaliação'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _synchronize(CheckpointEvaluation? evaluation) {
    final key = '${evaluation?.level.wireValue}\u0000${evaluation?.notes}';
    if (_syncedKey == key) return;
    _syncedKey = key;
    if (evaluation == null) return;
    _level = evaluation.level;
    final notes = evaluation.notes ?? '';
    if (_notes.text != notes) {
      _notes.value = TextEditingValue(
        text: notes,
        selection: TextSelection.collapsed(offset: notes.length),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(cycleControllerProvider)
        .saveSelfEvaluation(
          checkpointId: widget.checkpoint.id,
          level: _level,
          weeklyReviewId: widget.reviewId,
          notes: _notes.text.isEmpty ? null : _notes.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold<void>(
      onSuccess: (_) {
        ref.invalidate(checkpointEvaluationProvider(widget.checkpoint.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avaliação salva.')));
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
