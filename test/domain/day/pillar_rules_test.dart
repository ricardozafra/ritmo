import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('PillarRules', () {
    test('morning requires workout and briefing or a morning waiver', () {
      expect(
        PillarRules.morningCompleted(
          const MorningEntry(workoutDone: true, briefingDone: false),
        ),
        isFalse,
      );
      expect(
        PillarRules.morningCompleted(
          const MorningEntry(workoutDone: true, briefingDone: true),
        ),
        isTrue,
      );
      expect(
        PillarRules.morningCompleted(null, activeWaiver: Pillar.morning),
        isTrue,
      );
    });

    test('day completion depends only on the literal toggle', () {
      expect(PillarRules.dayToggleLabel, Copy.dayToggle);
      expect(PillarRules.dayCompleted(const DayEntry(toggleOn: true)), isTrue);
      expect(
        PillarRules.dayCompleted(
          const DayEntry(toggleOn: false, note: 'Problema complexo'),
        ),
        isFalse,
      );
    });
    test('night completes with recovery or an ended linked study', () {
      expect(
        PillarRules.nightCompleted(
          const NightEntry(kind: NightKind.recovery),
          linkedStudyEnded: false,
        ),
        isTrue,
      );
      expect(
        PillarRules.nightCompleted(
          const NightEntry(kind: NightKind.study, studyBlockId: 'block-1'),
          linkedStudyEnded: false,
        ),
        isFalse,
      );
      expect(
        PillarRules.nightCompleted(
          const NightEntry(kind: NightKind.study, studyBlockId: 'block-1'),
          linkedStudyEnded: true,
        ),
        isTrue,
      );
    });

    test('manual and automatic briefing completion require no duration', () {
      final instant = tz.TZDateTime(tz.UTC, 2026, 5, 4, 7);
      final manual = PillarRules.completeBriefing(
        const MorningEntry(workoutDone: true),
        mode: BriefingCompletion.manual,
        at: instant,
      );
      final automatic = PillarRules.completeBriefing(
        null,
        mode: BriefingCompletion.automatic,
        at: instant,
      );

      expect(manual.briefingDone, isTrue);
      expect(manual.briefingMode, BriefingCompletion.manual);
      expect(manual.briefingAt, instant);
      expect(manual.workoutDone, isTrue);
      expect(automatic.briefingDone, isTrue);
      expect(automatic.briefingMode, BriefingCompletion.automatic);
    });
  });
}
