import '../../data/repositories/today_repository.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/day/day_state_machine.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/seal_eligibility.dart' as eligibility;
import '../../domain/day/today_view.dart';
import '../../domain/time/night_window.dart';
import '../../domain/time/operational_clock.dart';

final class TodayProjection {
  const TodayProjection();

  static const CyclePolicy _cyclePolicy = CyclePolicy();

  TodayView project({
    required TodaySnapshot snapshot,
    required OperationalClock clock,
    required DateTime now,
  }) {
    final day = snapshot.day;
    final deviceZoneDiverges = clock.deviceZoneDiverges;
    if (day.isMute) {
      return MuteTodayView(
        operationalDate: day.operationalDate,
        deviceZoneDiverges: deviceZoneDiverges,
      );
    }

    final mode = !day.isOpen
        ? TodayMode.closed
        : day.baseResult == DayResult.sealed
        ? TodayMode.openSealed
        : TodayMode.openUnsealed;

    final activeWaiver = snapshot.activeWaiver;
    final pillarStatus = PillarRules.status(
      snapshot.entries,
      activeWaiver: activeWaiver?.pillar,
      linkedStudyEnded: snapshot.linkedStudyBlock?.endedAt != null,
    );
    final sealWaiver = activeWaiver == null
        ? null
        : eligibility.PillarWaiver(pillar: activeWaiver.pillar);
    final isSealEligible = eligibility.sealEligible(pillarStatus, sealWaiver);
    final uncovered = eligibility.uncoveredIncompletePillars(
      pillarStatus,
      sealWaiver,
    );

    final nextCheckpoint = _cyclePolicy.nextFutureCheckpoint(
      snapshot.cycle,
      snapshot.checkpoints,
      day.operationalDate,
    );
    final countdownDays = _cyclePolicy.countdownDays(
      nextCheckpoint,
      day.operationalDate,
    );
    final awaitingClosure = _cyclePolicy.awaitingClosure(
      snapshot.cycle,
      snapshot.checkpoints,
      day.operationalDate,
    );

    final nightWindowState = mode == TodayMode.openUnsealed
        ? NightWindow(
            clock,
          ).evaluate(now: now, operationalDate: day.operationalDate)
        : NightWindowState.closed;

    return WorkdayTodayView(
      operationalDate: day.operationalDate,
      deviceZoneDiverges: deviceZoneDiverges,
      mode: mode,
      day: day,
      cycleSummary: TodayCycleSummary(
        cycle: snapshot.cycle,
        nextCheckpoint: nextCheckpoint,
      ),
      countdownDays: countdownDays,
      awaitingClosure: awaitingClosure,
      entries: snapshot.entries,
      linkedStudyBlock: snapshot.linkedStudyBlock,
      activeWaiver: activeWaiver,
      visibleInitiative: snapshot.visibleInitiative,
      pillarStatus: pillarStatus,
      sealEligible: isSealEligible,
      uncoveredIncompletePillars: uncovered,
      nightWindowState: nightWindowState,
    );
  }
}
