import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/protocol_providers.dart';
import '../../core/copy.dart';
import '../../core/limits.dart';
import '../../domain/protocol/protocol_alarm.dart';
import '../manifest/stone_screen.dart';

enum _ProtocolFlowStep { stone, form }

class ProtocolFlowScreen extends ConsumerStatefulWidget {
  const ProtocolFlowScreen({required this.protocolId, super.key});

  static const stoneStageKey = ValueKey<String>('protocol-stone-stage');
  static const formStageKey = ValueKey<String>('protocol-form-stage');
  static const continueButtonKey = ValueKey<String>('protocol-continue-button');
  static const causeFieldKey = ValueKey<String>('protocol-cause-field');
  static const classificationKey = ValueKey<String>(
    'protocol-plan-or-execution',
  );
  static const adjustmentFieldKey = ValueKey<String>(
    'protocol-adjustment-field',
  );
  static const submitButtonKey = ValueKey<String>('protocol-submit-button');

  final String protocolId;

  @override
  ConsumerState<ProtocolFlowScreen> createState() => _ProtocolFlowScreenState();
}

class _ProtocolFlowScreenState extends ConsumerState<ProtocolFlowScreen> {
  final TextEditingController _causeController = TextEditingController();
  final TextEditingController _adjustmentController = TextEditingController();

  late final DateTime _triggeredAt;
  _ProtocolFlowStep _step = _ProtocolFlowStep.stone;
  PlanOrExecution? _planOrExecution;
  bool _submitting = false;
  bool _unavailable = false;
  bool _routeClosing = false;

  @override
  void initState() {
    super.initState();
    _triggeredAt = ref.read(protocolClockProvider).nowInBusinessZone();
  }

  @override
  void dispose() {
    _causeController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  void _showForm() {
    setState(() => _step = _ProtocolFlowStep.form);
  }

  void _showStone() {
    setState(() => _step = _ProtocolFlowStep.stone);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds if a holiday invalidates the selected protocol while this flow
    // is open; the gate then closes without selecting a replacement.
    ref.watch(protocolForThisLaunchProvider);
    final gate = ref.watch(protocolSessionGateProvider);
    final isSelectedProtocol =
        !gate.isSessionClosed && gate.selectedId == widget.protocolId;
    final unavailable = _unavailable || !isSelectedProtocol;

    return PopScope<void>(
      canPop: _routeClosing || unavailable || _step == _ProtocolFlowStep.stone,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop &&
            !_routeClosing &&
            !unavailable &&
            _step == _ProtocolFlowStep.form) {
          _showStone();
        }
      },
      child: unavailable
          ? _buildUnavailableStage()
          : switch (_step) {
              _ProtocolFlowStep.stone => _buildStoneStage(),
              _ProtocolFlowStep.form => _buildFormStage(),
            },
    );
  }

  Widget _buildStoneStage() {
    return Scaffold(
      key: ProtocolFlowScreen.stoneStageKey,
      appBar: AppBar(title: const Text('Pedra')),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Expanded(child: StoneContent()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: ProtocolFlowScreen.continueButtonKey,
                onPressed: _showForm,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStage() {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      key: ProtocolFlowScreen.formStageKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar à Pedra',
          onPressed: _submitting ? null : _showStone,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Protocolo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: <Widget>[
            Text(Copy.protocolCauseQuestion, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: ProtocolFlowScreen.causeFieldKey,
              controller: _causeController,
              enabled: !_submitting,
              maxLength: Limits.protocolTextMaxRunes,
              maxLines: 5,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Resposta',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Copy.protocolPlanOrExecutionQuestion,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<PlanOrExecution>(
              key: ProtocolFlowScreen.classificationKey,
              segments: const <ButtonSegment<PlanOrExecution>>[
                ButtonSegment<PlanOrExecution>(
                  value: PlanOrExecution.plan,
                  label: Text('Plano'),
                ),
                ButtonSegment<PlanOrExecution>(
                  value: PlanOrExecution.execution,
                  label: Text('Execução'),
                ),
              ],
              selected: _planOrExecution == null
                  ? const <PlanOrExecution>{}
                  : <PlanOrExecution>{_planOrExecution!},
              emptySelectionAllowed: true,
              onSelectionChanged: _submitting
                  ? null
                  : (selection) {
                      setState(() {
                        _planOrExecution = selection.isEmpty
                            ? null
                            : selection.first;
                      });
                    },
            ),
            const SizedBox(height: 24),
            Text(Copy.protocolAdjustmentQuestion, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: ProtocolFlowScreen.adjustmentFieldKey,
              controller: _adjustmentController,
              enabled: !_submitting,
              maxLength: Limits.protocolTextMaxRunes,
              maxLines: 5,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_submitting) _submit();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Resposta',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: ProtocolFlowScreen.submitButtonKey,
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Concluir protocolo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableStage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Protocolo')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Este protocolo não está disponível nesta abertura.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _closeRoute,
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final planOrExecution = _planOrExecution;
    if (planOrExecution == null) {
      _showMessage('Selecione plano ou execução.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final result = await ref
          .read(protocolControllerProvider)
          .answerSelected(
            ProtocolAnswer(
              triggeredAt: ref
                  .read(protocolClockProvider)
                  .toBusinessZone(_triggeredAt),
              cause: _causeController.text,
              planOrExecution: planOrExecution,
              adjustment: _adjustmentController.text,
            ),
          );
      if (!mounted) return;

      result.fold<void>(
        onSuccess: (_) {
          ref.invalidate(protocolForThisLaunchProvider);
          _closeRoute();
        },
        onFailure: (failure) {
          final isUnavailable = switch (failure.code) {
            'protocol_not_found' ||
            'protocol_not_pending' ||
            'protocol_not_selected' => true,
            _ => false,
          };
          if (isUnavailable) {
            ref.read(protocolSessionGateProvider).closeSession();
            ref.invalidate(protocolForThisLaunchProvider);
          }
          setState(() {
            _submitting = false;
            _unavailable = isUnavailable;
          });
          _showMessage(failure.message);
        },
      );
    } on Object {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Não foi possível concluir o protocolo. Tente novamente.');
    }
  }

  void _closeRoute() {
    if (!mounted || _routeClosing) return;
    setState(() {
      _routeClosing = true;
      _submitting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) context.pop();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
