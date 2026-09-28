library;

import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../time/operational_calendar.dart';
import 'seal_eligibility.dart';

enum DayResult { sealed, unsealed, mute }

enum MuteCause { weekend, holiday }

/// Estado diário de domínio. O lifecycle ([closedAt]) é independente do
/// resultado, e toda instância nasce respeitando os invariantes de RD-2/RD-3.
final class Day {
  factory Day({
    required OperationalDate operationalDate,
    required DayResult baseResult,
    required DayResult effectiveResult,
    tz.TZDateTime? closedAt,
    tz.TZDateTime? sealTimestamp,
    MuteCause? muteCause,
    DayResult? previousResult,
  }) {
    final problem = _invariantProblem(
      baseResult: baseResult,
      effectiveResult: effectiveResult,
      sealTimestamp: sealTimestamp,
      muteCause: muteCause,
      previousResult: previousResult,
    );
    if (problem != null) {
      throw ArgumentError('Estado diário inválido: $problem');
    }
    return Day._(
      operationalDate: operationalDate,
      baseResult: baseResult,
      effectiveResult: effectiveResult,
      closedAt: closedAt,
      sealTimestamp: sealTimestamp,
      muteCause: muteCause,
      previousResult: previousResult,
    );
  }

  const Day._({
    required this.operationalDate,
    required this.baseResult,
    required this.effectiveResult,
    required this.closedAt,
    required this.sealTimestamp,
    required this.muteCause,
    required this.previousResult,
  });

  final OperationalDate operationalDate;
  final DayResult baseResult;
  final DayResult effectiveResult;
  final tz.TZDateTime? closedAt;
  final tz.TZDateTime? sealTimestamp;
  final MuteCause? muteCause;
  final DayResult? previousResult;

  bool get isOpen => closedAt == null;
  bool get isFrozen => !isOpen;
  bool get isMute => effectiveResult == DayResult.mute;

  static String? _invariantProblem({
    required DayResult baseResult,
    required DayResult effectiveResult,
    required tz.TZDateTime? sealTimestamp,
    required MuteCause? muteCause,
    required DayResult? previousResult,
  }) {
    if (baseResult == DayResult.mute) {
      return 'baseResult deve ser sealed ou unsealed';
    }
    if (previousResult == DayResult.mute) {
      return 'previousResult deve ser sealed, unsealed ou nulo';
    }
    if ((effectiveResult == DayResult.mute) != (muteCause != null)) {
      return 'effectiveResult mute deve corresponder a muteCause';
    }
    if ((baseResult == DayResult.sealed) != (sealTimestamp != null)) {
      return 'baseResult sealed deve corresponder a sealTimestamp';
    }
    final derived = muteCause == null ? baseResult : DayResult.mute;
    if (effectiveResult != derived) {
      return 'effectiveResult deve derivar de baseResult e muteCause';
    }
    if (muteCause == MuteCause.holiday && previousResult == null) {
      return 'feriado deve preservar previousResult';
    }
    if (muteCause == MuteCause.holiday && previousResult != baseResult) {
      return 'previousResult do feriado deve preservar o resultado base';
    }
    return null;
  }
}

sealed class DayCommand {
  const DayCommand();
}

final class SealDay extends DayCommand {
  const SealDay();
}

final class ReopenDay extends DayCommand {
  const ReopenDay();
}

final class CloseDay extends DayCommand {
  const CloseDay(this.at);

  final tz.TZDateTime at;
}

final class ApplyHoliday extends DayCommand {
  const ApplyHoliday({this.reasonText});

  final String? reasonText;
}

final class RemoveHoliday extends DayCommand {
  const RemoveHoliday({this.reasonText});

  final String? reasonText;
}

/// Dados externos mínimos para avaliar um comando de selo.
///
/// A elegibilidade é calculada pelas regras de pilares/dispensa; esta máquina
/// apenas exige o veredito e registra o instante fornecido pelo relógio oficial.
final class SealContext {
  const SealContext({
    required this.isEligible,
    required this.now,
    this.uncoveredIncompletePillars = const {},
  });

  final bool isEligible;
  final tz.TZDateTime now;
  final Set<Pillar> uncoveredIncompletePillars;
}

/// Máquina de estados pura do dia operacional.
final class DayStateMachine {
  const DayStateMachine();

  Result<Day, DayViolation> apply(
    Day current,
    DayCommand command,
    SealContext context,
  ) => switch (command) {
    SealDay() => _seal(current, context),
    ReopenDay() => _reopen(current),
    CloseDay(:final at) => _close(current, at),
    ApplyHoliday() => _applyHoliday(current),
    RemoveHoliday() => _removeHoliday(current),
  };

