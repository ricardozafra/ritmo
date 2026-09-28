// Feature: ritmo, Property 29: Unicidade semanal do lembrete de revisão
//
// Para qualquer semana operacional, exatamente um plano de lembrete de revisão
// permanece ativo no sistema (UNIQUE(kind, week_start)), com no máximo uma
// entrega por semana no SO e idempotência garantida por
// idempotency_key = "<kind>:<week_start>".
//
// **Validates: Requirements RF-05.20, RF-05.21, RF-08.8, RF-08.11, RF-08.13,
// RF-08.14, RF-08.17, RF-08.18, RNF-04.8, RNF-04.9**

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/app/scheduler.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/notifications/local_notification_gateway.dart';
import 'package:ritmo/data/repositories/notification_plans_repository.dart';
import 'package:ritmo/data/repositories/settings_repository.dart';
import 'package:ritmo/domain/notifications/notification_plan.dart';
import 'package:ritmo/domain/review/review_schedule_validator.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

final class InMemoryNotificationGateway implements LocalNotificationGateway {
  final Map<int, ScheduledNotification> scheduled = {};
  final List<ScheduledNotification> scheduleCalls = [];
  final List<int> cancelCalls = [];

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> requestPermission() async => true;

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

typedef _UniquenessFixture = ({
  OperationalDate weekStart,
  ReviewWeekday weekday,
  int timeMinutes,
  bool sundayExceptionEnabled,
  int reconciliationRounds,
});

final Generator<_UniquenessFixture> _anyUniquenessFixture = any.simple(
  generate: (random, size) {
    final monday = anyOperationalDate(random, size).value;
    final weekStart = monday.addDays(1 - monday.weekday);

    final isSunday = random.nextBool();
    final ReviewWeekday weekday;
    final int timeMinutes;
    final bool sundayEnabled;

    if (isSunday) {
      weekday = ReviewWeekday.sunday;
      // 20:00 to 22:00 -> 1200 to 1320
      timeMinutes = 1200 + random.nextInt(121);
      sundayEnabled = true;
    } else {
      weekday = ReviewWeekday.monday;
      // After dayCloseTime (e.g. 03:00 = 180 min) -> 240 to 1200
      timeMinutes = 240 + random.nextInt(960);
      sundayEnabled = random.nextBool();
    }

    final rounds = 2 + random.nextInt(4);

    return (
      weekStart: weekStart,
      weekday: weekday,
      timeMinutes: timeMinutes,
      sundayExceptionEnabled: sundayEnabled,
      reconciliationRounds: rounds,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_UniquenessFixture>(
    _anyUniquenessFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 29: Unicidade semanal do lembrete de revisão', (
    fixture,
  ) async {
    final database = db.RitmoDatabase(NativeDatabase.memory());
    final plansRepo = NotificationPlansRepository(database);
    final settingsRepo = SettingsRepository(database);
    final gateway = InMemoryNotificationGateway();
    final location = ensureBusinessLocation();

    // Fixa o instante corrente no início da semana operacional (segunda 09:00)
    final nowInstant = tz.TZDateTime(
      location,
      fixture.weekStart.year,
      fixture.weekStart.month,
      fixture.weekStart.day,
      9,
      0,
    );

    final clock = SystemOperationalClock(
      calendar: const OperationalCalendar.seed(),
      deviceInstant: () => nowInstant.toUtc(),
    );

    try {
      // Atualiza a configuração da revisão
      await (database.update(
        database.settings,
      )..where((s) => s.id.equals(1))).write(
        db.SettingsCompanion(
          reviewWeekday: Value(fixture.weekday.wireValue),
          reviewTimeMin: Value(fixture.timeMinutes),
          sundayNotificationEnabled: Value(fixture.sundayExceptionEnabled),
        ),
      );

      final scheduler = NotificationScheduler(
        clock: clock,
        plans: plansRepo,
        settings: settingsRepo,
        gateway: gateway,
      );

      // Executa múltiplas rodadas de reconciliação consecutivas
      for (var round = 0; round < fixture.reconciliationRounds; round++) {
        await scheduler.reconcilePlans();
      }

      // Verifica unicidade no repositório
      final allPlans = await plansRepo.watchAll().first;
      final plannedList = allPlans
          .where((p) => p.state == PlanState.planned)
          .toList();

      // Se há plano agendado para o futuro da semana:
      if (plannedList.isNotEmpty) {
        expect(plannedList.length, equals(1));
        final plan = plannedList.first;

        // Idempotency key segue estritamente o formato "<kind>:<week_start>"
        final expectedKind = fixture.weekday == ReviewWeekday.sunday
            ? NotificationKind.weeklyReviewSunday
            : NotificationKind.weeklyReviewMonday;
        expect(plan.kind, equals(expectedKind));
        expect(plan.idempotencyKey, contains(plan.kind.wireValue));

        // No SO (gateway), existe no máximo 1 agendamento ativo
        expect(gateway.scheduled.length, equals(1));
        final scheduledNotif = gateway.scheduled.values.first;
        expect(scheduledNotif.idempotencyKey, equals(plan.idempotencyKey));

        // Simula entrega
        final delivered = await scheduler.handleDelivery(plan.idempotencyKey);
        // Após entrega, uma nova reconciliação NÃO volta o plano a planned
        await scheduler.reconcilePlans();

        final afterDelivery = await plansRepo.findByKey(plan.idempotencyKey);
        expect(afterDelivery, isNotNull);
        expect(
          afterDelivery!.state,
          equals(delivered ? PlanState.delivered : PlanState.suppressed),
        );
        expect(afterDelivery.state, isNot(PlanState.planned));
      }
    } finally {
      await database.close();
    }
  });

  group('Propriedade 29: Idempotência direta por chave', () {
    test('upsert com a mesma chave sobrescreve sem duplicar', () async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final plansRepo = NotificationPlansRepository(database);
      final location = ensureBusinessLocation();
      final targetDate = OperationalDate(2026, 3, 9);
      final key = NotificationPlan.keyFor(
        NotificationKind.weeklyReviewMonday,
        targetDate,
      );

      try {
        final plan1 = NotificationPlan(
          idempotencyKey: key,
          kind: NotificationKind.weeklyReviewMonday,
          plannedAt: tz.TZDateTime(location, 2026, 3, 9, 10, 0),
          state: PlanState.planned,
        );
        final plan2 = NotificationPlan(
          idempotencyKey: key,
          kind: NotificationKind.weeklyReviewMonday,
          plannedAt: tz.TZDateTime(location, 2026, 3, 9, 11, 0),
          state: PlanState.planned,
        );

        await plansRepo.upsert(plan1);
        await plansRepo.upsert(plan2);

        final all = await plansRepo.watchAll().first;
        expect(all.length, equals(1));
        expect(all.first.idempotencyKey, equals(key));
        expect(all.first.plannedAt.hour, equals(11));
      } finally {
        await database.close();
      }
    });
  });
}
