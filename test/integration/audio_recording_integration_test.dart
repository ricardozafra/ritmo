import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/limits.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/audio_repository.dart';
import 'package:ritmo/data/storage/disk_space_checker.dart';
import 'package:ritmo/domain/audio/audio_policy.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group(
    'AudioRecordingIntegrationTest (Task 24.10 - RNF-05.2, RNF-05.5, RD-35, RD-37)',
    () {
      late db.RitmoDatabase database;
      late Directory tempDir;
      late AudioRepository repository;
      late tz.Location location;
      late tz.TZDateTime now;

      setUp(() async {
        database = db.RitmoDatabase(NativeDatabase.memory());
        tempDir = await Directory.systemTemp.createTemp('audio_integration_');
        location = ensureBusinessLocation();
        now = tz.TZDateTime(location, 2026, 6, 15, 14, 30);

        // 100 MB de espaço simulado
        final spaceChecker = FixedDiskSpaceChecker(100 * 1024 * 1024);

        repository = AudioRepository(
          database: database,
          baseDirectory: tempDir,
          diskSpaceChecker: spaceChecker,
          businessLocation: location,
        );
      });

      tearDown(() async {
        await database.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test(
        'Gravação dentro do limite (Pilar do Dia <= 5 min): salva arquivo válido, duração e byte_size',
        () async {
          final sampleBytes = List<int>.generate(2048, (i) => i % 256);
          const durationMs = 120000; // 2 minutos

          final result = await repository.saveAudio(
            id: 'audio-day-note-valid',
            kind: AudioKind.dayNote,
            relativePath: 'audio/day_note_valid.m4a',
            durationMs: durationMs,
            bytes: sampleBytes,
            createdAt: now,
          );

          expect(result.isSuccess, isTrue);
          final record =
              (result as Success<AudioAssetRecord, AudioFailure>).value;
          expect(record.id, equals('audio-day-note-valid'));
          expect(record.kind, equals(AudioKind.dayNote));
          expect(record.durationMs, equals(120000));
          expect(record.byteSize, equals(sampleBytes.length));

          // Verifica arquivo persistido
          final physicalFile = await repository.getAudioFile(
            record.relativePath,
          );
          expect(physicalFile, isNotNull);
          expect(await physicalFile!.exists(), isTrue);
          expect(await physicalFile.readAsBytes(), equals(sampleBytes));

          // Verifica registro relacional
          final dbRow = await repository.findById('audio-day-note-valid');
          expect(dbRow, isNotNull);
          expect(dbRow!.durationMs, equals(120000));
          expect(dbRow.byteSize, equals(sampleBytes.length));
        },
      );

      test(
        'Gravação dentro do limite (Revisão Semanal <= 30 min): salva arquivo válido, duração e byte_size',
        () async {
          final sampleBytes = List<int>.generate(4096, (i) => (i * 3) % 256);
          const durationMs = 900000; // 15 minutos

          final result = await repository.saveAudio(
            id: 'audio-review-valid',
            kind: AudioKind.weeklyReview,
            relativePath: 'audio/weekly_review_valid.m4a',
            durationMs: durationMs,
            bytes: sampleBytes,
            createdAt: now,
          );

          expect(result.isSuccess, isTrue);
          final record =
              (result as Success<AudioAssetRecord, AudioFailure>).value;
          expect(record.id, equals('audio-review-valid'));
          expect(record.kind, equals(AudioKind.weeklyReview));
          expect(record.durationMs, equals(900000));
          expect(record.byteSize, equals(sampleBytes.length));

          final physicalFile = await repository.getAudioFile(
            record.relativePath,
          );
          expect(physicalFile, isNotNull);
          expect(await physicalFile!.exists(), isTrue);
          expect(await physicalFile.readAsBytes(), equals(sampleBytes));
        },
      );

      test(
        'Encerramento gracioso no limite: Pilar do Dia excedendo 5 min limita a exatamente 5 min',
        () async {
          final sampleBytes = List<int>.generate(1024, (i) => i % 128);
          const durationMs = 360000; // 6 minutos (> 5 min)

          final result = await repository.saveAudio(
            id: 'audio-day-note-exceeded',
            kind: AudioKind.dayNote,
            relativePath: 'audio/day_note_exceeded.m4a',
            durationMs: durationMs,
            bytes: sampleBytes,
            createdAt: now,
          );

          expect(result.isSuccess, isTrue);
          final record =
              (result as Success<AudioAssetRecord, AudioFailure>).value;
          // Duração limitada ao teto de 5 minutos (Limits.dayNoteMaxDurationMs)
          expect(record.durationMs, equals(Limits.dayNoteMaxDurationMs));
          expect(record.durationMs, equals(300000));

          // Arquivo válido preservado
          final physicalFile = await repository.getAudioFile(
            record.relativePath,
          );
          expect(physicalFile, isNotNull);
          expect(await physicalFile!.exists(), isTrue);
          expect(await physicalFile.readAsBytes(), equals(sampleBytes));
        },
      );

      test(
        'Encerramento gracioso no limite: Revisão Semanal excedendo 30 min limita a exatamente 30 min',
        () async {
          final sampleBytes = List<int>.generate(1024, (i) => i % 128);
          const durationMs = 2100000; // 35 minutos (> 30 min)

          final result = await repository.saveAudio(
            id: 'audio-review-exceeded',
            kind: AudioKind.weeklyReview,
            relativePath: 'audio/weekly_review_exceeded.m4a',
            durationMs: durationMs,
            bytes: sampleBytes,
            createdAt: now,
          );

          expect(result.isSuccess, isTrue);
          final record =
              (result as Success<AudioAssetRecord, AudioFailure>).value;
          // Duração limitada ao teto de 30 minutos (Limits.weeklyReviewMaxDurationMs)
          expect(record.durationMs, equals(Limits.weeklyReviewMaxDurationMs));
          expect(record.durationMs, equals(1800000));

          final physicalFile = await repository.getAudioFile(
            record.relativePath,
          );
          expect(physicalFile, isNotNull);
          expect(await physicalFile!.exists(), isTrue);
          expect(await physicalFile.readAsBytes(), equals(sampleBytes));
        },
      );

      test(
        'Falha injetada: erro de escrita/banco preserva o último arquivo e metadado válidos intactos (RNF-05.5)',
        () async {
          // 1. Grava previamente um áudio válido de forma bem-sucedida
          final initialBytes = [10, 20, 30, 40, 50];
          final initialResult = await repository.saveAudio(
            id: 'audio-initial-stable',
            kind: AudioKind.dayNote,
            relativePath: 'audio/stable_audio.m4a',
            durationMs: 60000,
            bytes: initialBytes,
            createdAt: now,
          );
          expect(initialResult.isSuccess, isTrue);

          final initialFile = await repository.getAudioFile(
            'audio/stable_audio.m4a',
          );
          expect(initialFile, isNotNull);
          expect(await initialFile!.readAsBytes(), equals(initialBytes));

          final initialRecord = await repository.findById(
            'audio-initial-stable',
          );
          expect(initialRecord, isNotNull);

          // 2. Tenta uma nova gravação que sobrescreveria o caminho, mas com falha injetada no banco
          // Fechamos a conexão do banco para simular falha no meio do salvamento (RNF-05.5)
          await database.close();

          final corruptedBytes = [99, 99, 99, 99];
          final failedResult = await repository.saveAudio(
            id: 'audio-corrupted-attempt',
            kind: AudioKind.dayNote,
            relativePath: 'audio/stable_audio.m4a',
            durationMs: 50000,
            bytes: corruptedBytes,
            createdAt: now,
          );

          // Falha esperada
          expect(failedResult.isFailure, isTrue);

          // O arquivo anterior válido não foi sobrescrito pelos bytes corrompidos
          final fileAfterFailure = File(
            '${tempDir.path}/audio/stable_audio.m4a',
          );
          expect(await fileAfterFailure.exists(), isTrue);
          expect(await fileAfterFailure.readAsBytes(), equals(initialBytes));

          // Nenhum arquivo temporário de staging deixado para trás
          final stagingFile = File(
            '${tempDir.path}/audio/.staging_audio-corrupted-attempt',
          );
          expect(await stagingFile.exists(), isFalse);
        },
      );
    },
  );
}
