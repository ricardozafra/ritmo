import 'package:drift/drift.dart';

/// Cópia local editável do manifesto distribuído como asset.
class Manifests extends Table {
  TextColumn get id => text()();
  TextColumn get contentMarkdown => text()();
  TextColumn get assetVersion => text()();
  IntColumn get firstCopiedAt => integer()();
  IntColumn get lastEditedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (length(CAST(content_markdown AS BLOB)) <= 1048576)',
  ];
}
