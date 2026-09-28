/// Janela de ações noturnas do Ritmo, derivada sem consultar o relógio.
library;

import '../../core/copy.dart';
import 'operational_calendar.dart';
import 'operational_clock.dart';

/// Ações ordinárias disponíveis para o Pilar da Noite.
enum NightAction { study, recovery }

/// Projeção imutável das ações e da copy aplicáveis ao instante avaliado.
final class NightWindowState {
  const NightWindowState._({required this.actions, this.copy});

  static const beforeStudyDeadline = NightWindowState._(
    actions: <NightAction>{NightAction.study, NightAction.recovery},
  );

  static const recoveryOnly = NightWindowState._(
    actions: <NightAction>{NightAction.recovery},
    copy: Copy.nightRecoveryOnly,
  );

  static const closed = NightWindowState._(actions: <NightAction>{});

  final Set<NightAction> actions;
  final String? copy;

  bool get allowsStudy => actions.contains(NightAction.study);
  bool get allowsRecovery => actions.contains(NightAction.recovery);
  bool get hasActions => actions.isNotEmpty;
}

/// Particiona puramente a janela noturna de uma data operacional.
///
/// [now] é recebido do chamador; esta classe nunca consulta o instante atual.
/// O [clock] serve somente para materializar as fronteiras configuradas no
/// fuso oficial `America/Sao_Paulo`.
final class NightWindow {
  const NightWindow(this.clock);

  final OperationalClock clock;

  NightWindowState evaluate({
    required DateTime now,
    required OperationalDate operationalDate,
  }) {
    final blockDeadline = clock.blockDeadline(operationalDate);
    if (now.isBefore(blockDeadline)) {
      return NightWindowState.beforeStudyDeadline;
    }

    final operationalClose = clock.operationalClose(operationalDate);
    if (now.isBefore(operationalClose)) {
      return NightWindowState.recoveryOnly;
    }

    return NightWindowState.closed;
  }
}
