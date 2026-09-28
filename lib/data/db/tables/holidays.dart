import 'package:drift/drift.dart';

import 'days.dart';

/// Feriado manual auditável; remoções desativam o registro sem apagá-lo.
class Holidays extends Table {
  TextColumn get operationalDate => text().references(Days, #operationalDate)();
  BoolColumn get active => boolean()();
  IntColumn get createdAt => integer()();
  IntColumn get removedAt => integer().nullable()();
  TextColumn get applyReasonText => text().nullable()();
  TextColumn get removeReasonText => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {operationalDate};

  @override
  List<String> get customConstraints => const [
    'CHECK (apply_reason_text IS NULL OR length(apply_reason_text) <= 500)',
    'CHECK (remove_reason_text IS NULL OR length(remove_reason_text) <= 500)',
  ];
}
