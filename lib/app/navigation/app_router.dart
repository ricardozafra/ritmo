import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ritmo/ritmo_projection.dart';
import '../../domain/time/operational_calendar.dart';
import '../../ui/cycles/cycle_closure_screen.dart';
import '../../ui/cycles/cycle_editor_screen.dart';
import '../../ui/manifest/stone_screen.dart';
import '../../ui/navigation/mvp_shell.dart';
import '../../ui/navigation/route_unavailable_screen.dart';
import '../../ui/people/pessoas_screen.dart';
import '../../ui/protocol/protocol_flow_screen.dart';
import '../../ui/review/weekly_review_detail_screen.dart';
import '../../ui/review/weekly_review_history_screen.dart';
import '../../ui/review/weekly_review_screen.dart';
import '../../ui/ritmo/protocol_history_screen.dart';
import '../../ui/ritmo/ritmo_day_detail_screen.dart';
import '../../ui/ritmo/ritmo_screen.dart';
import '../../ui/settings/settings_screen.dart';
import '../../ui/today/today_screen.dart';

abstract final class AppRoute {
  static const rootPath = '/';
  static const todayPath = '/hoje';
  static const ritmoPath = '/ritmo';
  static const ritmoDayPathPattern = '/ritmo/dia/:date';
  static const ritmoProtocolsPath = '/ritmo/protocolos';
  static const ritmoDayRelativePath = 'dia/:date';
  static const ritmoProtocolsRelativePath = 'protocolos';
  static const peoplePath = '/pessoas';
  static const stonePath = '/pedra';
  static const stoneEditPath = '/pedra/editar';
  static const stoneEditRelativePath = 'editar';
  static const settingsPath = '/config';
  static const protocolPathPattern = '/protocolo/:id';
  static const reviewPath = '/revisao';
  static const reviewHistoryPath = '/revisoes';
  static const reviewDetailPathPattern = '/revisoes/:id';
  static const reviewDetailRelativePath = ':id';
  static const cycleEditorPath = '/ciclo/editar';
  static const cycleClosurePath = '/ciclo/encerramento';

  static const todayName = 'today';
  static const ritmoName = 'ritmo';
  static const ritmoDayName = 'ritmo-day';
  static const ritmoProtocolsName = 'ritmo-protocols';
  static const peopleName = 'people';
  static const stoneName = 'stone';
  static const stoneEditName = 'stone-edit';
  static const settingsName = 'settings';
  static const protocolName = 'protocol';
  static const reviewName = 'review';
  static const reviewHistoryName = 'review-history';
  static const reviewDetailName = 'review-detail';
  static const cycleEditorName = 'cycle-edit';
  static const cycleClosureName = 'cycle-closure';

  static String ritmoDayPath(OperationalDate date) => '/ritmo/dia/${date.iso}';

  static String protocolPath(String protocolId) =>
      '/protocolo/${Uri.encodeComponent(protocolId)}';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final todayNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'today');
  final ritmoNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ritmo');
  final peopleNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'people');
  final stoneNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'stone');
  final settingsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'settings',
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.todayPath,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.rootPath,
        redirect: (context, state) => AppRoute.todayPath,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MvpShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: todayNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.todayPath,
                name: AppRoute.todayName,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: ritmoNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.ritmoPath,
                name: AppRoute.ritmoName,
                builder: (context, state) => const RitmoScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: AppRoute.ritmoDayRelativePath,
                    name: AppRoute.ritmoDayName,
                    builder: (context, state) {
                      final date = OperationalDateCodec.tryParse(
                        state.pathParameters['date'] ?? '',
                      );
                      return date == null
                          ? const RouteUnavailableScreen()
                          : RitmoDayDetailScreen(operationalDate: date);
                    },
                  ),
                  GoRoute(
                    path: AppRoute.ritmoProtocolsRelativePath,
                    name: AppRoute.ritmoProtocolsName,
                    builder: (context, state) => const ProtocolHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: peopleNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.peoplePath,
                name: AppRoute.peopleName,
                builder: (context, state) => const PessoasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: stoneNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.stonePath,
                name: AppRoute.stoneName,
                builder: (context, state) => const StoneScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: AppRoute.stoneEditRelativePath,
                    name: AppRoute.stoneEditName,
                    builder: (context, state) => const StoneEditScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.settingsPath,
                name: AppRoute.settingsName,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoute.protocolPathPattern,
        name: AppRoute.protocolName,
        builder: (context, state) =>
            ProtocolFlowScreen(protocolId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoute.reviewPath,
        name: AppRoute.reviewName,
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoute.reviewHistoryPath,
        name: AppRoute.reviewHistoryName,
        builder: (context, state) => const WeeklyReviewHistoryScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoute.reviewDetailRelativePath,
            name: AppRoute.reviewDetailName,
            builder: (context, state) =>
                WeeklyReviewDetailScreen(reviewId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoute.cycleEditorPath,
        name: AppRoute.cycleEditorName,
        builder: (context, state) => const CycleEditorScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoute.cycleClosurePath,
        name: AppRoute.cycleClosureName,
        builder: (context, state) => const CycleClosureScreen(),
      ),
    ],
    errorBuilder: (context, state) => const RouteUnavailableScreen(),
  );

  ref.onDispose(router.dispose);
  return router;
});
