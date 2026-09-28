/// Catálogo central das copies que a especificação declara como literais.
///
/// Estes textos são parte do contrato de produto e não devem ser
/// parafraseados nas camadas de domínio ou interface.
abstract final class Copy {
  // RF-01.8
  static const String dayToggle = 'Presença e execução honradas hoje';

  // RF-01.17
  static const String nightRecoveryOnly =
      'O expediente de estudo encerrou. Resta a noite.';

  // RF-01.28
  static const String workoutLabel = 'Treino de musculação';

  // RF-03.2
  static const String singleLostDay = 'Um dia perdido não é derrota; é dado.';

  // RF-05.14
  static const String muteDay = 'Território sagrado. Presença integral.';

  // RF-07.11
  static const String weeklyBridgesExhausted =
      'Pontes visitadas ou adiadas esta semana';

  // RF-07.14
  static const String contactSuggestionIntent = 'sem pedir nada';

  // RF-03.14
  static const String protocolCauseQuestion = 'o que causou?';
  static const String protocolPlanOrExecutionQuestion =
      'o problema é o plano ou a execução?';
  static const String protocolAdjustmentQuestion = 'qual o ajuste?';

  /// Perguntas do protocolo na ordem definida pelo produto.
  static const List<String> protocolQuestions = <String>[
    protocolCauseQuestion,
    protocolPlanOrExecutionQuestion,
    protocolAdjustmentQuestion,
  ];

  // RF-08.1
  static const String reviewFulfilledQuestion = 'o que foi cumprido?';
  static const String reviewFailedQuestion = 'o que falhou?';
  static const String reviewLessonQuestion = 'o que a falha ensina?';

  /// Perguntas da revisão semanal na ordem definida pelo produto.
  static const List<String> reviewQuestions = <String>[
    reviewFulfilledQuestion,
    reviewFailedQuestion,
    reviewLessonQuestion,
  ];

  // RF-02.2, RF-02.4
  static const String sealDay = 'Selar o Dia';
  static const String reopenDay = 'Reabrir o Dia';
  static const String closedDayReadOnly =
      'O dia foi encerrado e está disponível somente para leitura.';

  // RF-05.2
  static const String businessTimezoneNotice =
      'Datas e horários seguem America/Sao_Paulo.';

  // RF-06.18
  static const String awaitingCycleClosure = 'aguardando encerramento';

  // RF-02.14
  static const String returnRuleName = 'Regra do Retorno';
}
