import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  final date = OperationalDate(2026, 5, 4);
  final sealAt = tz.TZDateTime(tz.UTC, 2026, 5, 4, 22, 30);
  final closeAt = tz.TZDateTime(tz.UTC, 2026, 5, 5, 3);
  const machine = DayStateMachine();

  Day unsealed({tz.TZDateTime? closedAt}) => Day(
    operationalDate: date,
    baseResult: DayResult.unsealed,
    effectiveResult: DayResult.unsealed,
    closedAt: closedAt,
  );

  Day sealed({tz.TZDateTime? closedAt}) => Day(
    operationalDate: date,
    baseResult: DayResult.sealed,
    effectiveResult: DayResult.sealed,
    closedAt: closedAt,
    sealTimestamp: sealAt,
  );

  SealContext context({bool eligible = true, tz.TZDateTime? now}) =>
      SealContext(isEligible: eligible, now: now ?? sealAt);

  Day valueOf(Result<Day, DayViolation> result) =>
      (result as Success<Day, DayViolation>).value;

  DayViolation failureOf(Result<Day, DayViolation> result) =>
      (result as Failure<Day, DayViolation>).failure;

  group('invariantes de Day', () {
    test('aceita lifecycle aberto ou encerrado sem alterar o resultado', () {
      final open = unsealed();
      final closed = unsealed(closedAt: closeAt);

      expect(open.isOpen, isTrue);
      expect(open.isFrozen, isFalse);
      expect(closed.isOpen, isFalse);
      expect(closed.isFrozen, isTrue);
      expect(closed.effectiveResult, DayResult.unsealed);
    });

    test('rejeita effectiveResult mute sem muteCause e a relação inversa', () {
      expect(
        () => Day(
          operationalDate: date,
          baseResult: DayResult.unsealed,
          effectiveResult: DayResult.mute,
        ),
        throwsArgumentError,
      );
      expect(
        () => Day(
          operationalDate: date,
          baseResult: DayResult.unsealed,
          effectiveResult: DayResult.unsealed,
          muteCause: MuteCause.weekend,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita feriado sem previousResult', () {
      expect(
        () => Day(
          operationalDate: date,
          baseResult: DayResult.unsealed,
          effectiveResult: DayResult.mute,
          muteCause: MuteCause.holiday,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita inconsistência entre selo e sealTimestamp', () {
      expect(
        () => Day(
          operationalDate: date,
          baseResult: DayResult.sealed,
          effectiveResult: DayResult.sealed,
        ),
        throwsArgumentError,
      );
      expect(
        () => Day(
          operationalDate: date,
          baseResult: DayResult.unsealed,
          effectiveResult: DayResult.unsealed,
          sealTimestamp: sealAt,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SealDay e ReopenDay', () {
    test('sela dia aberto elegível com o instante informado', () {
      final result = machine.apply(unsealed(), const SealDay(), context());
      final day = valueOf(result);

      expect(day.baseResult, DayResult.sealed);
      expect(day.effectiveResult, DayResult.sealed);
      expect(day.sealTimestamp, sealAt);
      expect(day.closedAt, isNull);
    });

    test('rejeita selo inelegível com mensagem neutra', () {
      final result = machine.apply(
        unsealed(),
        const SealDay(),
        context(eligible: false),
      );
      final violation = failureOf(result);

      expect(violation.code, 'day_not_seal_eligible');
      expect(
        violation.message,
        'Ainda há itens do dia a concluir ou dispensar.',
      );
    });

    test('reabre dia selado e limpa sealTimestamp', () {
      final result = machine.apply(sealed(), const ReopenDay(), context());
      final day = valueOf(result);

      expect(day.baseResult, DayResult.unsealed);
      expect(day.effectiveResult, DayResult.unsealed);
      expect(day.sealTimestamp, isNull);
      expect(day.isOpen, isTrue);
    });

    test('rejeita selo e reabertura após fechamento', () {
      final sealResult = machine.apply(
        unsealed(closedAt: closeAt),
        const SealDay(),
        context(),
      );
      final reopenResult = machine.apply(
        sealed(closedAt: closeAt),
        const ReopenDay(),
        context(),
      );

      expect(failureOf(sealResult).code, 'day_closed');
      expect(failureOf(reopenResult).code, 'day_closed');
      expect(
        failureOf(reopenResult).message,
        'O dia encerrado está disponível somente para leitura.',
      );
    });
  });

  group('CloseDay', () {
    test('preenche closedAt sem acoplar lifecycle ao resultado', () {
      final result = machine.apply(unsealed(), CloseDay(closeAt), context());
      final day = valueOf(result);

      expect(day.closedAt, closeAt);
      expect(day.baseResult, DayResult.unsealed);
      expect(day.effectiveResult, DayResult.unsealed);
      expect(day.sealTimestamp, isNull);
    });

    test('rejeita segundo fechamento sem alterar o estado', () {
      final current = sealed(closedAt: closeAt);
      final result = machine.apply(
        current,
        CloseDay(closeAt.add(const Duration(days: 1))),
        context(),
      );

      expect(result.isFailure, isTrue);
      expect(failureOf(result).code, 'day_already_closed');
      expect(current.closedAt, closeAt);
      expect(current.baseResult, DayResult.sealed);
    });
  });

  group('ApplyHoliday e RemoveHoliday', () {
    test('aplica feriado em dia encerrado sem destruir selo ou lifecycle', () {
      final current = sealed(closedAt: closeAt);
      final result = machine.apply(
        current,
        const ApplyHoliday(reasonText: 'Feriado local'),
        context(),
      );
      final day = valueOf(result);

      expect(day.effectiveResult, DayResult.mute);
      expect(day.muteCause, MuteCause.holiday);
      expect(day.previousResult, DayResult.sealed);
      expect(day.baseResult, DayResult.sealed);
      expect(day.sealTimestamp, sealAt);
      expect(day.closedAt, closeAt);
    });

    test('reaplicar feriado é idempotente', () {
      final holiday = valueOf(
        machine.apply(unsealed(), const ApplyHoliday(), context()),
      );
      final reapplied = valueOf(
        machine.apply(holiday, const ApplyHoliday(), context()),
      );

      expect(reapplied, same(holiday));
    });

    test('remove feriado e restaura previousResult preservando auditoria', () {
      final holiday = valueOf(
        machine.apply(
          sealed(closedAt: closeAt),
          const ApplyHoliday(),
          context(),
        ),
      );
      final result = machine.apply(
        holiday,
        const RemoveHoliday(reasonText: 'Correção de calendário'),
        context(),
      );
      final restored = valueOf(result);

      expect(restored.effectiveResult, DayResult.sealed);
      expect(restored.muteCause, isNull);
      expect(restored.previousResult, DayResult.sealed);
      expect(restored.baseResult, DayResult.sealed);
      expect(restored.sealTimestamp, sealAt);
      expect(restored.closedAt, closeAt);
    });

    test('rejeita remoção sem feriado e aplicação sobre fim de semana', () {
      final weekend = Day(
        operationalDate: OperationalDate(2026, 5, 9),
        baseResult: DayResult.unsealed,
        effectiveResult: DayResult.mute,
        muteCause: MuteCause.weekend,
      );
      final remove = machine.apply(
        unsealed(),
        const RemoveHoliday(),
        context(),
      );
      final apply = machine.apply(weekend, const ApplyHoliday(), context());

      expect(failureOf(remove).code, 'day_not_holiday');
      expect(failureOf(apply).code, 'day_already_mute');
      expect(failureOf(apply).message, isNot(contains('erro')));
      expect(failureOf(apply).message, isNot(contains('falha')));
    });
  });
}
