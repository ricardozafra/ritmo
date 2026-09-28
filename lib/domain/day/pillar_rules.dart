import 'package:timezone/timezone.dart' as tz;

import '../../core/copy.dart';
import 'seal_eligibility.dart';

enum BriefingCompletion { automatic, manual }

enum NightKind { study, recovery }

final class MorningEntry {
  const MorningEntry({
    this.workoutDone = false,
    this.briefingDone = false,
    this.briefingMode,
    this.workoutAt,
    this.briefingAt,
  });

  final bool workoutDone;
  final bool briefingDone;
  final BriefingCompletion? briefingMode;
  final tz.TZDateTime? workoutAt;
  final tz.TZDateTime? briefingAt;

  MorningEntry completeBriefing({
    required BriefingCompletion mode,
    required tz.TZDateTime at,
  }) => MorningEntry(
    workoutDone: workoutDone,
    briefingDone: true,
    briefingMode: mode,
    workoutAt: workoutAt,
    briefingAt: at,
  );
}

final class DayEntry {
  const DayEntry({
    this.toggleOn = false,
    this.changeInitiativeId,
    this.note,
    this.noteAudioId,
  });

  final bool toggleOn;
  final String? changeInitiativeId;
  final String? note;
  final String? noteAudioId;
}

final class NightEntry {
  const NightEntry({this.kind, this.recoveryNote, this.studyBlockId});

  final NightKind? kind;
  final String? recoveryNote;
  final String? studyBlockId;
}

final class PillarEntriesSnapshot {
  const PillarEntriesSnapshot({this.morning, this.day, this.night});

  final MorningEntry? morning;
  final DayEntry? day;
  final NightEntry? night;
}

/// Regras puras de conclusão dos três pilares.
abstract final class PillarRules {
  /// Copy obrigatória do toggle; nota e áudio nunca participam da conclusão.
  static const String dayToggleLabel = Copy.dayToggle;

  static bool morningCompleted(MorningEntry? entry, {Pillar? activeWaiver}) =>
      activeWaiver == Pillar.morning ||
      (entry?.workoutDone == true && entry?.briefingDone == true);

  static bool dayCompleted(DayEntry? entry) => entry?.toggleOn == true;

  static bool nightCompleted(
    NightEntry? entry, {
    required bool linkedStudyEnded,
  }) =>
      entry?.kind == NightKind.recovery ||
      (entry?.kind == NightKind.study &&
          entry?.studyBlockId != null &&
          linkedStudyEnded);

  static PillarStatus status(
    PillarEntriesSnapshot entries, {
    Pillar? activeWaiver,
    bool linkedStudyEnded = false,
  }) => PillarStatus(
    morningCompleted: morningCompleted(
      entries.morning,
      activeWaiver: activeWaiver,
    ),
    dayCompleted: dayCompleted(entries.day),
    nightCompleted: nightCompleted(
      entries.night,
      linkedStudyEnded: linkedStudyEnded,
    ),
  );

  /// Conclusão manual e automática têm a mesma semântica e nenhuma duração
  /// mínima. O modo apenas preserva qual gatilho concluiu o briefing.
  static MorningEntry completeBriefing(
    MorningEntry? current, {
    required BriefingCompletion mode,
    required tz.TZDateTime at,
  }) => (current ?? const MorningEntry()).completeBriefing(mode: mode, at: at);
}
