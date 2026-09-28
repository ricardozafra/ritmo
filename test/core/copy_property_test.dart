// Feature: ritmo, Property 52: Catálogo de copies literais e sóbrias
//
// Para qualquer constante do catálogo de copies, o texto não contém emoji nem
// nenhum termo do conjunto proibido (streak, sequência recorde, pontos, badge
// de recompensa, ranking, punição, vergonha), e toda copy declarada literal na
// especificação é exatamente igual ao seu texto declarado.
//
// **Validates: Requirements RF-02.19, RF-01.8, RF-01.28, RF-03.2, RF-03.14,
// RF-05.14, RF-07.11, RF-07.14, RF-08.1, RNF-03.3, RNF-03.4**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/copy.dart';

import '../generators/shared.dart';

/// Entrada do catálogo: constante exposta por `Copy` e o texto exatamente como
/// declarado na especificação, com o requisito que o declara.
typedef CopyEntry = ({
  String requirement,
  String name,
  String text,
  String declared,
});

/// Texto declarado literal em `requirements.md`, transcrito caractere a
/// caractere, independente da implementação sob teste.
const List<CopyEntry> _catalog = <CopyEntry>[
  (
    requirement: 'RF-01.8',
    name: 'dayToggle',
    text: Copy.dayToggle,
    declared: 'Presença e execução honradas hoje',
  ),
  (
    requirement: 'RF-01.17',
    name: 'nightRecoveryOnly',
    text: Copy.nightRecoveryOnly,
    declared: 'O expediente de estudo encerrou. Resta a noite.',
  ),
  (
    requirement: 'RF-01.28',
    name: 'workoutLabel',
    text: Copy.workoutLabel,
    declared: 'Treino de musculação',
  ),
  (
    requirement: 'RF-03.2',
    name: 'singleLostDay',
    text: Copy.singleLostDay,
    declared: 'Um dia perdido não é derrota; é dado.',
  ),
  (
    requirement: 'RF-05.14',
    name: 'muteDay',
    text: Copy.muteDay,
    declared: 'Território sagrado. Presença integral.',
  ),
  (
    requirement: 'RF-07.11',
    name: 'weeklyBridgesExhausted',
    text: Copy.weeklyBridgesExhausted,
    declared: 'Pontes visitadas ou adiadas esta semana',
  ),
  (
    requirement: 'RF-07.14',
    name: 'contactSuggestionIntent',
    text: Copy.contactSuggestionIntent,
    declared: 'sem pedir nada',
  ),
  (
    requirement: 'RF-03.14',
    name: 'protocolQuestions[0]',
    text: Copy.protocolCauseQuestion,
    declared: 'o que causou?',
  ),
  (
    requirement: 'RF-03.14',
    name: 'protocolQuestions[1]',
    text: Copy.protocolPlanOrExecutionQuestion,
    declared: 'o problema é o plano ou a execução?',
  ),
  (
    requirement: 'RF-03.14',
    name: 'protocolQuestions[2]',
    text: Copy.protocolAdjustmentQuestion,
    declared: 'qual o ajuste?',
  ),
  (
    requirement: 'RF-08.1',
    name: 'reviewQuestions[0]',
    text: Copy.reviewFulfilledQuestion,
    declared: 'o que foi cumprido?',
  ),
  (
    requirement: 'RF-08.1',
    name: 'reviewQuestions[1]',
    text: Copy.reviewFailedQuestion,
    declared: 'o que falhou?',
  ),
  (
    requirement: 'RF-08.1',
    name: 'reviewQuestions[2]',
    text: Copy.reviewLessonQuestion,
    declared: 'o que a falha ensina?',
  ),
];

/// Qualquer constante do catálogo de copies.
final Generator<CopyEntry> anyCopyEntry = any.choose(_catalog);

/// Conjunto proibido pela Propriedade 52. Termos de palavra única exigem
/// fronteira de palavra; expressões são buscadas como sequência.
const List<String> _forbiddenWords = <String>[
  'streak',
  'pontos',
  'ranking',
  'punição',
  'vergonha',
];

const List<String> _forbiddenPhrases = <String>[
  'sequência recorde',
  'badge de recompensa',
];

/// Faixas Unicode de emoji e pictogramas, incluindo seletor de apresentação
/// emoji e keycap combinante.
const List<(int, int)> _emojiRanges = <(int, int)>[
  (0x1F000, 0x1FAFF), // pictogramas, emoticons, bandeiras, símbolos estendidos
  (0x2600, 0x27BF), // símbolos diversos e dingbats
  (0x2B00, 0x2BFF), // setas e formas decorativas
  (0x20E3, 0x20E3), // keycap combinante
  (0xFE0F, 0xFE0F), // seletor de apresentação emoji
];

bool _containsEmoji(String text) => text.runes.any(
  (rune) => _emojiRanges.any((range) => rune >= range.$1 && rune <= range.$2),
);

const Map<String, String> _diacritics = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Normaliza caixa e acentuação para que a busca não dependa de grafia.
String _fold(String text) {
  final lowered = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lowered.split('')) {
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}

List<String> _forbiddenTermsIn(String text) {
  final folded = _fold(text);
  return <String>[
    for (final word in _forbiddenWords)
      if (RegExp('(?<![a-z0-9])${_fold(word)}(?![a-z0-9])').hasMatch(folded))
        word,
    for (final phrase in _forbiddenPhrases)
      if (folded.contains(_fold(phrase))) phrase,
  ];
}

void main() {
  Glados(
    anyCopyEntry,
    RitmoGlados.ci(),
  ).test('Propriedade 52: copies do catálogo são literais e sóbrias', (
    CopyEntry entry,
  ) {
    // RNF-03.4: a copy não é parafraseada — é igual ao texto declarado.
    expect(
      entry.text,
      entry.declared,
      reason:
          'Copy.${entry.name} deve reproduzir literalmente ${entry.requirement}',
    );

    // RNF-03.3: tom sóbrio, sem emoji.
    expect(
      _containsEmoji(entry.text),
      isFalse,
      reason: 'Copy.${entry.name} contém emoji: "${entry.text}"',
    );

    // RF-02.19 e RNF-03.3: nenhum termo de gamificação ou punição.
    expect(
      _forbiddenTermsIn(entry.text),
      isEmpty,
      reason: 'Copy.${entry.name} usa termo proibido: "${entry.text}"',
    );
  });
}
