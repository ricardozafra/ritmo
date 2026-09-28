import 'package:drift/drift.dart';

/// Configuração local singleton. A única chave válida é `id = 1`.
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get activationDate => text().nullable()();
  TextColumn get businessTimezone =>
      text().withDefault(const Constant('America/Sao_Paulo'))();
  IntColumn get dayCloseTimeMin => integer().withDefault(const Constant(180))();
  IntColumn get nightEndTimeMin => integer().withDefault(const Constant(180))();
  TextColumn get reviewWeekday =>
      text().withDefault(const Constant('sunday'))();
  IntColumn get reviewTimeMin => integer().withDefault(const Constant(1260))();
  BoolColumn get sundayNotificationEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get syncEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (id = 1)',
    "CHECK (business_timezone = 'America/Sao_Paulo')",
    'CHECK (day_close_time_min BETWEEN 0 AND 240)',
    'CHECK (night_end_time_min BETWEEN 0 AND 1439)',
    "CHECK (review_weekday IN ('sunday', 'monday'))",
    'CHECK (review_time_min BETWEEN 0 AND 1439)',
    "CHECK ((review_weekday = 'sunday' AND review_time_min BETWEEN 1200 AND 1320) OR (review_weekday = 'monday' AND review_time_min > day_close_time_min))",
  ];
}
