// Feature: ritmo, Property 46: Renderização de Markdown não executa HTML
//
// Para qualquer Markdown local, HTML bruto é mantido como texto inerte, a
// fonte original permanece reconstruível e recursos remotos nunca se tornam
// ImageProvider ou platform view. Contratos de widget verificam também a
// integralidade dos tokens legíveis e o destaque exclusivo do Juramento.
//
// **Validates: Requirements RF-09.6, RNF-02.5**

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:ritmo/ui/manifest/manifest_render_plan.dart';
import 'package:ritmo/ui/manifest/safe_manifest_markdown.dart';

import '../../generators/shared.dart';

typedef _UnsafeMarkdownFixture = ({
  int token,
  String lineEnding,
  bool includeOath,
  int extraHtmlBlocks,
});

final Generator<_UnsafeMarkdownFixture> _anyUnsafeMarkdown = any.simple(
  generate: (Random random, int size) {
    const endings = <String>['\n', '\r\n', '\r'];
    return (
      token: random.nextInt(1 << 30),
      lineEnding: endings[random.nextInt(endings.length)],
      includeOath: random.nextBool(),
      extraHtmlBlocks: random.nextInt(max(1, min(size + 1, 5))),
    );
  },
  shrink: (_UnsafeMarkdownFixture fixture) sync* {
    const minimal = (
      token: 0,
      lineEnding: '\n',
      includeOath: true,
      extraHtmlBlocks: 0,
    );
    if (fixture != minimal) yield minimal;
  },
);

String _document(_UnsafeMarkdownFixture fixture) {
  final lines = <String>[
    '# Pedra ${fixture.token}',
    '',
    'antes-${fixture.token}',
    '',
    '<script data-token="${fixture.token}">script-${fixture.token}</script>',
    '<div onclick="danger-${fixture.token}()">html-${fixture.token}</div>',
    '<img src="https://example.invalid/raw-${fixture.token}.png" '
        'onerror="danger-${fixture.token}()">',
    for (var index = 0; index < fixture.extraHtmlBlocks; index++) ...[
      '',
      '<section onmouseover="danger()">extra-${fixture.token}-$index</section>',
    ],
    '',
    '[link-${fixture.token}](javascript:danger-${fixture.token}())',
    '![imagem-${fixture.token}](https://example.invalid/${fixture.token}.png)',
    if (fixture.includeOath) ...[
      '',
      '## IV. O JURAMENTO INTERNO',
      '',
      '> juramento-${fixture.token}',
      '> segunda-linha-${fixture.token}',
      '',
      '> bloco-comum-${fixture.token}',
    ],
    '',
    'depois-${fixture.token}',
  ];
  return lines.join(fixture.lineEnding);
}

int _occurrences(String source, String needle) {
  var count = 0;
  var offset = 0;
  while (true) {
    final index = source.indexOf(needle, offset);
    if (index < 0) return count;
    count++;
    offset = index + needle.length;
  }
}

