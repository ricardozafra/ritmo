// Feature: ritmo, Property 45: Parser do Juramento
//
// Para qualquer documento Markdown, o parser usa a primeira ocorrência
// canônica do heading e devolve, em intervalo half-open não vazio, exatamente
// o primeiro bloco contíguo de blockquote quando a primeira linha não vazia
// posterior começa por `>`. O texto de entrada permanece idêntico.
//
// A integralidade de renderização pertence à Propriedade 46. Este teste é
// estritamente de domínio e não cria nem pressupõe comportamento de UI.
//
// **Validates: Requirements RF-09.7, RF-09.8, RF-09.10, RF-09.12**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:ritmo/domain/manifest/oath_parser.dart';

import '../../generators/shared.dart';

const String _canonicalHeading = '## IV. O JURAMENTO INTERNO';

enum _LineEnding { lf, crlf, cr, mixed }

typedef _OathFixture = ({
  int token,
  int prefixLength,
  int suffixLength,
  int blankLineCount,
  int blockLength,
  int secondBlockLength,
  int styleOffset,
  int mixedOffset,
});

typedef _ExpectedRange = ({int start, int endExclusive, List<String> block});

typedef _DocumentCase = ({
  String label,
  List<String> lines,
  _ExpectedRange? expected,
});

const _OathFixture _minimalFixture = (
  token: 0,
  prefixLength: 1,
  suffixLength: 1,
  blankLineCount: 0,
  blockLength: 1,
  secondBlockLength: 1,
  styleOffset: 0,
  mixedOffset: 0,
);

final Generator<_OathFixture> _anyOathFixture = any.simple(
  generate: (Random random, int size) {
    final breadth = max(1, min(size + 1, 6));
    return (
      token: random.nextInt(1 << 20),
      prefixLength: 1 + random.nextInt(breadth),
      suffixLength: 1 + random.nextInt(breadth),
      blankLineCount: random.nextInt(breadth),
      blockLength: 1 + random.nextInt(breadth),
      secondBlockLength: 1 + random.nextInt(breadth),
      styleOffset: random.nextInt(4),
      mixedOffset: random.nextInt(3),
    );
  },
  shrink: (_OathFixture value) sync* {
    if (value != _minimalFixture) yield _minimalFixture;
  },
);

List<String> _prefix(_OathFixture fixture) => List<String>.generate(
  fixture.prefixLength,
  (int index) => '# Prefixo íntegro ${fixture.token}.$index',
  growable: false,
);

List<String> _suffix(_OathFixture fixture) => List<String>.generate(
  fixture.suffixLength,
  (int index) => 'Sufixo comum ação ${fixture.token}.$index',
  growable: false,
);

List<String> _blankLines(
  _OathFixture fixture,
  int variant, {
  required int count,
}) {
  const forms = <String>['', ' ', '\t', ' \t '];
  return List<String>.generate(
    count,
    (int index) =>
        forms[(fixture.styleOffset + variant + index) % forms.length],
    growable: false,
  );
}

String _canonicalHeadingLine(_OathFixture fixture, int variant) {
  return switch ((fixture.styleOffset + variant) % 4) {
    0 => _canonicalHeading,
    1 => '  $_canonicalHeading  ',
    2 => '\t$_canonicalHeading\t',
    _ => ' \t$_canonicalHeading\t ',
  };
}

String _blockquoteLine({
  required _OathFixture fixture,
  required int index,
  required int variant,
  required String blockName,
}) {
  final body = '$blockName ação ${fixture.token}.$index';
  return switch ((fixture.styleOffset + variant + index) % 4) {
    0 => '> $body',
    1 => '>$body',
    2 => '  > $body',
    _ => '\t>$body',
  };
}

List<String> _blockquote(
  _OathFixture fixture,
  int variant, {
  required int length,
  required String blockName,
}) => List<String>.generate(
  length,
  (int index) => _blockquoteLine(
    fixture: fixture,
    index: index,
    variant: variant,
    blockName: blockName,
  ),
  growable: false,
);

_DocumentCase _validCase({
  required String label,
  required List<String> prefix,
  required String heading,
  required List<String> blankLines,
  required List<String> firstBlock,
  required List<String> remainder,
}) {
  final start = prefix.length + 1 + blankLines.length;
  return (
    label: label,
    lines: <String>[
      ...prefix,
      heading,
      ...blankLines,
      ...firstBlock,
      ...remainder,
    ],
    expected: (
      start: start,
      endExclusive: start + firstBlock.length,
      block: List<String>.unmodifiable(firstBlock),
    ),
  );
}

_DocumentCase _invalidCase(String label, List<String> lines) =>
    (label: label, lines: lines, expected: null);

