import 'export_values.dart';

final class ExportHoliday {
  ExportHoliday({
    required this.operationalDate,
    required this.active,
    required this.createdAt,
    required this.removedAt,
    required this.applyReasonText,
    required this.removeReasonText,
  });

  factory ExportHoliday.fromJson(JsonMap json) => ExportHoliday(
    operationalDate: readDate(json, 'operational_date'),
    active: readBool(json, 'active'),
    createdAt: readInstant(json, 'created_at'),
    removedAt: readNullableInstant(json, 'removed_at'),
    applyReasonText: readNullableString(json, 'apply_reason_text'),
    removeReasonText: readNullableString(json, 'remove_reason_text'),
  );

  final ExportOperationalDate operationalDate;
  final bool active;
  final ExportOfficialInstant createdAt;
  final ExportOfficialInstant? removedAt;
  final String? applyReasonText;
  final String? removeReasonText;

  JsonMap toJson() => {
    'operational_date': operationalDate.value,
    'active': active,
    'created_at': createdAt.value,
    'removed_at': removedAt?.value,
    'apply_reason_text': applyReasonText,
    'remove_reason_text': removeReasonText,
  };
}

final class ExportProtocolAlarm {
  ExportProtocolAlarm({
    required this.id,
    required this.generationId,
    required this.startDate,
    required this.endDate,
    required this.sequenceLength,
    required this.state,
    required this.previousState,
    required this.triggeredAt,
    required this.cause,
    required this.planOrExecution,
    required this.adjustment,
  }) {
    requireNonEmpty(id, 'protocol_alarm.id');
    requireNonEmpty(generationId, 'protocol_alarm.generation_id');
    if (sequenceLength < 2) {
      throw ArgumentError.value(sequenceLength, 'sequenceLength', 'mínimo 2');
    }
  }

  factory ExportProtocolAlarm.fromJson(JsonMap json) => ExportProtocolAlarm(
    id: readString(json, 'id'),
    generationId: readString(json, 'generation_id'),
    startDate: readDate(json, 'start_date'),
    endDate: readDate(json, 'end_date'),
    sequenceLength: readInt(json, 'sequence_length'),
    state: readEnum(json, 'state', ExportProtocolState.values),
    previousState: readNullableEnum(
      json,
      'previous_state',
      ExportProtocolState.values,
    ),
    triggeredAt: readNullableInstant(json, 'triggered_at'),
    cause: readNullableString(json, 'cause'),
    planOrExecution: readNullableEnum(
      json,
      'plan_or_execution',
      ExportPlanOrExecution.values,
    ),
    adjustment: readNullableString(json, 'adjustment'),
  );

  final String id;
  final String generationId;
  final ExportOperationalDate startDate;
  final ExportOperationalDate endDate;
  final int sequenceLength;
  final ExportProtocolState state;
  final ExportProtocolState? previousState;
  final ExportOfficialInstant? triggeredAt;
  final String? cause;
  final ExportPlanOrExecution? planOrExecution;
  final String? adjustment;

  JsonMap toJson() => {
    'id': id,
    'generation_id': generationId,
    'start_date': startDate.value,
    'end_date': endDate.value,
    'sequence_length': sequenceLength,
    'state': state.name,
    'previous_state': previousState?.name,
    'triggered_at': triggeredAt?.value,
    'cause': cause,
    'plan_or_execution': planOrExecution?.name,
    'adjustment': adjustment,
  };
}

final class ExportCheckpointEvaluation {
  ExportCheckpointEvaluation({
    required this.id,
    required this.checkpointId,
    required this.weeklyReviewId,
    required this.gartnerLevel,
    required this.notes,
  }) {
    requireNonEmpty(id, 'checkpoint_eval.id');
    requireNonEmpty(checkpointId, 'checkpoint_eval.checkpoint_id');
  }

  factory ExportCheckpointEvaluation.fromJson(JsonMap json) =>
      ExportCheckpointEvaluation(
        id: readString(json, 'id'),
        checkpointId: readString(json, 'checkpoint_id'),
        weeklyReviewId: readNullableString(json, 'weekly_review_id'),
        gartnerLevel: readEnum(
          json,
          'gartner_level',
          ExportGartnerLevel.values,
        ),
        notes: readNullableString(json, 'notes'),
      );

  final String id;
  final String checkpointId;
  final String? weeklyReviewId;
  final ExportGartnerLevel gartnerLevel;
  final String? notes;

  JsonMap toJson() => {
    'id': id,
    'checkpoint_id': checkpointId,
    'weekly_review_id': weeklyReviewId,
    'gartner_level': gartnerLevel.name,
    'notes': notes,
  };
}

