import 'export_values.dart';

final class ExportReviewSettings {
  ExportReviewSettings({
    required this.weekday,
    required this.time,
    required this.sundayNotificationEnabled,
  });

  factory ExportReviewSettings.fromJson(JsonMap json) => ExportReviewSettings(
    weekday: readEnum(json, 'weekday', ExportReviewWeekday.values),
    time: ExportCivilTime(readString(json, 'time')),
    sundayNotificationEnabled: readBool(json, 'sunday_notification_enabled'),
  );

  final ExportReviewWeekday weekday;
  final ExportCivilTime time;
  final bool sundayNotificationEnabled;

  JsonMap toJson() => {
    'weekday': weekday.name,
    'time': time.value,
    'sunday_notification_enabled': sundayNotificationEnabled,
  };
}

final class ExportSettings {
  ExportSettings({
    required this.activationDate,
    required this.dayCloseTime,
    required this.nightEndTime,
    required this.review,
    required this.syncEnabled,
  }) {
    if (syncEnabled) {
      throw ArgumentError.value(
        syncEnabled,
        'syncEnabled',
        'deve ser false na v1',
      );
    }
  }

  factory ExportSettings.fromJson(JsonMap json) => ExportSettings(
    activationDate: readNullableDate(json, 'activation_date'),
    dayCloseTime: ExportCivilTime(readString(json, 'day_close_time')),
    nightEndTime: ExportCivilTime(readString(json, 'night_end_time')),
    review: ExportReviewSettings.fromJson(readObject(json, 'review')),
    syncEnabled: readBool(json, 'sync_enabled'),
  );

  final ExportOperationalDate? activationDate;
  final ExportCivilTime dayCloseTime;
  final ExportCivilTime nightEndTime;
  final ExportReviewSettings review;
  final bool syncEnabled;

  JsonMap toJson() => {
    'activation_date': activationDate?.value,
    'day_close_time': dayCloseTime.value,
    'night_end_time': nightEndTime.value,
    'review': review.toJson(),
    'sync_enabled': syncEnabled,
  };
}

final class ExportDayDerived {
  const ExportDayDerived({
    required this.isWorkday,
    required this.countsInMetrics,
  });

  factory ExportDayDerived.fromJson(JsonMap json) => ExportDayDerived(
    isWorkday: readBool(json, 'is_workday'),
    countsInMetrics: readBool(json, 'counts_in_metrics'),
  );

  final bool isWorkday;
  final bool countsInMetrics;

  JsonMap toJson() => {
    'is_workday': isWorkday,
    'counts_in_metrics': countsInMetrics,
  };
}

final class ExportPillarEntry {
  ExportPillarEntry({
    required this.operationalDate,
    required this.pillar,
    required this.workoutDone,
    required this.briefingDone,
    required this.briefingMode,
    required this.workoutAt,
    required this.briefingAt,
    required this.toggleOn,
    required this.changeInitiativeId,
    required this.noteText,
    required this.noteAudioRef,
    required this.nightKind,
    required this.recoveryNote,
    required this.studyBlockId,
  });

  factory ExportPillarEntry.fromJson(JsonMap json) => ExportPillarEntry(
    operationalDate: readDate(json, 'operational_date'),
    pillar: readEnum(json, 'pillar', ExportPillar.values),
    workoutDone: readBool(json, 'workout_done'),
    briefingDone: readBool(json, 'briefing_done'),
    briefingMode: readNullableEnum(
      json,
      'briefing_mode',
      ExportBriefingMode.values,
    ),
    workoutAt: readNullableInstant(json, 'workout_at'),
    briefingAt: readNullableInstant(json, 'briefing_at'),
    toggleOn: readBool(json, 'toggle_on'),
    changeInitiativeId: readNullableString(json, 'change_initiative_id'),
    noteText: readNullableString(json, 'note_text'),
    noteAudioRef: switch (readNullableObject(json, 'note_audio_ref')) {
      final value? => ExportAudioReference.fromJson(value),
      null => null,
    },
    nightKind: readNullableEnum(json, 'night_kind', ExportNightKind.values),
    recoveryNote: readNullableString(json, 'recovery_note'),
    studyBlockId: readNullableString(json, 'study_block_id'),
  );

  final ExportOperationalDate operationalDate;
  final ExportPillar pillar;
  final bool workoutDone;
  final bool briefingDone;
  final ExportBriefingMode? briefingMode;
  final ExportOfficialInstant? workoutAt;
  final ExportOfficialInstant? briefingAt;
  final bool toggleOn;
  final String? changeInitiativeId;
  final String? noteText;
  final ExportAudioReference? noteAudioRef;
  final ExportNightKind? nightKind;
  final String? recoveryNote;
  final String? studyBlockId;

  JsonMap toJson() => {
    'operational_date': operationalDate.value,
    'pillar': pillar.name,
    'workout_done': workoutDone,
    'briefing_done': briefingDone,
    'briefing_mode': briefingMode?.name,
    'workout_at': workoutAt?.value,
    'briefing_at': briefingAt?.value,
    'toggle_on': toggleOn,
    'change_initiative_id': changeInitiativeId,
    'note_text': noteText,
    'note_audio_ref': noteAudioRef?.toJson(),
    'night_kind': nightKind?.name,
    'recovery_note': recoveryNote,
    'study_block_id': studyBlockId,
  };
}

final class ExportStudyBlock {
  ExportStudyBlock({
    required this.id,
    required this.operationalDate,
    required this.startedAt,
    required this.blockDeadline,
    required this.endedAt,
  }) {
    requireNonEmpty(id, 'study_block.id');
  }

