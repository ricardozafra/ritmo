// Tarefa 18.2: smoke e verificações estáticas do escopo MVP.
//
// Reúne, em asserções determinísticas, as invariantes de escopo que o produto
// exige: ausência de gamificação, telemetria, cliente HTTP/backend, login e
// reconciliação manual de timer; flags padrão desligadas; os destinos
// habilitados navegáveis (Fase 2 inclui Pessoas), com Revisão/Exportação e o
// editor/Encerramento de Ciclo ainda sem rota invocável; e contraste WCAG AA
// nos pares de cor realmente renderizados.
//
// Valida: RF-02.19, RF-03.21, RF-06.13, RA-01.4, RA-01.10, RD-10, RNF-02.1,
// RNF-02.2, RNF-02.3, RNF-03.2; Restrições 6.1, 6.5, 6.6.

import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/providers/cycle_providers.dart';
import 'package:ritmo/app/providers/metrics_providers.dart';
import 'package:ritmo/app/providers/ritmo_providers.dart';
import 'package:ritmo/app/providers/settings_providers.dart';
import 'package:ritmo/app/providers/today_providers.dart';
import 'package:ritmo/app/ritmo/ritmo_projection.dart';
import 'package:ritmo/app/ritmo_app.dart';
import 'package:ritmo/data/db/database.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/data/repositories/metrics_repository.dart';
import 'package:ritmo/data/repositories/settings_repository.dart';
import 'package:ritmo/domain/review/review_schedule_validator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/ui/navigation/mvp_shell.dart';
import 'package:ritmo/ui/navigation/route_unavailable_screen.dart';
import 'package:ritmo/ui/settings/settings_screen.dart';
import 'package:ritmo/ui/today/today_screen.dart';

import '../../tool/mvp_scope_check.dart';

