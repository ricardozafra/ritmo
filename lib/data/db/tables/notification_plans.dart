import 'package:drift/drift.dart';

/// Plano semanal idempotente de notificação da revisão.
class NotificationPlans extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get kind => text()();
  IntColumn get plannedAt => integer()();
  TextColumn get state => text()();

  @override
  Set<Column<Object>> get primaryKey => {idempotencyKey};

  @override
  List<String> get customConstraints => const [
    "CHECK (kind IN ('weekly_review_sunday', 'weekly_review_monday'))",
    "CHECK (state IN ('planned', 'delivered', 'cancelled', 'suppressed'))",
  ];
}
