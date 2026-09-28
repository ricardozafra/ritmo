// Feature: ritmo, Property 34: Rollover de ciclo preserva histórico
//
// Para qualquer ciclo com checkpoints e avaliações, concluir o Encerramento de
// Ciclo deixa exatamente um ciclo `active`, marca o anterior como `archived` e
// read-only, e mantém toda avaliação e todo checkpoint acessíveis pelos
// identificadores originais.
//
// **Validates: Requirements RF-06.11, RF-06.12, RF-06.14, RD-20**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/cycle_repository.dart';
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _RolloverFixture = ({
  OperationalDate cycle1Start,
  int cycle1Days,
  int numCheckpoints,
  GartnerLevel finalLevel,
});

final Generator<_RolloverFixture> _anyRolloverFixture = any.simple(
  generate: (random, size) {
    final start = anyOperationalDate(random, size).value;
    final days = 30 + random.nextInt(180);
    final count = 1 + random.nextInt(3);
    final level =
        GartnerLevel.values[random.nextInt(GartnerLevel.values.length)];

    return (
      cycle1Start: start,
      cycle1Days: days,
      numCheckpoints: count,
      finalLevel: level,
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_RolloverFixture>(_anyRolloverFixture, RitmoGlados.ci()).test(
    'Propriedade 34: Rollover de ciclo preserva histórico',
    (fixture) async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = CycleRepository(database);

      final c1End = fixture.cycle1Start.addDays(fixture.cycle1Days);
      final c2Start = c1End.addDays(1);
      final c2End = c2Start.addDays(180);

      try {
        // 1. Limpa seed e cadastra ciclo 1 com checkpoints
        await database.delete(database.checkpointEvals).go();
        await database.delete(database.checkpoints).go();
        await database.delete(database.cycles).go();

        final c1Id = 'cycle-1-${fixture.cycle1Start.iso}';
        await database
            .into(database.cycles)
            .insert(
              db.CyclesCompanion.insert(
                id: c1Id,
                name: 'Ciclo 1',
                purposeText: 'Finalidade Ciclo 1',
                startDate: fixture.cycle1Start.iso,
                endDate: c1End.iso,
                state: 'active',
              ),
            );

        final c1Checkpoints = <String>[];
        for (var i = 0; i < fixture.numCheckpoints; i++) {
          final cpId = 'cp-1-$i-${fixture.cycle1Start.iso}';
          c1Checkpoints.add(cpId);
          await database
              .into(database.checkpoints)
              .insert(
                db.CheckpointsCompanion.insert(
                  id: cpId,
                  cycleId: c1Id,
                  competency: 'ST',
                  date: fixture.cycle1Start.addDays(10 * (i + 1)).iso,
                  status: 'pending',
                ),
              );
        }

        // 2. Prepara novo ciclo e avaliações finais
        final finalEvaluations = [
          for (var i = 0; i < c1Checkpoints.length; i++)
            FinalEvaluationRecord(
              id: 'eval-c1-$i',
              checkpointId: c1Checkpoints[i],
              level: fixture.finalLevel,
              notes: 'Nota final $i',
            ),
        ];

        final c2Id = 'cycle-2-${fixture.cycle1Start.iso}';
        final newCycle = NewCycleRecord(
          id: c2Id,
          name: 'Ciclo 2',
          purposeText: 'Finalidade Ciclo 2',
          startDate: c2Start,
          endDate: c2End,
          checkpoints: [
            NewCheckpointRecord(
              id: 'cp-2-0',
              competency: Competency.in_,
              date: c2Start.addDays(30),
            ),
          ],
        );

        // 3. Executa o Encerramento de Ciclo
        final closureResult = await repository.completeClosure(
          closingCycleId: c1Id,
          finalEvaluations: finalEvaluations,
          newCycle: newCycle,
        );

        expect(closureResult.isSuccess, isTrue);

        // Invariante 1: Exatamente UM ciclo permanece ativo
        final allCycles = await (database.select(database.cycles)).get();
        final activeCycles = allCycles
            .where((c) => c.state == 'active')
            .toList();
        expect(activeCycles.length, equals(1));
        expect(activeCycles.first.id, equals(c2Id));

        // Invariante 2: O ciclo anterior está arquivado
        final archivedCycle = allCycles.firstWhere((c) => c.id == c1Id);
        expect(archivedCycle.state, equals('archived'));

        // Invariante 3: O ciclo arquivado é read-only
        final updateResult = await repository.updatePurposeAndPeriod(
          cycleId: c1Id,
          purposeText: 'Tentativa de alteração',
          startDate: fixture.cycle1Start,
          endDate: c1End,
        );
        if (updateResult case Failure(:final failure)) {
          expect(failure.code, equals('cycle_archived'));
        } else {
          fail('Ciclo arquivado permitiu alteração de finalidade e período!');
        }

        // Invariante 4: Checkpoints do ciclo anterior permanecem acessíveis
        for (final cpId in c1Checkpoints) {
          final cpRow = await (database.select(
            database.checkpoints,
          )..where((c) => c.id.equals(cpId))).getSingleOrNull();
          expect(cpRow, isNotNull);
          expect(cpRow!.cycleId, equals(c1Id));

          // Avaliações permanecem associadas aos identificadores originais
          final eval = await repository.findEvaluationForCheckpoint(cpId);
          expect(eval, isNotNull);
          expect(eval!.checkpointId, equals(cpId));
          expect(eval.level, equals(fixture.finalLevel));
        }
      } finally {
        await database.close();
      }
    },
  );

  group('Propriedade 34: Validações de pré-condições do novo ciclo', () {
    test('período invertido no novo ciclo falha e não altera estado', () async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = CycleRepository(database);

      try {
        final result = await repository.completeClosure(
          closingCycleId: 'cycle-seed-v1',
          finalEvaluations: const [],
          newCycle: NewCycleRecord(
            id: 'c-invalid',
            name: 'Nome',
            purposeText: 'Finalidade',
            startDate: OperationalDate(2027, 7, 1),
            endDate: OperationalDate(2027, 6, 1), // invertido
            checkpoints: [
              NewCheckpointRecord(
                id: 'cp-0',
                competency: Competency.st,
                date: OperationalDate(2027, 6, 15),
              ),
            ],
          ),
        );

        if (result case Failure(:final failure)) {
          expect(failure.code, equals('cycle_period_invalid'));
        } else {
          fail('Esperava erro cycle_period_invalid');
        }

        // Ciclo original permanece ativo
        final active = await repository.watchActive().first;
        expect(active, isNotNull);
        expect(active!.cycle.id, equals('cycle-seed-v1'));
      } finally {
        await database.close();
      }
    });
  });
}