void main() {
  group('varredura estática do escopo MVP', () {
    test('lib/ não reintroduz padrões fora do escopo do MVP', () {
      final report = scanMvpScopePaths(const <String>['lib']);
      expect(
        report.isClean,
        isTrue,
        reason: report.violations.map((v) => v.toString()).join('\n'),
      );
      expect(report.scannedFiles, greaterThan(0));
    });

    test('a varredura reconhece cada padrão proibido', () {
      expect(
        scanMvpScopeSource(
          source: 'const streak = 3;',
          path: 'lib/x.dart',
        ).single.rule,
        'anti-gamification',
      );
      expect(
        scanMvpScopeSource(
          source: "import 'package:http/http.dart';",
          path: 'lib/x.dart',
        ).single.rule,
        'no-network-client',
      );
      expect(
        scanMvpScopeSource(
          source: 'final a = FirebaseAnalytics.instance;',
          path: 'lib/x.dart',
        ).single.rule,
        'no-telemetry',
      );
      expect(
        scanMvpScopeSource(
          source: 'final c = HttpClient();',
          path: 'lib/x.dart',
        ).single.rule,
        'no-raw-sockets',
      );
      expect(
        scanMvpScopeSource(
          source: 'void resumeTimer() {}',
          path: 'lib/x.dart',
        ).single.rule,
        'no-manual-timer-reconciliation',
      );
      expect(
        scanMvpScopeSource(
          source: 'UPDATE settings SET sync_enabled = 1;',
          path: 'lib/x.dart',
        ).single.rule,
        'sync-flag-must-default-off',
      );
    });

    test(
      'comentários e strings de documentação não geram falsos positivos',
      () {
        expect(
          scanMvpScopeSource(
            source: '// streak e badge são proibidos',
            path: 'lib/x.dart',
          ),
          isEmpty,
        );
        expect(
          scanMvpScopeSource(
            source: 'const doc = "sem reward nem leaderboard aqui";',
            path: 'lib/x.dart',
          ),
          isNot(isEmpty),
          reason: 'literais de conteúdo ainda são inspecionados',
        );
      },
    );

    test('flutter_local_notifications e just_audio permanecem permitidos', () {
      expect(
        scanMvpScopeSource(
          source: "import 'package:flutter_local_notifications/x.dart';",
          path: 'lib/x.dart',
        ),
        isEmpty,
      );
      expect(
        scanMvpScopeSource(
          source: "import 'package:just_audio/just_audio.dart';",
          path: 'lib/x.dart',
        ),
        isEmpty,
      );
    });
  });

  group('gating de rotas de fases futuras', () {
    test('o roteador não registra rota de Exportação', () {
      final routerSource = File(
        'lib/app/navigation/app_router.dart',
      ).readAsStringSync();
      final violations = findGatedRouteRegistrations(
        routerSource: routerSource,
        path: 'lib/app/navigation/app_router.dart',
      );
      expect(
        violations,
        isEmpty,
        reason: violations.map((v) => v.toString()).join('\n'),
      );
    });

    test('o helper detecta uma rota de fase futura registrada', () {
      final violations = findGatedRouteRegistrations(
        routerSource: "GoRoute(path: '/exportacao', name: 'export')",
        path: 'lib/app/navigation/app_router.dart',
      );
      expect(violations, isNot(isEmpty));
      expect(violations.first.rule, 'no-future-phase-route');
    });

    test('Pessoas, Revisão e os fluxos de ciclo não são sinalizados', () {
      final people = findGatedRouteRegistrations(
        routerSource: "GoRoute(path: '/pessoas', name: 'people')",
        path: 'lib/app/navigation/app_router.dart',
      );
      final review = findGatedRouteRegistrations(
        routerSource: "GoRoute(path: '/revisao', name: 'review')",
        path: 'lib/app/navigation/app_router.dart',
      );
      final cycleEditor = findGatedRouteRegistrations(
        routerSource: "GoRoute(path: '/ciclo/editar', name: 'cycle-edit')",
        path: 'lib/app/navigation/app_router.dart',
      );
      final cycleClosure = findGatedRouteRegistrations(
        routerSource:
            "GoRoute(path: '/ciclo/encerramento', name: 'cycle-closure')",
        path: 'lib/app/navigation/app_router.dart',
      );
      expect(people, isEmpty);
      expect(review, isEmpty);
      expect(cycleEditor, isEmpty);
      expect(cycleClosure, isEmpty);
    });

    test('a Exportação permanece sinalizada como fase futura', () {
      final violations = findGatedRouteRegistrations(
        routerSource: "GoRoute(path: '/exportacao', name: 'export')",
        path: 'lib/app/navigation/app_router.dart',
      );
      expect(violations, isNot(isEmpty));
      expect(violations.first.rule, 'no-future-phase-route');
    });
  });

  group('contraste WCAG AA dos pares realmente renderizados', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF405D4C));

    // Pares (fundo, texto) usados na UII do MVP: superfícies, primário e os
    // estados do heatmap definidos em monthly_heatmap.dart.
    final pairs = <String, ({Color background, Color foreground})>{
      'surface/onSurface': (
        background: scheme.surface,
        foreground: scheme.onSurface,
      ),
      'surfaceContainerHighest/onSurfaceVariant': (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
      'primary/onPrimary': (
        background: scheme.primary,
        foreground: scheme.onPrimary,
      ),
      'primaryContainer/onPrimaryContainer': (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      'surfaceContainerLow/onSurface': (
        background: scheme.surfaceContainerLow,
        foreground: scheme.onSurface,
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} atinge 4.5:1 (texto normal AA)', () {
        final ratio = _contrastRatio(
          entry.value.foreground,
          entry.value.background,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} teve razão ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('smoke de navegação e destinos do MVP', () {
    testWidgets('os cinco destinos habilitados são navegáveis na Fase 2', (
      tester,
    ) async {
      final database = RitmoDatabase(NativeDatabase.memory());
      addTearDown(database.close);

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

      final navigationBar = find.byKey(MvpShell.navigationBarKey);
      expect(navigationBar, findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (final label in const <String>[
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
      // Revisão e Exportação são fluxos/fases futuras, não destinos.
      for (final absent in const <String>['Revisão', 'Exportação']) {
        expect(find.text(absent), findsNothing);
      }

      // Os destinos habilitados resolvem telas reais, não a de indisponível.
      expect(find.byKey(TodayScreen.screenKey), findsOneWidget);
      expect(find.byType(RouteUnavailableScreen), findsNothing);

      await tester.tap(
        find.descendant(
          of: navigationBar,
          matching: find.text('Configurações'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump();
    });
  });
}

/// Razão de contraste WCAG entre duas cores opacas, em `[1, 21]`.
double _contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double component) {
    final c = component;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
