import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ritmo/app/providers/cycle_providers.dart';
import 'package:ritmo/app/providers/metrics_providers.dart';
import 'package:ritmo/app/providers/ritmo_providers.dart';
import 'package:ritmo/app/providers/settings_providers.dart';
import 'package:ritmo/app/providers/today_providers.dart';
import 'package:ritmo/app/ritmo/ritmo_projection.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/app/ritmo_app.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/data/repositories/metrics_repository.dart';
import 'package:ritmo/data/repositories/settings_repository.dart';
import 'package:ritmo/domain/review/review_schedule_validator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/ui/navigation/mvp_shell.dart';
import 'package:ritmo/ui/protocol/protocol_flow_screen.dart';
import 'package:ritmo/ui/ritmo/ritmo_screen.dart';
import 'package:ritmo/ui/settings/settings_screen.dart';
import 'package:ritmo/ui/today/today_screen.dart';

void main() {
  testWidgets('o app expõe cinco destinos e Pedra precede o Protocolo', (
    tester,
  ) async {
    final database = RitmoDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    for (final date in const ['2026-01-05', '2026-01-06']) {
      await database.customStatement(
        "INSERT INTO days (operational_date, base_result, effective_result) "
        "VALUES (?, 'unsealed', 'unsealed')",
        [date],
      );
    }
    await database.customStatement(
      'INSERT INTO protocol_alarms '
      '(id, generation_id, start_date, end_date, sequence_length, state) '
      "VALUES ('protocol-1', 'seq:2026-01-05', '2026-01-05', "
      "'2026-01-06', 2, 'pending')",
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ritmoDatabaseProvider.overrideWithValue(database),
          settingsSnapshotProvider.overrideWith(
            (ref) => Stream<SettingsSnapshot>.value(
              const SettingsSnapshot(
                calendar: OperationalCalendar.seed(),
                syncEnabled: false,
                reviewWeekday: ReviewWeekday.sunday,
                reviewTimeMinutes: 1260,
                sundayNotificationEnabled: false,
              ),
            ),
          ),
          holidaySettingsEntriesProvider.overrideWith(
            (ref) => Stream<List<HolidaySettingsEntry>>.value(
              const <HolidaySettingsEntry>[],
            ),
          ),
          todayChangesProvider.overrideWith(
            (ref) => const Stream<void>.empty(),
          ),
          metricsInputProvider.overrideWith(
            (ref) => Stream<MetricsInput>.value(
              MetricsInput(activationDate: null, days: const []),
            ),
          ),
          ritmoCurrentOperationalDateProvider.overrideWith(
            (ref) => OperationalDate(2026, 8, 19),
          ),
          ritmoMonthProvider.overrideWith(
            (ref, month) => Stream<RitmoMonthView>.value(
              const RitmoProjection().projectMonth(
                month: month,
                days: const [],
              ),
            ),
          ),
          competencyEvolutionProvider.overrideWith(
            (ref) => Stream<List<CompetencyEvolution>>.value(
              const <CompetencyEvolution>[],
            ),
          ),
        ],
        child: const RitmoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ProtocolFlowScreen.stoneStageKey), findsOneWidget);
    expect(find.byKey(ProtocolFlowScreen.formStageKey), findsNothing);

    await tester.tap(find.byKey(ProtocolFlowScreen.continueButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ProtocolFlowScreen.stoneStageKey), findsNothing);
    expect(find.byKey(ProtocolFlowScreen.formStageKey), findsOneWidget);
    expect(find.text('o que causou?'), findsOneWidget);
    expect(find.text('o problema é o plano ou a execução?'), findsOneWidget);
    expect(find.text('qual o ajuste?'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar à Pedra'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(
      tester.element(find.byKey(ProtocolFlowScreen.stoneStageKey)),
    );
    router.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(TodayScreen.screenKey), findsOneWidget);

    final navigationBar = find.byKey(MvpShell.navigationBarKey);
    expect(navigationBar, findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in <String>[
      'Hoje',
      'Ritmo',
      'Pessoas',
      'Pedra',
      'Configurações',
    ]) {
      expect(
        find.descendant(of: navigationBar, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(find.text('Revisão'), findsNothing);
    expect(find.text('Exportação'), findsNothing);

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Ritmo')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(RitmoScreen.screenKey), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Configurações')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
  });
}
