import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/seal_eligibility.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';

/// Persistência tipada dos três registros de pilar de uma data operacional.
///
/// As mutações passam pela guarda diária e convergem pela chave única
/// `(operational_date, pillar)`. O lifecycle de StudyBlock fica fora daqui.
final class PillarEntriesRepository {
  PillarEntriesRepository(
    db.RitmoDatabase database, {
    GuardedDayWriter? writer,
    tz.Location? businessLocation,
  }) : _database = database,
       _writer = writer ?? GuardedDayWriter(database),
       _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final GuardedDayWriter _writer;
  final tz.Location _businessLocation;

  Future<PillarEntriesSnapshot> entriesForDate(OperationalDate date) async {
    final rows = await (_database.select(
      _database.pillarEntries,
    )..where((entry) => entry.operationalDate.equals(date.iso))).get();
    db.PillarEntry? find(Pillar pillar) {
      for (final row in rows) {
        if (row.pillar == pillar.name) return row;
      }
      return null;
    }

    final morning = find(Pillar.morning);
    final daily = find(Pillar.day);
    final night = find(Pillar.night);
    return PillarEntriesSnapshot(
      morning: morning == null ? null : _morning(morning),
      day: daily == null ? null : _day(daily),
      night: night == null ? null : _night(night),
    );
  }

  Future<PillarStatus> statusForDate(OperationalDate date) async {
    final entries = await entriesForDate(date);
    final activeWaiver =
        await (_database.select(_database.pillarWaivers)..where(
              (waiver) =>
                  waiver.date.equals(date.iso) & waiver.revokedAt.isNull(),
            ))
            .getSingleOrNull();
    final studyBlockId = entries.night?.studyBlockId;
    var linkedStudyEnded = false;
    if (studyBlockId != null) {
      final block =
          await (_database.select(_database.studyBlocks)..where(
                (block) =>
                    block.id.equals(studyBlockId) &
                    block.operationalDate.equals(date.iso),
              ))
              .getSingleOrNull();
      linkedStudyEnded = block?.endedAt != null;
    }

    return PillarRules.status(
      entries,
      activeWaiver: activeWaiver == null ? null : _pillar(activeWaiver.pillar),
      linkedStudyEnded: linkedStudyEnded,
    );
  }

  Future<Result<MorningEntry, DayViolation>> completeWorkout(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) => _writeEntry(
    date,
    Pillar.morning,
    db.PillarEntriesCompanion(
      workoutDone: const Value(true),
      workoutAt: Value(at.millisecondsSinceEpoch),
    ),
    () async => (await entriesForDate(date)).morning!,
  );

  /// Deve ser chamado exclusivamente pelo evento de fim natural do MP3 local.
  Future<Result<MorningEntry, DayViolation>> completeBriefingFromLocalMp3End(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) => _completeBriefing(date, BriefingCompletion.automatic, at);

  /// Conclusão imediata: não recebe início nem duração, portanto zero é válido.
  Future<Result<MorningEntry, DayViolation>> completeBriefingManually(
    OperationalDate date, {
    required tz.TZDateTime at,
  }) => _completeBriefing(date, BriefingCompletion.manual, at);

  Future<Result<MorningEntry, DayViolation>> _completeBriefing(
    OperationalDate date,
    BriefingCompletion mode,
    tz.TZDateTime at,
  ) => _writeEntry(
    date,
    Pillar.morning,
    db.PillarEntriesCompanion(
      briefingDone: const Value(true),
      briefingMode: Value(mode.name),
      briefingAt: Value(at.millisecondsSinceEpoch),
    ),
    () async => (await entriesForDate(date)).morning!,
  );

