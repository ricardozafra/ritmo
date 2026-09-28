import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/eligible_day.dart';
import 'package:ritmo/domain/day/waiver_policy.dart';
import 'package:ritmo/domain/day/waiver_recurrence.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  const recurrence = WaiverRecurrence();
  const policy = WaiverPolicy();

  // 2026-03-02 é segunda-feira; 03-07 e 03-08 são fim de semana.
  final monday = OperationalDate(2026, 3, 2);
  final tuesday = OperationalDate(2026, 3, 3);
  final wednesday = OperationalDate(2026, 3, 4);
  final thursday = OperationalDate(2026, 3, 5);
  final friday = OperationalDate(2026, 3, 6);
  final saturday = OperationalDate(2026, 3, 7);
  final sunday = OperationalDate(2026, 3, 8);
  final nextMonday = OperationalDate(2026, 3, 9);

  EligibleDay day(
    OperationalDate date, {
    bool isMute = false,
    bool isClosed = true,
    bool isSealed = false,
  }) => EligibleDay(
    date: date,
    isWorkday: !date.isWeekend && !isMute,
    isClosed: isClosed,
    isSealed: isSealed,
    isMute: isMute || date.isWeekend,
  );

  PillarWaiver waiver(
    OperationalDate date,
    Pillar pillar, {
    tz.TZDateTime? revokedAt,
  }) => PillarWaiver(
    id: 'waiver-${date.iso}-${pillar.name}',
    date: date,
    pillar: pillar,
    reasonText: 'Motivo',
    revokedAt: revokedAt,
  );

  List<EligibleDay> week({Map<OperationalDate, bool> mute = const {}}) => [
    for (final date in [
      monday,
      tuesday,
      wednesday,
      thursday,
      friday,
      saturday,
      sunday,
    ])
      day(date, isMute: mute[date] ?? false),
  ];

  test('primeira dispensa do pilar não exige diálogo', () {
    final assessment = recurrence.assess(
      Pillar.morning,
      wednesday,
      WaiverHistory(days: week()),
    );

    expect(assessment.verdict, RecurrenceVerdict.first);
    expect(assessment.previousChainLength, 0);
    expect(assessment.chainStartDate, isNull);
    expect(assessment.position, 1);
  });

  test('dia útil anterior com dispensa ativa do mesmo pilar exige diálogo', () {
    final assessment = recurrence.assess(
      Pillar.morning,
      wednesday,
      WaiverHistory(days: week(), waivers: [waiver(tuesday, Pillar.morning)]),
    );

    expect(assessment.verdict, RecurrenceVerdict.requiresReturnRuleDialog);
    expect(assessment.previousChainLength, 1);
    expect(assessment.chainStartDate, tuesday);
    expect(assessment.position, 2);
  });

  test('dias mute são pulados sem interromper a cadeia (RF-02.21)', () {
    final assessment = recurrence.assess(
      Pillar.night,
      nextMonday,
      WaiverHistory(
        days: [...week(), day(nextMonday, isClosed: false)],
        waivers: [waiver(friday, Pillar.night)],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.requiresReturnRuleDialog);
    expect(assessment.previousChainLength, 1);
    expect(assessment.chainStartDate, friday);
  });

  test('feriado manual entre as dispensas não interrompe a cadeia', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: week(mute: {wednesday: true}),
        waivers: [waiver(tuesday, Pillar.day)],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.requiresReturnRuleDialog);
    expect(assessment.previousChainLength, 1);
    expect(assessment.chainStartDate, tuesday);
  });

  test('cadeia acumula dias úteis consecutivos do mesmo pilar', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: week(),
        waivers: [
          waiver(monday, Pillar.day),
          waiver(tuesday, Pillar.day),
          waiver(wednesday, Pillar.day),
        ],
      ),
    );

    expect(assessment.previousChainLength, 3);
    expect(assessment.chainStartDate, monday);
    expect(assessment.position, 4);
  });

  test('dispensa ativa de outro pilar encerra a cadeia (RF-02.15)', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: week(),
        waivers: [
          waiver(monday, Pillar.day),
          waiver(tuesday, Pillar.night),
          waiver(wednesday, Pillar.day),
        ],
      ),
    );

    expect(assessment.previousChainLength, 1);
    expect(assessment.chainStartDate, wednesday);
  });

  test('dia útil sem dispensa ativa encerra a cadeia (RF-02.15)', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: week(),
        waivers: [waiver(monday, Pillar.day), waiver(tuesday, Pillar.day)],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.first);
    expect(assessment.previousChainLength, 0);
  });

  test('dia útil selado sem a dispensa encerra a cadeia (RF-02.15)', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: [
          day(monday),
          day(tuesday),
          day(wednesday, isSealed: true),
          day(thursday, isClosed: false),
        ],
        waivers: [waiver(monday, Pillar.day), waiver(tuesday, Pillar.day)],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.first);
    expect(assessment.previousChainLength, 0);
  });

  test('dia útil selado com a dispensa mantém a cadeia', () {
    final assessment = recurrence.assess(
      Pillar.day,
      thursday,
      WaiverHistory(
        days: [
          day(wednesday, isSealed: true),
          day(thursday, isClosed: false),
        ],
        waivers: [waiver(wednesday, Pillar.day)],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.requiresReturnRuleDialog);
    expect(assessment.previousChainLength, 1);
  });

  test('dispensa revogada nunca conta na recorrência (RF-02.25)', () {
    final assessment = recurrence.assess(
      Pillar.morning,
      wednesday,
      WaiverHistory(
        days: week(),
        waivers: [
          waiver(
            tuesday,
            Pillar.morning,
            revokedAt: tz.TZDateTime(tz.UTC, 2026, 3, 3, 20),
          ),
        ],
      ),
    );

    expect(assessment.verdict, RecurrenceVerdict.first);
    expect(assessment.previousChainLength, 0);
  });

  test('política exige o diálogo antes de persistir a segunda dispensa', () {
    final context = DayContext(
      days: week(),
      waivers: [waiver(tuesday, Pillar.morning)],
    );
    final command = CreateWaiver(
      id: 'waiver-nova',
      date: wednesday,
      pillar: Pillar.morning,
      reasonText: 'Compromisso familiar',
    );

    final rejected = policy.create(command, context);

    expect(
      (rejected as Failure<PillarWaiver, WaiverViolation>).failure.code,
      'waiver_return_rule_dialog_required',
    );
    expect(
      policy.recurrence(Pillar.morning, wednesday, context.history),
      RecurrenceVerdict.requiresReturnRuleDialog,
    );

    final confirmed = policy.create(
      CreateWaiver(
        id: command.id,
        date: command.date,
        pillar: command.pillar,
        reasonText: command.reasonText,
        recurrenceConfirmed: true,
      ),
      context,
    );

    expect(confirmed, isA<Success<PillarWaiver, WaiverViolation>>());
    final created = (confirmed as Success<PillarWaiver, WaiverViolation>).value;
    expect(created.recurrenceConfirmed, isTrue);
  });

  test('primeira dispensa da cadeia é criada sem marcar confirmação', () {
    final result = policy.create(
      CreateWaiver(
        id: 'waiver-primeira',
        date: wednesday,
        pillar: Pillar.morning,
        reasonText: 'Compromisso familiar',
        recurrenceConfirmed: true,
      ),
      DayContext(days: week()),
    );

    final created =
        (result as Success<PillarWaiver, WaiverViolation>).value;
    expect(created.recurrenceConfirmed, isFalse);
  });
}
