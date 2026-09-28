import 'package:drift/drift.dart';

/// Cartões fixos de mentoria, separados do cadastro de contatos.
class Mentorships extends Table {
  TextColumn get id => text()();
  TextColumn get competency => text()();
  TextColumn get mentorName => text().nullable()();
  TextColumn get lastMeetingDate => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {competency},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (competency IN ('ST', 'IN', 'CA'))",
    'CHECK (mentor_name IS NULL OR length(mentor_name) <= 120)',
  ];
}
