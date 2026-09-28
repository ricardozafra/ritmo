import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/providers/metrics_providers.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/metrics/metrics_calculator.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late RitmoDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = RitmoDatabase(NativeDatabase.memory());
    await database.select(database.settings).getSingle();
    container = ProviderContainer(
      overrides: [ritmoDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('provider retorna 0/0 antes da ativação', () async {
    expect(await _readRate(container), Rate.zero);
  });

  test('provider deriva somente dias elegíveis de settings e days', () async {
    await database.customStatement(
      "UPDATE settings SET activation_date = '2026-01-05' WHERE id = 1",
    );
    await _insertDay(database, '2026-01-02', sealed: true);
    await _insertDay(database, '2026-01-05', sealed: true);
    await _insertDay(database, '2026-01-06', sealed: true);
    await _insertDay(database, '2026-01-07');
    await _insertDay(database, '2026-01-08', sealed: true, closed: false);
    await _insertDay(database, '2026-01-10', sealed: true, mute: true);
    await database.customStatement(
      'INSERT INTO pillar_entries (operational_date, pillar, night_kind) '
      "VALUES ('2026-01-05', 'night', 'recovery'), "
      "('2026-01-06', 'night', 'study')",
    );
    await database.customStatement(
      'INSERT INTO pillar_waivers (id, date, pillar, reason_text) '
      "VALUES ('waiver-1', '2026-01-06', 'morning', 'Consulta')",
    );

    expect(
      await _readRate(container),
      Rate(numerator: 2, denominator: 3),
    );
  });
}

Future<Rate> _readRate(ProviderContainer container) async {
  final subscription = container.listen(metricsInputProvider, (_, _) {});
  try {
    await container.read(metricsInputProvider.future);
    return container.read(metricsRateProvider).requireValue;
  } finally {
    subscription.close();
  }
}

Future<void> _insertDay(
  RitmoDatabase database,
  String date, {
  bool sealed = false,
  bool closed = true,
  bool mute = false,
}) => database.customStatement(
  'INSERT INTO days '
  '(operational_date, base_result, effective_result, closed_at, '
  'seal_timestamp, mute_cause) VALUES (?, ?, ?, ?, ?, ?)',
  [
    date,
    sealed ? 'sealed' : 'unsealed',
    mute ? 'mute' : (sealed ? 'sealed' : 'unsealed'),
    closed ? 100 : null,
    sealed ? 50 : null,
    mute ? 'weekend' : null,
  ],
);
