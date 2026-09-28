import 'package:drift/drift.dart';

import 'days.dart';

/// Reflexão persistida para uma geração de sequência de falha.
class ProtocolAlarms extends Table {
  TextColumn get id => text()();
  TextColumn get generationId => text()();
  @ReferenceName('protocolStart')
  TextColumn get startDate => text().references(Days, #operationalDate)();
  @ReferenceName('protocolEnd')
  TextColumn get endDate => text().references(Days, #operationalDate)();
  IntColumn get sequenceLength => integer()();
  TextColumn get state => text()();
  TextColumn get previousState => text().nullable()();
  IntColumn get triggeredAt => integer().nullable()();
  TextColumn get cause => text().nullable()();
  TextColumn get planOrExecution => text().nullable()();
  TextColumn get adjustment => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (sequence_length >= 2)',
    "CHECK (state IN ('pending', 'answered', 'invalidated'))",
    "CHECK (previous_state IS NULL OR previous_state IN ('pending', 'answered'))",
    "CHECK ((state = 'invalidated') = (previous_state IS NOT NULL))",
    "CHECK (plan_or_execution IS NULL OR plan_or_execution IN ('plan', 'execution'))",
    'CHECK (cause IS NULL OR length(cause) <= 2000)',
    'CHECK (adjustment IS NULL OR length(adjustment) <= 2000)',
    'CHECK (start_date <= end_date)',
  ];
}
