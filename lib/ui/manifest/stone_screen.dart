import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation/app_router.dart';
import '../../app/providers/manifest_providers.dart';
import '../../core/limits.dart';
import 'safe_manifest_markdown.dart';
import 'utf8_byte_length_limiting_text_input_formatter.dart';

class StoneScreen extends ConsumerWidget {
  const StoneScreen({super.key});

  static const screenKey = ValueKey<String>('stone-screen');
  static const editButtonKey = ValueKey<String>('stone-edit-button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(manifestPresentationProvider);
    final canEdit = switch (presentation) {
      AsyncData(:final value) => value.isEditable,
      _ => false,
    };

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: const Text('Pedra'),
        actions: <Widget>[
          if (canEdit)
            IconButton(
              key: editButtonKey,
              tooltip: 'Editar Pedra',
              onPressed: () => context.push(AppRoute.stoneEditPath),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: const SafeArea(top: false, child: StoneContent()),
    );
  }
}

/// Leitura compartilhada pela aba Pedra e pelo estágio inicial do Protocolo.
class StoneContent extends ConsumerWidget {
  const StoneContent({super.key});

  static const contentKey = ValueKey<String>('stone-content');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(manifestPresentationProvider);
    return KeyedSubtree(
      key: contentKey,
      child: presentation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ManifestLoadError(
          onRetry: () => ref.invalidate(manifestPresentationProvider),
        ),
        data: (value) => _ManifestReader(presentation: value),
      ),
    );
  }
}

class StoneEditScreen extends ConsumerWidget {
  const StoneEditScreen({super.key});

  static const screenKey = ValueKey<String>('stone-edit-screen');
  static const editorFieldKey = ValueKey<String>('stone-editor-field');
  static const saveButtonKey = ValueKey<String>('stone-save-button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(manifestPresentationProvider);
    return presentation.when(
      loading: () => const _StoneEditStatus(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _StoneEditStatus(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Não foi possível carregar a cópia local da Pedra.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(manifestPresentationProvider),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (value) => value.isEditable
          ? _ManifestEditor(initialMarkdown: value.markdown)
          : const _StoneEditStatus(
              child: Text(
                'A cópia local não está disponível para edição.',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

class _ManifestReader extends StatelessWidget {
  const _ManifestReader({required this.presentation});

  final ManifestPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!presentation.isEditable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              'Exibindo o manifesto empacotado somente para leitura. '
              'A cópia local está temporariamente indisponível.',
            ),
          ),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SafeManifestMarkdown(
                markdown: presentation.markdown,
                selectable: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManifestLoadError extends StatelessWidget {
  const _ManifestLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Não foi possível carregar a Pedra.',
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

class _StoneEditStatus extends StatelessWidget {
  const _StoneEditStatus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: StoneEditScreen.screenKey,
    appBar: AppBar(title: const Text('Editar Pedra')),
    body: SafeArea(
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

class _ManifestEditor extends ConsumerStatefulWidget {
  const _ManifestEditor({required this.initialMarkdown});

  final String initialMarkdown;

  @override
  ConsumerState<_ManifestEditor> createState() => _ManifestEditorState();
}

class _ManifestEditorState extends ConsumerState<_ManifestEditor> {
  late final TextEditingController _controller;
  late final Utf8ByteLengthLimitingTextInputFormatter _formatter;
  late int _byteLength;
  bool _saving = false;
  bool _routeClosing = false;
  bool _limitNoticeScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMarkdown);
    _byteLength = utf8.encode(widget.initialMarkdown).length;
    _formatter = Utf8ByteLengthLimitingTextInputFormatter(
      maxBytes: Limits.manifestMaxUtf8Bytes,
      onLimitExceeded: _scheduleLimitNotice,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_saving || _routeClosing,
      child: Scaffold(
        key: StoneEditScreen.screenKey,
        appBar: AppBar(
          title: const Text('Editar Pedra'),
          actions: <Widget>[
            IconButton(
              key: StoneEditScreen.saveButtonKey,
              tooltip: 'Salvar Pedra',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Edite o Markdown local. O conteúdo empacotado não será '
                  'alterado.',
                ),
                const SizedBox(height: 8),
                Text(
                  '$_byteLength de ${Limits.manifestMaxUtf8Bytes} bytes UTF-8',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    key: StoneEditScreen.editorFieldKey,
                    controller: _controller,
                    enabled: !_saving,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    inputFormatters: <Utf8ByteLengthLimitingTextInputFormatter>[
                      _formatter,
                    ],
                    onChanged: (value) {
                      setState(() => _byteLength = utf8.encode(value).length);
                    },
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      labelText: 'Manifesto em Markdown',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(manifestServiceProvider)
          .save(_controller.text);
      if (!mounted) return;

      result.fold<void>(
        onSuccess: (_) {
          final messenger = ScaffoldMessenger.of(context);
          setState(() {
            _saving = false;
            _routeClosing = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !context.canPop()) return;
            ref.invalidate(manifestPresentationProvider);
            context.pop();
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Pedra salva localmente.')),
              );
          });
        },
        onFailure: (failure) {
          setState(() => _saving = false);
          _showMessage(failure.message);
        },
      );
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Não foi possível salvar a Pedra. Tente novamente.');
    }
  }

  void _scheduleLimitNotice() {
    if (_limitNoticeScheduled) return;
    _limitNoticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _limitNoticeScheduled = false;
      if (!mounted) return;
      _showMessage('O conteúdo excede o limite permitido.');
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
