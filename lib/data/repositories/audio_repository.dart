import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/audio/audio_policy.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../storage/disk_space_checker.dart';

/// Registro de domínio para metadados de áudio local (RD-37).
final class AudioAssetRecord {
  const AudioAssetRecord({
    required this.id,
    required this.relativePath,
    required this.kind,
    required this.durationMs,
    required this.byteSize,
    required this.createdAt,
  });

  final String id;
  final String relativePath;
  final AudioKind kind;
  final int durationMs;
  final int byteSize;
  final tz.TZDateTime createdAt;
}

/// Repositório de áudio local e integridade de arquivos em diretório privado (RD-35, RD-37, RNF-05.2, RNF-05.3, RNF-05.5).
final class AudioRepository {
  AudioRepository({
    required this.database,
    required this.baseDirectory,
    DiskSpaceChecker? diskSpaceChecker,
    AudioPolicy? audioPolicy,
    tz.Location? businessLocation,
  }) : _diskSpaceChecker = diskSpaceChecker ?? const SystemDiskSpaceChecker(),
       _audioPolicy = audioPolicy ?? const AudioPolicy(),
       _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase database;
  final Directory baseDirectory;
  final DiskSpaceChecker _diskSpaceChecker;
  final AudioPolicy _audioPolicy;
  final tz.Location _businessLocation;

  Directory get audioDirectory => Directory(p.join(baseDirectory.path, 'audio'));

  /// Salva um novo arquivo de áudio com verificação prévia de espaço,
  /// encerramento gracioso no limite e preservação do arquivo anterior em caso de falha.
  Future<Result<AudioAssetRecord, AudioFailure>> saveAudio({
    required String id,
    required AudioKind kind,
    required String relativePath,
    required int durationMs,
    required List<int> bytes,
    required tz.TZDateTime createdAt,
    String? targetPillarDate,
    String? targetWeeklyReviewId,
  }) async {
    // 1. Verificação prévia de espaço (RNF-05.3)
    final audioDir = audioDirectory;
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final freeBytes = await _diskSpaceChecker.getFreeBytes(audioDir.path);
    final requiredBytes = _audioPolicy.estimatedBytesFor(kind);

    if (!_audioPolicy.hasSufficientSpace(
      freeBytes: freeBytes,
      requiredBytes: requiredBytes,
    )) {
      return const Result.failure(
        AudioFailure(
          code: 'insufficient_space',
          message: 'Espaço de armazenamento insuficiente.',
        ),
      );
    }

    // 2. Encerramento gracioso no limite de duração (RNF-05.2, RD-35)
    final clampedDuration = _audioPolicy.clampDuration(kind, durationMs);
    final byteSize = bytes.length;

    if (clampedDuration <= 0 || byteSize <= 0) {
      return const Result.failure(
        AudioFailure(
          code: 'invalid_audio_data',
          message: 'Dados de áudio inválidos.',
        ),
      );
    }

    // 3. Gravação atômica em arquivo de staging (RNF-05.5)
    final stagingFile = File(p.join(audioDir.path, '.staging_$id'));
    final targetFile = File(p.join(baseDirectory.path, relativePath));

    try {
      await stagingFile.parent.create(recursive: true);
      await targetFile.parent.create(recursive: true);
      await stagingFile.writeAsBytes(bytes, flush: true);

      // 4. Persistência relacional em transação (RNF-05.5)
      await database.transaction(() async {
        await database.into(database.audioAssets).insert(
          db.AudioAssetsCompanion.insert(
            id: id,
            relativePath: relativePath,
            kind: kind.wireValue,
            durationMs: clampedDuration,
            byteSize: byteSize,
            createdAt: createdAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );

        if (targetPillarDate != null) {
          await (database.update(database.pillarEntries)
                ..where(
                  (r) =>
                      r.operationalDate.equals(targetPillarDate) &
                      r.pillar.equals('day'),
                ))
              .write(
                db.PillarEntriesCompanion(
                  noteAudioId: Value(id),
                ),
              );
        }

        if (targetWeeklyReviewId != null) {
          await (database.update(database.weeklyReviews)
                ..where((r) => r.id.equals(targetWeeklyReviewId)))
              .write(
                db.WeeklyReviewsCompanion(
                  audioId: Value(id),
                ),
              );
        }
      });

      // 5. Sucesso: move staging para destino final
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await stagingFile.rename(targetFile.path);

      final record = AudioAssetRecord(
        id: id,
        relativePath: relativePath,
        kind: kind,
        durationMs: clampedDuration,
        byteSize: byteSize,
        createdAt: createdAt,
      );

      return Result.success(record);
    } catch (error) {
      // Em caso de falha, descarta arquivo de staging para preservar dados anteriores intactos
      if (await stagingFile.exists()) {
        try {
          await stagingFile.delete();
        } catch (_) {}
      }
      return Result.failure(AudioFailure(cause: error));
    }
  }

  /// Recupera o arquivo físico do áudio em diretório privado.
  Future<File?> getAudioFile(String relativePath) async {
    final file = File(p.join(baseDirectory.path, relativePath));
    if (await file.exists()) return file;
    return null;
  }

  /// Busca metadados do áudio por identificador.
  Future<AudioAssetRecord?> findById(String id) async {
    final row = await (database.select(database.audioAssets)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toRecord(row);
  }

  /// Observa todos os áudios locais persistidos.
  Stream<List<AudioAssetRecord>> watchAll() =>
      database.select(database.audioAssets).watch().map(
            (rows) => rows.map(_toRecord).toList(),
          );

  AudioAssetRecord _toRecord(db.AudioAsset row) => AudioAssetRecord(
    id: row.id,
    relativePath: row.relativePath,
    kind: AudioKind.fromWire(row.kind) ?? AudioKind.dayNote,
    durationMs: row.durationMs,
    byteSize: row.byteSize,
    createdAt: tz.TZDateTime.fromMillisecondsSinceEpoch(
      _businessLocation,
      row.createdAt,
    ),
  );
}
