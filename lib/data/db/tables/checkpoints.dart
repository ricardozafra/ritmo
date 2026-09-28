import 'package:drift/drift.dart';

import 'cycles.dart';

/// Marco datado de uma competência pertencente a um ciclo.
class Checkpoints extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get competency => text()();
  TextColumn get date => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (competency IN ('ST', 'IN', 'CA'))",
  ];
}
