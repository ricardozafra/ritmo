// Feature: ritmo, Property 54: Escalabilidade tipográfica sem perda de ações
//
// Para qualquer fator de escala tipográfica dentro da faixa de acessibilidade,
// a tela Hoje de um dia útil aberto mantém as ações essenciais presentes: os
// controles dos três pilares, criar dispensa e o botão de selar continuam na
// árvore, sem overflow de layout. Aumentar a fonte nunca oculta uma ação.
//
// A projeção é fixada por override, isolando a propriedade tipográfica do
// runtime temporal (relógio, observador e timer de deadline), que tem cobertura
// própria. O boundary runtime é mantido em carregamento — o build da tela só o
// consulta para `pendingEditBoundary`, tratando ausência como nula.
//
// **Validates: Requirements RNF-03.1**

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
import 'package:ritmo/ui/today/today_screen.dart';

void main() {
  // Fatores cobrindo o padrão e os extremos de acessibilidade do Android.
  const scales = <double>[1.0, 1.3, 1.6, 2.0];

  final view = _openWorkdayView();

  testWidgets(
    'Propriedade 54: a tela Hoje preserva ações em qualquer escala de fonte',
    (tester) async {
      // Viewport alto o suficiente para a lista materializar todos os cartões
      // em qualquer escala, isolando a asserção de presença da rolagem lazy.
      tester.view.physicalSize = const Size(1400, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final scale in scales) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todayViewProvider.overrideWith((ref) async => view),
              // Mantido em carregamento: sem runtime real, sem timers.
              boundaryRuntimeProvider.overrideWith(
                (ref) => Completer<BoundaryRuntime>().future,
              ),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const TodayScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final reason = 'escala $scale';

        // Controles dos três pilares permanecem presentes na árvore.
        expect(find.text(Copy.workoutLabel), findsOneWidget, reason: reason);
        expect(find.text(Copy.dayToggle), findsOneWidget, reason: reason);
        expect(find.text('Iniciar Estudo'), findsOneWidget, reason: reason);

        // Ações essenciais de selo e dispensa permanecem disponíveis.
        expect(
          find.widgetWithText(FilledButton, Copy.sealDay),
          findsOneWidget,
          reason: reason,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Criar dispensa'),
          findsOneWidget,
          reason: reason,
        );

        // Nenhum overflow de layout foi acusado durante a renderização.
        expect(tester.takeException(), isNull, reason: reason);
      }
    },
  );
}

WorkdayTodayView _openWorkdayView() {
  final date = OperationalDate(2026, 1, 5); // segunda, dia útil
  return WorkdayTodayView(
    operationalDate: date,
    deviceZoneDiverges: false,
    mode: TodayMode.openUnsealed,
    day: Day(
      operationalDate: date,
      baseResult: DayResult.unsealed,
      effectiveResult: DayResult.unsealed,
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
    nightWindowState: NightWindowState.beforeStudyDeadline,
  );
}

final Cycle _seedCycle = Cycle(
  id: 'cycle-seed-v1',
  name: 'Ciclo',
  purposeText: 'Finalidade do ciclo seed',
  startDate: OperationalDate(2026, 1, 1),
  endDate: OperationalDate(2027, 6, 30),
  state: CycleState.active,
);
