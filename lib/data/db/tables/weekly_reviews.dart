import 'package:drift/drift.dart';

import 'audio_assets.dart';

/// Revisão semanal editável enquanto draft e imutável após finalização.
class WeeklyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get weekStart => text()();
  TextColumn get answerFulfilled => text().nullable()();
  TextColumn get answerFailed => text().nullable()();
  TextColumn get answerLesson => text().nullable()();
  TextColumn get audioId => text().nullable().references(AudioAssets, #id)();
  TextColumn get state => text().withDefault(const Constant('draft'))();
  IntColumn get createdAt => integer()();
  IntColumn get autosavedAt => integer().nullable()();
  IntColumn get finalizedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {weekStart},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (answer_fulfilled IS NULL OR length(answer_fulfilled) <= 5000)',
    'CHECK (answer_failed IS NULL OR length(answer_failed) <= 5000)',
    'CHECK (answer_lesson IS NULL OR length(answer_lesson) <= 5000)',
    "CHECK (state IN ('draft', 'finalized'))",
    "CHECK ((state = 'finalized') = (finalized_at IS NOT NULL))",
  ];
}
