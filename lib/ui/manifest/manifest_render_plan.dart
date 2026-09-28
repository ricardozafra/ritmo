import '../../domain/manifest/oath_parser.dart';

/// Uma linha do manifesto, incluindo seu terminador original.
final class ManifestSourceLine {
  const ManifestSourceLine({
    required this.content,
    required this.terminator,
    required this.isOath,
  });

  final String content;
  final String terminator;
  final bool isOath;

  String get source => '$content$terminator';
}

/// Plano puro usado pelo renderizador seguro do manifesto.
///
/// O plano preserva o documento original para auditoria, mantém cada terminador
/// de linha e produz uma entrada Markdown na qual HTML bruto está visível como
/// texto inerte. O bloco do Juramento recebe um marcador privado consumido por
/// [SafeManifestMarkdown].
final class ManifestRenderPlan {
  ManifestRenderPlan._({
    required this.originalMarkdown,
    required this.safeMarkdown,
    required this.oathRange,
    required List<ManifestSourceLine> sourceLines,
  }) : sourceLines = List<ManifestSourceLine>.unmodifiable(sourceLines);

  /// Marcador interno que nunca é encaminhado para a árvore visível.
  static const String oathMarker = '\uE000ritmo-oath:';

  final String originalMarkdown;
  final String safeMarkdown;
  final LineRange? oathRange;
  final List<ManifestSourceLine> sourceLines;

  bool get hasOath => oathRange != null;

  /// Reconstrói byte a byte (em unidades UTF-16) a entrada recebida.
  String get reconstructedMarkdown =>
      sourceLines.map((line) => line.source).join();

  factory ManifestRenderPlan.fromMarkdown(
    String markdown, {
    OathParser parser = const OathParser(),
  }) {
    final range = parser.findOathInMarkdown(markdown);
    final tokenized = _tokenizeLines(markdown);
    final sourceLines = <ManifestSourceLine>[];
    final safe = StringBuffer();

    for (var index = 0; index < tokenized.length; index++) {
      final line = tokenized[index];
      final isOath = range?.contains(index) ?? false;
      sourceLines.add(
        ManifestSourceLine(
          content: line.content,
          terminator: line.terminator,
          isOath: isOath,
        ),
      );

      if (isOath) {
        safe
          ..write(oathMarker)
          ..write(_neutralize(_blockquoteBody(line.content)));
      } else {
        safe.write(_neutralize(line.content));
      }
      safe.write(line.terminator);
    }

    return ManifestRenderPlan._(
      originalMarkdown: markdown,
      safeMarkdown: safe.toString(),
      oathRange: range,
      sourceLines: sourceLines,
    );
  }

  static String _neutralize(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      // Uma ocorrência fornecida pelo usuário continua visível, mas não pode
      // ser interpretada como o marcador privado de bloco.
      .replaceAll(oathMarker, '&#xE000;ritmo-oath:');

  static String _blockquoteBody(String line) {
    final trimmed = line.trimLeft();
    assert(trimmed.startsWith('>'));
    final markerOffset = line.length - trimmed.length;
    var bodyStart = markerOffset + 1;
    if (bodyStart < line.length) {
      final next = line.codeUnitAt(bodyStart);
      if (next == 0x20 || next == 0x09) bodyStart++;
    }
    return line.substring(bodyStart);
  }

  static List<({String content, String terminator})> _tokenizeLines(
    String source,
  ) {
    final lines = <({String content, String terminator})>[];
    var lineStart = 0;
    var index = 0;

    while (index < source.length) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit != 0x0A && codeUnit != 0x0D) {
        index++;
        continue;
      }

      var terminatorEnd = index + 1;
      if (codeUnit == 0x0D &&
          terminatorEnd < source.length &&
          source.codeUnitAt(terminatorEnd) == 0x0A) {
        terminatorEnd++;
      }
      lines.add((
        content: source.substring(lineStart, index),
        terminator: source.substring(index, terminatorEnd),
      ));
      lineStart = terminatorEnd;
      index = terminatorEnd;
    }

    lines.add((content: source.substring(lineStart), terminator: ''));
    return lines;
  }
}