  /// Persiste o toggle e sua nota opcional; somente o toggle conclui o pilar.
  ///
  /// A iniciativa ativa é capturada apenas ao criar a entrada. Atualizações
  /// posteriores nunca reatribuem o vínculo histórico.
  Future<Result<DayEntry, DayViolation>> recordDay(
    OperationalDate date, {
    required bool toggleOn,
    String? note,
  }) => _writer.write<DayEntry>(
    operationalDate: date.iso,
    write: () async {
      final existing =
          await (_database.select(_database.pillarEntries)..where(
                (entry) =>
                    entry.operationalDate.equals(date.iso) &
                    entry.pillar.equals(Pillar.day.name),
              ))
              .getSingleOrNull();
      if (existing == null) {
        final activeInitiative =
            await (_database.select(_database.changeInitiatives)
                  ..where((initiative) => initiative.active.equals(true)))
                .getSingleOrNull();
        await _database
            .into(_database.pillarEntries)
            .insert(
              db.PillarEntriesCompanion.insert(
                operationalDate: date.iso,
                pillar: Pillar.day.name,
                changeInitiativeId: Value(activeInitiative?.id),
              ),
            );
      }
      await (_database.update(_database.pillarEntries)..where(
            (entry) =>
                entry.operationalDate.equals(date.iso) &
                entry.pillar.equals(Pillar.day.name),
          ))
          .write(
            db.PillarEntriesCompanion(
              toggleOn: Value(toggleOn),
              noteText: Value(note),
            ),
          );
      return (await entriesForDate(date)).day!;
    },
  );

  /// Confirma Recuperação sem criar timer ou exigir duração mínima.
  Future<Result<NightEntry, DayViolation>> confirmRecovery(
    OperationalDate date, {
    String? note,
  }) => _writeEntry(
    date,
    Pillar.night,
    db.PillarEntriesCompanion(
      nightKind: const Value('recovery'),
      recoveryNote: Value(note),
      studyBlockId: const Value(null),
    ),
    () async => (await entriesForDate(date)).night!,
  );

  Future<Result<T, DayViolation>> _writeEntry<T>(
    OperationalDate date,
    Pillar pillar,
    db.PillarEntriesCompanion changes,
    Future<T> Function() readBack,
  ) => _writer.write<T>(
    operationalDate: date.iso,
    write: () async {
      await _database
          .into(_database.pillarEntries)
          .insert(
            db.PillarEntriesCompanion.insert(
              operationalDate: date.iso,
              pillar: pillar.name,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await (_database.update(_database.pillarEntries)..where(
            (entry) =>
                entry.operationalDate.equals(date.iso) &
                entry.pillar.equals(pillar.name),
          ))
          .write(changes);
      return readBack();
    },
  );

  MorningEntry _morning(db.PillarEntry row) => MorningEntry(
    workoutDone: row.workoutDone,
    briefingDone: row.briefingDone,
    briefingMode: switch (row.briefingMode) {
      'automatic' => BriefingCompletion.automatic,
      'manual' => BriefingCompletion.manual,
      _ => null,
    },
    workoutAt: _instant(row.workoutAt),
    briefingAt: _instant(row.briefingAt),
  );
  DayEntry _day(db.PillarEntry row) => DayEntry(
    toggleOn: row.toggleOn,
    changeInitiativeId: row.changeInitiativeId,
    note: row.noteText,
    noteAudioId: row.noteAudioId,
  );

  NightEntry _night(db.PillarEntry row) => NightEntry(
    kind: switch (row.nightKind) {
      'study' => NightKind.study,
      'recovery' => NightKind.recovery,
      _ => null,
    },
    recoveryNote: row.recoveryNote,
    studyBlockId: row.studyBlockId,
  );

  Pillar _pillar(String value) => switch (value) {
    'morning' => Pillar.morning,
    'day' => Pillar.day,
    'night' => Pillar.night,
    _ => throw StateError('Pilar persistido inválido: $value'),
  };

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : tz.TZDateTime.fromMillisecondsSinceEpoch(
          _businessLocation,
          millisecondsSinceEpoch,
        );
}
