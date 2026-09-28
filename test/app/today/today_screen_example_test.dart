// Tarefa 17.11: exemplos e edge cases da UI do MVP na tela Hoje.
//
// Verifica no widget real que a tela Hoje apresenta os estados normativos do
// dia operacional: dia mudo mostra somente a frase literal; dia útil aberto
// expõe pilares e ações; a janela "somente Recuperação" exibe a copy literal e
// oculta Estudo; dia encerrado e dia selado ficam somente para leitura; e o
// indicador de fuso divergente aparece de forma discreta.
//
// A projeção é fixada por override para isolar a apresentação do runtime
// temporal, que possui cobertura própria (fronteira, deadline e relógio).
//
// Valida: RF-05.2, RF-05.14, RF-01.17, RF-02.4, Copy literais.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/providers/boundary_providers.dart';
import 'package:ritmo/app/providers/today_providers.dart';
import 'package:ritmo/core/copy.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/day/day_state_machine.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/day/today_view.dart';
import 'package:ritmo/domain/time/night_window.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:ritmo/ui/today/today_screen.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  Future<void> pumpToday(WidgetTester tester, TodayView view) async {
    // Viewport alto para a lista materializar todos os cartões, tornando as
    // asserções de presença independentes da rolagem lazy.
    tester.view.physicalSize = const Size(1400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayViewProvider.overrideWith((ref) async => view),
          boundaryRuntimeProvider.overrideWith(
            (ref) => Completer<BoundaryRuntime>().future,
          ),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('dia mudo exibe somente a frase literal, sem pilares', (
    tester,
  ) async {
    await pumpToday(tester, _muteView());

    expect(find.text(Copy.muteDay), findsOneWidget);
    expect(find.text(Copy.workoutLabel), findsNothing);
    expect(find.text(Copy.dayToggle), findsNothing);
    expect(find.widgetWithText(FilledButton, Copy.sealDay), findsNothing);
  });

  testWidgets('dia útil aberto expõe os três pilares e a ação de selar', (
    tester,
  ) async {
    await pumpToday(tester, _openWorkdayView());

    expect(find.text(Copy.workoutLabel), findsOneWidget);
    expect(find.text(Copy.dayToggle), findsOneWidget);
    expect(find.text('Iniciar Estudo'), findsOneWidget);
    expect(find.text('Escolher Recuperação'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, Copy.sealDay), findsOneWidget);
  });

  testWidgets(
    'janela somente-Recuperação exibe a copy literal e oculta Estudo',
    (tester) async {
      await pumpToday(
        tester,
        _openWorkdayView(nightWindow: NightWindowState.recoveryOnly),
      );

      expect(find.text(Copy.nightRecoveryOnly), findsOneWidget);
      expect(find.text('Iniciar Estudo'), findsNothing);
      expect(find.text('Escolher Recuperação'), findsOneWidget);
    },
  );

  testWidgets('dia encerrado fica somente para leitura', (tester) async {
    await pumpToday(tester, _closedView());

    expect(find.text(Copy.closedDayReadOnly), findsOneWidget);
    // Sem controles de edição: nenhuma caixa de treino interativa.
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.widgetWithText(FilledButton, Copy.sealDay), findsNothing);
  });

  testWidgets('dia selado oferece reabertura antes de editar', (tester) async {
    await pumpToday(tester, _sealedView());

    expect(find.widgetWithText(FilledButton, Copy.reopenDay), findsOneWidget);
    expect(find.widgetWithText(FilledButton, Copy.sealDay), findsNothing);
  });

  testWidgets('indicador de fuso divergente aparece de forma discreta', (
    tester,
  ) async {
    await pumpToday(tester, _openWorkdayView(deviceZoneDiverges: true));

    expect(find.byTooltip(Copy.businessTimezoneNotice), findsOneWidget);
  });

  testWidgets('sem divergência de fuso, nenhum indicador é exibido', (
    tester,
  ) async {
    await pumpToday(tester, _openWorkdayView());

    expect(find.byTooltip(Copy.businessTimezoneNotice), findsNothing);
  });
}

final tz.Location _location = ensureBusinessLocation();
final OperationalDate _date = OperationalDate(2026, 1, 5); // segunda, dia útil

MuteTodayView _muteView() =>
    MuteTodayView(operationalDate: _date, deviceZoneDiverges: false);

WorkdayTodayView _openWorkdayView({
  NightWindowState nightWindow = NightWindowState.beforeStudyDeadline,
  bool deviceZoneDiverges = false,
}) => _workday(
  mode: TodayMode.openUnsealed,
  baseResult: DayResult.unsealed,
  nightWindow: nightWindow,
  deviceZoneDiverges: deviceZoneDiverges,
);

WorkdayTodayView _closedView() => _workday(
  mode: TodayMode.closed,
  baseResult: DayResult.unsealed,
  closedAt: tz.TZDateTime(_location, 2026, 1, 6, 3),
  nightWindow: NightWindowState.closed,
);

WorkdayTodayView _sealedView() => _workday(
  mode: TodayMode.openSealed,
  baseResult: DayResult.sealed,
  sealTimestamp: tz.TZDateTime(_location, 2026, 1, 5, 23),
  nightWindow: NightWindowState.beforeStudyDeadline,
);

WorkdayTodayView _workday({
  required TodayMode mode,
  required DayResult baseResult,
  required NightWindowState nightWindow,
  tz.TZDateTime? closedAt,
  tz.TZDateTime? sealTimestamp,
  bool deviceZoneDiverges = false,
}) => WorkdayTodayView(
  operationalDate: _date,
  deviceZoneDiverges: deviceZoneDiverges,
  mode: mode,
  day: Day(
    operationalDate: _date,
    baseResult: baseResult,
    effectiveResult: baseResult,
    closedAt: closedAt,
    sealTimestamp: sealTimestamp,
  ),
  cycleSummary: TodayCycleSummary(cycle: _seedCycle),
  countdownDays: 42,
  awaitingClosure: false,
  entries: const PillarEntriesSnapshot(),
  linkedStudyBlock: null,
  activeWaiver: null,
  visibleInitiative: null,
  pillarStatus: const PillarStatus(
    morningCompleted: false,
    dayCompleted: false,
    nightCompleted: false,
  ),
  sealEligible: false,
  uncoveredIncompletePillars: const {},
  nightWindowState: nightWindow,
);

final Cycle _seedCycle = Cycle(
  id: 'cycle-seed-v1',
  name: 'Ciclo',
  purposeText: 'Finalidade do ciclo seed',
  startDate: OperationalDate(2026, 1, 1),
  endDate: OperationalDate(2027, 6, 30),
  state: CycleState.active,
);
