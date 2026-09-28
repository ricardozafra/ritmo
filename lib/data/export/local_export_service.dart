import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:path/path.dart' as p;
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/cycles/cycle_policy.dart';
import '../../domain/export/export_envelope.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../storage/disk_space_checker.dart';

/// Resultado de sucesso de uma exportação local atômica (RD-27).
final class ExportPackageResult {
  const ExportPackageResult({
    required this.exportDirectory,
    required this.jsonFile,
    required this.envelope,
    required this.audioFileCount,
    required this.totalBytes,
  });

  final Directory exportDirectory;
  final File jsonFile;
  final RitmoExportEnvelope envelope;
  final int audioFileCount;
  final int totalBytes;
}

/// Serviço de execução de exportação local de dados (Fase 3).
///
/// Habilitado somente sob demanda explícita do usuário na Fase 3.
/// Não realiza upload nem sincronização e garante publicação atômica do pacote (RA-01.11, RD-27, RNF-02.2, RNF-05.4, RNF-05.5).
///
/// Convenção de layout do pacote exportado:
/// - `<export_dir>/ritmo_export.json`: envelope JSON canônico estruturado.
/// - `<export_dir>/audio/<nome_arquivo>`: arquivos de áudio referenciados pelo envelope copiados para o subdiretório `audio/`.
final class LocalExportService {
  LocalExportService({
    required this.database,
    required this.appDirectory,
    DiskSpaceChecker? diskSpaceChecker,
    tz.Location? businessLocation,
    this.clock,
    this.cyclePolicy = const CyclePolicy(),
  }) : _diskSpaceChecker = diskSpaceChecker ?? const SystemDiskSpaceChecker(),
       _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase database;
  final Directory appDirectory;
  final DiskSpaceChecker _diskSpaceChecker;
  final tz.Location _businessLocation;
  final OperationalClock? clock;
  final CyclePolicy cyclePolicy;

  Directory get audioDirectory => Directory(p.join(appDirectory.path, 'audio'));

