import 'package:drift/drift.dart';

/// Finalidade e período de um ciclo; awaiting closure permanece derivado.
class Cycles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get purposeText => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get state => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (length(name) <= 120)',
    'CHECK (length(purpose_text) <= 1000)',
    "CHECK (state IN ('active', 'archived'))",
    'CHECK (start_date <= end_date)',
  ];
}