final class ExportCheckpoint {
  ExportCheckpoint({
    required this.id,
    required this.cycleId,
    required this.competency,
    required this.date,
    required this.status,
    required Iterable<ExportCheckpointEvaluation> evaluations,
  }) : evaluations = List.unmodifiable(evaluations) {
    requireNonEmpty(id, 'checkpoint.id');
    requireNonEmpty(cycleId, 'checkpoint.cycle_id');
    requireNonEmpty(status, 'checkpoint.status');
  }

  factory ExportCheckpoint.fromJson(JsonMap json) => ExportCheckpoint(
    id: readString(json, 'id'),
    cycleId: readString(json, 'cycle_id'),
    competency: readEnum(json, 'competency', ExportCompetency.values),
    date: readDate(json, 'date'),
    status: readString(json, 'status'),
    evaluations: readObjectList(
      json,
      'checkpoint_evals',
      ExportCheckpointEvaluation.fromJson,
    ),
  );

  final String id;
  final String cycleId;
  final ExportCompetency competency;
  final ExportOperationalDate date;
  final String status;
  final List<ExportCheckpointEvaluation> evaluations;

  JsonMap toJson() => {
    'id': id,
    'cycle_id': cycleId,
    'competency': competency.name,
    'date': date.value,
    'status': status,
    'checkpoint_evals': evaluations.map((value) => value.toJson()).toList(),
  };
}

final class ExportCycleClosureInvite {
  ExportCycleClosureInvite({required this.cycleId, required this.weekStart}) {
    requireNonEmpty(cycleId, 'cycle_closure_invite.cycle_id');
  }

  factory ExportCycleClosureInvite.fromJson(JsonMap json) =>
      ExportCycleClosureInvite(
        cycleId: readString(json, 'cycle_id'),
        weekStart: readDate(json, 'week_start'),
      );

  final String cycleId;
  final ExportOperationalDate weekStart;

  JsonMap toJson() => {'cycle_id': cycleId, 'week_start': weekStart.value};
}

final class ExportCycleDerived {
  const ExportCycleDerived({required this.awaitingClosure});

  factory ExportCycleDerived.fromJson(JsonMap json) =>
      ExportCycleDerived(awaitingClosure: readBool(json, 'awaiting_closure'));

  final bool awaitingClosure;

  JsonMap toJson() => {'awaiting_closure': awaitingClosure};
}

final class ExportCycle {
  ExportCycle({
    required this.id,
    required this.name,
    required this.purposeText,
    required this.startDate,
    required this.endDate,
    required this.state,
    required this.derived,
    required Iterable<ExportCheckpoint> checkpoints,
    required Iterable<ExportCycleClosureInvite> closureInvites,
  }) : checkpoints = List.unmodifiable(checkpoints),
       closureInvites = List.unmodifiable(closureInvites) {
    requireNonEmpty(id, 'cycle.id');
  }

  factory ExportCycle.fromJson(JsonMap json) => ExportCycle(
    id: readString(json, 'id'),
    name: readString(json, 'name'),
    purposeText: readString(json, 'purpose_text'),
    startDate: readDate(json, 'start_date'),
    endDate: readDate(json, 'end_date'),
    state: readEnum(json, 'state', ExportCycleState.values),
    derived: ExportCycleDerived.fromJson(readObject(json, 'derived')),
    checkpoints: readObjectList(json, 'checkpoints', ExportCheckpoint.fromJson),
    closureInvites: readObjectList(
      json,
      'cycle_closure_invites',
      ExportCycleClosureInvite.fromJson,
    ),
  );

  final String id;
  final String name;
  final String purposeText;
  final ExportOperationalDate startDate;
  final ExportOperationalDate endDate;
  final ExportCycleState state;
  final ExportCycleDerived derived;
  final List<ExportCheckpoint> checkpoints;
  final List<ExportCycleClosureInvite> closureInvites;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'purpose_text': purposeText,
    'start_date': startDate.value,
    'end_date': endDate.value,
    'state': state.name,
    'derived': derived.toJson(),
    'checkpoints': checkpoints.map((value) => value.toJson()).toList(),
    'cycle_closure_invites': closureInvites
        .map((value) => value.toJson())
        .toList(),
  };
}

final class ExportMentorship {
  ExportMentorship({
    required this.id,
    required this.competency,
    required this.mentorName,
    required this.lastMeetingDate,
  }) {
    requireNonEmpty(id, 'mentorship.id');
  }

  factory ExportMentorship.fromJson(JsonMap json) => ExportMentorship(
    id: readString(json, 'id'),
    competency: readEnum(json, 'competency', ExportCompetency.values),
    mentorName: readNullableString(json, 'mentor_name'),
    lastMeetingDate: readNullableDate(json, 'last_meeting_date'),
  );

