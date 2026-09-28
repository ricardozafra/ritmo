import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/app/scheduler.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/notifications/local_notification_gateway.dart';
import 'package:ritmo/data/repositories/notification_plans_repository.dart';
import 'package:ritmo/data/repositories/settings_repository.dart';
import 'package:ritmo/domain/notifications/notification_plan.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

final class TestNotificationGateway implements LocalNotificationGateway {
  final Map<int, ScheduledNotification> scheduled = {};
  final List<ScheduledNotification> scheduleCalls = [];
  final List<int> cancelCalls = [];
  bool permissionGranted = true;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    scheduleCalls.add(notification);
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
  }
}

void main() {
  const allowedTitles = {'Revisão Semanal'};
  const allowedBodies = {'É hora de revisar sua semana no Ritmo.'};

  late db.RitmoDatabase database;
  late NotificationPlansRepository plansRepo;
  late SettingsRepository settingsRepo;
  late TestNotificationGateway gateway;
  late tz.Location location;

  setUp(() {
    database = db.RitmoDatabase(NativeDatabase.memory());
    plansRepo = NotificationPlansRepository(database);
    settingsRepo = SettingsRepository(database);
    gateway = TestNotificationGateway();
    location = ensureBusinessLocation();
  });

  tearDown(() async {
    await database.close();
  });

  group('RF-05.23, RF-08.8, RF-08.11: Allow-list de textos de notificação', () {
    test(
      'agendamento dominical emite título e corpo estritamente da allow-list',
      () async {
        final sunday = OperationalDate(2026, 3, 8);
        final sundayMorning = tz.TZDateTime(location, 2026, 3, 8, 10, 0);

        final clock = SystemOperationalClock(
          calendar: const OperationalCalendar.seed(),
          deviceInstant: () => sundayMorning.toUtc(),
        );
        expect(clock.operationalDateNow(), equals(sunday));

        await (database.update(
          database.settings,
        )..where((s) => s.id.equals(1))).write(
          const db.SettingsCompanion(
            reviewWeekday: Value('sunday'),
            reviewTimeMin: Value(1230), // 20:30
            sundayNotificationEnabled: Value(true),
          ),
        );

        final scheduler = NotificationScheduler(
          clock: clock,
          plans: plansRepo,
          settings: settingsRepo,
          gateway: gateway,
        );

        await scheduler.reconcilePlans();

        expect(gateway.scheduled.length, equals(1));
        final notification = gateway.scheduled.values.first;

        expect(allowedTitles.contains(notification.title), isTrue);
        expect(notification.title, equals('Revisão Semanal'));
        expect(allowedBodies.contains(notification.body), isTrue);
        expect(
          notification.body,
          equals('É hora de revisar sua semana no Ritmo.'),
        );
        expect(notification.id, isNonNegative);
      },
    );

    test(
      'agendamento de segunda-feira emite título e corpo estritamente da allow-list',
      () async {
        final mondayMorning = tz.TZDateTime(location, 2026, 3, 9, 8, 0);

        final clock = SystemOperationalClock(
          calendar: const OperationalCalendar.seed(),
          deviceInstant: () => mondayMorning.toUtc(),
        );

        await (database.update(
          database.settings,
        )..where((s) => s.id.equals(1))).write(
          const db.SettingsCompanion(
            reviewWeekday: Value('monday'),
            reviewTimeMin: Value(600), // 10:00
            sundayNotificationEnabled: Value(false),
          ),
        );

        final scheduler = NotificationScheduler(
          clock: clock,
          plans: plansRepo,
          settings: settingsRepo,
          gateway: gateway,
        );

        await scheduler.reconcilePlans();

        expect(gateway.scheduled.length, equals(1));
        final notification = gateway.scheduled.values.first;

        expect(allowedTitles.contains(notification.title), isTrue);
        expect(notification.title, equals('Revisão Semanal'));
        expect(allowedBodies.contains(notification.body), isTrue);
        expect(
          notification.body,
          equals('É hora de revisar sua semana no Ritmo.'),
        );
      },
    );
  });

  group(
    'RF-05.23, RNF-04.8, RNF-04.9: Integração com gateway e cancelamento por mudança de configuração',
    () {
      test(
        'mudança de domingo para segunda cancela agendamento dominical no gateway',
        () async {
          final sundayMorning = tz.TZDateTime(location, 2026, 3, 8, 10, 0);

          final clock = SystemOperationalClock(
            calendar: const OperationalCalendar.seed(),
            deviceInstant: () => sundayMorning.toUtc(),
          );

          // Inicia como domingo
          await (database.update(
            database.settings,
          )..where((s) => s.id.equals(1))).write(
            const db.SettingsCompanion(
              reviewWeekday: Value('sunday'),
              reviewTimeMin: Value(1230),
              sundayNotificationEnabled: Value(true),
            ),
          );

          final scheduler = NotificationScheduler(
            clock: clock,
            plans: plansRepo,
            settings: settingsRepo,
            gateway: gateway,
          );

          await scheduler.reconcilePlans();
          expect(gateway.scheduled.length, equals(1));
          final initialId = gateway.scheduled.keys.first;

          // Altera configuração para segunda-feira
          await (database.update(
            database.settings,
          )..where((s) => s.id.equals(1))).write(
            const db.SettingsCompanion(
              reviewWeekday: Value('monday'),
              reviewTimeMin: Value(600),
              sundayNotificationEnabled: Value(false),
            ),
          );

          await scheduler.reconcilePlans();

          // O agendamento anterior de domingo foi cancelado no gateway
          expect(gateway.cancelCalls.contains(initialId), isTrue);
          expect(gateway.scheduled.containsKey(initialId), isFalse);

          // E o novo agendamento de segunda está ativo
          expect(gateway.scheduled.length, equals(1));
          final newId = gateway.scheduled.keys.first;
          expect(newId, isNot(equals(initialId)));
        },
      );
    },
  );

  group(
    'RNF-04.7, RNF-04.8: Cancelamento/supressão de entregas durante blackout',
    () {
      test(
        'entrega na madrugada de segunda antes da abertura é suprimida',
        () async {
          // 03:00 de segunda com abertura em 03:30
          final mondayDawn = tz.TZDateTime(location, 2026, 3, 9, 3, 0);

          final clock = SystemOperationalClock(
            calendar: const OperationalCalendar(
              dayCloseTime: LocalTimeOfDay(3, 30),
              nightEndTime: LocalTimeOfDay(23, 0),
            ),
            deviceInstant: () => mondayDawn.toUtc(),
          );

          final weekStart = OperationalDate(2026, 3, 9);
          final key = NotificationPlan.keyFor(
            NotificationKind.weeklyReviewMonday,
            weekStart,
          );

          await plansRepo.upsert(
            NotificationPlan(
              idempotencyKey: key,
              kind: NotificationKind.weeklyReviewMonday,
              plannedAt: mondayDawn,
              state: PlanState.planned,
            ),
          );

          final scheduler = NotificationScheduler(
            clock: clock,
            plans: plansRepo,
            settings: settingsRepo,
            gateway: gateway,
          );

          // handleDelivery deve barrar por estar dentro do blackout
          final delivered = await scheduler.handleDelivery(key);
          expect(delivered, isFalse);

          final planAfter = await plansRepo.findByKey(key);
          expect(planAfter!.state, equals(PlanState.suppressed));
        },
      );

      test(
        'entrega no domingo à noite com opt-in habilitado é liberada com sucesso',
        () async {
          final sundayNight = tz.TZDateTime(location, 2026, 3, 8, 20, 30);

          final clock = SystemOperationalClock(
            calendar: const OperationalCalendar.seed(),
            deviceInstant: () => sundayNight.toUtc(),
          );

          await (database.update(
            database.settings,
          )..where((s) => s.id.equals(1))).write(
            const db.SettingsCompanion(
              reviewWeekday: Value('sunday'),
              reviewTimeMin: Value(1230),
              sundayNotificationEnabled: Value(true),
            ),
          );

          final weekStart = OperationalDate(2026, 3, 2);
          final key = NotificationPlan.keyFor(
            NotificationKind.weeklyReviewSunday,
            weekStart,
          );

          await plansRepo.upsert(
            NotificationPlan(
              idempotencyKey: key,
              kind: NotificationKind.weeklyReviewSunday,
              plannedAt: sundayNight,
              state: PlanState.planned,
            ),
          );

          final scheduler = NotificationScheduler(
            clock: clock,
            plans: plansRepo,
            settings: settingsRepo,
            gateway: gateway,
          );

          final delivered = await scheduler.handleDelivery(key);
          expect(delivered, isTrue);

          final planAfter = await plansRepo.findByKey(key);
          expect(planAfter!.state, equals(PlanState.delivered));
        },
      );
    },
  );
}