List<_DocumentCase> _documents(_OathFixture fixture, int variant) {
  final prefix = _prefix(fixture);
  final suffix = _suffix(fixture);
  final heading = _canonicalHeadingLine(fixture, variant);
  final generatedBlanks = _blankLines(
    fixture,
    variant,
    count: fixture.blankLineCount,
  );
  final nonEmptyBlanks = _blankLines(
    fixture,
    variant + 1,
    count: fixture.blankLineCount + 1,
  );
  final firstBlock = _blockquote(
    fixture,
    variant,
    length: fixture.blockLength,
    blockName: 'primeiro bloco',
  );
  final singleLineBlock = <String>[firstBlock.first];
  final secondBlock = _blockquote(
    fixture,
    variant + 1,
    length: fixture.secondBlockLength,
    blockName: 'segundo bloco',
  );

  return <_DocumentCase>[
    _validCase(
      label: 'válido com segundo bloco separado',
      prefix: prefix,
      heading: heading,
      blankLines: generatedBlanks,
      firstBlock: firstBlock,
      remainder: <String>[' \t ', ...secondBlock, ...suffix],
    ),
    _validCase(
      label: 'válido com bloco unitário e conteúdo comum posterior',
      prefix: prefix,
      heading: heading,
      blankLines: nonEmptyBlanks,
      firstBlock: singleLineBlock,
      remainder: suffix,
    ),
    _invalidCase('heading com nível inválido', <String>[
      ...prefix,
      '  ### IV. O JURAMENTO INTERNO  ',
      ...generatedBlanks,
      ...firstBlock,
      ...suffix,
    ]),
    _invalidCase('heading com caixa inválida', <String>[
      ...prefix,
      '\t## IV. O Juramento Interno\t',
      ...generatedBlanks,
      ...firstBlock,
      ...suffix,
    ]),
    _invalidCase('heading com sufixo inválido', <String>[
      ...prefix,
      '  ## IV. O JURAMENTO INTERNO extra  ',
      ...generatedBlanks,
      ...firstBlock,
      ...suffix,
    ]),
    _invalidCase('conteúdo comum antes do blockquote', <String>[
      ...prefix,
      heading,
      ...generatedBlanks,
      'conteúdo comum anterior ${fixture.token}',
      ...firstBlock,
      ...suffix,
    ]),
    _invalidCase(
      'primeira ocorrência canônica inválida seguida de segunda válida',
      <String>[
        ...prefix,
        heading,
        ...generatedBlanks,
        'conteúdo comum invalida a primeira ocorrência ${fixture.token}',
        '',
        _canonicalHeadingLine(fixture, variant + 1),
        ...nonEmptyBlanks,
        ...firstBlock,
        ...suffix,
      ],
    ),
    _invalidCase('heading sem linha não vazia posterior', <String>[
      ...prefix,
      heading,
      ...generatedBlanks,
    ]),
  ];
}

String _lineSeparator(_LineEnding ending, int boundaryIndex, int mixedOffset) {
  return switch (ending) {
    _LineEnding.lf => '\n',
    _LineEnding.crlf => '\r\n',
    _LineEnding.cr => '\r',
    _LineEnding.mixed => const <String>[
      '\n',
      '\r',
      '\r\n',
    ][(mixedOffset + boundaryIndex) % 3],
  };
}

String _serialize(
  List<String> lines,
  _LineEnding ending,
  int mixedOffset, {
  required bool trailingNewline,
}) {
  final buffer = StringBuffer();
  for (var index = 0; index < lines.length; index++) {
    if (index > 0) {
      buffer.write(_lineSeparator(ending, index - 1, mixedOffset));
    }
    buffer.write(lines[index]);
  }
  if (trailingNewline) {
    buffer.write(_lineSeparator(ending, lines.length - 1, mixedOffset));
  }
  return buffer.toString();
}

void _verifyDocument({
  required OathParser parser,
  required _OathFixture fixture,
  required _DocumentCase document,
  required _LineEnding ending,
  required bool trailingNewline,
}) {
  final markdown = _serialize(
    document.lines,
    ending,
    fixture.mixedOffset,
    trailingNewline: trailingNewline,
  );
  final originalText = String.fromCharCodes(markdown.codeUnits);
  final originalCodeUnits = List<int>.of(markdown.codeUnits, growable: false);
  final context =
      '${document.label}; lineEnding=${ending.name}; '
      'trailingNewline=$trailingNewline; fixture=$fixture';

  final actual = parser.findOathInMarkdown(markdown);

  expect(markdown, originalText, reason: '$context; String alterada');
  expect(
    markdown.codeUnits,
    orderedEquals(originalCodeUnits),
    reason: '$context; caracteres alterados',
  );

  final expected = document.expected;
  if (expected == null) {
    expect(actual, isNull, reason: context);
    return;
  }

  expect(actual, isNotNull, reason: context);
  final range = actual!;
  expect(range.start, expected.start, reason: context);
  expect(range.endExclusive, expected.endExclusive, reason: context);
  expect(range.length, expected.block.length, reason: context);
  expect(range.length, greaterThan(0), reason: context);
  expect(range.contains(range.start - 1), isFalse, reason: context);
  expect(range.contains(range.start), isTrue, reason: context);
  expect(range.contains(range.endExclusive - 1), isTrue, reason: context);
  expect(range.contains(range.endExclusive), isFalse, reason: context);
  expect(
    document.lines.sublist(range.start, range.endExclusive),
    orderedEquals(expected.block),
    reason: '$context; bloco diferente do construído pelo oráculo',
  );
}

void main() {
  const parser = OathParser();

  Glados<_OathFixture>(_anyOathFixture, RitmoGlados.ci(runs: 100)).test(
    'Propriedade 45: a primeira ocorrência canônica governa o intervalo',
    (_OathFixture fixture) {
      for (final ending in _LineEnding.values) {
        final documents = _documents(fixture, ending.index);
        for (final trailingNewline in <bool>[false, true]) {
          for (final document in documents) {
            _verifyDocument(
              parser: parser,
              fixture: fixture,
              document: document,
              ending: ending,
              trailingNewline: trailingNewline,
            );
          }
        }
      }
    },
  );
}
