import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../domain/manifest/oath_parser.dart';
import 'manifest_render_plan.dart';

/// Renderiza o manifesto local sem expor callbacks ou carregamento remoto.
final class SafeManifestMarkdown extends StatelessWidget {
  const SafeManifestMarkdown({
    super.key,
    required this.markdown,
    this.parser = const OathParser(),
    this.styleSheet,
    this.selectable = false,
  });

  static const Key oathKey = ValueKey<String>('safe-manifest-oath');

  final String markdown;
  final OathParser parser;
  final MarkdownStyleSheet? styleSheet;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final plan = ManifestRenderPlan.fromMarkdown(markdown, parser: parser);
    final effectiveStyle = MarkdownStyleSheet.fromTheme(
      Theme.of(context),
    ).merge(styleSheet);

    // Blockquotes comuns permanecem neutros. O único destaque visual é
    // aplicado pelo builder privado do Juramento.
    final normalStyle = effectiveStyle.copyWith(
      blockquote: effectiveStyle.p,
      blockquotePadding: EdgeInsets.zero,
      blockquoteDecoration: const BoxDecoration(),
    );

    return MarkdownBody(
      data: plan.safeMarkdown,
      selectable: selectable,
      styleSheet: normalStyle,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      blockSyntaxes: const <md.BlockSyntax>[_OathBlockSyntax()],
      builders: <String, MarkdownElementBuilder>{
        _OathBlockSyntax.tag: _OathElementBuilder(
          styleSheet: effectiveStyle,
          selectable: selectable,
        ),
      },
      sizedImageBuilder: _safeImageBuilder,
      // Nenhum onTapLink é exposto: links continuam legíveis, mas não podem
      // abrir navegador, executar URI javascript ou invocar código externo.
      onTapLink: null,
      softLineBreak: true,
    );
  }
}

/// Placeholder exclusivamente local para qualquer imagem Markdown.
///
/// A URI é exibida como dado e nunca é resolvida por [ImageProvider].
final class SafeMarkdownImagePlaceholder extends StatelessWidget {
  const SafeMarkdownImagePlaceholder({
    super.key,
    required this.uri,
    this.alt,
    this.title,
  });

  final Uri uri;
  final String? alt;
  final String? title;

  String get visibleText {
    final description = (alt == null || alt!.isEmpty) ? 'imagem' : alt!;
    return '[$description — ${uri.toString()}]';
  }

  @override
  Widget build(BuildContext context) =>
      Semantics(image: true, label: visibleText, child: Text(visibleText));
}

Widget _safeImageBuilder(MarkdownImageConfig config) =>
    SafeMarkdownImagePlaceholder(
      key: ValueKey<String>('safe-markdown-image:${config.uri}'),
      uri: config.uri,
      alt: config.alt,
      title: config.title,
    );

final class _OathBlockSyntax extends md.BlockSyntax {
  const _OathBlockSyntax();

  static const String tag = 'ritmo-oath';

  @override
  RegExp get pattern => _pattern;

  static final RegExp _pattern = RegExp(
    '^${RegExp.escape(ManifestRenderPlan.oathMarker)}',
  );

  @override
  md.Node parse(md.BlockParser parser) {
    final lines = <String>[];
    while (!parser.isDone && pattern.hasMatch(parser.current.content)) {
      lines.add(
        parser.current.content.substring(ManifestRenderPlan.oathMarker.length),
      );
      parser.advance();
    }

    final element = md.Element.empty(tag);
    element.attributes['markdown'] = lines.join('\n');
    return element;
  }
}

final class _OathElementBuilder extends MarkdownElementBuilder {
  _OathElementBuilder({required this.styleSheet, required this.selectable});

  final MarkdownStyleSheet styleSheet;
  final bool selectable;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final markdown = element.attributes['markdown'] ?? '';
    final serifItalic = const TextStyle(
      fontFamily: 'serif',
      fontStyle: FontStyle.italic,
    );
    TextStyle? oathStyle(TextStyle? source) => source?.merge(serifItalic);

    final oathStyleSheet = styleSheet.copyWith(
      a: oathStyle(styleSheet.a),
      p: oathStyle(styleSheet.p),
      code: oathStyle(styleSheet.code),
      h1: oathStyle(styleSheet.h1),
      h2: oathStyle(styleSheet.h2),
      h3: oathStyle(styleSheet.h3),
      h4: oathStyle(styleSheet.h4),
      h5: oathStyle(styleSheet.h5),
      h6: oathStyle(styleSheet.h6),
      em: oathStyle(styleSheet.em),
      strong: oathStyle(styleSheet.strong),
      del: oathStyle(styleSheet.del),
      blockquote: oathStyle(styleSheet.p),
      img: oathStyle(styleSheet.img),
      checkbox: oathStyle(styleSheet.checkbox),
      listBullet: oathStyle(styleSheet.listBullet),
      tableHead: oathStyle(styleSheet.tableHead),
      tableBody: oathStyle(styleSheet.tableBody),
      blockquotePadding: EdgeInsets.zero,
      blockquoteDecoration: const BoxDecoration(),
    );
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: SafeManifestMarkdown.oathKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MarkdownBody(
        data: markdown,
        selectable: selectable,
        styleSheet: oathStyleSheet,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        sizedImageBuilder: _safeImageBuilder,
        onTapLink: null,
        softLineBreak: true,
      ),
    );
  }
}