  final String id;
  final ExportCompetency competency;
  final String? mentorName;
  final ExportOperationalDate? lastMeetingDate;

  JsonMap toJson() => {
    'id': id,
    'competency': competency.name,
    'mentor_name': mentorName,
    'last_meeting_date': lastMeetingDate?.value,
  };
}

final class ExportWeeklyContactSuggestion {
  ExportWeeklyContactSuggestion({
    required this.weekStart,
    required this.contactId,
    required this.status,
    required this.createdAt,
  }) {
    requireNonEmpty(contactId, 'weekly_contact_suggestion.contact_id');
  }

  factory ExportWeeklyContactSuggestion.fromJson(JsonMap json) =>
      ExportWeeklyContactSuggestion(
        weekStart: readDate(json, 'week_start'),
        contactId: readString(json, 'contact_id'),
        status: readEnum(json, 'status', ExportSuggestionStatus.values),
        createdAt: readInstant(json, 'created_at'),
      );

  final ExportOperationalDate weekStart;
  final String contactId;
  final ExportSuggestionStatus status;
  final ExportOfficialInstant createdAt;

  JsonMap toJson() => {
    'week_start': weekStart.value,
    'contact_id': contactId,
    'status': status.name,
    'created_at': createdAt.value,
  };
}

final class ExportContact {
  ExportContact({
    required this.id,
    required this.name,
    required this.contextNote,
    required this.lastTouchDate,
    required this.createdAt,
    required Iterable<ExportWeeklyContactSuggestion> weeklySuggestions,
  }) : weeklySuggestions = List.unmodifiable(weeklySuggestions) {
    requireNonEmpty(id, 'contact.id');
  }

  factory ExportContact.fromJson(JsonMap json) => ExportContact(
    id: readString(json, 'id'),
    name: readString(json, 'name'),
    contextNote: readNullableString(json, 'context_note'),
    lastTouchDate: readNullableDate(json, 'last_touch_date'),
    createdAt: readInstant(json, 'created_at'),
    weeklySuggestions: readObjectList(
      json,
      'weekly_contact_suggestions',
      ExportWeeklyContactSuggestion.fromJson,
    ),
  );

  final String id;
  final String name;
  final String? contextNote;
  final ExportOperationalDate? lastTouchDate;
  final ExportOfficialInstant createdAt;
  final List<ExportWeeklyContactSuggestion> weeklySuggestions;

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'context_note': contextNote,
    'last_touch_date': lastTouchDate?.value,
    'created_at': createdAt.value,
    'weekly_contact_suggestions': weeklySuggestions
        .map((value) => value.toJson())
        .toList(),
  };
}

final class ExportWeeklyReview {
  ExportWeeklyReview({
    required this.id,
    required this.weekStart,
    required this.answerFulfilled,
    required this.answerFailed,
    required this.answerLesson,
    required this.audioRef,
    required this.state,
    required this.createdAt,
    required this.autosavedAt,
    required this.finalizedAt,
  }) {
    requireNonEmpty(id, 'weekly_review.id');
    if ((state == ExportWeeklyReviewState.finalized) != (finalizedAt != null)) {
      throw ArgumentError('estado finalized deve corresponder a finalizedAt');
    }
  }

  factory ExportWeeklyReview.fromJson(JsonMap json) => ExportWeeklyReview(
    id: readString(json, 'id'),
    weekStart: readDate(json, 'week_start'),
    answerFulfilled: readNullableString(json, 'answer_fulfilled'),
    answerFailed: readNullableString(json, 'answer_failed'),
    answerLesson: readNullableString(json, 'answer_lesson'),
    audioRef: switch (readNullableObject(json, 'audio_ref')) {
      final value? => ExportAudioReference.fromJson(value),
      null => null,
    },
    state: readEnum(json, 'state', ExportWeeklyReviewState.values),
    createdAt: readInstant(json, 'created_at'),
    autosavedAt: readNullableInstant(json, 'autosaved_at'),
    finalizedAt: readNullableInstant(json, 'finalized_at'),
  );

  final String id;
  final ExportOperationalDate weekStart;
  final String? answerFulfilled;
  final String? answerFailed;
  final String? answerLesson;
  final ExportAudioReference? audioRef;
  final ExportWeeklyReviewState state;
  final ExportOfficialInstant createdAt;
  final ExportOfficialInstant? autosavedAt;
  final ExportOfficialInstant? finalizedAt;

  JsonMap toJson() => {
    'id': id,
    'week_start': weekStart.value,
    'answer_fulfilled': answerFulfilled,
    'answer_failed': answerFailed,
    'answer_lesson': answerLesson,
    'audio_ref': audioRef?.toJson(),
    'state': state.name,
    'created_at': createdAt.value,
    'autosaved_at': autosavedAt?.value,
    'finalized_at': finalizedAt?.value,
  };
}