void main() {
  Glados<_UnsafeMarkdownFixture>(
    _anyUnsafeMarkdown,
    RitmoGlados.ci(runs: 100),
  ).test('Propriedade 46: o plano neutraliza HTML sem perder a fonte', (
    _UnsafeMarkdownFixture fixture,
  ) {
    final markdown = _document(fixture);
    final originalCodeUnits = List<int>.of(markdown.codeUnits, growable: false);
    final plan = ManifestRenderPlan.fromMarkdown(markdown);
    final context =
        'token=${fixture.token}, oath=${fixture.includeOath}, '
        'ending=${fixture.lineEnding.codeUnits}';

    expect(plan.originalMarkdown, markdown, reason: context);
    expect(plan.reconstructedMarkdown, markdown, reason: context);
    expect(
      plan.reconstructedMarkdown.codeUnits,
      orderedEquals(originalCodeUnits),
      reason: context,
    );
    expect(plan.safeMarkdown.contains('<'), isFalse, reason: context);
    expect(plan.safeMarkdown, contains('&lt;script'), reason: context);
    expect(
      plan.safeMarkdown,
      contains('script-${fixture.token}'),
      reason: context,
    );
    expect(plan.safeMarkdown, contains('onclick='), reason: context);
    expect(plan.safeMarkdown, contains('javascript:'), reason: context);
    expect(
      plan.safeMarkdown,
      contains('imagem-${fixture.token}'),
      reason: context,
    );

    final oathLines = plan.sourceLines.where((line) => line.isOath).length;
    expect(plan.hasOath, fixture.includeOath, reason: context);
    expect(oathLines, fixture.includeOath ? 2 : 0, reason: context);
    expect(
      _occurrences(plan.safeMarkdown, ManifestRenderPlan.oathMarker),
      oathLines,
      reason: context,
    );
  });

  testWidgets(
    'árvore segura preserva texto, bloqueia recursos remotos e destaca só o Juramento',
    (WidgetTester tester) async {
      const samples = 24;
      for (var token = 0; token < samples; token++) {
        final fixture = (
          token: token,
          lineEnding: switch (token % 3) {
            0 => '\n',
            1 => '\r\n',
            _ => '\r',
          },
          includeOath: true,
          extraHtmlBlocks: token % 4,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SafeManifestMarkdown(markdown: _document(fixture)),
              ),
            ),
          ),
        );
        await tester.pump();

        final visible = _visibleText(tester);
        for (final tokenText in <String>[
          'antes-$token',
          'script-$token',
          'html-$token',
          'link-$token',
          'imagem-$token',
          'juramento-$token',
          'segunda-linha-$token',
          'bloco-comum-$token',
          'depois-$token',
        ]) {
          expect(visible, contains(tokenText), reason: 'amostra $token');
        }

        expect(find.byType(SafeMarkdownImagePlaceholder), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(find.byType(RawImage), findsNothing);
        expect(find.byType(AndroidView), findsNothing);
        expect(find.byType(UiKitView), findsNothing);
        expect(find.byType(PlatformViewLink), findsNothing);
        expect(find.byKey(SafeManifestMarkdown.oathKey), findsOneWidget);

        final oathText = _textWidgetContaining(tester, 'juramento-$token');
        expect(_styleOf(oathText).fontFamily, 'serif');
        expect(_styleOf(oathText).fontStyle, FontStyle.italic);

        final commonQuote = _textWidgetContaining(tester, 'bloco-comum-$token');
        expect(_styleOf(commonQuote).fontFamily, isNot('serif'));
        expect(_styleOf(commonQuote).fontStyle, isNot(FontStyle.italic));
      }
    },
  );

  testWidgets('sem heading válido renderiza tudo sem destaque', (
    WidgetTester tester,
  ) async {
    const markdown = '''# Pedra

<script>payload-sem-heading</script>

> bloco-normal

![imagem-local](https://example.invalid/image.png)

fim-sem-heading''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SafeManifestMarkdown(markdown: markdown)),
      ),
    );
    await tester.pump();

    final visible = _visibleText(tester);
    expect(visible, contains('payload-sem-heading'));
    expect(visible, contains('bloco-normal'));
    expect(visible, contains('imagem-local'));
    expect(visible, contains('fim-sem-heading'));
    expect(find.byKey(SafeManifestMarkdown.oathKey), findsNothing);
    expect(find.byType(SafeMarkdownImagePlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(PlatformViewLink), findsNothing);
  });
}

String _visibleText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    buffer
      ..write(widget.data ?? widget.textSpan?.toPlainText() ?? '')
      ..write('\n');
  }
  for (final element in find.byType(SelectableText).evaluate()) {
    final widget = element.widget as SelectableText;
    buffer
      ..write(widget.data ?? widget.textSpan?.toPlainText() ?? '')
      ..write('\n');
  }
  return buffer.toString();
}

Text _textWidgetContaining(WidgetTester tester, String token) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(token),
    description: 'Text contendo $token',
  );
  expect(finder, findsOneWidget);
  return tester.widget<Text>(finder);
}

TextStyle _styleOf(Text text) {
  final spanStyle = text.textSpan is TextSpan
      ? (text.textSpan! as TextSpan).style
      : null;
  return text.style ?? spanStyle ?? const TextStyle();
}
