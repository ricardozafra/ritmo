import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/copy.dart';

void main() {
  group('Copy', () {
    test('preserva os literais do dia e da noite', () {
      expect(Copy.dayToggle, 'Presença e execução honradas hoje');
      expect(
        Copy.nightRecoveryOnly,
        'O expediente de estudo encerrou. Resta a noite.',
      );
      expect(Copy.singleLostDay, 'Um dia perdido não é derrota; é dado.');
      expect(Copy.muteDay, 'Território sagrado. Presença integral.');
      expect(Copy.workoutLabel, 'Treino de musculação');
    });

    test('preserva os literais de Pontes', () {
      expect(
        Copy.weeklyBridgesExhausted,
        'Pontes visitadas ou adiadas esta semana',
      );
      expect(Copy.contactSuggestionIntent, 'sem pedir nada');
    });

    test('preserva as perguntas do protocolo na ordem declarada', () {
      expect(Copy.protocolQuestions, <String>[
        'o que causou?',
        'o problema é o plano ou a execução?',
        'qual o ajuste?',
      ]);
    });

    test('preserva as perguntas da revisão na ordem declarada', () {
      expect(Copy.reviewQuestions, <String>[
        'o que foi cumprido?',
        'o que falhou?',
        'o que a falha ensina?',
      ]);
    });
  });
}
