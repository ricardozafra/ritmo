import '../../core/copy.dart';
import '../cycles/cycle_policy.dart';
import '../time/night_window.dart';
import '../time/operational_calendar.dart';
import 'change_initiative.dart';
import 'day_state_machine.dart';
import 'pillar_rules.dart';
import 'pillar_waiver.dart';
import 'seal_eligibility.dart' show Pillar, PillarStatus;
import 'study_block.dart';

enum TodayMode { openUnsealed, openSealed, closed }

final class TodayCycleSummary {
  const TodayCycleSummary({required this.cycle, this.nextCheckpoint});

  final Cycle cycle;
  final Checkpoint? nextCheckpoint;

  String get purposeText => cycle.purposeText;
}

sealed class TodayView {
  const TodayView({
    required this.operationalDate,
    required this.deviceZoneDiverges,
  });

  final OperationalDate operationalDate;
  final bool deviceZoneDiverges;
}

final class MuteTodayView extends TodayView {
  const MuteTodayView({
    required super.operationalDate,
    required super.deviceZoneDiverges,
    this.message = Copy.muteDay,
  });

  final String message;
}

final class WorkdayTodayView extends TodayView {
  WorkdayTodayView({
    required super.operationalDate,
    required super.deviceZoneDiverges,
    required this.mode,
    required this.day,
    required this.cycleSummary,
    required this.countdownDays,
    required this.awaitingClosure,
    required this.entries,
    required this.linkedStudyBlock,
    required this.activeWaiver,
    required this.visibleInitiative,
    required this.pillarStatus,
    required this.sealEligible,
    required Set<Pillar> uncoveredIncompletePillars,
    required this.nightWindowState,
  }) : uncoveredIncompletePillars = Set.unmodifiable(
         uncoveredIncompletePillars,
       );

  final TodayMode mode;
  final Day day;
  final TodayCycleSummary cycleSummary;
  final int? countdownDays;
  final bool awaitingClosure;
  final PillarEntriesSnapshot entries;
  final StudyBlock? linkedStudyBlock;
  final PillarWaiver? activeWaiver;
  final ChangeInitiative? visibleInitiative;
  final PillarStatus pillarStatus;
  final bool sealEligible;
  final Set<Pillar> uncoveredIncompletePillars;
  final NightWindowState nightWindowState;

  Cycle get cycle => cycleSummary.cycle;
  String get purposeText => cycleSummary.purposeText;
  Checkpoint? get nextCheckpoint => cycleSummary.nextCheckpoint;

  bool get canEdit => mode == TodayMode.openUnsealed;
  bool get canReopen => mode == TodayMode.openSealed;
  bool get canSeal => canEdit && sealEligible;
}
