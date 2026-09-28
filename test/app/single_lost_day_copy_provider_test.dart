import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/providers/metrics_providers.dart';
import 'package:ritmo/app/providers/protocol_providers.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/protocol/single_lost_day_copy.dart';
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

  test('provider disponibiliza a projeção literal e neutra', () async {
    await database.customStatement(
      "UPDATE settings SET activation_date = '2026-01-05' WHERE id = 1",
    );
    await _insertDay(database, '2026-01-05');

    final presentation = await _readPresentation(container);

    expect(presentation?.text, Copy.singleLostDay);
    expect(presentation?.color, FailureCopyColor.neutralGray);
  });

  test(
    'provider não disponibiliza a copy para duas falhas correntes',
    () async {
      await database.customStatement(
        "UPDATE settings SET activation_date = '2026-01-05' WHERE id = 1",
      );
      await _insertDay(database, '2026-01-05');
      await _insertDay(database, '2026-01-06');

      expect(await _readPresentation(container), isNull);
    },
  );
}

Future<FailureCopyPresentation?> _readPresentation(
  ProviderContainer container,
) async {
  final subscription = container.listen(metricsInputProvider, (_, _) {});
  try {
    await container.read(metricsInputProvider.future);
    return container.read(singleLostDayCopyProvider).requireValue;
  } finally {
    subscription.close();
  }
}

Future<void> _insertDay(RitmoDatabase database, String date) =>
    database.customStatement(
      'INSERT INTO days '
      '(operational_date, base_result, effective_result, closed_at) '
      "VALUES (?, 'unsealed', 'unsealed', 100)",
      [date],
    );
