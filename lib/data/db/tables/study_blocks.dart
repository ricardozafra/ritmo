import 'package:drift/drift.dart';

import 'days.dart';

/// Bloco de Estudo sem estado ou duração acumulada.
class StudyBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get operationalDate =>
      text().references(Days, #operationalDate)();
  IntColumn get startedAt => integer()();
  IntColumn get blockDeadline => integer()();
  IntColumn get endedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (started_at <= block_deadline)',
    'CHECK (ended_at IS NULL OR (ended_at >= started_at AND ended_at <= block_deadline))',
  ];
}
