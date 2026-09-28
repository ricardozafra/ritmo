import 'package:drift/drift.dart';

import 'cycles.dart';

/// Registro lógico que limita o convite de encerramento a uma vez por semana.
class CycleClosureInvites extends Table {
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get weekStart => text()();

  @override
  Set<Column<Object>> get primaryKey => {cycleId, weekStart};
}
