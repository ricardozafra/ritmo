// Feature: ritmo, Property 47: Limites textuais em caracteres Unicode
//
// Para qualquer string Unicode arbitrária, incluindo pares surrogate e marcas
// combinantes, e qualquer campo com limite declarado em caracteres, a entrada
// resultante preserva integralmente o prefixo válido, tem no máximo o número
// declarado de runes, bloqueia apenas o excedente e nunca aplica truncamento
// silencioso nem impõe limite mínimo.
//
// **Validates: Requirements RD-28, RD-29, RD-30, RD-31, RD-32, RD-33, RD-36,
// RNF-05.1, RNF-05.6**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/limits.dart';
import 'package:ritmo/core/result.dart';

import '../generators/shared.dart';

/// Campo com limite textual declarado: [declaredMaxRunes] é transcrito de
/// `requirements.md`, independente da implementação; [maxRunes] é o valor
/// exposto pela fonte única `Limits`.
typedef LimitedField = ({
  String requirement,
  String name,
  int declaredMaxRunes,
  int maxRunes,
});

const List<LimitedField> _fields = <LimitedField>[
  (
    requirement: 'RD-28',
    name: 'nomes editáveis (mentor, contato, ciclo, iniciativa)',
    declaredMaxRunes: 120,
    maxRunes: Limits.editableNameMaxRunes,
  ),
  (
    requirement: 'RD-29',
    name: 'nota curta, nota de Recuperação, motivo de dispensa, contexto de contato',
    declaredMaxRunes: 500,
    maxRunes: Limits.shortTextMaxRunes,
  ),
  (
    requirement: 'RD-30',
    name: 'causa e ajuste de ProtocolAlarm',
    declaredMaxRunes: 2000,
    maxRunes: Limits.protocolTextMaxRunes,
  ),
  (
    requirement: 'RD-31',
    name: 'respostas de WeeklyReview',
    declaredMaxRunes: 5000,
    maxRunes: Limits.weeklyReviewAnswerMaxRunes,
  ),
  (
    requirement: 'RD-32',
    name: 'notas de CheckpointEval',
    declaredMaxRunes: 2000,
    maxRunes: Limits.checkpointNotesMaxRunes,
  ),
  (
    requirement: 'RD-33',
    name: 'Cycle.purpose_text',
    declaredMaxRunes: 1000,
    maxRunes: Limits.cyclePurposeMaxRunes,
  ),
];

/// Qualquer campo com limite declarado em caracteres Unicode.
final Generator<LimitedField> anyLimitedField = any.choose(_fields);

/// Fronteiras exercitadas pelo texto gerado. Inclui todos os limites declarados
/// e `1`, que produz textos de 0, 1 e 2 runes — a borda onde um limite mínimo
/// implícito apareceria.
final List<int> _textBoundaries = <int>[
  1,
  ...{for (final field in _fields) field.maxRunes},
];

/// Texto Unicode arbitrário orbitando uma das fronteiras declaradas. Como a
/// fronteira do texto e o limite aplicado são sorteados de forma independente,
/// o par explora tanto entradas muito abaixo do limite quanto muito acima dele,
/// além de `limite - 1`, `limite` e `limite + 1`.
final Generator<UnicodeTextFixture> anyTextAtDeclaredBoundary = any.simple(
  generate: (random, size) {
    final boundary = _textBoundaries[random.nextInt(_textBoundaries.length)];
    final generator = boundary == Limits.shortTextMaxRunes
        ? anyUnicodeText
        : unicodeTextAround(boundary);
    return generator(random, size).value;
  },
  shrink: (value) sync* {
    if (value.text.isNotEmpty) {
      yield (text: '', boundary: value.boundary, kind: value.kind);
    }
  },
);

void main() {
  const policy = LimitPolicy();

  Glados2<LimitedField, UnicodeTextFixture>(
    anyLimitedField,
    anyTextAtDeclaredBoundary,
    RitmoGlados.ci(),
  ).test('Propriedade 47: limites textuais em caracteres Unicode', (
    LimitedField field,
    UnicodeTextFixture input,
  ) {
    // RD-28 a RD-33: o limite aplicado é exatamente o declarado.
    expect(
      field.maxRunes,
      field.declaredMaxRunes,
      reason: '${field.name} deve respeitar ${field.requirement}',
    );

    final runes = input.text.runes.toList(growable: false);
    final expectedAcceptedRunes = runes.length <= field.maxRunes
        ? runes.length
        : field.maxRunes;
    final result = policy.clampRunes(input.text, field.maxRunes);
    final context =
        'campo ${field.requirement} (limite ${field.maxRunes}), '
        'entrada ${input.kind.name} com ${runes.length} runes';

    // RD-36 e RNF-05.6: a medição é em caracteres Unicode (runes), não em
    // unidades UTF-16, então pares surrogate e marcas combinantes contam um.
    expect(result.acceptedRunes, expectedAcceptedRunes, reason: context);
    expect(
      result.acceptedRunes <= field.maxRunes,
      isTrue,
      reason: 'aceito acima do limite em $context',
    );

    // RNF-05.1: o prefixo válido é preservado integralmente e apenas o
    // excedente é bloqueado, sempre em fronteira de rune.
    expect(
      result.accepted,
      String.fromCharCodes(runes.take(expectedAcceptedRunes)),
      reason: context,
    );
    expect(
      result.rejected,
      String.fromCharCodes(runes.skip(expectedAcceptedRunes)),
      reason: context,
    );
    expect(
      result.rejectedRunes,
      runes.length - expectedAcceptedRunes,
      reason: context,
    );

    // RNF-05.6: nunca há truncamento silencioso — o original permanece
    // disponível e a concatenação de aceito e bloqueado o reconstrói.
    expect(result.original, input.text, reason: context);
    expect(result.accepted + result.rejected, input.text, reason: context);

    if (runes.length <= field.maxRunes) {
      // RD-36: nenhum limite mínimo é imposto; qualquer texto dentro do limite
      // é aceito na íntegra, inclusive vazio.
      expect(result.accepted, input.text, reason: context);
      expect(result.rejected, isEmpty, reason: context);
      expect(result.exceeded, isFalse, reason: context);
      expect(result.wasClamped, isFalse, reason: context);
      expect(result.violation, isNull, reason: context);
    } else {
      // RNF-05.1: o excedente é visível e reportado em runes.
      expect(result.exceeded, isTrue, reason: context);
      expect(result.rejected, isNotEmpty, reason: context);
      final violation = result.violation;
      expect(violation, isNotNull, reason: context);
      expect(violation!.actual, runes.length, reason: context);
      expect(violation.maximum, field.maxRunes, reason: context);
      expect(violation.unit, LimitUnit.runes, reason: context);
    }

    // RNF-05.6: aplicação determinística e idempotente — reaplicar o limite ao
    // conteúdo já aceito não bloqueia mais nada.
    final reapplied = policy.clampRunes(result.accepted, field.maxRunes);
    expect(reapplied.accepted, result.accepted, reason: context);
    expect(reapplied.rejected, isEmpty, reason: context);
    expect(reapplied.exceeded, isFalse, reason: context);

    // RD-36: o vazio é sempre aceito, para qualquer campo declarado.
    final empty = policy.clampRunes('', field.maxRunes);
    expect(empty.accepted, isEmpty, reason: context);
    expect(empty.exceeded, isFalse, reason: context);
    expect(empty.violation, isNull, reason: context);
  });
}