  factory ExportStudyBlock.fromJson(JsonMap json) => ExportStudyBlock(
    id: readString(json, 'id'),
    operationalDate: readDate(json, 'operational_date'),
    startedAt: readInstant(json, 'started_at'),
    blockDeadline: readInstant(json, 'block_deadline'),
    endedAt: readNullableInstant(json, 'ended_at'),
  );

  final String id;
  final ExportOperationalDate operationalDate;
  final ExportOfficialInstant startedAt;
  final ExportOfficialInstant blockDeadline;
  final ExportOfficialInstant? endedAt;

  JsonMap toJson() => {
    'id': id,
    'operational_date': operationalDate.value,
    'started_at': startedAt.value,
    'block_deadline': blockDeadline.value,
    'ended_at': endedAt?.value,
  };
}

final class ExportPillarWaiver {
  ExportPillarWaiver({
    required this.id,
    required this.operationalDate,
    required this.pillar,
    required this.reasonText,
    required this.recurrenceConfirmed,
    required this.revokedAt,
  }) {
    requireNonEmpty(id, 'pillar_waiver.id');
    requireNonEmpty(reasonText.trim(), 'pillar_waiver.reason_text');
  }

  factory ExportPillarWaiver.fromJson(JsonMap json) => ExportPillarWaiver(
    id: readString(json, 'id'),
    operationalDate: readDate(json, 'operational_date'),
    pillar: readEnum(json, 'pillar', ExportPillar.values),
    reasonText: readString(json, 'reason_text'),
    recurrenceConfirmed: readBool(json, 'recurrence_confirmed'),
    revokedAt: readNullableInstant(json, 'revoked_at'),
  );

  final String id;
  final ExportOperationalDate operationalDate;
  final ExportPillar pillar;
  final String reasonText;
  final bool recurrenceConfirmed;
  final ExportOfficialInstant? revokedAt;

  JsonMap toJson() => {
    'id': id,
    'operational_date': operationalDate.value,
    'pillar': pillar.name,
    'reason_text': reasonText,
    'recurrence_confirmed': recurrenceConfirmed,
    'revoked_at': revokedAt?.value,
  };
}

final class ExportDay {
  ExportDay({
    required this.operationalDate,
    required this.baseResult,
    required this.effectiveResult,
    required this.muteCause,
    required this.previousResult,
    required this.closedAt,
    required this.sealTimestamp,
    required this.derived,
    required Iterable<ExportPillarEntry> pillarEntries,
    required Iterable<ExportStudyBlock> studyBlocks,
    required Iterable<ExportPillarWaiver> pillarWaivers,
  }) : pillarEntries = List.unmodifiable(pillarEntries),
       studyBlocks = List.unmodifiable(studyBlocks),
       pillarWaivers = List.unmodifiable(pillarWaivers) {
    if (baseResult == ExportDayResult.mute) {
      throw ArgumentError('baseResult não pode ser mute');
    }
    if ((effectiveResult == ExportDayResult.mute) != (muteCause != null)) {
      throw ArgumentError('effectiveResult mute deve corresponder a muteCause');
    }
    if (muteCause == ExportMuteCause.holiday && previousResult == null) {
      throw ArgumentError('feriado deve preservar previousResult');
    }
  }

  factory ExportDay.fromJson(JsonMap json) => ExportDay(
    operationalDate: readDate(json, 'operational_date'),
    baseResult: readEnum(json, 'base_result', ExportDayResult.values),
    effectiveResult: readEnum(json, 'effective_result', ExportDayResult.values),
    muteCause: readNullableEnum(json, 'mute_cause', ExportMuteCause.values),
    previousResult: readNullableEnum(
      json,
      'previous_result',
      ExportDayResult.values,
    ),
    closedAt: readNullableInstant(json, 'closed_at'),
    sealTimestamp: readNullableInstant(json, 'seal_timestamp'),
    derived: ExportDayDerived.fromJson(readObject(json, 'derived')),
    pillarEntries: readObjectList(
      json,
      'pillar_entries',
      ExportPillarEntry.fromJson,
    ),
    studyBlocks: readObjectList(
      json,
      'study_blocks',
      ExportStudyBlock.fromJson,
    ),
    pillarWaivers: readObjectList(
      json,
      'pillar_waivers',
      ExportPillarWaiver.fromJson,
    ),
  );

  final ExportOperationalDate operationalDate;
  final ExportDayResult baseResult;
  final ExportDayResult effectiveResult;
  final ExportMuteCause? muteCause;
  final ExportDayResult? previousResult;
  final ExportOfficialInstant? closedAt;
  final ExportOfficialInstant? sealTimestamp;
  final ExportDayDerived derived;
  final List<ExportPillarEntry> pillarEntries;
  final List<ExportStudyBlock> studyBlocks;
  final List<ExportPillarWaiver> pillarWaivers;

  JsonMap toJson() => {
    'operational_date': operationalDate.value,
    'base_result': baseResult.name,
    'effective_result': effectiveResult.name,
    'mute_cause': muteCause?.name,
    'previous_result': previousResult?.name,
    'closed_at': closedAt?.value,
    'seal_timestamp': sealTimestamp?.value,
    'derived': derived.toJson(),
    'pillar_entries': pillarEntries.map((value) => value.toJson()).toList(),
    'study_blocks': studyBlocks.map((value) => value.toJson()).toList(),
    'pillar_waivers': pillarWaivers.map((value) => value.toJson()).toList(),
  };
}
