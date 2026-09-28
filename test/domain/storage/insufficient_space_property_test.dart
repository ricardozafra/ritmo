// Feature: ritmo, Property 51: Espaço insuficiente impede gravação e exportação
//
// Para qualquer par (espaço livre estimado, tamanho estimado da operação), a
// gravação de áudio ou a exportação inicia se e somente se o espaço livre é
// suficiente; quando insuficiente, nenhum arquivo parcial é apresentado como
// válido e nenhum dado anterior é alterado.
//
// **Validates: Requirements RNF-05.3, RNF-05.4**

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/export/local_export_service.dart';
import 'package:ritmo/data/repositories/audio_repository.dart';
import 'package:ritmo/data/storage/disk_space_checker.dart';
import 'package:ritmo/domain/audio/audio_policy.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import '../../generators/shared.dart';

typedef _SpaceFixture = ({int freeBytes, AudioKind kind, int audioDurationMs});

final Generator<_SpaceFixture> _anySpaceFixture = any.simple(
  generate: (random, size) {
    // Variação de espaço de 0 até 60 MiB cobrindo faixas abaixo e acima dos limiares
    final freeBytes = random.nextInt(60 * 1024 * 1024);
    final kind = AudioKind.values[random.nextInt(AudioKind.values.length)];
    final durationMs = 1000 + random.nextInt(40 * 60 * 1000);

    return (freeBytes: freeBytes, kind: kind, audioDurationMs: durationMs);
  },
  shrink: (value) sync* {},
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Property 51: Espaço insuficiente impede gravação e exportação', () {
    Glados<_SpaceFixture>(_anySpaceFixture, RitmoGlados.ci()).test(
      'Áudio: Inicia se e somente se espaço livre >= estimado, sem arquivos residuais nem alteração de dados',
      (fixture) async {
        const policy = AudioPolicy();
        final requiredSpace = policy.estimatedBytesFor(fixture.kind);
        final hasSpace = policy.hasSufficientSpace(
          freeBytes: fixture.freeBytes,
          requiredBytes: requiredSpace,
        );

        // 1. Validação da política pura
        expect(hasSpace, equals(fixture.freeBytes >= requiredSpace));

        // 2. Validação no repositório de persistência
        final database = db.RitmoDatabase(NativeDatabase.memory());
        final tempDir = await Directory.systemTemp.createTemp('audio_prop51_');
        final fixedChecker = FixedDiskSpaceChecker(fixture.freeBytes);
        final location = ensureBusinessLocation();
        final now = tz.TZDateTime(location, 2026, 6, 15, 10, 0);

        try {
          final repo = AudioRepository(
            database: database,
            baseDirectory: tempDir,
            diskSpaceChecker: fixedChecker,
            audioPolicy: policy,
            businessLocation: location,
          );

          // Insere previamente um áudio válido para garantir que não seja corrompido
          final initialAudioFile = File(
            '${tempDir.path}/audio/initial_valid.m4a',
          );
          await initialAudioFile.parent.create(recursive: true);
          await initialAudioFile.writeAsString('CONTEUDO_ANTERIOR_VALIDO');

          await database
              .into(database.audioAssets)
              .insert(
                db.AudioAssetsCompanion.insert(
                  id: 'initial-audio-id',
                  relativePath: 'audio/initial_valid.m4a',
                  kind: AudioKind.dayNote.wireValue,
                  durationMs: 60000,
                  byteSize: 26,
                  createdAt: now.millisecondsSinceEpoch,
                ),
              );

          final initialAssetsCount =
              (await database.select(database.audioAssets).get()).length;

          final sampleBytes = List<int>.generate(1024, (i) => i % 256);
          final relativePath = 'audio/test-attempt-${fixture.freeBytes}.m4a';
          final result = await repo.saveAudio(
            id: 'test-attempt-${fixture.freeBytes}',
            kind: fixture.kind,
            relativePath: relativePath,
            durationMs: fixture.audioDurationMs,
            bytes: sampleBytes,
            createdAt: now,
          );

          if (!hasSpace) {
            // Se espaço é insuficiente, deve falhar com código específico e mensagem neutra
            expect(result.isFailure, isTrue);
            final failure =
                (result as Failure<AudioAssetRecord, AudioFailure>).failure;
            expect(failure.code, equals('insufficient_space'));
            expect(
              failure.message,
              equals('Espaço de armazenamento insuficiente.'),
            );

            // Nenhum novo registro adicionado ao banco
            final currentAssets = await database
                .select(database.audioAssets)
                .get();
            expect(currentAssets.length, equals(initialAssetsCount));

            // Nenhum arquivo residual criado
            final attemptFile = File('${tempDir.path}/$relativePath');
            expect(await attemptFile.exists(), isFalse);

            // Arquivo e metadados anteriores permanecem íntegros
            expect(await initialAudioFile.exists(), isTrue);
            expect(
              await initialAudioFile.readAsString(),
              equals('CONTEUDO_ANTERIOR_VALIDO'),
            );
          } else {
            // Se espaço suficiente, gravação é bem sucedida
            expect(result.isSuccess, isTrue);
            final record =
                (result as Success<AudioAssetRecord, AudioFailure>).value;
            final file = await repo.getAudioFile(record.relativePath);
            expect(file, isNotNull);
            expect(await file!.exists(), isTrue);
            expect(record.byteSize, equals(sampleBytes.length));
          }
        } finally {
          await database.close();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    Glados<_SpaceFixture>(_anySpaceFixture, RitmoGlados.ci()).test(
      'Exportação: Bloqueia sem criar pacote parcial quando espaço insuficiente',
      (fixture) async {
        final database = db.RitmoDatabase(NativeDatabase.memory());
        final tempDir = await Directory.systemTemp.createTemp('export_prop51_');
        final targetExportDir = Directory('${tempDir.path}/exports');
        await targetExportDir.create(recursive: true);

        final fixedChecker = FixedDiskSpaceChecker(fixture.freeBytes);
        final location = ensureBusinessLocation();
        final now = tz.TZDateTime(location, 2026, 6, 15, 10, 0);

        try {
          final exportService = LocalExportService(
            database: database,
            appDirectory: tempDir,
            diskSpaceChecker: fixedChecker,
            businessLocation: location,
          );

          // Mede o tamanho real mínimo necessário estimado pelo serviço
          final envelope = await exportService.buildEnvelope(now);
          final jsonLength = envelope.toPrettyJson().length;
          final requiredBytes = jsonLength + 1024 * 1024; // 1 MiB buffer

          final result = await exportService.exportPackage(
            targetDirectory: targetExportDir,
            generatedAt: now,
            isPhase3Enabled: true,
          );

          if (fixture.freeBytes < requiredBytes) {
            // Falha com mensagem neutra
            expect(result.isFailure, isTrue);
            final failure =
                (result as Failure<ExportPackageResult, ExportFailure>).failure;
            expect(failure.code, equals('insufficient_space'));
            expect(
              failure.message,
              equals('Espaço de armazenamento insuficiente.'),
            );

            // Nenhum pacote publicado ou pasta de staging mantida no diretório de destino
            final contents = targetExportDir.listSync();
            expect(contents, isEmpty);
          } else {
            // Sucesso na exportação
            expect(result.isSuccess, isTrue);
            final packageResult =
                (result as Success<ExportPackageResult, ExportFailure>).value;
            expect(await packageResult.exportDirectory.exists(), isTrue);
            expect(await packageResult.jsonFile.exists(), isTrue);
          }
        } finally {
          await database.close();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}
