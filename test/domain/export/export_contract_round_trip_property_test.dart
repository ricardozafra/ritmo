// Feature: ritmo, Property 49: Round trip do contrato de exportação
//
// Para qualquer agregado válido na interseção entre os DTOs e o schema v1,
// serializar e desserializar preserva todos os campos, referências de áudio e
// a ordem das listas. Cada entrada exercita um envelope mínimo e um agregado
// rico com todos os 28 DTOs do contrato.
//
// **Validates: Requirements RA-01.9, RD-27, RD-37**

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:ritmo/domain/export/export_envelope.dart';

import '../../generators/shared.dart';

typedef _ExportInput = ({
  int token,
  int calendarIndex,
  int orderCode,
  int dayDurationMs,
  int reviewDurationMs,
  int reviewHour,
  int reviewMinute,
});

typedef _PrimitiveMap = Map<String, Object?>;

final Generator<_ExportInput> _anyExportInput = any.simple(
  generate: (Random random, int size) => (
    token: random.nextInt(1 << 30),
    calendarIndex: random.nextInt(3),
    orderCode: random.nextInt(1 << 20),
    dayDurationMs: 1 + random.nextInt(300000),
    reviewDurationMs: 1 + random.nextInt(1800000),
    reviewHour: random.nextInt(24),
    reviewMinute: random.nextInt(60),
  ),
  shrink: (_ExportInput input) sync* {
    const minimal = (
      token: 0,
      calendarIndex: 0,
      orderCode: 0,
      dayDurationMs: 1,
      reviewDurationMs: 1,
      reviewHour: 0,
      reviewMinute: 0,
    );
    if (input != minimal) yield minimal;
  },
);

final class _Schedule {
  _Schedule(this.anchor, this.offset);

  final DateTime anchor;
  final String offset;

  ExportOperationalDate date(int dayOffset) =>
      ExportOperationalDate(_dateText(anchor.add(Duration(days: dayOffset))));

  ExportOfficialInstant instant(
    int dayOffset,
    int hour,
    int minute, {
    int second = 0,
    String? fraction,
  }) {
    final date = _dateText(anchor.add(Duration(days: dayOffset)));
    final fractionalPart = fraction == null ? '' : '.$fraction';
    return ExportOfficialInstant(
      '$date'
      'T${_twoDigits(hour)}:${_twoDigits(minute)}:${_twoDigits(second)}'
      '$fractionalPart$offset',
    );
  }
}

_Schedule _scheduleFor(int index) => switch (index) {
  0 => _Schedule(DateTime.utc(2018, 1, 8), '-02:00'),
  1 => _Schedule(DateTime.utc(2024, 2, 26), '-03:00'),
  _ => _Schedule(DateTime.utc(2026, 3, 23), '-03:00'),
};

