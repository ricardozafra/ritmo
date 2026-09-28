import 'package:drift/drift.dart';

/// Contato explícito para o rodízio semanal, sem vínculo com mentoria.
class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get contextNote => text().nullable()();
  TextColumn get lastTouchDate => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (length(name) <= 120)',
    'CHECK (context_note IS NULL OR length(context_note) <= 500)',
  ];
}
