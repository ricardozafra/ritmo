import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Requisição de agendamento local, independente do plugin.
final class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.idempotencyKey,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  /// Identificador numérico estável do agendamento no SO (derivado da chave).
  final int id;

  /// Chave idempotente semanal transportada no payload para revalidação na
  /// entrega (RNF-04.8).
  final String idempotencyKey;

  final String title;
  final String body;

  /// Instante absoluto no fuso oficial (RNF-04.1).
  final tz.TZDateTime scheduledAt;
}

/// Porta local para agendar e cancelar notificações do SO.
///
/// Nenhuma notificação do Ritmo é crítica ao segundo; o agendamento usa modo
/// inexato e não solicita permissão de alarme exato. A recusa de permissão
/// mantém o app integralmente funcional — as notificações são opcionais em
/// todas as fases (RNF-04 nota de plataforma).
abstract interface class LocalNotificationGateway {
  /// Inicializa o plugin uma única vez. Idempotente.
  Future<void> ensureInitialized();

  /// Solicita a permissão de notificação (Android 13+ `POST_NOTIFICATIONS`,
  /// iOS). Retorna `true` quando concedida; `false` não impede o app de
  /// funcionar.
  Future<bool> requestPermission();

  /// Agenda [notification] com `zonedSchedule` no fuso oficial, em modo
  /// inexato. Sobrescreve um agendamento existente com o mesmo `id`.
  Future<void> schedule(ScheduledNotification notification);

  /// Cancela o agendamento de um `id`.
  Future<void> cancel(int id);

  /// Cancela todos os agendamentos.
  Future<void> cancelAll();
}

/// Implementação sobre `flutter_local_notifications`.
///
/// Usa `AndroidScheduleMode.inexactAllowWhileIdle` para não exigir
/// `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` e evitar
/// `ExactAlarmPermissionException`. No Android 13+ solicita apenas
/// `POST_NOTIFICATIONS`.
final class FlutterLocalNotificationGateway
    implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    DidReceiveNotificationResponseCallback? onSelect,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       // ignore: prefer_initializing_formals
       _onSelect = onSelect;

  static const String channelId = 'ritmo_weekly_review';
  static const String channelName = 'Revisão Semanal';
  static const String channelDescription =
      'Lembrete da Revisão Semanal do Ritmo.';

  final FlutterLocalNotificationsPlugin _plugin;
  final DidReceiveNotificationResponseCallback? _onSelect;
  bool _initialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onSelect,
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iOS != null) {
      final granted = await iOS.requestPermissions(alert: true);
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    await ensureInitialized();
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: notification.scheduledAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notification.idempotencyKey,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await ensureInitialized();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await ensureInitialized();
    await _plugin.cancelAll();
  }
}

/// Gateway inerte: não agenda nada. Usado quando as notificações estão
/// indisponíveis (permissão negada, plataforma sem suporte) ou em testes.
final class NoOpLocalNotificationGateway implements LocalNotificationGateway {
  const NoOpLocalNotificationGateway();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(ScheduledNotification notification) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}