final class ExportManifest {
  ExportManifest({
    required this.id,
    required this.assetVersion,
    required this.firstCopiedAt,
    required this.lastEditedAt,
    required this.contentMarkdown,
  }) {
    requireNonEmpty(id, 'manifest.id');
  }

  factory ExportManifest.fromJson(JsonMap json) => ExportManifest(
    id: readString(json, 'id'),
    assetVersion: readString(json, 'asset_version'),
    firstCopiedAt: readInstant(json, 'first_copied_at'),
    lastEditedAt: readNullableInstant(json, 'last_edited_at'),
    contentMarkdown: readString(json, 'content_markdown'),
  );

  final String id;
  final String assetVersion;
  final ExportOfficialInstant firstCopiedAt;
  final ExportOfficialInstant? lastEditedAt;
  final String contentMarkdown;

  JsonMap toJson() => {
    'id': id,
    'asset_version': assetVersion,
    'first_copied_at': firstCopiedAt.value,
    'last_edited_at': lastEditedAt?.value,
    'content_markdown': contentMarkdown,
  };
}

final class ExportChangeInitiative {
  ExportChangeInitiative({
    required this.id,
    required this.name,
    required this.active,
  }) {
    requireNonEmpty(id, 'change_initiative.id');
  }

  factory ExportChangeInitiative.fromJson(JsonMap json) =>
      ExportChangeInitiative(
        id: readString(json, 'id'),
        name: readString(json, 'name'),
        active: readBool(json, 'active'),
      );

  final String id;
  final String name;
  final bool active;

  JsonMap toJson() => {'id': id, 'name': name, 'active': active};
}

final class ExportAudioAsset {
  ExportAudioAsset({
    required this.id,
    required this.relativePath,
    required this.kind,
    required this.durationMs,
    required this.byteSize,
    required this.createdAt,
  }) {
    requireNonEmpty(id, 'audio_asset.id');
    validateRelativeAudioPath(relativePath);
    if (durationMs <= 0 || byteSize <= 0) {
      throw ArgumentError('durationMs e byteSize devem ser positivos');
    }
  }

  factory ExportAudioAsset.fromJson(JsonMap json) => ExportAudioAsset(
    id: readString(json, 'id'),
    relativePath: readString(json, 'relative_path'),
    kind: readEnum(
      json,
      'kind',
      ExportAudioKind.values,
      wireName: (value) => value.wireName,
    ),
    durationMs: readInt(json, 'duration_ms'),
    byteSize: readInt(json, 'byte_size'),
    createdAt: readInstant(json, 'created_at'),
  );

  final String id;
  final String relativePath;
  final ExportAudioKind kind;
  final int durationMs;
  final int byteSize;
  final ExportOfficialInstant createdAt;

  JsonMap toJson() => {
    'id': id,
    'relative_path': relativePath,
    'kind': kind.wireName,
    'duration_ms': durationMs,
    'byte_size': byteSize,
    'created_at': createdAt.value,
  };
}

final class ExportNotificationPlan {
  ExportNotificationPlan({
    required this.idempotencyKey,
    required this.kind,
    required this.plannedAt,
    required this.state,
  }) {
    requireNonEmpty(idempotencyKey, 'notification_plan.idempotency_key');
  }

  factory ExportNotificationPlan.fromJson(JsonMap json) =>
      ExportNotificationPlan(
        idempotencyKey: readString(json, 'idempotency_key'),
        kind: readEnum(
          json,
          'kind',
          ExportNotificationKind.values,
          wireName: (value) => value.wireName,
        ),
        plannedAt: readInstant(json, 'planned_at'),
        state: readEnum(json, 'state', ExportNotificationState.values),
      );

  final String idempotencyKey;
  final ExportNotificationKind kind;
  final ExportOfficialInstant plannedAt;
  final ExportNotificationState state;

  JsonMap toJson() => {
    'idempotency_key': idempotencyKey,
    'kind': kind.wireName,
    'planned_at': plannedAt.value,
    'state': state.name,
  };
}

final class ExportMetricsSnapshot {
  ExportMetricsSnapshot({required this.numerator, required this.denominator}) {
    if (numerator < 0 || denominator < 0 || numerator > denominator) {
      throw ArgumentError(
        'snapshot de métricas inválido: $numerator/$denominator',
      );
    }
  }

  factory ExportMetricsSnapshot.fromJson(JsonMap json) => ExportMetricsSnapshot(
    numerator: readInt(json, 'numerator'),
    denominator: readInt(json, 'denominator'),
  );

  final int numerator;
  final int denominator;

  JsonMap toJson() => {'numerator': numerator, 'denominator': denominator};
}
