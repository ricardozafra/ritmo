import 'package:drift/drift.dart';

/// Estado persistido de uma data operacional, com lifecycle separado do resultado.
class Days extends Table {
  TextColumn get operationalDate => text()();
  TextColumn get baseResult => text()();
  TextColumn get effectiveResult => text()();
  IntColumn get closedAt => integer().nullable()();
  IntColumn get sealTimestamp => integer().nullable()();
  TextColumn get muteCause => text().nullable()();
  TextColumn get previousResult => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {operationalDate};

  @override
  List<String> get customConstraints => const [
    "CHECK (base_result IN ('sealed', 'unsealed'))",
    "CHECK (effective_result IN ('sealed', 'unsealed', 'mute'))",
    "CHECK (mute_cause IS NULL OR mute_cause IN ('weekend', 'holiday'))",
    "CHECK (previous_result IS NULL OR previous_result IN ('sealed', 'unsealed'))",
    "CHECK ((effective_result = 'mute') = (mute_cause IS NOT NULL))",
    "CHECK (mute_cause IS NULL OR mute_cause <> 'holiday' OR previous_result IS NOT NULL)",
    "CHECK ((base_result = 'sealed') = (seal_timestamp IS NOT NULL))",
    'CHECK (mute_cause IS NOT NULL OR effective_result = base_result)',
  ];
}
