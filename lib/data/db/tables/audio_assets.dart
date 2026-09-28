import 'package:drift/drift.dart';

/// Metadados e integridade de um arquivo de áudio local.
class AudioAssets extends Table {
  TextColumn get id => text()();
  TextColumn get relativePath => text()();
  TextColumn get kind => text()();
  IntColumn get durationMs => integer()();
  IntColumn get byteSize => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (kind IN ('day_note', 'weekly_review'))",
    'CHECK (duration_ms > 0)',
    'CHECK (byte_size > 0)',
  ];
}
