import 'package:drift/drift.dart';

import 'audio_assets.dart';
import 'change_initiatives.dart';
import 'days.dart';
import 'study_blocks.dart';

/// Registro de exatamente um dos três pilares em uma data operacional.
class PillarEntries extends Table {
  TextColumn get operationalDate =>
      text().references(Days, #operationalDate)();
  TextColumn get pillar => text()();

  BoolColumn get workoutDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get briefingDone =>
      boolean().withDefault(const Constant(false))();
  TextColumn get briefingMode => text().nullable()();
  IntColumn get workoutAt => integer().nullable()();
  IntColumn get briefingAt => integer().nullable()();

  BoolColumn get toggleOn =>
      boolean().withDefault(const Constant(false))();
  TextColumn get changeInitiativeId =>
      text().nullable().references(ChangeInitiatives, #id)();
  TextColumn get noteText => text().nullable()();
  TextColumn get noteAudioId =>
      text().nullable().references(AudioAssets, #id)();

  TextColumn get nightKind => text().nullable()();
  TextColumn get recoveryNote => text().nullable()();
  TextColumn get studyBlockId =>
      text().nullable().references(StudyBlocks, #id)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {operationalDate, pillar},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (pillar IN ('morning', 'day', 'night'))",
    "CHECK (briefing_mode IS NULL OR briefing_mode IN ('automatic', 'manual'))",
    'CHECK (note_text IS NULL OR length(note_text) <= 500)',
    "CHECK (night_kind IS NULL OR night_kind IN ('study', 'recovery'))",
    'CHECK (recovery_note IS NULL OR length(recovery_note) <= 500)',
  ];
}
