import '../../core/copy.dart';
import '../day/eligible_day.dart';
import '../time/operational_calendar.dart';

/// Cor semântica da copy de um único dia não selado.
///
/// O domínio expõe apenas o tom permitido por RF-03.1; a UI é responsável por
/// mapear este token para o cinza neutro do tema, sem alternativa vermelha.
enum FailureCopyColor { neutralGray }

/// Projeção mínima consumida pela tela Ritmo.
final class FailureCopyPresentation {
  const FailureCopyPresentation({required this.text, required this.color});

  final String text;
  final FailureCopyColor color;
}

/// Deriva a copy de retorno sem persistir estado ou consultar o relógio.
final class SingleLostDayCopyDeriver {
  const SingleLostDayCopyDeriver();

  static const FailureCopyPresentation _singleLostDay =
      FailureCopyPresentation(
        text: Copy.singleLostDay,
        color: FailureCopyColor.neutralGray,
      );

  /// Retorna a copy somente quando a sequência corrente tem um único dia útil
  /// elegível, encerrado e não selado.
  ///
  /// Dias `mute`, não úteis, abertos e anteriores à ativação não contam. Um
  /// dia aberto também não encerra a sequência já observada; um dia útil
  /// encerrado e selado a encerra.
  FailureCopyPresentation? derive(
    List<EligibleDay> timeline,
    OperationalDate activationDate,
  ) {
    final ordered = List<EligibleDay>.of(timeline)
      ..sort((left, right) => left.date.compareTo(right.date));
    var currentLength = 0;

    for (final day in ordered) {
      if (day.date < activationDate || day.isMute || !day.isWorkday) continue;
      if (!day.isClosed) continue;
      if (day.isSealed) {
        currentLength = 0;
      } else {
        currentLength++;
      }
    }

    return currentLength == 1 ? _singleLostDay : null;
  }
}
