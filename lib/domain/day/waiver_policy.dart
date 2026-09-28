import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../time/operational_calendar.dart';
import 'eligible_day.dart';
// `Pillar` e `PillarWaiver` chegam pelo reexport de `waiver_recurrence.dart`.
import 'waiver_recurrence.dart';

export '../../core/result.dart' show WaiverViolation;
export 'pillar_waiver.dart' show Pillar, PillarWaiver;
export 'waiver_recurrence.dart'
    show RecurrenceAssessment, RecurrenceVerdict, WaiverHistory;

/// Dados informados para criar uma dispensa.
///
/// [pillar] é anulável para que a ausência vinda da interface seja rejeitada
/// explicitamente pela política, em vez de produzir uma dispensa incompleta.
/// [recurrenceConfirmed] indica que o diálogo da Regra do Retorno já foi
/// exibido e confirmado; sem ele a segunda dispensa da recorrência não é
/// criada (RF-02.14, RF-02.21).
final class CreateWaiver {
  const CreateWaiver({
    required this.id,
    required this.date,
    required this.pillar,
    required this.reasonText,
    this.recurrenceConfirmed = false,
  });

  final String id;
  final OperationalDate date;
  final Pillar? pillar;
  final String reasonText;
  final bool recurrenceConfirmed;
}

/// Histórico disponível para avaliar a unicidade lógica na data solicitada e a
/// recorrência do pilar nos dias úteis anteriores.
final class DayContext {
  const DayContext({
    this.waivers = const <PillarWaiver>[],
    this.activeWaiver,
    this.days = const <EligibleDay>[],
  });

  /// Dispensas conhecidas. Para avaliar recorrência deve incluir as dispensas
  /// dos dias úteis anteriores, não apenas as da data solicitada.
  final Iterable<PillarWaiver> waivers;

  /// Atalho para consumidores que já consultaram a dispensa ativa do dia.
  final PillarWaiver? activeWaiver;

  /// Projeção diária usada para distinguir dias úteis de dias `mute`.
  final Iterable<EligibleDay> days;

  bool hasActiveWaiverOn(OperationalDate date) {
    final current = activeWaiver;
    if (current != null && current.isActive && current.date == date) {
      return true;
    }
    return waivers.any((waiver) => waiver.date == date && waiver.isActive);
  }

  WaiverHistory get history => WaiverHistory(waivers: waivers, days: days);
}

/// Efeito descrito pela revogação positiva de uma dispensa (RF-02.23,
/// RF-02.24).
///
/// [waiver] já vem com `revoked_at` preenchido: a partir dele a dispensa é
/// histórico auditável e não cobre mais pilar algum no selo nem participa da
/// recorrência (RF-02.25). [completedPillar] é o pilar que o usuário conclui na
/// mesma operação, de modo que ambos os efeitos pertençam à mesma transação.
final class RevokeOutcome {
  const RevokeOutcome({required this.waiver, required this.completedPillar});

  final PillarWaiver waiver;
  final Pillar completedPillar;

  tz.TZDateTime get revokedAt => waiver.revokedAt!;

  @override
  String toString() =>
      'RevokeOutcome(${waiver.id} revogada em ${revokedAt.toIso8601String()}, '
      'pilar ${completedPillar.name})';
}

/// Regras puras de criação de dispensa (RF-02.9, RF-02.10, RF-02.12 a
/// RF-02.15, RF-02.21 e RD-11).
final class WaiverPolicy {
  const WaiverPolicy();

  static const WaiverRecurrence _recurrence = WaiverRecurrence();

  /// Recorrência daquele pilar na data, considerando somente dispensas ativas
  /// do mesmo pilar em dias úteis consecutivos (RF-02.12 a RF-02.15).
  RecurrenceVerdict recurrence(
    Pillar pillar,
    OperationalDate date,
    WaiverHistory history,
  ) => _recurrence.verdict(pillar, date, history);

  /// Avaliação completa da recorrência, com o tamanho da cadeia anterior.
  RecurrenceAssessment assessRecurrence(
    Pillar pillar,
    OperationalDate date,
    WaiverHistory history,
  ) => _recurrence.assess(pillar, date, history);

  Result<PillarWaiver, WaiverViolation> create(
    CreateWaiver command,
    DayContext context,
  ) {
    final pillar = command.pillar;
    if (pillar == null) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_pillar_required',
          message: 'Escolha o pilar a dispensar.',
        ),
      );
    }

    final reason = command.reasonText.trim();
    if (reason.isEmpty) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_reason_empty',
          message: 'Informe um motivo para a dispensa.',
        ),
      );
    }

    if (context.hasActiveWaiverOn(command.date)) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_active_already_exists',
          message: 'Esta data operacional já possui uma dispensa ativa.',
        ),
      );
    }

    final assessment = _recurrence.assess(
      pillar,
      command.date,
      context.history,
    );
    if (assessment.requiresReturnRuleDialog && !command.recurrenceConfirmed) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_return_rule_dialog_required',
          message:
              'Confirme o diálogo da Regra do Retorno antes de registrar '
              'esta dispensa.',
        ),
      );
    }

    return Result.success(
      PillarWaiver(
        id: command.id,
        date: command.date,
        pillar: pillar,
        reasonText: reason,
        // Registra apenas a confirmação exigida pela recorrência: a primeira
        // dispensa da cadeia nunca é marcada como confirmada (RF-02.13).
        recurrenceConfirmed: assessment.requiresReturnRuleDialog,
      ),
    );
  }

  /// Retira a dispensa porque o usuário conclui o pilar dispensado.
  ///
  /// Pura: descreve o efeito sem gravá-lo. [confirmed] representa a confirmação
  /// neutra exigida antes de concluir o pilar; sem ela nada é revogado
  /// (RF-02.23). Em caso de sucesso, a dispensa devolvida já está revogada e,
  /// portanto, sem efeito sobre selo e recorrência (RF-02.24, RF-02.25).
  Result<RevokeOutcome, WaiverViolation> revokeForCompletion(
    PillarWaiver waiver,
    DayContext context, {
    required Pillar completing,
    required tz.TZDateTime at,
    required bool confirmed,
  }) {
    if (!waiver.isActive || !context.hasActiveWaiverOn(waiver.date)) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_not_active',
          message: 'Não há dispensa ativa nesta data operacional.',
        ),
      );
    }

    if (waiver.pillar != completing) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_pillar_not_waived',
          message: 'A dispensa ativa não cobre o pilar concluído.',
        ),
      );
    }

    if (!confirmed) {
      return const Result.failure(
        WaiverViolation(
          code: 'waiver_revoke_confirmation_required',
          message: 'Confirme a retirada da dispensa para concluir o pilar.',
        ),
      );
    }

    return Result.success(
      RevokeOutcome(waiver: waiver.revoked(at), completedPillar: completing),
    );
  }
}
