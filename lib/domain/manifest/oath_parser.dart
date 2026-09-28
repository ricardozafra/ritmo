/// Parser puro do intervalo do Juramento dentro do manifesto Markdown.
///
/// Não interpreta nem altera o Markdown: apenas devolve os índices das linhas
/// que formam o primeiro bloco de citação após o heading canônico.
library;

/// Intervalo de linhas no formato `[start, endExclusive)`.
final class LineRange {
  const LineRange(this.start, this.endExclusive)
    : assert(start >= 0),
      assert(endExclusive > start);

  /// Índice, baseado em zero, da primeira linha do intervalo.
  final int start;

  /// Índice exclusivo da primeira linha posterior ao intervalo.
  final int endExclusive;

  int get length => endExclusive - start;

  bool contains(int lineIndex) =>
      lineIndex >= start && lineIndex < endExclusive;

  @override
  bool operator ==(Object other) =>
      other is LineRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => 'LineRange($start, $endExclusive)';
}

/// Localiza o Juramento definido por RF-09.7, RF-09.8 e RF-09.10.
final class OathParser {
  const OathParser();

  static const String oathHeading = '## IV. O JURAMENTO INTERNO';

  /// Normaliza terminadores de [markdown], divide o documento e procura o
  /// Juramento sem alterar o conteúdo das linhas.
  LineRange? findOathInMarkdown(String markdown) =>
      findOath(_normalizedLines(markdown));

  /// Retorna o intervalo do primeiro bloco contíguo de blockquote após a
  /// primeira ocorrência do heading canônico, ou `null`.
  ///
  /// Elementos podem conter terminadores de linha (por exemplo, quando um
  /// documento CRLF foi separado apenas por `\n`); eles são normalizados antes
  /// da busca. Os índices retornados se referem à sequência normalizada.
  LineRange? findOath(List<String> lines) {
    final normalizedLines = _normalizedLines(lines.join('\n'));
    final headingIndex = normalizedLines.indexWhere(
      (line) => line.trim() == oathHeading,
    );
    if (headingIndex < 0) return null;

    var blockStart = headingIndex + 1;
    while (blockStart < normalizedLines.length &&
        normalizedLines[blockStart].trim().isEmpty) {
      blockStart++;
    }

    if (blockStart == normalizedLines.length ||
        !_isBlockquote(normalizedLines[blockStart])) {
      return null;
    }

    var blockEnd = blockStart + 1;
    while (blockEnd < normalizedLines.length &&
        _isBlockquote(normalizedLines[blockEnd])) {
      blockEnd++;
    }

    return LineRange(blockStart, blockEnd);
  }

  static List<String> _normalizedLines(String markdown) =>
      markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  static bool _isBlockquote(String line) => line.trimLeft().startsWith('>');
}
