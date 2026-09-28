import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation/app_router.dart';
import 'providers/boundary_providers.dart';
import 'providers/notification_providers.dart';
import 'providers/protocol_providers.dart';

class RitmoApp extends ConsumerStatefulWidget {
  const RitmoApp({super.key});

  @override
  ConsumerState<RitmoApp> createState() => _RitmoAppState();
}

class _RitmoAppState extends ConsumerState<RitmoApp> {
  String? _presentedProtocolId;

  @override
  Widget build(BuildContext context) {
    ref.watch(boundaryRuntimeProvider);
    // Ativa a reconciliação contínua dos planos de notificação (Fase 2).
    ref.watch(notificationReconciliationProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen(protocolForThisLaunchProvider, (previous, next) {
      next.whenData((protocol) {
        if (protocol == null || _presentedProtocolId != null) return;
        _presentedProtocolId = protocol.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          router.push<void>(AppRoute.protocolPath(protocol.id));
        });
      });
    });

    return MaterialApp.router(
      title: 'Ritmo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF405D4C)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
