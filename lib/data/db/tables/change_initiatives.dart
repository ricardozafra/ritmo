import 'package:drift/drift.dart';

/// Iniciativa de mudança; índice parcial limita a uma linha ativa.
class ChangeInitiatives extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (length(name) <= 120)',
  ];
}