  Result<Day, DayViolation> _seal(Day current, SealContext context) {
    if (!current.isOpen) return _closed();
    if (current.isMute) {
      return _failure(
        code: 'day_mute',
        message: 'Esta ação não está disponível para este dia.',
      );
    }
    if (current.baseResult == DayResult.sealed) {
      return _failure(
        code: 'day_already_sealed',
        message: 'O dia já está selado.',
      );
    }
    if (!context.isEligible) {
      return _failure(
        code: 'day_not_seal_eligible',
        message: context.uncoveredIncompletePillars.isEmpty
            ? 'Ainda há itens do dia a concluir ou dispensar.'
            : 'Ainda falta concluir ou dispensar: '
                  '${_pillarNames(context.uncoveredIncompletePillars)}.',
      );
    }

    return _success(
      current,
      baseResult: DayResult.sealed,
      effectiveResult: DayResult.sealed,
      sealTimestamp: context.now,
    );
  }

  Result<Day, DayViolation> _reopen(Day current) {
    if (!current.isOpen) return _closed();
    if (current.isMute) {
      return _failure(
        code: 'day_mute',
        message: 'Esta ação não está disponível para este dia.',
      );
    }
    if (current.baseResult != DayResult.sealed) {
      return _failure(
        code: 'day_not_sealed',
        message: 'O dia já está aberto para edição.',
      );
    }

    return _success(
      current,
      baseResult: DayResult.unsealed,
      effectiveResult: DayResult.unsealed,
      clearSealTimestamp: true,
    );
  }

  Result<Day, DayViolation> _close(Day current, tz.TZDateTime at) {
    if (current.isFrozen) {
      return _failure(
        code: 'day_already_closed',
        message: 'O dia já está encerrado.',
      );
    }
    return _success(current, closedAt: at);
  }

  Result<Day, DayViolation> _applyHoliday(Day current) {
    if (current.muteCause == MuteCause.holiday) {
      return Result<Day, DayViolation>.success(current);
    }
    if (current.isMute) {
      return _failure(
        code: 'day_already_mute',
        message: 'O dia já está classificado sem atividades diárias.',
      );
    }

    return _success(
      current,
      effectiveResult: DayResult.mute,
      muteCause: MuteCause.holiday,
      previousResult: current.effectiveResult,
    );
  }

  Result<Day, DayViolation> _removeHoliday(Day current) {
    final previous = current.previousResult;
    if (current.muteCause != MuteCause.holiday || previous == null) {
      return _failure(
        code: 'day_not_holiday',
        message: 'A data operacional não está classificada como feriado.',
      );
    }

    return _success(
      current,
      effectiveResult: previous,
      clearMuteCause: true,
      // Mantido para auditoria; a operação Holiday registra aplicação/remoção.
      previousResult: previous,
    );
  }

  Result<Day, DayViolation> _success(
    Day current, {
    DayResult? baseResult,
    DayResult? effectiveResult,
    tz.TZDateTime? closedAt,
    tz.TZDateTime? sealTimestamp,
    bool clearSealTimestamp = false,
    MuteCause? muteCause,
    bool clearMuteCause = false,
    DayResult? previousResult,
  }) => Result<Day, DayViolation>.success(
    Day(
      operationalDate: current.operationalDate,
      baseResult: baseResult ?? current.baseResult,
      effectiveResult: effectiveResult ?? current.effectiveResult,
      closedAt: closedAt ?? current.closedAt,
      sealTimestamp: clearSealTimestamp
          ? null
          : sealTimestamp ?? current.sealTimestamp,
      muteCause: clearMuteCause ? null : muteCause ?? current.muteCause,
      previousResult: previousResult ?? current.previousResult,
    ),
  );

  String _pillarNames(Set<Pillar> pillars) => Pillar.values
      .where(pillars.contains)
      .map(
        (pillar) => switch (pillar) {
          Pillar.morning => 'Manhã/Corpo',
          Pillar.day => 'Dia/Presente',
          Pillar.night => 'Noite/Futuro',
        },
      )
      .join(', ');

  Result<Day, DayViolation> _closed() => _failure(
    code: 'day_closed',
    message: 'O dia encerrado está disponível somente para leitura.',
  );

  Result<Day, DayViolation> _failure({
    required String code,
    required String message,
  }) => Result<Day, DayViolation>.failure(
    DayViolation(code: code, message: message),
  );
}
