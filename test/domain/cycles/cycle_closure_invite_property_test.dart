// Feature: ritmo, Property 35: Convite de encerramento no máximo uma vez por semana
//
// Para qualquer histórico de convites e qualquer número de aberturas da Revisão
// Semanal dentro da mesma semana operacional, no máximo um convite de
// Encerramento de Ciclo é apresentado, o adiamento nunca o transforma em
// obrigatório, e nenhuma notificação é enviada.
//
// **Validates: Requirements RF-06.9, RF-06.10, RF-06.17**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/app/controllers/cycle_controller.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/cycle_repository.dart';
import 'package:ritmo/data/repositories/notification_plans_repository.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/notifications/notification_plan.dart';
import 'package:ritmo/domain/people/weekly_contact_suggestion.dart'
    show operationalWeekStart;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';

import '../../generators/shared.dart';

typedef _InviteFixture = ({
  OperationalDate cycleStart,
  int cycleDurationDays,
  int
  reviewDayOffset, // days after cycle end (>= 0 so cycle is awaiting closure)
  int reviewOpenings, // 1 to 15 review screen openings
});

final Generator<_InviteFixture> _anyInviteFixture = any.simple(
  generate: (random, size) {
    final start = anyOperationalDate(random, size).value;
    final duration = 30 + random.nextInt(365);
    final offset = random.nextInt(60); // 0 to 59 days after cycle end
    final openings = 1 + random.nextInt(15);

    return (
      cycleStart: start,
      cycleDurationDays: duration,
      reviewDayOffset: offset,
      reviewOpenings: openings,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_InviteFixture>(_anyInviteFixture, RitmoGlados.ci()).test(
    'Propriedade 35: Convite de encerramento no máximo uma vez por semana',
    (fixture) async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final cycleRepo = CycleRepository(database);
      final plansRepo = NotificationPlansRepository(database);
      final policy = const CyclePolicy();

      final endDate = fixture.cycleStart.addDays(fixture.cycleDurationDays);
      final reviewDate = endDate.addDays(fixture.reviewDayOffset);
      final weekStart = operationalWeekStart(reviewDate);

      final clock = SystemOperationalClock(
        calendar: const OperationalCalendar.seed(),
        deviceInstant: () =>
            DateTime.utc(reviewDate.year, reviewDate.month, reviewDate.day, 12),
      );

      final controller = CycleController(
        cycleRepo,
        loadClock: () async => clock,
      );

      try {
        // 1. Cadastra ciclo elegível para encerramento
        final cycle = Cycle(
          id: 'cycle-p35',
          name: 'Ciclo Teste',
          purposeText: 'Propósito',
          startDate: fixture.cycleStart,
          endDate: endDate,
          state: CycleState.active,
        );

        final checkpoints = [
          Checkpoint(
            id: 'cp-p35',
            cycleId: cycle.id,
            competency: Competency.st,
            date: endDate,
            status: 'pending',
          ),
        ];

        // Limpa ciclo pré-semeado
        await database.delete(database.checkpoints).go();
        await database.delete(database.cycles).go();

        // Salva no banco de dados
        await database
            .into(database.cycles)
            .insert(
              db.CyclesCompanion.insert(
                id: cycle.id,
                name: cycle.name,
                purposeText: cycle.purposeText,
                startDate: cycle.startDate.iso,
                endDate: cycle.endDate.iso,
                state: 'active',
              ),
            );

        await database
            .into(database.checkpoints)
            .insert(
              db.CheckpointsCompanion.insert(
                id: checkpoints.first.id,
                cycleId: cycle.id,
                competency: 'ST',
                date: checkpoints.first.date.iso,
                status: 'pending',
              ),
            );

        // Como reviewDate >= endDate, o ciclo está aguardando encerramento
        expect(policy.awaitingClosure(cycle, checkpoints, reviewDate), isTrue);

        // 2. Simula múltiplas aberturas da Revisão Semanal na mesma semana
        int presentedCount = 0;

        for (var i = 0; i < fixture.reviewOpenings; i++) {
          final alreadyInvited = await cycleRepo.hasInviteForWeek(
            cycleId: cycle.id,
            weekStart: weekStart,
          );

          final shouldOffer = policy.shouldOfferClosureInvite(
            cycle,
            checkpoints,
            reviewDate,
            alreadyInvitedThisWeek: alreadyInvited,
          );

          if (shouldOffer) {
            presentedCount++;
            // Usuário adia o convite
            final deferResult = await controller.deferClosureInvite(cycle.id);
            expect(deferResult.isSuccess, isTrue);
          }
        }

        // No máximo UM convite é apresentado por semana operacional
        expect(presentedCount, equals(1));

        // 3. O adiamento NUNCA torna o ciclo obrigatório nem bloqueia o app
        final activeAfter = await cycleRepo.watchActive().first;
        expect(activeAfter, isNotNull);
        expect(activeAfter!.cycle.state, equals(CycleState.active));

        // 4. Nenhuma notificação de ciclo foi criada ou agendada
        final allPlans = await plansRepo.watchAll().first;
        for (final plan in allPlans) {
          expect(
            plan.kind,
            isNot(equals(NotificationKind.fromWire('cycle_closure'))),
          );
        }
      } finally {
        await database.close();
      }
    },
  );

  group('Propriedade 35: Casos de borda de transição semanal', () {
    test(
      'adiamento na semana 1 permite novo convite na semana 2 se ainda em aberto',
      () async {
        final database = db.RitmoDatabase(NativeDatabase.memory());
        final cycleRepo = CycleRepository(database);
        final policy = const CyclePolicy();

        final cycle = Cycle(
          id: 'cycle-w1-w2',
          name: 'Ciclo Semanas',
          purposeText: 'Propósito',
          startDate: OperationalDate(2026, 1, 1),
          endDate: OperationalDate(2026, 3, 1),
          state: CycleState.active,
        );
        final checkpoints = [
          Checkpoint(
            id: 'cp-w1-w2',
            cycleId: cycle.id,
            competency: Competency.st,
            date: OperationalDate(2026, 3, 1),
            status: 'pending',
          ),
        ];

        await database.delete(database.checkpoints).go();
        await database.delete(database.cycles).go();

        await database
            .into(database.cycles)
            .insert(
              db.CyclesCompanion.insert(
                id: cycle.id,
                name: cycle.name,
                purposeText: cycle.purposeText,
                startDate: cycle.startDate.iso,
                endDate: cycle.endDate.iso,
                state: 'active',
              ),
            );
        final week1Date = OperationalDate(2026, 3, 4);
        final week1Start = operationalWeekStart(week1Date);

        // Semana 2: 2026-03-09
        final week2Date = OperationalDate(2026, 3, 11);
        final week2Start = operationalWeekStart(week2Date);

        // Semana 1 inicial: sem convite ainda
        expect(
          await cycleRepo.hasInviteForWeek(
            cycleId: cycle.id,
            weekStart: week1Start,
          ),
          isFalse,
        );
        expect(
          policy.shouldOfferClosureInvite(
            cycle,
            checkpoints,
            week1Date,
            alreadyInvitedThisWeek: false,
          ),
          isTrue,
        );

        // Registra convite da semana 1
        await cycleRepo.recordInvite(cycleId: cycle.id, weekStart: week1Start);

        // Semana 1 após adiamento: convite bloqueado
        expect(
          await cycleRepo.hasInviteForWeek(
            cycleId: cycle.id,
            weekStart: week1Start,
          ),
          isTrue,
        );
        expect(
          policy.shouldOfferClosureInvite(
            cycle,
            checkpoints,
            week1Date,
            alreadyInvitedThisWeek: true,
          ),
          isFalse,
        );

        // Semana 2: convite da semana 1 não afeta semana 2
        expect(
          await cycleRepo.hasInviteForWeek(
            cycleId: cycle.id,
            weekStart: week2Start,
          ),
          isFalse,
        );
        expect(
          policy.shouldOfferClosureInvite(
            cycle,
            checkpoints,
            week2Date,
            alreadyInvitedThisWeek: false,
          ),
          isTrue,
        );

        await database.close();
      },
    );
  });
}
