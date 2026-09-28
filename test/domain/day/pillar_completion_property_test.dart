// Feature: ritmo, Property 5: Conclusão de pilares
//
// Para qualquer conjunto de registros de pilar e qualquer dispensa ativa,
// `morning` está concluído se e somente se (treino e briefing concluídos) ou a
// dispensa ativa é de `morning`; `day` está concluído se e somente se o toggle
// está ligado, independentemente de nota textual ou de voz; `night` está
// concluído se e somente se há Recuperação confirmada ou bloco de Estudo
// encerrado, sem qualquer exigência de duração mínima.
//
// **Validates: Requirements RF-01.3, RF-01.9, RF-01.10, RF-01.16, RF-01.18,
// RF-02.11, RF-04.1, RF-04.2**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

void main() {
  Glados<PillarEntriesFixture>(
    anyPillarEntries,
    RitmoGlados.ci(),
  ).test('Propriedade 5: conclusão de pilares', (PillarEntriesFixture fixture) {
    final activeWaiver = activeWaiverPillar(fixture.waiver);
    final morning = MorningEntry(
      workoutDone: fixture.workoutDone,
      briefingDone: fixture.briefingDone,
      briefingMode: fixture.briefingMode,
    );
    final day = DayEntry(
      toggleOn: fixture.toggleOn,
      note: fixture.note,
      noteAudioId: fixture.noteAudioId,
    );
    final night = NightEntry(
      kind: fixture.nightKind,
      recoveryNote: fixture.recoveryNote,
      studyBlockId: fixture.studyBlockId,
    );
    // Um bloco só pode estar encerrado se existir vinculado ao registro.
    final linkedStudyEnded = fixture.studyBlockId != null && fixture.studyEnded;
    final status = PillarRules.status(
      PillarEntriesSnapshot(morning: morning, day: day, night: night),
      activeWaiver: activeWaiver,
      linkedStudyEnded: linkedStudyEnded,
    );
    final context =
        'treino ${fixture.workoutDone}, briefing ${fixture.briefingDone}, '
        'toggle ${fixture.toggleOn}, nota ${fixture.note}, '
        'áudio ${fixture.noteAudioId}, noite ${fixture.nightKind}, '
        'bloco ${fixture.studyBlockId}, encerrado ${fixture.studyEnded}, '
        'duração ${fixture.studyDuration}, dispensa ${fixture.waiver}';

    // Modelo de referência derivado diretamente dos requisitos.
    final expectedMorning =
        (fixture.workoutDone && fixture.briefingDone) ||
        activeWaiver == Pillar.morning;
    final expectedDay = fixture.toggleOn;
    final expectedNight =
        fixture.nightKind == NightKind.recovery ||
        (fixture.nightKind == NightKind.study && linkedStudyEnded);

    expect(status.morningCompleted, expectedMorning, reason: context);
    expect(status.dayCompleted, expectedDay, reason: context);
    expect(status.nightCompleted, expectedNight, reason: context);
    expect(status.incompletePillars, <Pillar>{
      if (!expectedMorning) Pillar.morning,
      if (!expectedDay) Pillar.day,
      if (!expectedNight) Pillar.night,
    }, reason: context);

    // RF-02.11: a dispensa da Manhã cobre treino e briefing conjuntamente, e
    // dispensa de outro pilar nunca conclui a Manhã.
    expect(
      PillarRules.morningCompleted(morning, activeWaiver: Pillar.morning),
      isTrue,
      reason: context,
    );
    for (final other in <Pillar>[Pillar.day, Pillar.night]) {
      expect(
        PillarRules.morningCompleted(morning, activeWaiver: other),
        fixture.workoutDone && fixture.briefingDone,
        reason: context,
      );
    }

    // RF-01.9 e RF-01.10: nota textual ou de voz nunca altera o Pilar do Dia.
    for (final note in <String?>[null, '', fixture.note, 'nota longa']) {
      for (final audioId in <String?>[null, fixture.noteAudioId, 'audio-2']) {
        expect(
          PillarRules.dayCompleted(
            DayEntry(
              toggleOn: fixture.toggleOn,
              note: note,
              noteAudioId: audioId,
            ),
          ),
          expectedDay,
          reason: context,
        );
      }
    }

    // RF-01.16, RF-01.18, RF-04.1 e RF-04.2: Estudo encerrado e Recuperação
    // confirmada concluem a Noite sem duração mínima e sem depender de nota.
    final startedAt = tz.TZDateTime.utc(2026, 1, 5, 22);
    for (final duration in <Duration>{Duration.zero, fixture.studyDuration}) {
      final endedAt = startedAt.add(duration);
      // Encerrado é ter `ended_at`, inclusive quando igual ao início.
      final ended = !endedAt.isBefore(startedAt);
      expect(
        PillarRules.nightCompleted(
          const NightEntry(kind: NightKind.study, studyBlockId: 'block-1'),
          linkedStudyEnded: ended,
        ),
        isTrue,
        reason: '$context, duração $duration',
      );
    }
    expect(
      PillarRules.nightCompleted(
        NightEntry(kind: NightKind.recovery, recoveryNote: fixture.recoveryNote),
        linkedStudyEnded: false,
      ),
      isTrue,
      reason: context,
    );
    // Estudo ainda aberto não conclui a Noite.
    expect(
      PillarRules.nightCompleted(
        NightEntry(kind: NightKind.study, studyBlockId: 'block-1'),
        linkedStudyEnded: false,
      ),
      isFalse,
      reason: context,
    );
  });
}
