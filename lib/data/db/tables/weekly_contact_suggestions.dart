import 'package:drift/drift.dart';

import 'contacts.dart';

/// Progressão persistida de contatos sugeridos em uma semana operacional.
class WeeklyContactSuggestions extends Table {
  TextColumn get weekStart => text()();
  TextColumn get contactId => text().references(Contacts, #id)();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {weekStart, contactId},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (status IN ('pending', 'done', 'skipped'))",
  ];
}