  /// Constrói o envelope de exportação canônico a partir de todas as tabelas persistidas.
  Future<RitmoExportEnvelope> buildEnvelope(
    tz.TZDateTime generatedAt, {
    OperationalDate? referenceOperationalDate,
  }) async {
    final settingsRow = await database
        .select(database.settings)
        .getSingleOrNull();
    if (settingsRow == null) {
      throw StateError('Configuração persistida ausente: settings id=1.');
    }

    final calendar = OperationalCalendar(
      dayCloseTime: LocalTimeOfDay.fromMinutes(settingsRow.dayCloseTimeMin),
      nightEndTime: LocalTimeOfDay.fromMinutes(settingsRow.nightEndTimeMin),
    );
    final referenceDate =
        referenceOperationalDate ??
        clock?.operationalDateNow() ??
        calendar.operationalDateOf(generatedAt);

    final exportSettings = ExportSettings(
      activationDate: settingsRow.activationDate != null
          ? ExportOperationalDate(settingsRow.activationDate!)
          : null,
      dayCloseTime: ExportCivilTime(
        LocalTimeOfDay.fromMinutes(settingsRow.dayCloseTimeMin).toString(),
      ),
      nightEndTime: ExportCivilTime(
        LocalTimeOfDay.fromMinutes(settingsRow.nightEndTimeMin).toString(),
      ),
      review: ExportReviewSettings(
        weekday: ExportReviewWeekday.values.firstWhere(
          (w) => w.name == settingsRow.reviewWeekday,
          orElse: () => ExportReviewWeekday.sunday,
        ),
        time: ExportCivilTime(
          LocalTimeOfDay.fromMinutes(settingsRow.reviewTimeMin).toString(),
        ),
        sundayNotificationEnabled: settingsRow.sundayNotificationEnabled,
      ),
      syncEnabled: false,
    );

    // Dias e seus agregados
    final dayRows = await (database.select(
      database.days,
    )..orderBy([(r) => OrderingTerm(expression: r.operationalDate)])).get();

    final exportDays = <ExportDay>[];
    for (final dayRow in dayRows) {
      final pillarRows =
          await (database.select(database.pillarEntries)
                ..where((r) => r.operationalDate.equals(dayRow.operationalDate))
                ..orderBy([(r) => OrderingTerm(expression: r.pillar)]))
              .get();

      final studyBlockRows =
          await (database.select(database.studyBlocks)
                ..where((r) => r.operationalDate.equals(dayRow.operationalDate))
                ..orderBy([(r) => OrderingTerm(expression: r.startedAt)]))
              .get();

      final waiverRows =
          await (database.select(database.pillarWaivers)
                ..where((r) => r.date.equals(dayRow.operationalDate))
                ..orderBy([(r) => OrderingTerm(expression: r.pillar)]))
              .get();

      final exportPillars = <ExportPillarEntry>[];
      for (final pRow in pillarRows) {
        ExportAudioReference? audioRef;
        if (pRow.noteAudioId != null) {
          final audioRow = await (database.select(
            database.audioAssets,
          )..where((r) => r.id.equals(pRow.noteAudioId!))).getSingleOrNull();
          if (audioRow != null) {
            audioRef = ExportAudioReference(
              id: audioRow.id,
              relativePath: audioRow.relativePath,
            );
          }
        }

        exportPillars.add(
          ExportPillarEntry(
            operationalDate: ExportOperationalDate(pRow.operationalDate),
            pillar: ExportPillar.values.firstWhere(
              (p) => p.name == pRow.pillar,
            ),
            workoutDone: pRow.workoutDone,
            briefingDone: pRow.briefingDone,
            briefingMode: pRow.briefingMode != null
                ? ExportBriefingMode.values.firstWhere(
                    (b) => b.name == pRow.briefingMode,
                  )
                : null,
            workoutAt: pRow.workoutAt != null
                ? _toInstant(pRow.workoutAt!)
                : null,
            briefingAt: pRow.briefingAt != null
                ? _toInstant(pRow.briefingAt!)
                : null,
            toggleOn: pRow.toggleOn,
            changeInitiativeId: pRow.changeInitiativeId,
            noteText: pRow.noteText,
            noteAudioRef: audioRef,
            nightKind: pRow.nightKind != null
                ? ExportNightKind.values.firstWhere(
                    (k) => k.name == pRow.nightKind,
                  )
                : null,
            recoveryNote: pRow.recoveryNote,
            studyBlockId: pRow.studyBlockId,
          ),
        );
      }

      final exportBlocks = studyBlockRows
          .map(
            (b) => ExportStudyBlock(
              id: b.id,
              operationalDate: ExportOperationalDate(b.operationalDate),
              startedAt: _toInstant(b.startedAt),
              blockDeadline: _toInstant(b.blockDeadline),
              endedAt: b.endedAt != null ? _toInstant(b.endedAt!) : null,
            ),
          )
          .toList();

      final exportWaivers = waiverRows
          .map(
            (w) => ExportPillarWaiver(
              id: w.id,
              operationalDate: ExportOperationalDate(w.date),
              pillar: ExportPillar.values.firstWhere((p) => p.name == w.pillar),
              reasonText: w.reasonText,
              recurrenceConfirmed: w.recurrenceConfirmed,
              revokedAt: w.revokedAt != null ? _toInstant(w.revokedAt!) : null,
            ),
          )
          .toList();

      final opDate = _parseDate(dayRow.operationalDate);
      final isWorkday = dayRow.muteCause == null && !opDate.isWeekend;
      final countsInMetrics = isWorkday && dayRow.effectiveResult != 'mute';

      exportDays.add(
        ExportDay(
          operationalDate: ExportOperationalDate(dayRow.operationalDate),
          baseResult: ExportDayResult.values.firstWhere(
            (r) => r.name == dayRow.baseResult,
          ),
          effectiveResult: ExportDayResult.values.firstWhere(
            (r) => r.name == dayRow.effectiveResult,
          ),
          muteCause: dayRow.muteCause != null
              ? ExportMuteCause.values.firstWhere(
                  (c) => c.name == dayRow.muteCause,
                )
              : null,
          previousResult: dayRow.previousResult != null
              ? ExportDayResult.values.firstWhere(
                  (r) => r.name == dayRow.previousResult,
                )
              : null,
          closedAt: dayRow.closedAt != null
              ? _toInstant(dayRow.closedAt!)
              : null,
          sealTimestamp: dayRow.sealTimestamp != null
              ? _toInstant(dayRow.sealTimestamp!)
              : null,
          derived: ExportDayDerived(
            isWorkday: isWorkday,
            countsInMetrics: countsInMetrics,
          ),
          pillarEntries: exportPillars,
          studyBlocks: exportBlocks,
          pillarWaivers: exportWaivers,
        ),
      );
    }

    // Feriados
    final holidayRows = await (database.select(
      database.holidays,
    )..orderBy([(r) => OrderingTerm(expression: r.operationalDate)])).get();
    final exportHolidays = holidayRows
        .map(
          (h) => ExportHoliday(
            operationalDate: ExportOperationalDate(h.operationalDate),
            active: h.active,
            createdAt: _toInstant(h.createdAt),
            removedAt: h.removedAt != null ? _toInstant(h.removedAt!) : null,
            applyReasonText: h.applyReasonText,
            removeReasonText: h.removeReasonText,
          ),
        )
        .toList();

    // Protocol Alarms
    final alarmRows = await (database.select(
      database.protocolAlarms,
    )..orderBy([(r) => OrderingTerm(expression: r.startDate)])).get();
    final exportAlarms = alarmRows
        .map(
          (a) => ExportProtocolAlarm(
            id: a.id,
            generationId: a.generationId,
            startDate: ExportOperationalDate(a.startDate),
            endDate: ExportOperationalDate(a.endDate),
            sequenceLength: a.sequenceLength,
            state: ExportProtocolState.values.firstWhere(
              (s) => s.name == a.state,
            ),
            previousState: a.previousState != null
                ? ExportProtocolState.values.firstWhere(
                    (s) => s.name == a.previousState,
                  )
                : null,
            triggeredAt: a.triggeredAt != null
                ? _toInstant(a.triggeredAt!)
                : null,
            cause: a.cause,
            planOrExecution: a.planOrExecution != null
                ? ExportPlanOrExecution.values.firstWhere(
                    (e) => e.name == a.planOrExecution,
                  )
                : null,
            adjustment: a.adjustment,
          ),
        )
        .toList();

    // Ciclos, checkpoints e avaliações
    final cycleRows = await (database.select(
      database.cycles,
    )..orderBy([(r) => OrderingTerm(expression: r.startDate)])).get();
    final exportCycles = <ExportCycle>[];
    for (final cRow in cycleRows) {
      final checkpointRows =
          await (database.select(database.checkpoints)
                ..where((r) => r.cycleId.equals(cRow.id))
                ..orderBy([(r) => OrderingTerm(expression: r.date)]))
              .get();

      final exportCheckpoints = <ExportCheckpoint>[];
      final domainCheckpoints = <Checkpoint>[];
      for (final cpRow in checkpointRows) {
        final evalRows = await (database.select(
          database.checkpointEvals,
        )..where((r) => r.checkpointId.equals(cpRow.id))).get();

        final exportEvals = evalRows
            .map(
              (ev) => ExportCheckpointEvaluation(
                id: ev.id,
                checkpointId: ev.checkpointId,
                weeklyReviewId: ev.weeklyReviewId,
                gartnerLevel: ExportGartnerLevel.values.firstWhere(
                  (l) => l.name == ev.gartnerLevel,
                ),
                notes: ev.notes,
              ),
            )
            .toList();

        final cpDate = _parseDate(cpRow.date);
        final domainCompetency = switch (cpRow.competency.toUpperCase()) {
          'ST' => Competency.st,
          'IN' => Competency.in_,
          'CA' => Competency.ca,
          _ => Competency.st,
        };

        domainCheckpoints.add(
          Checkpoint(
            id: cpRow.id,
            cycleId: cpRow.cycleId,
            competency: domainCompetency,
            date: cpDate,
            status: cpRow.status,
          ),
        );

        exportCheckpoints.add(
          ExportCheckpoint(
            id: cpRow.id,
            cycleId: cpRow.cycleId,
            competency: ExportCompetency.values.firstWhere(
              (c) => c.name == cpRow.competency,
            ),
            date: ExportOperationalDate(cpRow.date),
            status: cpRow.status,
            evaluations: exportEvals,
          ),
        );
      }

      final inviteRows = await (database.select(
        database.cycleClosureInvites,
      )..where((r) => r.cycleId.equals(cRow.id))).get();
      final exportInvites = inviteRows
          .map(
            (i) => ExportCycleClosureInvite(
              cycleId: i.cycleId,
              weekStart: ExportOperationalDate(i.weekStart),
            ),
          )
          .toList();

      final domainCycle = Cycle(
        id: cRow.id,
        name: cRow.name,
        purposeText: cRow.purposeText,
        startDate: _parseDate(cRow.startDate),
        endDate: _parseDate(cRow.endDate),
        state: cRow.state == 'archived'
            ? CycleState.archived
            : CycleState.active,
      );

      final isAwaitingClosure = cyclePolicy.awaitingClosure(
        domainCycle,
        domainCheckpoints,
        referenceDate,
      );

      exportCycles.add(
        ExportCycle(
          id: cRow.id,
          name: cRow.name,
          purposeText: cRow.purposeText,
          startDate: ExportOperationalDate(cRow.startDate),
          endDate: ExportOperationalDate(cRow.endDate),
          state: cRow.state == 'archived'
              ? ExportCycleState.archived
              : ExportCycleState.active,
          derived: ExportCycleDerived(awaitingClosure: isAwaitingClosure),
          checkpoints: exportCheckpoints,
          closureInvites: exportInvites,
        ),
      );
    }

    // Mentorias
    final mentorshipRows = await database.select(database.mentorships).get();
    final exportMentorships = mentorshipRows
        .map(
          (m) => ExportMentorship(
            id: m.id,
            competency: ExportCompetency.values.firstWhere(
              (c) => c.name == m.competency,
            ),
            mentorName: m.mentorName,
            lastMeetingDate: m.lastMeetingDate != null
                ? ExportOperationalDate(m.lastMeetingDate!)
                : null,
          ),
        )
        .toList();

    // Contatos e sugestões
    final contactRows = await database.select(database.contacts).get();
    final exportContacts = <ExportContact>[];
    for (final ctRow in contactRows) {
      final suggestionRows = await (database.select(
        database.weeklyContactSuggestions,
      )..where((r) => r.contactId.equals(ctRow.id))).get();

      final exportSuggestions = suggestionRows
          .map(
            (s) => ExportWeeklyContactSuggestion(
              weekStart: ExportOperationalDate(s.weekStart),
              contactId: s.contactId,
              status: ExportSuggestionStatus.values.firstWhere(
                (st) => st.name == s.status,
              ),
              createdAt: _toInstant(s.createdAt),
            ),
          )
          .toList();

      exportContacts.add(
        ExportContact(
          id: ctRow.id,
          name: ctRow.name,
          contextNote: ctRow.contextNote,
          lastTouchDate: ctRow.lastTouchDate != null
              ? ExportOperationalDate(ctRow.lastTouchDate!)
              : null,
          createdAt: _toInstant(ctRow.createdAt),
          weeklySuggestions: exportSuggestions,
        ),
      );
    }

    // Revisões Semanais
    final reviewRows = await (database.select(
      database.weeklyReviews,
    )..orderBy([(r) => OrderingTerm(expression: r.weekStart)])).get();
    final exportReviews = <ExportWeeklyReview>[];
    for (final rw in reviewRows) {
      ExportAudioReference? audioRef;
      if (rw.audioId != null) {
        final audioRow = await (database.select(
          database.audioAssets,
        )..where((r) => r.id.equals(rw.audioId!))).getSingleOrNull();
        if (audioRow != null) {
          audioRef = ExportAudioReference(
            id: audioRow.id,
            relativePath: audioRow.relativePath,
          );
        }
      }

      exportReviews.add(
        ExportWeeklyReview(
          id: rw.id,
          weekStart: ExportOperationalDate(rw.weekStart),
          answerFulfilled: rw.answerFulfilled,
          answerFailed: rw.answerFailed,
          answerLesson: rw.answerLesson,
          audioRef: audioRef,
          state: ExportWeeklyReviewState.values.firstWhere(
            (s) => s.name == rw.state,
          ),
          createdAt: _toInstant(rw.createdAt),
          autosavedAt: rw.autosavedAt != null
              ? _toInstant(rw.autosavedAt!)
              : null,
          finalizedAt: rw.finalizedAt != null
              ? _toInstant(rw.finalizedAt!)
              : null,
        ),
      );
    }

    // Manifesto
    final manifestRow = await database
        .select(database.manifests)
        .getSingleOrNull();
    final exportManifest = manifestRow != null
        ? ExportManifest(
            id: manifestRow.id,
            assetVersion: manifestRow.assetVersion,
            firstCopiedAt: _toInstant(manifestRow.firstCopiedAt),
            lastEditedAt: manifestRow.lastEditedAt != null
                ? _toInstant(manifestRow.lastEditedAt!)
                : null,
            contentMarkdown: manifestRow.contentMarkdown,
          )
        : ExportManifest(
            id: 'manifest-default',
            assetVersion: 'v1',
            firstCopiedAt: _toInstant(generatedAt.millisecondsSinceEpoch),
            lastEditedAt: null,
            contentMarkdown: '',
          );

    // Change initiatives
    final initRows = await database.select(database.changeInitiatives).get();
    final exportInits = initRows
        .map(
          (ci) => ExportChangeInitiative(
            id: ci.id,
            name: ci.name,
            active: ci.active,
          ),
        )
        .toList();

    // Audio assets
    final assetRows = await database.select(database.audioAssets).get();
    final exportAssets = assetRows
        .map(
          (a) => ExportAudioAsset(
            id: a.id,
            relativePath: a.relativePath,
            kind: ExportAudioKind.values.firstWhere(
              (k) => k.wireName == a.kind,
            ),
            durationMs: a.durationMs,
            byteSize: a.byteSize,
            createdAt: _toInstant(a.createdAt),
          ),
        )
        .toList();

    // Notification plans
    final planRows = await database.select(database.notificationPlans).get();
    final exportPlans = planRows
        .map(
          (p) => ExportNotificationPlan(
            idempotencyKey: p.idempotencyKey,
            kind: ExportNotificationKind.values.firstWhere(
              (k) => k.wireName == p.kind,
            ),
            plannedAt: _toInstant(p.plannedAt),
            state: ExportNotificationState.values.firstWhere(
              (s) => s.name == p.state,
            ),
          ),
        )
        .toList();

    // Métricas
    var sealedWorkdays = 0;
    var totalWorkdays = 0;
    for (final day in dayRows) {
      final opDate = _parseDate(day.operationalDate);
      final isWorkday = day.muteCause == null && !opDate.isWeekend;
      final countsInMetrics = isWorkday && day.effectiveResult != 'mute';
      if (countsInMetrics) {
        totalWorkdays++;
        if (day.effectiveResult == 'sealed') {
          sealedWorkdays++;
        }
      }
    }
    final exportMetrics = ExportMetricsSnapshot(
      numerator: sealedWorkdays,
      denominator: totalWorkdays,
    );

    return RitmoExportEnvelope(
      generatedAt: _formatInstant(generatedAt),
      settings: exportSettings,
      days: exportDays,
      holidays: exportHolidays,
      protocolAlarms: exportAlarms,
      cycles: exportCycles,
      mentorships: exportMentorships,
      contacts: exportContacts,
      weeklyReviews: exportReviews,
      manifest: exportManifest,
      changeInitiatives: exportInits,
      audioAssets: exportAssets,
      notificationPlans: exportPlans,
      metricsSnapshot: exportMetrics,
    );
  }

