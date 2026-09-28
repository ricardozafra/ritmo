import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/domain/manifest/oath_parser.dart';

void main() {
  const parser = OathParser();

  group('OathParser', () {
    test('localiza o primeiro bloco contíguo após heading e linhas vazias', () {
      const markdown = '''# Pedra

  ## IV. O JURAMENTO INTERNO  
 
\t
> primeira linha
  > segunda linha

> outro bloco''';

      final range = parser.findOathInMarkdown(markdown);

      expect(range, const LineRange(5, 7));
      expect(range?.length, 2);
      expect(range?.contains(5), isTrue);
      expect(range?.contains(7), isFalse);
    });

    test('normaliza LF, CRLF e CR para o mesmo intervalo', () {
      const lf = 'antes\n## IV. O JURAMENTO INTERNO\n\n> um\n> dois\ndepois';

      for (final markdown in <String>[
        lf,
        lf.replaceAll('\n', '\r\n'),
        lf.replaceAll('\n', '\r'),
      ]) {
        expect(
          parser.findOathInMarkdown(markdown),
          const LineRange(3, 5),
        );
      }
    });

    test('aceita a API de linhas e remove CR residual de conteúdo CRLF', () {
      final lines =
          '## IV. O JURAMENTO INTERNO\r\n\r\n> juramento\r\ntexto'
              .split('\n');

      expect(parser.findOath(lines), const LineRange(2, 3));
    });

    test('retorna null quando o heading exato não existe', () {
      for (final heading in <String>[
        '## Juramento',
        '## IV. O Juramento Interno',
        '### IV. O JURAMENTO INTERNO',
        '## IV. O JURAMENTO INTERNO extra',
      ]) {
        expect(parser.findOathInMarkdown('$heading\n> texto'), isNull);
      }
    });

    test('retorna null quando o primeiro conteúdo posterior não é blockquote', () {
      const markdown = '''## IV. O JURAMENTO INTERNO

texto comum
> bloco posterior''';

      expect(parser.findOathInMarkdown(markdown), isNull);
    });

    test('a primeira ocorrência exata governa mesmo se outra seria válida', () {
      const markdown = '''## IV. O JURAMENTO INTERNO
texto comum

## IV. O JURAMENTO INTERNO
> bloco''';

      expect(parser.findOathInMarkdown(markdown), isNull);
    });

    test('retorna null para documento vazio ou heading sem conteúdo posterior', () {
      expect(parser.findOathInMarkdown(''), isNull);
      expect(
        parser.findOathInMarkdown('## IV. O JURAMENTO INTERNO\n \t'),
        isNull,
      );
    });
  });
}
