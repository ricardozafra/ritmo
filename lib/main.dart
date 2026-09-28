import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers/notification_providers.dart';
import 'app/ritmo_app.dart';
import 'data/notifications/local_notification_gateway.dart';
import 'domain/time/operational_clock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Garante a base de fusos carregada antes de qualquer agendamento no fuso
  // oficial (RNF-04.1).
  ensureBusinessLocation();
  runApp(
    ProviderScope(
      overrides: [
        localNotificationGatewayProvider.overrideWithValue(
          FlutterLocalNotificationGateway(),
        ),
      ],
      child: const RitmoApp(),
    ),
  );
}