  /// Executa a exportação local completa com verificação prévia de espaço e publicação atômica (RNF-05.4, RNF-05.5, RD-27).
  Future<Result<ExportPackageResult, ExportFailure>> exportPackage({
    required Directory targetDirectory,
    required tz.TZDateTime generatedAt,
    bool isPhase3Enabled = true,
    OperationalDate? referenceOperationalDate,
  }) async {
    // 1. Gating da Fase 3 (RA-01.11)
    if (!isPhase3Enabled) {
      return const Result.failure(
        ExportFailure(
          code: 'phase_unavailable',
          message: 'A exportação local está disponível apenas na Fase 3.',
        ),
      );
    }

    final settingsRow = await database
        .select(database.settings)
        .getSingleOrNull();
    if (settingsRow == null) {
      return const Result.failure(
        ExportFailure(
          code: 'missing_settings',
          message: 'Configuração persistida ausente: settings id=1.',
        ),
      );
    }

    try {
      // 2. Monta o envelope em memória
      final envelope = await buildEnvelope(
        generatedAt,
        referenceOperationalDate: referenceOperationalDate,
      );
      final jsonString = envelope.toPrettyJson();
      final jsonBytes = utf8.encode(jsonString).length;

      // 3. Calcula bytes estimados totais (JSON + todos os áudios + 1 MiB de margem)
      var totalAudioBytes = 0;
      for (final asset in envelope.audioAssets) {
        totalAudioBytes += asset.byteSize;
      }
      final requiredBytes = jsonBytes + totalAudioBytes + 1024 * 1024;

      // 4. Verificação prévia de espaço (RNF-05.4)
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }
      final freeBytes = await _diskSpaceChecker.getFreeBytes(
        targetDirectory.path,
      );

      if (freeBytes < requiredBytes) {
        return const Result.failure(
          ExportFailure(
            code: 'insufficient_space',
            message: 'Espaço de armazenamento insuficiente.',
          ),
        );
      }

      // 5. Publicação atômica via diretório de staging (RD-27, RNF-05.5)
      final stagingName =
          '.staging_export_${generatedAt.millisecondsSinceEpoch}';
      final stagingDir = Directory(p.join(targetDirectory.path, stagingName));

      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      await stagingDir.create(recursive: true);

      final finalPackageName =
          'ritmo_export_${generatedAt.millisecondsSinceEpoch}';
      final finalPackageDir = Directory(
        p.join(targetDirectory.path, finalPackageName),
      );

      try {
        // Grava o JSON canônico
        final jsonFile = File(p.join(stagingDir.path, 'ritmo_export.json'));
        await jsonFile.writeAsString(jsonString, flush: true);

        // Copia arquivos de áudio referenciados para subdiretório audio/ (RD-27, RNF-05.5)
        var copiedAudios = 0;
        final stagingAudioDir = Directory(p.join(stagingDir.path, 'audio'));
        if (envelope.audioAssets.isNotEmpty) {
          await stagingAudioDir.create(recursive: true);
          for (final asset in envelope.audioAssets) {
            var srcFile = File(p.join(appDirectory.path, asset.relativePath));
            if (!await srcFile.exists()) {
              final fallbackSrc = File(
                p.join(
                  appDirectory.path,
                  'audio',
                  p.basename(asset.relativePath),
                ),
              );
              if (await fallbackSrc.exists()) {
                srcFile = fallbackSrc;
              }
            }

            if (await srcFile.exists()) {
              final dstFileName = p.basename(asset.relativePath);
              final dstFile = File(p.join(stagingAudioDir.path, dstFileName));
              await srcFile.copy(dstFile.path);
              copiedAudios++;
            }
          }
        }

        // Renomeia o diretório de staging para o pacote final
        if (await finalPackageDir.exists()) {
          await finalPackageDir.delete(recursive: true);
        }
        await stagingDir.rename(finalPackageDir.path);

        final publishedJsonFile = File(
          p.join(finalPackageDir.path, 'ritmo_export.json'),
        );

        return Result.success(
          ExportPackageResult(
            exportDirectory: finalPackageDir,
            jsonFile: publishedJsonFile,
            envelope: envelope,
            audioFileCount: copiedAudios,
            totalBytes: jsonBytes + totalAudioBytes,
          ),
        );
      } catch (error) {
        // Limpa o diretório de staging em caso de falha; nenhum pacote parcial é publicado (RNF-05.4, RNF-05.5)
        if (await stagingDir.exists()) {
          try {
            await stagingDir.delete(recursive: true);
          } catch (_) {}
        }
        return Result.failure(ExportFailure(cause: error));
      }
    } catch (error) {
      return Result.failure(ExportFailure(cause: error));
    }
  }

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  ExportOfficialInstant _toInstant(int millisecondsSinceEpoch) {
    final tzTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
      _businessLocation,
      millisecondsSinceEpoch,
    );
    return _formatInstant(tzTime);
  }

  ExportOfficialInstant _formatInstant(tz.TZDateTime instant) {
    final year = instant.year.toString().padLeft(4, '0');
    final month = instant.month.toString().padLeft(2, '0');
    final day = instant.day.toString().padLeft(2, '0');
    final hour = instant.hour.toString().padLeft(2, '0');
    final minute = instant.minute.toString().padLeft(2, '0');
    final second = instant.second.toString().padLeft(2, '0');
    final offsetMinutes = instant.timeZoneOffset.inMinutes;
    final sign = offsetMinutes.isNegative ? '-' : '+';
    final absHours = (offsetMinutes.abs() ~/ 60).toString().padLeft(2, '0');
    return ExportOfficialInstant(
      '$year-$month-${day}T$hour:$minute:$second$sign$absHours:00',
    );
  }
}
