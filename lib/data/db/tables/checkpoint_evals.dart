import 'package:drift/drift.dart';

import 'checkpoints.dart';
import 'weekly_reviews.dart';

/// Autoavaliação de competência, opcionalmente ligada a uma revisão semanal.
class CheckpointEvals extends Table {
  TextColumn get id => text()();
  TextColumn get checkpointId => text().references(Checkpoints, #id)();
  TextColumn get weeklyReviewId =>
      text().nullable().references(WeeklyReviews, #id)();
  TextColumn get gartnerLevel => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (gartner_level IN ('BD', 'B', 'I', 'A', 'E'))",
    'CHECK (notes IS NULL OR length(notes) <= 2000)',
  ];
}