String _dateText(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${_twoDigits(value.month)}-${_twoDigits(value.day)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _unicodeText(_ExportInput input, String label) =>
    '$label-${input.token}: ação, café, bússola 🧭, e\u0301 combinado, '
    '"aspas", barra /, barra reversa \\ e nova linha\nlinha seguinte';

String _id(_ExportInput input, String suffix) => 't${input.token}-$suffix';

List<T> _ordered<T>(_ExportInput input, int salt, List<T> values) {
  if (values.length < 2) return List<T>.of(values, growable: false);
  final shift = (input.orderCode + salt) % values.length;
  var result = <T>[...values.skip(shift), ...values.take(shift)];
  if ((input.orderCode + salt).isOdd) {
    result = result.reversed.toList(growable: false);
  }
  return List<T>.unmodifiable(result);
}

RitmoExportEnvelope _minimumEnvelope(_ExportInput input) => RitmoExportEnvelope(
  generatedAt: ExportOfficialInstant('2018-01-08T00:00:00.1-02:00'),
  settings: ExportSettings(
    activationDate: null,
    dayCloseTime: ExportCivilTime('03:00'),
    nightEndTime: ExportCivilTime('01:30'),
    review: ExportReviewSettings(
      weekday: ExportReviewWeekday.monday,
      time: ExportCivilTime('00:00'),
      sundayNotificationEnabled: false,
    ),
    syncEnabled: false,
  ),
  days: const <ExportDay>[],
  holidays: const <ExportHoliday>[],
  protocolAlarms: const <ExportProtocolAlarm>[],
  cycles: const <ExportCycle>[],
  mentorships: const <ExportMentorship>[],
  contacts: const <ExportContact>[],
  weeklyReviews: const <ExportWeeklyReview>[],
  manifest: ExportManifest(
    id: _id(input, 'manifest-minimum'),
    assetVersion: '1.0.0-minimum',
    firstCopiedAt: ExportOfficialInstant('2017-07-03T08:00:00-03:00'),
    lastEditedAt: null,
    contentMarkdown: _unicodeText(input, 'manifesto mínimo'),
  ),
  changeInitiatives: const <ExportChangeInitiative>[],
  audioAssets: const <ExportAudioAsset>[],
  notificationPlans: const <ExportNotificationPlan>[],
  metricsSnapshot: ExportMetricsSnapshot(numerator: 0, denominator: 0),
);

RitmoExportEnvelope _richEnvelope(
  _ExportInput input, {
  required bool awaitingClosure,
}) {
  final schedule = _scheduleFor(input.calendarIndex);
  final prefix = 't${input.token}';
  final activeInitiativeId = '$prefix-initiative-active';
  final dayAudioId = '$prefix-audio-day';
  final dayAudioPath = 'audio/day-note-$prefix.m4a';
  final reviewAudioId = '$prefix-audio-review';
  final reviewAudioPath = 'audio/weekly-review-$prefix.m4a';
  final finalReviewId = '$prefix-review-finalized';

  final dayAudio = ExportAudioAsset(
    id: dayAudioId,
    relativePath: dayAudioPath,
    kind: ExportAudioKind.dayNote,
    durationMs: input.dayDurationMs,
    byteSize: input.dayDurationMs * 8,
    createdAt: schedule.instant(0, 15, 30, fraction: '125'),
  );
  final reviewAudio = ExportAudioAsset(
    id: reviewAudioId,
    relativePath: reviewAudioPath,
    kind: ExportAudioKind.weeklyReview,
    durationMs: input.reviewDurationMs,
    byteSize: input.reviewDurationMs * 8,
    createdAt: schedule.instant(6, 20, 45, fraction: '654321'),
  );

  final openBlockId = '$prefix-study-open';
  final closedBlockId = '$prefix-study-closed';
  final openBlock = ExportStudyBlock(
    id: openBlockId,
    operationalDate: schedule.date(0),
    startedAt: schedule.instant(0, 23, 10),
    blockDeadline: schedule.instant(1, 1, 30),
    endedAt: null,
  );
  final closedBlock = ExportStudyBlock(
    id: closedBlockId,
    operationalDate: schedule.date(0),
    startedAt: schedule.instant(0, 20, 0, fraction: '2'),
    blockDeadline: schedule.instant(0, 22, 30),
    endedAt: schedule.instant(0, 21, 15, fraction: '25'),
  );

  final firstDayEntries = <ExportPillarEntry>[
    ExportPillarEntry(
      operationalDate: schedule.date(0),
      pillar: ExportPillar.morning,
      workoutDone: true,
      briefingDone: true,
      briefingMode: ExportBriefingMode.automatic,
      workoutAt: schedule.instant(0, 6, 30, fraction: '1'),
      briefingAt: schedule.instant(0, 7, 10),
      toggleOn: false,
      changeInitiativeId: null,
      noteText: null,
      noteAudioRef: null,
      nightKind: null,
      recoveryNote: null,
      studyBlockId: null,
    ),
    ExportPillarEntry(
      operationalDate: schedule.date(0),
      pillar: ExportPillar.day,
      workoutDone: false,
      briefingDone: true,
      briefingMode: ExportBriefingMode.manual,
      workoutAt: null,
      briefingAt: schedule.instant(0, 12, 5, fraction: '123456'),
      toggleOn: true,
      changeInitiativeId: activeInitiativeId,
      noteText: _unicodeText(input, 'nota do dia'),
      noteAudioRef: ExportAudioReference(
        id: dayAudioId,
        relativePath: dayAudioPath,
      ),
      nightKind: null,
      recoveryNote: null,
      studyBlockId: null,
    ),
    ExportPillarEntry(
      operationalDate: schedule.date(0),
      pillar: ExportPillar.night,
      workoutDone: false,
      briefingDone: false,
      briefingMode: null,
      workoutAt: null,
      briefingAt: null,
      toggleOn: false,
      changeInitiativeId: null,
      noteText: null,
      noteAudioRef: null,
      nightKind: ExportNightKind.study,
      recoveryNote: null,
      studyBlockId: openBlockId,
    ),
  ];

  final secondDayEntries = <ExportPillarEntry>[
    ExportPillarEntry(
      operationalDate: schedule.date(4),
      pillar: ExportPillar.morning,
      workoutDone: false,
      briefingDone: false,
      briefingMode: null,
      workoutAt: null,
      briefingAt: null,
      toggleOn: false,
      changeInitiativeId: null,
      noteText: null,
      noteAudioRef: null,
      nightKind: null,
      recoveryNote: null,
      studyBlockId: null,
    ),
    ExportPillarEntry(
      operationalDate: schedule.date(4),
      pillar: ExportPillar.day,
      workoutDone: true,
      briefingDone: false,
      briefingMode: null,
      workoutAt: schedule.instant(4, 14, 0, fraction: '333'),
      briefingAt: null,
      toggleOn: false,
      changeInitiativeId: null,
      noteText: null,
      noteAudioRef: null,
      nightKind: null,
      recoveryNote: null,
      studyBlockId: null,
    ),
    ExportPillarEntry(
      operationalDate: schedule.date(4),
      pillar: ExportPillar.night,
      workoutDone: false,
      briefingDone: false,
      briefingMode: null,
      workoutAt: null,
      briefingAt: null,
      toggleOn: false,
      changeInitiativeId: null,
      noteText: _unicodeText(input, 'nota noturna'),
      noteAudioRef: null,
      nightKind: ExportNightKind.recovery,
      recoveryNote: _unicodeText(input, 'recuperação'),
      studyBlockId: null,
    ),
  ];

  final waivers = <ExportPillarWaiver>[
    ExportPillarWaiver(
      id: '$prefix-waiver-active',
      operationalDate: schedule.date(4),
      pillar: ExportPillar.morning,
      reasonText: _unicodeText(input, 'dispensa vigente'),
      recurrenceConfirmed: false,
      revokedAt: null,
    ),
    ExportPillarWaiver(
      id: '$prefix-waiver-revoked',
      operationalDate: schedule.date(4),
      pillar: ExportPillar.day,
      reasonText: _unicodeText(input, 'dispensa revogada'),
      recurrenceConfirmed: true,
      revokedAt: schedule.instant(4, 16, 0, fraction: '4'),
    ),
  ];

  final normalUnsealed = ExportDay(
    operationalDate: schedule.date(0),
    baseResult: ExportDayResult.unsealed,
    effectiveResult: ExportDayResult.unsealed,
    muteCause: null,
    previousResult: null,
    closedAt: null,
    sealTimestamp: null,
    derived: const ExportDayDerived(isWorkday: true, countsInMetrics: true),
    pillarEntries: _ordered(input, 1, firstDayEntries),
    studyBlocks: _ordered(input, 2, [openBlock, closedBlock]),
    pillarWaivers: const <ExportPillarWaiver>[],
  );
  final normalSealed = ExportDay(
    operationalDate: schedule.date(4),
    baseResult: ExportDayResult.sealed,
    effectiveResult: ExportDayResult.sealed,
    muteCause: null,
    previousResult: null,
    closedAt: schedule.instant(5, 3, 0),
    sealTimestamp: schedule.instant(4, 22, 41, fraction: '42'),
    derived: const ExportDayDerived(isWorkday: true, countsInMetrics: true),
    pillarEntries: _ordered(input, 3, secondDayEntries),
    studyBlocks: const <ExportStudyBlock>[],
    pillarWaivers: _ordered(input, 4, waivers),
  );
  final weekendSaturday = ExportDay(
    operationalDate: schedule.date(5),
    baseResult: ExportDayResult.unsealed,
    effectiveResult: ExportDayResult.mute,
    muteCause: ExportMuteCause.weekend,
    previousResult: null,
    closedAt: schedule.instant(6, 3, 0),
    sealTimestamp: null,
    derived: const ExportDayDerived(isWorkday: false, countsInMetrics: false),
    pillarEntries: const <ExportPillarEntry>[],
    studyBlocks: const <ExportStudyBlock>[],
    pillarWaivers: const <ExportPillarWaiver>[],
  );
  final weekendSunday = ExportDay(
    operationalDate: schedule.date(6),
    baseResult: ExportDayResult.unsealed,
    effectiveResult: ExportDayResult.mute,
    muteCause: ExportMuteCause.weekend,
    previousResult: null,
    closedAt: null,
    sealTimestamp: null,
    derived: const ExportDayDerived(isWorkday: false, countsInMetrics: false),
    pillarEntries: const <ExportPillarEntry>[],
    studyBlocks: const <ExportStudyBlock>[],
    pillarWaivers: const <ExportPillarWaiver>[],
  );
  final holidayUnsealed = ExportDay(
    operationalDate: schedule.date(7),
    baseResult: ExportDayResult.unsealed,
    effectiveResult: ExportDayResult.mute,
    muteCause: ExportMuteCause.holiday,
    previousResult: ExportDayResult.unsealed,
    closedAt: null,
    sealTimestamp: null,
    derived: const ExportDayDerived(isWorkday: false, countsInMetrics: false),
    pillarEntries: const <ExportPillarEntry>[],
    studyBlocks: const <ExportStudyBlock>[],
    pillarWaivers: const <ExportPillarWaiver>[],
  );
  final holidaySealed = ExportDay(
    operationalDate: schedule.date(8),
    baseResult: ExportDayResult.sealed,
    effectiveResult: ExportDayResult.mute,
    muteCause: ExportMuteCause.holiday,
    previousResult: ExportDayResult.sealed,
    closedAt: schedule.instant(9, 3, 0, fraction: '5'),
    sealTimestamp: schedule.instant(8, 21, 30),
    derived: const ExportDayDerived(isWorkday: false, countsInMetrics: false),
    pillarEntries: const <ExportPillarEntry>[],
    studyBlocks: const <ExportStudyBlock>[],
    pillarWaivers: const <ExportPillarWaiver>[],
  );

  final holidays = <ExportHoliday>[
    ExportHoliday(
      operationalDate: schedule.date(7),
      active: true,
      createdAt: schedule.instant(7, 8, 0),
      removedAt: null,
      applyReasonText: _unicodeText(input, 'feriado aplicado'),
      removeReasonText: null,
    ),
    ExportHoliday(
      operationalDate: schedule.date(8),
      active: true,
      createdAt: schedule.instant(8, 8, 0, fraction: '6'),
      removedAt: null,
      applyReasonText: null,
      removeReasonText: null,
    ),
    ExportHoliday(
      operationalDate: schedule.date(10),
      active: false,
      createdAt: schedule.instant(10, 8, 0),
      removedAt: schedule.instant(10, 9, 0, fraction: '75'),
      applyReasonText: null,
      removeReasonText: _unicodeText(input, 'feriado removido'),
    ),
  ];

  final protocols = <ExportProtocolAlarm>[
    ExportProtocolAlarm(
      id: '$prefix-protocol-pending',
      generationId: '$prefix-generation-pending',
      startDate: schedule.date(-3),
      endDate: schedule.date(-2),
      sequenceLength: 2,
      state: ExportProtocolState.pending,
      previousState: null,
      triggeredAt: null,
      cause: null,
      planOrExecution: null,
      adjustment: null,
    ),
    ExportProtocolAlarm(
      id: '$prefix-protocol-answered',
      generationId: '$prefix-generation-answered',
      startDate: schedule.date(-2),
      endDate: schedule.date(0),
      sequenceLength: 3,
      state: ExportProtocolState.answered,
      previousState: null,
      triggeredAt: schedule.instant(0, 3, 0, fraction: '8'),
      cause: _unicodeText(input, 'causa respondida'),
      planOrExecution: ExportPlanOrExecution.execution,
      adjustment: _unicodeText(input, 'ajuste executado'),
    ),
    ExportProtocolAlarm(
      id: '$prefix-protocol-invalidated-pending',
      generationId: '$prefix-generation-invalidated-pending',
      startDate: schedule.date(1),
      endDate: schedule.date(3),
      sequenceLength: 3,
      state: ExportProtocolState.invalidated,
      previousState: ExportProtocolState.pending,
      triggeredAt: schedule.instant(3, 3, 0),
      cause: _unicodeText(input, 'reclassificação pendente'),
      planOrExecution: ExportPlanOrExecution.plan,
      adjustment: null,
    ),
    ExportProtocolAlarm(
      id: '$prefix-protocol-invalidated-answered',
      generationId: '$prefix-generation-invalidated-answered',
      startDate: schedule.date(2),
      endDate: schedule.date(5),
      sequenceLength: 4,
      state: ExportProtocolState.invalidated,
      previousState: ExportProtocolState.answered,
      triggeredAt: schedule.instant(5, 3, 0, fraction: '9'),
      cause: null,
      planOrExecution: null,
      adjustment: _unicodeText(input, 'ajuste após resposta'),
    ),
  ];

  final currentCycleId = '$prefix-cycle-current';
  final awaitingCycleId = '$prefix-cycle-awaiting';
  final archivedCycleId = '$prefix-cycle-archived';
  final checkpointStId = '$prefix-checkpoint-st';
  final checkpointInId = '$prefix-checkpoint-in';
  final checkpointCaId = '$prefix-checkpoint-ca';

  ExportCheckpointEvaluation evaluation(
    String suffix,
    String checkpointId,
    ExportGartnerLevel level, {
    required bool linkedReview,
    required bool withNotes,
  }) => ExportCheckpointEvaluation(
    id: '$prefix-evaluation-$suffix',
    checkpointId: checkpointId,
    weeklyReviewId: linkedReview ? finalReviewId : null,
    gartnerLevel: level,
    notes: withNotes ? _unicodeText(input, 'avaliação $suffix') : null,
  );

  final checkpoints = <ExportCheckpoint>[
    ExportCheckpoint(
      id: checkpointStId,
      cycleId: currentCycleId,
      competency: ExportCompetency.ST,
      date: schedule.date(0),
      status: 'evaluated',
      evaluations: _ordered(input, 5, [
        evaluation(
          'bd',
          checkpointStId,
          ExportGartnerLevel.BD,
          linkedReview: false,
          withNotes: false,
        ),
        evaluation(
          'b',
          checkpointStId,
          ExportGartnerLevel.B,
          linkedReview: true,
          withNotes: true,
        ),
      ]),
    ),
    ExportCheckpoint(
      id: checkpointInId,
      cycleId: currentCycleId,
      competency: ExportCompetency.IN,
      date: schedule.date(3),
      status: 'evaluated',
      evaluations: _ordered(input, 6, [
        evaluation(
          'i',
          checkpointInId,
          ExportGartnerLevel.I,
          linkedReview: false,
          withNotes: true,
        ),
        evaluation(
          'a',
          checkpointInId,
          ExportGartnerLevel.A,
          linkedReview: true,
          withNotes: false,
        ),
      ]),
    ),
    ExportCheckpoint(
      id: checkpointCaId,
      cycleId: currentCycleId,
      competency: ExportCompetency.CA,
      date: schedule.date(6),
      status: 'evaluated',
      evaluations: [
        evaluation(
          'e',
          checkpointCaId,
          ExportGartnerLevel.E,
          linkedReview: true,
          withNotes: true,
        ),
      ],
    ),
  ];

  final cycles = <ExportCycle>[
    if (awaitingClosure)
      ExportCycle(
        id: awaitingCycleId,
        name: _unicodeText(input, 'ciclo aguardando'),
        purposeText: _unicodeText(input, 'propósito aguardando fechamento'),
        startDate: schedule.date(-80),
        endDate: schedule.date(5),
        state: ExportCycleState.active,
        derived: const ExportCycleDerived(awaitingClosure: true),
        checkpoints: const <ExportCheckpoint>[],
        closureInvites: _ordered(input, 8, [
          ExportCycleClosureInvite(
            cycleId: awaitingCycleId,
            weekStart: schedule.date(6),
          ),
          ExportCycleClosureInvite(
            cycleId: awaitingCycleId,
            weekStart: schedule.date(13),
          ),
        ]),
      )
    else
      ExportCycle(
        id: currentCycleId,
        name: _unicodeText(input, 'ciclo vigente'),
        purposeText: _unicodeText(input, 'propósito vigente'),
        startDate: schedule.date(-10),
        endDate: schedule.date(40),
        state: ExportCycleState.active,
        derived: const ExportCycleDerived(awaitingClosure: false),
        checkpoints: _ordered(input, 7, checkpoints),
        closureInvites: const <ExportCycleClosureInvite>[],
      ),
    ExportCycle(
      id: archivedCycleId,
      name: _unicodeText(input, 'ciclo arquivado'),
      purposeText: _unicodeText(input, 'propósito arquivado'),
      startDate: schedule.date(-150),
      endDate: schedule.date(-90),
      state: ExportCycleState.archived,
      derived: const ExportCycleDerived(awaitingClosure: false),
      checkpoints: const <ExportCheckpoint>[],
      closureInvites: const <ExportCycleClosureInvite>[],
    ),
  ];

  final mentorships = <ExportMentorship>[
    ExportMentorship(
      id: '$prefix-mentorship-st',
      competency: ExportCompetency.ST,
      mentorName: null,
      lastMeetingDate: null,
    ),
    ExportMentorship(
      id: '$prefix-mentorship-in',
      competency: ExportCompetency.IN,
      mentorName: _unicodeText(input, 'mentora IN'),
      lastMeetingDate: schedule.date(-1),
    ),
    ExportMentorship(
      id: '$prefix-mentorship-ca',
      competency: ExportCompetency.CA,
      mentorName: _unicodeText(input, 'mentor CA'),
      lastMeetingDate: schedule.date(2),
    ),
  ];

  final firstContactId = '$prefix-contact-first';
  final secondContactId = '$prefix-contact-second';
  final thirdContactId = '$prefix-contact-third';
  ExportWeeklyContactSuggestion suggestion(
    String contactId,
    int weekOffset,
    ExportSuggestionStatus status,
  ) => ExportWeeklyContactSuggestion(
    weekStart: schedule.date(weekOffset),
    contactId: contactId,
    status: status,
    createdAt: schedule.instant(weekOffset, 3, 0, fraction: '12'),
  );

  final contacts = <ExportContact>[
    ExportContact(
      id: firstContactId,
      name: _unicodeText(input, 'contato um'),
      contextNote: null,
      lastTouchDate: null,
      createdAt: schedule.instant(-20, 9, 0),
      weeklySuggestions: _ordered(input, 9, [
        suggestion(firstContactId, 0, ExportSuggestionStatus.pending),
        suggestion(firstContactId, 7, ExportSuggestionStatus.done),
        suggestion(firstContactId, 14, ExportSuggestionStatus.skipped),
      ]),
    ),
    ExportContact(
      id: secondContactId,
      name: _unicodeText(input, 'contato dois'),
      contextNote: _unicodeText(input, 'contexto do contato'),
      lastTouchDate: schedule.date(1),
      createdAt: schedule.instant(-10, 10, 0, fraction: '345'),
      weeklySuggestions: _ordered(input, 10, [
        suggestion(secondContactId, 0, ExportSuggestionStatus.done),
        suggestion(secondContactId, 7, ExportSuggestionStatus.pending),
      ]),
    ),
    ExportContact(
      id: thirdContactId,
      name: _unicodeText(input, 'contato três'),
      contextNote: null,
      lastTouchDate: schedule.date(2),
      createdAt: schedule.instant(-5, 11, 0),
      weeklySuggestions: const <ExportWeeklyContactSuggestion>[],
    ),
  ];

  final reviews = <ExportWeeklyReview>[
    ExportWeeklyReview(
      id: '$prefix-review-draft',
      weekStart: schedule.date(0),
      answerFulfilled: null,
      answerFailed: null,
      answerLesson: null,
      audioRef: null,
      state: ExportWeeklyReviewState.draft,
      createdAt: schedule.instant(6, 19, 0),
      autosavedAt: null,
      finalizedAt: null,
    ),
    ExportWeeklyReview(
      id: finalReviewId,
      weekStart: schedule.date(0),
      answerFulfilled: _unicodeText(input, 'realizado'),
      answerFailed: _unicodeText(input, 'não realizado'),
      answerLesson: _unicodeText(input, 'aprendizado'),
      audioRef: ExportAudioReference(
        id: reviewAudioId,
        relativePath: reviewAudioPath,
      ),
      state: ExportWeeklyReviewState.finalized,
      createdAt: schedule.instant(6, 20, 0, fraction: '1'),
      autosavedAt: schedule.instant(6, 20, 30, fraction: '22'),
      finalizedAt: schedule.instant(6, 21, 0, fraction: '333'),
    ),
  ];

  final initiatives = <ExportChangeInitiative>[
    ExportChangeInitiative(
      id: activeInitiativeId,
      name: _unicodeText(input, 'iniciativa ativa'),
      active: true,
    ),
    ExportChangeInitiative(
      id: '$prefix-initiative-inactive',
      name: _unicodeText(input, 'iniciativa inativa'),
      active: false,
    ),
  ];

  final notifications = <ExportNotificationPlan>[];
  var notificationIndex = 0;
  for (final kind in ExportNotificationKind.values) {
    for (final state in ExportNotificationState.values) {
      notifications.add(
        ExportNotificationPlan(
          idempotencyKey:
              '$prefix-${kind.wireName}-${state.name}-$notificationIndex',
          kind: kind,
          plannedAt: schedule.instant(
            6 + notificationIndex,
            21,
            notificationIndex,
            fraction: notificationIndex.isEven ? null : '4444',
          ),
          state: state,
        ),
      );
      notificationIndex++;
    }
  }

  final denominator = 1 + input.token % 100;
  final historicFirstCopy = schedule.offset == '-02:00'
      ? ExportOfficialInstant('2017-07-03T08:00:00.5-03:00')
      : ExportOfficialInstant('2018-01-08T08:00:00.5-02:00');

  return RitmoExportEnvelope(
    generatedAt: schedule.instant(10, 12, 0, fraction: '123456'),
    settings: ExportSettings(
      activationDate: schedule.date(-200),
      dayCloseTime: ExportCivilTime('03:00'),
      nightEndTime: ExportCivilTime('01:30'),
      review: ExportReviewSettings(
        weekday: input.token.isEven
            ? ExportReviewWeekday.sunday
            : ExportReviewWeekday.monday,
        time: ExportCivilTime(
          '${_twoDigits(input.reviewHour)}:${_twoDigits(input.reviewMinute)}',
        ),
        sundayNotificationEnabled: input.token.isEven,
      ),
      syncEnabled: false,
    ),
    days: _ordered(input, 11, [
      normalUnsealed,
      normalSealed,
      weekendSaturday,
      weekendSunday,
      holidayUnsealed,
      holidaySealed,
    ]),
    holidays: _ordered(input, 12, holidays),
    protocolAlarms: _ordered(input, 13, protocols),
    cycles: _ordered(input, 14, cycles),
    mentorships: _ordered(input, 15, mentorships),
    contacts: _ordered(input, 16, contacts),
    weeklyReviews: _ordered(input, 17, reviews),
    manifest: ExportManifest(
      id: '$prefix-manifest',
      assetVersion: '1.0.${input.token % 1000}',
      firstCopiedAt: historicFirstCopy,
      lastEditedAt: schedule.instant(9, 18, 0, fraction: '654321'),
      contentMarkdown: '# Manifesto\n\n${_unicodeText(input, 'conteúdo')}',
    ),
    changeInitiatives: _ordered(input, 18, initiatives),
    audioAssets: _ordered(input, 19, [dayAudio, reviewAudio]),
    notificationPlans: _ordered(input, 20, notifications),
    metricsSnapshot: ExportMetricsSnapshot(
      numerator: input.token % denominator,
      denominator: denominator,
    ),
  );
}

_PrimitiveMap _projectEnvelope(RitmoExportEnvelope value) => {
  'schema': RitmoExportEnvelope.schemaName,
  'schema_version': RitmoExportEnvelope.schemaVersion,
  'generated_at': value.generatedAt.value,
  'business_timezone': RitmoExportEnvelope.businessTimezone,
  'settings': _projectSettings(value.settings),
  'days': value.days.map(_projectDay).toList(growable: false),
  'holidays': value.holidays.map(_projectHoliday).toList(growable: false),
  'protocol_alarms': value.protocolAlarms
      .map(_projectProtocolAlarm)
      .toList(growable: false),
  'cycles': value.cycles.map(_projectCycle).toList(growable: false),
  'mentorships': value.mentorships
      .map(_projectMentorship)
      .toList(growable: false),
  'contacts': value.contacts.map(_projectContact).toList(growable: false),
  'weekly_reviews': value.weeklyReviews
      .map(_projectWeeklyReview)
      .toList(growable: false),
  'manifest': _projectManifest(value.manifest),
  'change_initiatives': value.changeInitiatives
      .map(_projectChangeInitiative)
      .toList(growable: false),
  'audio_assets': value.audioAssets
      .map(_projectAudioAsset)
      .toList(growable: false),
  'notification_plans': value.notificationPlans
      .map(_projectNotificationPlan)
      .toList(growable: false),
  'metrics_snapshot': _projectMetricsSnapshot(value.metricsSnapshot),
};

_PrimitiveMap _projectReviewSettings(ExportReviewSettings value) => {
  'weekday': value.weekday.name,
  'time': value.time.value,
  'sunday_notification_enabled': value.sundayNotificationEnabled,
};

_PrimitiveMap _projectSettings(ExportSettings value) => {
  'activation_date': value.activationDate?.value,
  'day_close_time': value.dayCloseTime.value,
  'night_end_time': value.nightEndTime.value,
  'review': _projectReviewSettings(value.review),
  'sync_enabled': value.syncEnabled,
};

_PrimitiveMap _projectDayDerived(ExportDayDerived value) => {
  'is_workday': value.isWorkday,
  'counts_in_metrics': value.countsInMetrics,
};

_PrimitiveMap _projectAudioReference(ExportAudioReference value) => {
  'id': value.id,
  'relative_path': value.relativePath,
};

_PrimitiveMap _projectPillarEntry(ExportPillarEntry value) => {
  'operational_date': value.operationalDate.value,
  'pillar': value.pillar.name,
  'workout_done': value.workoutDone,
  'briefing_done': value.briefingDone,
  'briefing_mode': value.briefingMode?.name,
  'workout_at': value.workoutAt?.value,
  'briefing_at': value.briefingAt?.value,
  'toggle_on': value.toggleOn,
  'change_initiative_id': value.changeInitiativeId,
  'note_text': value.noteText,
  'note_audio_ref': value.noteAudioRef == null
      ? null
      : _projectAudioReference(value.noteAudioRef!),
  'night_kind': value.nightKind?.name,
  'recovery_note': value.recoveryNote,
  'study_block_id': value.studyBlockId,
};

_PrimitiveMap _projectStudyBlock(ExportStudyBlock value) => {
  'id': value.id,
  'operational_date': value.operationalDate.value,
  'started_at': value.startedAt.value,
  'block_deadline': value.blockDeadline.value,
  'ended_at': value.endedAt?.value,
};

_PrimitiveMap _projectPillarWaiver(ExportPillarWaiver value) => {
  'id': value.id,
  'operational_date': value.operationalDate.value,
  'pillar': value.pillar.name,
  'reason_text': value.reasonText,
  'recurrence_confirmed': value.recurrenceConfirmed,
  'revoked_at': value.revokedAt?.value,
};

_PrimitiveMap _projectDay(ExportDay value) => {
  'operational_date': value.operationalDate.value,
  'base_result': value.baseResult.name,
  'effective_result': value.effectiveResult.name,
  'mute_cause': value.muteCause?.name,
  'previous_result': value.previousResult?.name,
  'closed_at': value.closedAt?.value,
  'seal_timestamp': value.sealTimestamp?.value,
  'derived': _projectDayDerived(value.derived),
  'pillar_entries': value.pillarEntries
      .map(_projectPillarEntry)
      .toList(growable: false),
  'study_blocks': value.studyBlocks
      .map(_projectStudyBlock)
      .toList(growable: false),
  'pillar_waivers': value.pillarWaivers
      .map(_projectPillarWaiver)
      .toList(growable: false),
};

_PrimitiveMap _projectHoliday(ExportHoliday value) => {
  'operational_date': value.operationalDate.value,
  'active': value.active,
  'created_at': value.createdAt.value,
  'removed_at': value.removedAt?.value,
  'apply_reason_text': value.applyReasonText,
  'remove_reason_text': value.removeReasonText,
};

_PrimitiveMap _projectProtocolAlarm(ExportProtocolAlarm value) => {
  'id': value.id,
  'generation_id': value.generationId,
  'start_date': value.startDate.value,
  'end_date': value.endDate.value,
  'sequence_length': value.sequenceLength,
  'state': value.state.name,
  'previous_state': value.previousState?.name,
  'triggered_at': value.triggeredAt?.value,
  'cause': value.cause,
  'plan_or_execution': value.planOrExecution?.name,
  'adjustment': value.adjustment,
};

_PrimitiveMap _projectCheckpointEvaluation(ExportCheckpointEvaluation value) =>
    {
      'id': value.id,
      'checkpoint_id': value.checkpointId,
      'weekly_review_id': value.weeklyReviewId,
      'gartner_level': value.gartnerLevel.name,
      'notes': value.notes,
    };

_PrimitiveMap _projectCheckpoint(ExportCheckpoint value) => {
  'id': value.id,
  'cycle_id': value.cycleId,
  'competency': value.competency.name,
  'date': value.date.value,
  'status': value.status,
  'checkpoint_evals': value.evaluations
      .map(_projectCheckpointEvaluation)
      .toList(growable: false),
};

_PrimitiveMap _projectCycleClosureInvite(ExportCycleClosureInvite value) => {
  'cycle_id': value.cycleId,
  'week_start': value.weekStart.value,
};

_PrimitiveMap _projectCycleDerived(ExportCycleDerived value) => {
  'awaiting_closure': value.awaitingClosure,
};

_PrimitiveMap _projectCycle(ExportCycle value) => {
  'id': value.id,
  'name': value.name,
  'purpose_text': value.purposeText,
  'start_date': value.startDate.value,
  'end_date': value.endDate.value,
  'state': value.state.name,
  'derived': _projectCycleDerived(value.derived),
  'checkpoints': value.checkpoints
      .map(_projectCheckpoint)
      .toList(growable: false),
  'cycle_closure_invites': value.closureInvites
      .map(_projectCycleClosureInvite)
      .toList(growable: false),
};

_PrimitiveMap _projectMentorship(ExportMentorship value) => {
  'id': value.id,
  'competency': value.competency.name,
  'mentor_name': value.mentorName,
  'last_meeting_date': value.lastMeetingDate?.value,
};

_PrimitiveMap _projectWeeklyContactSuggestion(
  ExportWeeklyContactSuggestion value,
) => {
  'week_start': value.weekStart.value,
  'contact_id': value.contactId,
  'status': value.status.name,
  'created_at': value.createdAt.value,
};

_PrimitiveMap _projectContact(ExportContact value) => {
  'id': value.id,
  'name': value.name,
  'context_note': value.contextNote,
  'last_touch_date': value.lastTouchDate?.value,
  'created_at': value.createdAt.value,
  'weekly_contact_suggestions': value.weeklySuggestions
      .map(_projectWeeklyContactSuggestion)
      .toList(growable: false),
};

_PrimitiveMap _projectWeeklyReview(ExportWeeklyReview value) => {
  'id': value.id,
  'week_start': value.weekStart.value,
  'answer_fulfilled': value.answerFulfilled,
  'answer_failed': value.answerFailed,
  'answer_lesson': value.answerLesson,
  'audio_ref': value.audioRef == null
      ? null
      : _projectAudioReference(value.audioRef!),
  'state': value.state.name,
  'created_at': value.createdAt.value,
  'autosaved_at': value.autosavedAt?.value,
  'finalized_at': value.finalizedAt?.value,
};

_PrimitiveMap _projectManifest(ExportManifest value) => {
  'id': value.id,
  'asset_version': value.assetVersion,
  'first_copied_at': value.firstCopiedAt.value,
  'last_edited_at': value.lastEditedAt?.value,
  'content_markdown': value.contentMarkdown,
};

_PrimitiveMap _projectChangeInitiative(ExportChangeInitiative value) => {
  'id': value.id,
  'name': value.name,
  'active': value.active,
};

_PrimitiveMap _projectAudioAsset(ExportAudioAsset value) => {
  'id': value.id,
  'relative_path': value.relativePath,
  'kind': value.kind.wireName,
  'duration_ms': value.durationMs,
  'byte_size': value.byteSize,
  'created_at': value.createdAt.value,
};

_PrimitiveMap _projectNotificationPlan(ExportNotificationPlan value) => {
  'idempotency_key': value.idempotencyKey,
  'kind': value.kind.wireName,
  'planned_at': value.plannedAt.value,
  'state': value.state.name,
};

_PrimitiveMap _projectMetricsSnapshot(ExportMetricsSnapshot value) => {
  'numerator': value.numerator,
  'denominator': value.denominator,
};

List<String> _listOrderSignature(RitmoExportEnvelope value) => <String>[
  'days:${value.days.map((item) => item.operationalDate.value).join('|')}',
  'holidays:${value.holidays.map((item) => '${item.operationalDate.value}:${item.active}').join('|')}',
  'protocols:${value.protocolAlarms.map((item) => item.id).join('|')}',
  'cycles:${value.cycles.map((item) => item.id).join('|')}',
  'mentorships:${value.mentorships.map((item) => item.id).join('|')}',
  'contacts:${value.contacts.map((item) => item.id).join('|')}',
  'reviews:${value.weeklyReviews.map((item) => item.id).join('|')}',
  'initiatives:${value.changeInitiatives.map((item) => item.id).join('|')}',
  'audio:${value.audioAssets.map((item) => item.id).join('|')}',
  'notifications:${value.notificationPlans.map((item) => item.idempotencyKey).join('|')}',
  for (final day in value.days)
    'day:${day.operationalDate.value}:pillars:'
        '${day.pillarEntries.map((item) => item.pillar.name).join('|')}',
  for (final day in value.days)
    'day:${day.operationalDate.value}:blocks:'
        '${day.studyBlocks.map((item) => item.id).join('|')}',
  for (final day in value.days)
    'day:${day.operationalDate.value}:waivers:'
        '${day.pillarWaivers.map((item) => item.id).join('|')}',
  for (final cycle in value.cycles)
    'cycle:${cycle.id}:checkpoints:'
        '${cycle.checkpoints.map((item) => item.id).join('|')}',
  for (final cycle in value.cycles)
    'cycle:${cycle.id}:invites:'
        '${cycle.closureInvites.map((item) => item.weekStart.value).join('|')}',
  for (final checkpoint in value.cycles.expand((cycle) => cycle.checkpoints))
    'checkpoint:${checkpoint.id}:evaluations:'
        '${checkpoint.evaluations.map((item) => item.id).join('|')}',
  for (final contact in value.contacts)
    'contact:${contact.id}:suggestions:'
        '${contact.weeklySuggestions.map((item) => '${item.weekStart.value}:${item.status.name}').join('|')}',
];

Iterable<String> _primitiveStrings(Object? value) sync* {
  if (value is String) {
    yield value;
  } else if (value is Map) {
    for (final child in value.values) {
      yield* _primitiveStrings(child);
    }
  } else if (value is Iterable<Object?>) {
    for (final child in value) {
      yield* _primitiveStrings(child);
    }
  }
}

void _expectAudioIntegrity(RitmoExportEnvelope envelope, String context) {
  final assets = <String, ExportAudioAsset>{
    for (final asset in envelope.audioAssets) asset.id: asset,
  };
  expect(assets.length, envelope.audioAssets.length, reason: context);

  void expectReference(
    ExportAudioReference reference,
    ExportAudioKind expectedKind,
  ) {
    final asset = assets[reference.id];
    if (asset == null) {
      fail('$context: referência sem asset: ${reference.id}');
    }
    expect(asset.relativePath, reference.relativePath, reason: context);
    expect(asset.kind, expectedKind, reason: context);
  }

  for (final day in envelope.days) {
    for (final entry in day.pillarEntries) {
      final reference = entry.noteAudioRef;
      if (reference != null) {
        expectReference(reference, ExportAudioKind.dayNote);
      }
    }
  }
  for (final review in envelope.weeklyReviews) {
    final reference = review.audioRef;
    if (reference != null) {
      expectReference(reference, ExportAudioKind.weeklyReview);
    }
  }
  for (final asset in envelope.audioAssets) {
    final maximum = switch (asset.kind) {
      ExportAudioKind.dayNote => 300000,
      ExportAudioKind.weeklyReview => 1800000,
    };
    expect(asset.durationMs, inInclusiveRange(1, maximum), reason: context);
    expect(asset.relativePath, startsWith('audio/'), reason: context);
  }
}

void _expectDayCoherence(RitmoExportEnvelope envelope, String context) {
  final activeHolidayDates = envelope.holidays
      .where((holiday) => holiday.active)
      .map((holiday) => holiday.operationalDate.value)
      .toSet();
  for (final day in envelope.days) {
    final weekday = DateTime.parse(day.operationalDate.value).weekday;
    switch (day.muteCause) {
      case null:
        expect(weekday <= DateTime.friday, isTrue, reason: context);
        expect(day.effectiveResult, day.baseResult, reason: context);
        expect(day.previousResult, isNull, reason: context);
        expect(day.derived.isWorkday, isTrue, reason: context);
        expect(day.derived.countsInMetrics, isTrue, reason: context);
      case ExportMuteCause.weekend:
        expect(weekday >= DateTime.saturday, isTrue, reason: context);
        expect(day.effectiveResult, ExportDayResult.mute, reason: context);
        expect(day.previousResult, isNull, reason: context);
        expect(day.derived.isWorkday, isFalse, reason: context);
        expect(day.derived.countsInMetrics, isFalse, reason: context);
      case ExportMuteCause.holiday:
        expect(weekday <= DateTime.friday, isTrue, reason: context);
        expect(
          activeHolidayDates,
          contains(day.operationalDate.value),
          reason: context,
        );
        expect(day.effectiveResult, ExportDayResult.mute, reason: context);
        expect(day.previousResult, day.baseResult, reason: context);
        expect(day.derived.isWorkday, isFalse, reason: context);
        expect(day.derived.countsInMetrics, isFalse, reason: context);
    }
    if (day.baseResult == ExportDayResult.sealed) {
      expect(day.sealTimestamp, isNotNull, reason: context);
    } else {
      expect(day.baseResult, ExportDayResult.unsealed, reason: context);
      expect(day.sealTimestamp, isNull, reason: context);
    }
  }
}

void _expectReferenceCoherence(RitmoExportEnvelope envelope, String context) {
  expect(
    envelope.cycles.where((cycle) => cycle.state == ExportCycleState.active),
    hasLength(1),
    reason: '$context: deve haver exatamente um ciclo ativo',
  );

  final reviewIds = envelope.weeklyReviews.map((review) => review.id).toSet();
  for (final cycle in envelope.cycles) {
    expect(
      cycle.startDate.value.compareTo(cycle.endDate.value) <= 0,
      isTrue,
      reason: context,
    );
    final generatedDate = envelope.generatedAt.value.substring(0, 10);
    final expectedAwaiting =
        cycle.state == ExportCycleState.active &&
        cycle.endDate.value.compareTo(generatedDate) < 0;
    expect(cycle.derived.awaitingClosure, expectedAwaiting, reason: context);
    for (final checkpoint in cycle.checkpoints) {
      expect(checkpoint.cycleId, cycle.id, reason: context);
      for (final evaluation in checkpoint.evaluations) {
        expect(evaluation.checkpointId, checkpoint.id, reason: context);
        final weeklyReviewId = evaluation.weeklyReviewId;
        if (weeklyReviewId != null) {
          expect(reviewIds, contains(weeklyReviewId), reason: context);
        }
      }
    }
    for (final invite in cycle.closureInvites) {
      expect(invite.cycleId, cycle.id, reason: context);
    }
  }

  for (final contact in envelope.contacts) {
    for (final suggestion in contact.weeklySuggestions) {
      expect(suggestion.contactId, contact.id, reason: context);
    }
  }

  for (final day in envelope.days) {
    for (final block in day.studyBlocks) {
      expect(block.operationalDate.value, day.operationalDate.value);
      expect(
        DateTime.parse(
              block.startedAt.value,
            ).compareTo(DateTime.parse(block.blockDeadline.value)) <=
            0,
        isTrue,
        reason: context,
      );
      final endedAt = block.endedAt;
      if (endedAt != null) {
        final ended = DateTime.parse(endedAt.value);
        expect(
          ended.compareTo(DateTime.parse(block.startedAt.value)) >= 0,
          isTrue,
          reason: context,
        );
        expect(
          ended.compareTo(DateTime.parse(block.blockDeadline.value)) <= 0,
          isTrue,
          reason: context,
        );
      }
    }
    for (final waiver in day.pillarWaivers) {
      expect(waiver.operationalDate.value, day.operationalDate.value);
    }
    for (final entry in day.pillarEntries) {
      expect(entry.operationalDate.value, day.operationalDate.value);
    }
  }
}

void _expectGeneratedCoverage(
  _ExportInput input,
  RitmoExportEnvelope minimum,
  List<RitmoExportEnvelope> richEnvelopes,
) {
  final context =
      'token=${input.token}, calendar=${input.calendarIndex}, '
      'order=${input.orderCode}';
  expect(richEnvelopes, hasLength(2), reason: context);
  final minimumListLengths = <String, int>{
    'days': minimum.days.length,
    'holidays': minimum.holidays.length,
    'protocol_alarms': minimum.protocolAlarms.length,
    'cycles': minimum.cycles.length,
    'mentorships': minimum.mentorships.length,
    'contacts': minimum.contacts.length,
    'weekly_reviews': minimum.weeklyReviews.length,
    'change_initiatives': minimum.changeInitiatives.length,
    'audio_assets': minimum.audioAssets.length,
    'notification_plans': minimum.notificationPlans.length,
  };
  for (final entry in minimumListLengths.entries) {
    expect(entry.value, 0, reason: '$context: mínimo/${entry.key}');
  }

  for (var index = 0; index < richEnvelopes.length; index++) {
    final rich = richEnvelopes[index];
    final richListLengths = <String, int>{
      'days': rich.days.length,
      'holidays': rich.holidays.length,
      'protocol_alarms': rich.protocolAlarms.length,
      'cycles': rich.cycles.length,
      'mentorships': rich.mentorships.length,
      'contacts': rich.contacts.length,
      'weekly_reviews': rich.weeklyReviews.length,
      'change_initiatives': rich.changeInitiatives.length,
      'audio_assets': rich.audioAssets.length,
      'notification_plans': rich.notificationPlans.length,
    };
    for (final entry in richListLengths.entries) {
      expect(
        entry.value,
        greaterThan(1),
        reason: '$context: rico[$index]/${entry.key}',
      );
    }
  }

  final rich = richEnvelopes.first;
  final cycles = richEnvelopes
      .expand((envelope) => envelope.cycles)
      .toList(growable: false);

  final pillarEntries = rich.days
      .expand((day) => day.pillarEntries)
      .toList(growable: false);
  final studyBlocks = rich.days
      .expand((day) => day.studyBlocks)
      .toList(growable: false);
  final waivers = rich.days
      .expand((day) => day.pillarWaivers)
      .toList(growable: false);
  final checkpoints = cycles
      .expand((cycle) => cycle.checkpoints)
      .toList(growable: false);
  final evaluations = checkpoints
      .expand((checkpoint) => checkpoint.evaluations)
      .toList(growable: false);
  final invites = cycles
      .expand((cycle) => cycle.closureInvites)
      .toList(growable: false);
  final suggestions = rich.contacts
      .expand((contact) => contact.weeklySuggestions)
      .toList(growable: false);

  expect(pillarEntries.length, greaterThan(1), reason: context);
  expect(studyBlocks.length, greaterThan(1), reason: context);
  expect(waivers.length, greaterThan(1), reason: context);
  expect(checkpoints.length, greaterThan(1), reason: context);
  expect(evaluations.length, greaterThan(1), reason: context);
  expect(invites.length, greaterThan(1), reason: context);
  expect(suggestions.length, greaterThan(1), reason: context);

  expect(
    rich.days.map((day) => day.muteCause).toSet(),
    containsAll(<ExportMuteCause?>[
      null,
      ExportMuteCause.weekend,
      ExportMuteCause.holiday,
    ]),
    reason: context,
  );
  final previousResults = rich.days
      .map((day) => day.previousResult)
      .whereType<ExportDayResult>()
      .toSet();
  expect(
    previousResults,
    equals(<ExportDayResult>{ExportDayResult.sealed, ExportDayResult.unsealed}),
    reason: context,
  );
  expect(
    previousResults,
    isNot(contains(ExportDayResult.mute)),
    reason: context,
  );
  expect(
    rich.protocolAlarms.map((alarm) => alarm.state).toSet(),
    equals(ExportProtocolState.values.toSet()),
    reason: context,
  );
  final previousStates = rich.protocolAlarms
      .map((alarm) => alarm.previousState)
      .whereType<ExportProtocolState>()
      .toSet();
  expect(
    previousStates,
    equals(<ExportProtocolState>{
      ExportProtocolState.pending,
      ExportProtocolState.answered,
    }),
    reason: context,
  );
  expect(
    previousStates,
    isNot(contains(ExportProtocolState.invalidated)),
    reason: context,
  );

  expect(
    rich.days
        .map((day) => (day.derived.isWorkday, day.derived.countsInMetrics))
        .toSet(),
    containsAll(<(bool, bool)>{(true, true), (false, false)}),
    reason: context,
  );
  expect(
    cycles.map((cycle) => cycle.derived.awaitingClosure).toSet(),
    equals(<bool>{false, true}),
    reason: context,
  );
  expect(
    cycles.map((cycle) => cycle.state).toSet(),
    equals(ExportCycleState.values.toSet()),
    reason: context,
  );
  expect(
    rich.weeklyReviews.map((review) => review.state).toSet(),
    equals(ExportWeeklyReviewState.values.toSet()),
    reason: context,
  );
  expect(
    rich.mentorships.map((mentorship) => mentorship.competency).toSet(),
    equals(ExportCompetency.values.toSet()),
    reason: context,
  );
  expect(
    checkpoints.map((checkpoint) => checkpoint.competency).toSet(),
    equals(ExportCompetency.values.toSet()),
    reason: context,
  );
  expect(
    evaluations.map((evaluation) => evaluation.gartnerLevel).toSet(),
    equals(ExportGartnerLevel.values.toSet()),
    reason: context,
  );
  expect(
    suggestions.map((suggestion) => suggestion.status).toSet(),
    equals(ExportSuggestionStatus.values.toSet()),
    reason: context,
  );
  expect(
    rich.notificationPlans.map((plan) => plan.kind).toSet(),
    equals(ExportNotificationKind.values.toSet()),
    reason: context,
  );
  expect(
    rich.notificationPlans.map((plan) => plan.state).toSet(),
    equals(ExportNotificationState.values.toSet()),
    reason: context,
  );
  expect(
    rich.audioAssets.map((asset) => asset.kind).toSet(),
    equals(ExportAudioKind.values.toSet()),
    reason: context,
  );
  expect(
    rich.changeInitiatives.where((initiative) => initiative.active).length,
    1,
    reason: context,
  );

  final nullableFields = <String, Iterable<Object?>>{
    'settings.activation_date': [
      minimum.settings.activationDate,
      rich.settings.activationDate,
    ],
    'pillar.briefing_mode': pillarEntries.map((entry) => entry.briefingMode),
    'pillar.workout_at': pillarEntries.map((entry) => entry.workoutAt),
    'pillar.briefing_at': pillarEntries.map((entry) => entry.briefingAt),
    'pillar.change_initiative_id': pillarEntries.map(
      (entry) => entry.changeInitiativeId,
    ),
    'pillar.note_text': pillarEntries.map((entry) => entry.noteText),
    'pillar.note_audio_ref': pillarEntries.map((entry) => entry.noteAudioRef),
    'pillar.night_kind': pillarEntries.map((entry) => entry.nightKind),
    'pillar.recovery_note': pillarEntries.map((entry) => entry.recoveryNote),
    'pillar.study_block_id': pillarEntries.map((entry) => entry.studyBlockId),
    'study_block.ended_at': studyBlocks.map((block) => block.endedAt),
    'waiver.revoked_at': waivers.map((waiver) => waiver.revokedAt),
    'day.mute_cause': rich.days.map((day) => day.muteCause),
    'day.previous_result': rich.days.map((day) => day.previousResult),
    'day.closed_at': rich.days.map((day) => day.closedAt),
    'day.seal_timestamp': rich.days.map((day) => day.sealTimestamp),
    'holiday.removed_at': rich.holidays.map((holiday) => holiday.removedAt),
    'holiday.apply_reason_text': rich.holidays.map(
      (holiday) => holiday.applyReasonText,
    ),
    'holiday.remove_reason_text': rich.holidays.map(
      (holiday) => holiday.removeReasonText,
    ),
    'protocol.previous_state': rich.protocolAlarms.map(
      (alarm) => alarm.previousState,
    ),
    'protocol.triggered_at': rich.protocolAlarms.map(
      (alarm) => alarm.triggeredAt,
    ),
    'protocol.cause': rich.protocolAlarms.map((alarm) => alarm.cause),
    'protocol.plan_or_execution': rich.protocolAlarms.map(
      (alarm) => alarm.planOrExecution,
    ),
    'protocol.adjustment': rich.protocolAlarms.map((alarm) => alarm.adjustment),
    'evaluation.weekly_review_id': evaluations.map(
      (evaluation) => evaluation.weeklyReviewId,
    ),
    'evaluation.notes': evaluations.map((evaluation) => evaluation.notes),
    'mentorship.mentor_name': rich.mentorships.map(
      (mentorship) => mentorship.mentorName,
    ),
    'mentorship.last_meeting_date': rich.mentorships.map(
      (mentorship) => mentorship.lastMeetingDate,
    ),
    'contact.context_note': rich.contacts.map((contact) => contact.contextNote),
    'contact.last_touch_date': rich.contacts.map(
      (contact) => contact.lastTouchDate,
    ),
    'review.answer_fulfilled': rich.weeklyReviews.map(
      (review) => review.answerFulfilled,
    ),
    'review.answer_failed': rich.weeklyReviews.map(
      (review) => review.answerFailed,
    ),
    'review.answer_lesson': rich.weeklyReviews.map(
      (review) => review.answerLesson,
    ),
    'review.audio_ref': rich.weeklyReviews.map((review) => review.audioRef),
    'review.autosaved_at': rich.weeklyReviews.map(
      (review) => review.autosavedAt,
    ),
    'review.finalized_at': rich.weeklyReviews.map(
      (review) => review.finalizedAt,
    ),
    'manifest.last_edited_at': [
      minimum.manifest.lastEditedAt,
      rich.manifest.lastEditedAt,
    ],
  };
  for (final entry in nullableFields.entries) {
    expect(
      entry.value.any((value) => value == null),
      isTrue,
      reason: '$context: ${entry.key} sem null',
    );
    expect(
      entry.value.any((value) => value != null),
      isTrue,
      reason: '$context: ${entry.key} sem não-null',
    );
  }

  final text = rich.manifest.contentMarkdown;
  expect(text, contains('ação'), reason: context);
  expect(text, contains('🧭'), reason: context);
  expect(text, contains('e\u0301'), reason: context);
  expect(text, contains('"aspas"'), reason: context);
  expect(text, contains('/'), reason: context);
  expect(text, contains('\\'), reason: context);
  expect(text, contains('\n'), reason: context);

  final primitiveStrings = _primitiveStrings(_projectEnvelope(rich)).toList();
  final instants = primitiveStrings.where((value) => value.contains('T'));
  expect(instants.any((value) => value.endsWith('-02:00')), isTrue);
  expect(instants.any((value) => value.endsWith('-03:00')), isTrue);
  expect(
    instants.any((value) => RegExp(r'\.\d{1,6}-0[23]:00$').hasMatch(value)),
    isTrue,
  );

  for (var index = 0; index < richEnvelopes.length; index++) {
    final envelope = richEnvelopes[index];
    final variantContext = '$context: rico[$index]';
    _expectAudioIntegrity(envelope, variantContext);
    _expectDayCoherence(envelope, variantContext);
    _expectReferenceCoherence(envelope, variantContext);
  }
}

void _expectRoundTrip(String label, RitmoExportEnvelope original) {
  final originalProjection = _projectEnvelope(original);
  final originalOrder = _listOrderSignature(original);
  final canonical = original.toCanonicalJson();

  expect(
    jsonDecode(canonical),
    equals(originalProjection),
    reason: '$label: JSON canônico divergiu da projeção independente',
  );

  final decoded = RitmoExportEnvelope.fromJsonString(canonical);
  expect(
    _projectEnvelope(decoded),
    equals(originalProjection),
    reason: '$label: projeção mudou depois da desserialização',
  );
  expect(
    decoded.toCanonicalJson(),
    canonical,
    reason: '$label: JSON canônico não foi estável',
  );
  expect(
    _listOrderSignature(decoded),
    orderedEquals(originalOrder),
    reason: '$label: ordem de alguma lista mudou',
  );
}

_PrimitiveMap _objectMap(Object? value, String label) {
  if (value is! Map) {
    fail('$label deve ser um objeto JSON');
  }
  return value.map((key, child) => MapEntry(key.toString(), child));
}

void main() {
  Glados<_ExportInput>(_anyExportInput, RitmoGlados.ci(runs: 100)).test(
    'Propriedade 49: round trip do contrato de exportação',
    (_ExportInput input) {
      final minimum = _minimumEnvelope(input);
      final current = _richEnvelope(input, awaitingClosure: false);
      final awaiting = _richEnvelope(input, awaitingClosure: true);
      _expectGeneratedCoverage(input, minimum, [current, awaiting]);

      _expectRoundTrip('mínimo token=${input.token}', minimum);
      _expectRoundTrip('rico vigente token=${input.token}', current);
      _expectRoundTrip(
        'rico aguardando encerramento token=${input.token}',
        awaiting,
      );
    },
  );

  test('fixture canônica é aceita e preservada estruturalmente', () {
    final source = File(
      'test/fixtures/export/ritmo.export.v1.json',
    ).readAsStringSync();
    final fixtureTree = jsonDecode(source);
    final fixture = RitmoExportEnvelope.fromJsonString(source);

    expect(_projectEnvelope(fixture), equals(fixtureTree));
    final canonical = fixture.toCanonicalJson();
    expect(jsonDecode(canonical), equals(fixtureTree));

    final decodedAgain = RitmoExportEnvelope.fromJsonString(canonical);
    expect(_projectEnvelope(decodedAgain), equals(fixtureTree));
    expect(decodedAgain.toCanonicalJson(), canonical);
    expect(
      _listOrderSignature(decodedAgain),
      orderedEquals(_listOrderSignature(fixture)),
    );
  });

  test('schema e fixture são JSON válidos e expõem as mesmas chaves raiz', () {
    final schema = _objectMap(
      jsonDecode(
        File('schemas/ritmo.export.v1.schema.json').readAsStringSync(),
      ),
      'schema',
    );
    final fixtureTree = _objectMap(
      jsonDecode(
        File('test/fixtures/export/ritmo.export.v1.json').readAsStringSync(),
      ),
      'fixture',
    );
    final requiredRaw = schema['required'];
    if (requiredRaw is! List<Object?> ||
        requiredRaw.any((value) => value is! String)) {
      fail('schema.required deve ser uma lista de chaves textuais');
    }
    final requiredKeys = requiredRaw.cast<String>().toSet();
    final propertyKeys = _objectMap(
      schema['properties'],
      'schema.properties',
    ).keys.toSet();
    final envelope = RitmoExportEnvelope.fromJson(fixtureTree);
    final emittedKeys = _objectMap(
      jsonDecode(envelope.toCanonicalJson()),
      'envelope emitido',
    ).keys.toSet();

    // Deliberadamente não interpreta nem alega validar semanticamente o
    // dialeto JSON Schema; este teste cobre sintaxe JSON e superfície raiz.
    expect(propertyKeys, equals(requiredKeys));
    expect(fixtureTree.keys.toSet(), equals(requiredKeys));
    expect(emittedKeys, equals(requiredKeys));
  });
}
