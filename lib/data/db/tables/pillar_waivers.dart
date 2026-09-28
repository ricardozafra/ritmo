import 'package:drift/drift.dart';

import 'days.dart';

/// Dispensa de um único pilar, preservada após eventual revogação.
class PillarWaivers extends Table {
  TextColumn get id => text()();
  TextColumn get date => text().references(Days, #operationalDate)();
  TextColumn get pillar => text()();
  TextColumn get reasonText => text()();
  BoolColumn get recurrenceConfirmed =>
      boolean().withDefault(const Constant(false))();
  IntColumn get revokedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (pillar IN ('morning', 'day', 'night'))",
    'CHECK (length(trim(reason_text)) > 0)',
    'CHECK (length(reason_text) <= 500)',
  ];
}
