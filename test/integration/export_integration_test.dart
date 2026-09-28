import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/export/local_export_service.dart';
import 'package:ritmo/data/storage/disk_space_checker.dart';
import 'package:ritmo/domain/audio/audio_policy.dart';
import 'package:ritmo/domain/export/export_envelope.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ExportIntegrationTest (Task 24.11 - RA-01.11, RD-27, RNF-05.4, RNF-05.5)', () {
    late db.RitmoDatabase database;
    late Directory appDir;
    late Directory exportTargetDir;
    late LocalExportService exportService;
    late tz.Location location;
    late tz.TZDateTime now;

    setUp(() async {
      database = db.RitmoDatabase(NativeDatabase.memory());
      appDir = await Directory.systemTemp.createTemp('ritmo_app_test_');
      exportTargetDir = await Directory.systemTemp.createTemp(
        'ritmo_export_target_',
      );
      location = ensureBusinessLocation();
      now = tz.TZDateTime(location, 2026, 6, 15, 12, 0);

      // 500 MB simulados
      final spaceChecker = FixedDiskSpaceChecker(500 * 1024 * 1024);

      exportService = LocalExportService(
        database: database,
        appDirectory: appDir,
        diskSpaceChecker: spaceChecker,
        businessLocation: location,
      );

      // Manifesto
      await database
          .into(database.manifests)
          .insert(
            db.ManifestsCompanion.insert(
              id: 'manifest-001',
              assetVersion: 'v1.0.0',
              firstCopiedAt: now.millisecondsSinceEpoch,
              lastEditedAt: Value(now.millisecondsSinceEpoch),
              contentMarkdown: '# Manifesto do Ritmo\nFoco e soberania.',
            ),
          );

      // Ciclo e Checkpoint (limpa seed antes de inserir customizado)
      await database.delete(database.checkpointEvals).go();
      await database.delete(database.checkpoints).go();
      await database.delete(database.cycles).go();

      await database
          .into(database.cycles)
          .insert(
            db.CyclesCompanion.insert(
              id: 'cycle-001',
              name: 'Ciclo 2026/2027',
              purposeText: 'Finalidade Estratégica',
              startDate: '2026-01-01',
              endDate: '2027-06-30',
              state: 'active',
            ),
          );

      await database
          .into(database.checkpoints)
          .insert(
            db.CheckpointsCompanion.insert(
              id: 'cp-001',
              cycleId: 'cycle-001',
              competency: 'ST',
              date: '2026-06-30',
              status: 'pending',
            ),
          );

      // Cria arquivos de áudio físicos e registros
      final dayAudioBytes = [1, 2, 3, 4, 5, 6, 7, 8];
      final dayAudioFile = File(p.join(appDir.path, 'audio', 'day_audio.m4a'));
      await dayAudioFile.parent.create(recursive: true);
      await dayAudioFile.writeAsBytes(dayAudioBytes);

      await database
          .into(database.audioAssets)
          .insert(
            db.AudioAssetsCompanion.insert(
              id: 'audio-asset-day',
              relativePath: 'audio/day_audio.m4a',
              kind: AudioKind.dayNote.wireValue,
              durationMs: 45000,
              byteSize: dayAudioBytes.length,
              createdAt: now.millisecondsSinceEpoch,
            ),
          );

      // Dia e pilar apontando para o áudio
      await database
          .into(database.days)
          .insert(
            db.DaysCompanion.insert(
              operationalDate: '2026-06-15',
              baseResult: 'sealed',
              effectiveResult: 'sealed',
              sealTimestamp: Value(now.millisecondsSinceEpoch),
            ),
          );

      await database
          .into(database.pillarEntries)
          .insert(
            db.PillarEntriesCompanion.insert(
              operationalDate: '2026-06-15',
              pillar: 'day',
              workoutDone: const Value(true),
              briefingDone: const Value(true),
              briefingMode: const Value('manual'),
              noteAudioId: const Value('audio-asset-day'),
              noteText: const Value('Nota textual do dia.'),
            ),
          );
    });

    tearDown(() async {
      await database.close();
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }
      if (await exportTargetDir.exists()) {
        await exportTargetDir.delete(recursive: true);
      }
    });

    test(
      'Fase gating: falha se exportação for acionada fora da Fase 3',
      () async {
        final result = await exportService.exportPackage(
          targetDirectory: exportTargetDir,
          generatedAt: now,
          isPhase3Enabled: false,
        );

        expect(result.isFailure, isTrue);
        final failure =
            (result as Failure<ExportPackageResult, ExportFailure>).failure;
        expect(failure.code, equals('phase_unavailable'));
        expect(failure.message, contains('Fase 3'));

        // Nenhum arquivo criado no diretório de destino
        expect(exportTargetDir.listSync(), isEmpty);
      },
    );

    test(
      'Exportação completa: gera JSON canônico e copia áudios para pasta audio/',
      () async {
        final result = await exportService.exportPackage(
          targetDirectory: exportTargetDir,
          generatedAt: now,
          isPhase3Enabled: true,
        );

        expect(result.isSuccess, isTrue);
        final package =
            (result as Success<ExportPackageResult, ExportFailure>).value;

        // 1. Diretório do pacote publicado
        expect(await package.exportDirectory.exists(), isTrue);
        expect(
          p.basename(package.exportDirectory.path),
          startsWith('ritmo_export_'),
        );

        // 2. Valida arquivo JSON contra o contrato canônico RitmoExportEnvelope
        expect(await package.jsonFile.exists(), isTrue);
        final jsonString = await package.jsonFile.readAsString();
        final decodedMap = json.decode(jsonString) as Map<String, Object?>;

        final parsedEnvelope = RitmoExportEnvelope.fromJson(decodedMap);
        expect(decodedMap['schema'], equals('ritmo.export'));
        expect(decodedMap['schema_version'], equals(1));
        expect(parsedEnvelope.manifest.id, equals('manifest-001'));
        expect(
          parsedEnvelope.manifest.contentMarkdown,
          contains('Manifesto do Ritmo'),
        );
        expect(parsedEnvelope.cycles.length, equals(1));
        expect(parsedEnvelope.cycles.first.id, equals('cycle-001'));
        expect(parsedEnvelope.cycles.first.derived.awaitingClosure, isFalse);
        expect(parsedEnvelope.days.length, equals(1));
        expect(
          parsedEnvelope.days.first.operationalDate.value,
          equals('2026-06-15'),
        );
        expect(parsedEnvelope.audioAssets.length, equals(1));
        expect(parsedEnvelope.audioAssets.first.id, equals('audio-asset-day'));

        // 3. Valida cópia física do áudio
        final targetAudioDir = Directory(
          p.join(package.exportDirectory.path, 'audio'),
        );
        expect(await targetAudioDir.exists(), isTrue);

        final exportedAudioFile = File(
          p.join(package.exportDirectory.path, 'audio', 'day_audio.m4a'),
        );
        expect(await exportedAudioFile.exists(), isTrue);
        expect(
          await exportedAudioFile.readAsBytes(),
          equals([1, 2, 3, 4, 5, 6, 7, 8]),
        );
        expect(package.audioFileCount, equals(1));

        // 4. Garante que nenhuma pasta de staging permaneceu
        final stagingEntities = exportTargetDir.listSync().where(
          (e) => p.basename(e.path).startsWith('.staging_'),
        );
        expect(stagingEntities, isEmpty);
      },
    );

    test(
      'Falha injetada: aborta sem deixar pacote parcial ou pasta staging corrompida',
      () async {
        // Cria previamente um pacote válido para verificar integridade anterior
        final priorValidPackage = Directory(
          p.join(exportTargetDir.path, 'prior_valid_package'),
        );
        await priorValidPackage.create();
        final priorFile = File(p.join(priorValidPackage.path, 'manifest.txt'));
        await priorFile.writeAsString('DADO_ANTERIOR_INTACTO');

        // Simula espaço insuficiente forçado para abortar a exportação
        final lowSpaceService = LocalExportService(
          database: database,
          appDirectory: appDir,
          diskSpaceChecker: FixedDiskSpaceChecker(
            10,
          ), // Apenas 10 bytes livres!
          businessLocation: location,
        );

        final result = await lowSpaceService.exportPackage(
          targetDirectory: exportTargetDir,
          generatedAt: now,
          isPhase3Enabled: true,
        );

        expect(result.isFailure, isTrue);
        final failure =
            (result as Failure<ExportPackageResult, ExportFailure>).failure;
        expect(failure.code, equals('insufficient_space'));

        // Pacote anterior permanece íntegro
        expect(await priorValidPackage.exists(), isTrue);
        expect(await priorFile.readAsString(), equals('DADO_ANTERIOR_INTACTO'));

        // Nenhum pacote parcial novo nem diretório .staging_ criado ou mantido
        final exportedPackages = exportTargetDir.listSync().where(
          (e) => p.basename(e.path).startsWith('ritmo_export_'),
        );
        expect(exportedPackages, isEmpty);

        final stagingPackages = exportTargetDir.listSync().where(
          (e) => p.basename(e.path).startsWith('.staging_'),
        );
        expect(stagingPackages, isEmpty);
      },
    );

    test(
      'Ciclos no envelope: awaitingClosure é derivado via CyclePolicy (ativo com checkpoint vencido vs em dia vs arquivado)',
      () async {
        // 1. cycle-001 ativo com checkpoint futuro (2026-06-30 > 2026-06-15) -> em dia (false)
        final envelopeInDue = await exportService.buildEnvelope(now);
        final cycleInDue = envelopeInDue.cycles.firstWhere(
          (c) => c.id == 'cycle-001',
        );
        expect(cycleInDue.derived.awaitingClosure, isFalse);

        // 2. Atualiza checkpoint para o passado (2026-05-01 < 2026-06-15) -> aguardando encerramento (true)
        await (database.update(database.checkpoints)
              ..where((tbl) => tbl.id.equals('cp-001')))
            .write(const db.CheckpointsCompanion(date: Value('2026-05-01')));

        final envelopeExpired = await exportService.buildEnvelope(now);
        final cycleExpired = envelopeExpired.cycles.firstWhere(
          (c) => c.id == 'cycle-001',
        );
        expect(cycleExpired.derived.awaitingClosure, isTrue);

        // 3. Quando o ciclo é arquivado, awaitingClosure volta a ser false mesmo com checkpoint passado
        await (database.update(database.cycles)
              ..where((tbl) => tbl.id.equals('cycle-001')))
            .write(const db.CyclesCompanion(state: Value('archived')));

        final envelopeArchived = await exportService.buildEnvelope(now);
        final cycleArchived = envelopeArchived.cycles.firstWhere(
          (c) => c.id == 'cycle-001',
        );
        expect(cycleArchived.derived.awaitingClosure, isFalse);
      },
    );

    test(
      'Settings ausente: falha explicitamente em buildEnvelope e exportPackage (sem fallback fictício)',
      () async {
        // Remove settings singleton para simular persistência corrompida / ausente
        await database.delete(database.settings).go();

        // 1. buildEnvelope lança StateError
        expect(
          () => exportService.buildEnvelope(now),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Configuração persistida ausente: settings id=1.'),
            ),
          ),
        );

        // 2. exportPackage retorna Result.failure com código 'missing_settings'
        final result = await exportService.exportPackage(
          targetDirectory: exportTargetDir,
          generatedAt: now,
          isPhase3Enabled: true,
        );

        expect(result.isFailure, isTrue);
        final failure =
            (result as Failure<ExportPackageResult, ExportFailure>).failure;
        expect(failure.code, equals('missing_settings'));
        expect(failure.message, contains('settings id=1'));
      },
    );

    test(
      'Cópia de áudio consistente: múltiplos áudios são publicados sob audio/ com audioFileCount exato',
      () async {
        // Adiciona um segundo arquivo de áudio físico e registro
        final reviewAudioBytes = [10, 20, 30, 40, 50];
        final reviewAudioFile = File(
          p.join(appDir.path, 'audio', 'weekly_review.m4a'),
        );
        await reviewAudioFile.parent.create(recursive: true);
        await reviewAudioFile.writeAsBytes(reviewAudioBytes);

        await database
            .into(database.audioAssets)
            .insert(
              db.AudioAssetsCompanion.insert(
                id: 'audio-asset-review',
                relativePath: 'audio/weekly_review.m4a',
                kind: AudioKind.weeklyReview.wireValue,
                durationMs: 120000,
                byteSize: reviewAudioBytes.length,
                createdAt: now.millisecondsSinceEpoch,
              ),
            );

        final result = await exportService.exportPackage(
          targetDirectory: exportTargetDir,
          generatedAt: now,
          isPhase3Enabled: true,
        );

        expect(result.isSuccess, isTrue);
        final package =
            (result as Success<ExportPackageResult, ExportFailure>).value;

        // Contagem exata de áudios
        expect(package.audioFileCount, equals(2));

        // Subdiretório audio/ existe e contém exatamente os arquivos de áudio
        final audioDir = Directory(
          p.join(package.exportDirectory.path, 'audio'),
        );
        expect(await audioDir.exists(), isTrue);

        final exportedDayAudio = File(p.join(audioDir.path, 'day_audio.m4a'));
        final exportedReviewAudio = File(
          p.join(audioDir.path, 'weekly_review.m4a'),
        );

        expect(await exportedDayAudio.exists(), isTrue);
        expect(await exportedReviewAudio.exists(), isTrue);
        expect(
          await exportedDayAudio.readAsBytes(),
          equals([1, 2, 3, 4, 5, 6, 7, 8]),
        );
        expect(
          await exportedReviewAudio.readAsBytes(),
          equals(reviewAudioBytes),
        );

        // O envelope contém os dois registros
        expect(package.envelope.audioAssets.length, equals(2));
      },
    );
  });
}
