import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/waiver_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  const policy = WaiverPolicy();
  final date = OperationalDate(2026, 3, 9);

  CreateWaiver command({
    Pillar? pillar = Pillar.morning,
    String reason = 'Compromisso familiar',
  }) => CreateWaiver(
    id: 'waiver-1',
    date: date,
    pillar: pillar,
    reasonText: reason,
  );

  PillarWaiver waiver({
    required String id,
    required OperationalDate waiverDate,
    tz.TZDateTime? revokedAt,
  }) => PillarWaiver(
    id: id,
    date: waiverDate,
    pillar: Pillar.day,
    reasonText: 'Motivo anterior',
    revokedAt: revokedAt,
  );

  test('cria dispensa com pilar e motivo normalizado', () {
    final result = policy.create(
      command(pillar: Pillar.night, reason: '  Viagem a trabalho  '),
      const DayContext(),
    );

    expect(result, isA<Success<PillarWaiver, WaiverViolation>>());
    final created = (result as Success<PillarWaiver, WaiverViolation>).value;
    expect(created.pillar, Pillar.night);
    expect(created.reasonText, 'Viagem a trabalho');
    expect(created.date, date);
    expect(created.isActive, isTrue);
  });

  test('rejeita pilar ausente e motivo vazio após trim', () {
    final missingPillar = policy.create(
      command(pillar: null),
      const DayContext(),
    );
    final blankReason = policy.create(
      command(reason: ' \t\n '),
      const DayContext(),
    );

    expect(
      (missingPillar as Failure<PillarWaiver, WaiverViolation>).failure.code,
      'waiver_pillar_required',
    );
    expect(
      (blankReason as Failure<PillarWaiver, WaiverViolation>).failure.code,
      'waiver_reason_empty',
    );
  });

  test('rejeita segunda dispensa ativa na mesma data operacional', () {
    final active = waiver(id: 'active', waiverDate: date);

    final result = policy.create(command(), DayContext(activeWaiver: active));

    expect(result, isA<Failure<PillarWaiver, WaiverViolation>>());
    expect(
      (result as Failure<PillarWaiver, WaiverViolation>).failure.code,
      'waiver_active_already_exists',
    );
  });

  test('dispensa revogada ou de outra data não bloqueia nova ativa', () {
    final revoked = waiver(
      id: 'revoked',
      waiverDate: date,
      revokedAt: tz.TZDateTime(tz.UTC, 2026, 3, 9, 12),
    );
    final anotherDate = waiver(id: 'another-date', waiverDate: date.previous);

    final result = policy.create(
      command(),
      DayContext(waivers: [revoked, anotherDate]),
    );

    expect(result, isA<Success<PillarWaiver, WaiverViolation>>());
  });

  group('revokeForCompletion', () {
    final at = tz.TZDateTime(tz.UTC, 2026, 3, 9, 20, 30);
    final active = PillarWaiver(
      id: 'active',
      date: date,
      pillar: Pillar.night,
      reasonText: 'Plantão',
      recurrenceConfirmed: true,
    );

    Result<RevokeOutcome, WaiverViolation> revoke({
      PillarWaiver? target,
      Pillar completing = Pillar.night,
      bool confirmed = true,
    }) {
      final waiver = target ?? active;
      return policy.revokeForCompletion(
        waiver,
        DayContext(activeWaiver: waiver),
        completing: completing,
        at: at,
        confirmed: confirmed,
      );
    }

    test('revoga a dispensa ativa quando a retirada é confirmada', () {
      final result = revoke();

      final outcome = (result as Success<RevokeOutcome, WaiverViolation>).value;
      expect(outcome.completedPillar, Pillar.night);
      expect(outcome.revokedAt, at);
      expect(outcome.waiver.isActive, isFalse);
      expect(outcome.waiver.id, active.id);
      expect(outcome.waiver.reasonText, 'Plantão');
      expect(outcome.waiver.recurrenceConfirmed, isTrue);
    });

    test('exige a confirmação neutra antes de concluir o pilar', () {
      final result = revoke(confirmed: false);

      expect(
        (result as Failure<RevokeOutcome, WaiverViolation>).failure.code,
        'waiver_revoke_confirmation_required',
      );
    });

    test('rejeita pilar diferente do dispensado', () {
      final result = revoke(completing: Pillar.morning);

      expect(
        (result as Failure<RevokeOutcome, WaiverViolation>).failure.code,
        'waiver_pillar_not_waived',
      );
    });

    test('rejeita dispensa já revogada', () {
      final result = revoke(target: active.revoked(at));

      expect(
        (result as Failure<RevokeOutcome, WaiverViolation>).failure.code,
        'waiver_not_active',
      );
    });
  });
}
