// Feature: ritmo, Property 36: Autoavaliação no mês civil do checkpoint
//
// Para qualquer par (semana da Revisão Semanal, conjunto de checkpoints), a
// autoavaliação de uma competência é incluída no fluxo se e somente se a
// revisão ocorre no mesmo mês civil do checkpoint dessa competência; níveis
// aceitos são exatamente BD, B, I, A, E.
//
// **Validates: Requirements RF-06.5, RF-06.6, RD-22**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/domain/cycles/cycle_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef _EvalFixture = ({
  OperationalDate reviewWeekStart,
  List<({int monthOffset, int day, Competency competency})> checkpointsData,
});

final Generator<_EvalFixture> _anyEvalFixture = any.simple(
  generate: (random, size) {
    final weekStart = anyOperationalDate(random, size).value;
    final numCheckpoints = 1 + random.nextInt(6);

    final cpList = <({int monthOffset, int day, Competency competency})>[];
    for (var i = 0; i < numCheckpoints; i++) {
      // monthOffset between -2 and +2
      final offset = -2 + random.nextInt(5);
      final day = 1 + random.nextInt(28);
      final comp = Competency.values[random.nextInt(Competency.values.length)];
      cpList.add((monthOffset: offset, day: day, competency: comp));
    }

    return (reviewWeekStart: weekStart, checkpointsData: cpList);
  },
  shrink: (fixture) sync* {},
);

void main() {
  const policy = CheckpointEvaluationPolicy();

  Glados<_EvalFixture>(
    _anyEvalFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 36: Autoavaliação no mês civil do checkpoint', (fixture) {
    final weekStart = fixture.reviewWeekStart;

    // Constrói lista de checkpoints baseados nos offsets
    final checkpoints = <Checkpoint>[];
    for (var i = 0; i < fixture.checkpointsData.length; i++) {
      final data = fixture.checkpointsData[i];
      // Calcula ano e mês aplicando o offset
      final totalMonths =
          (weekStart.year * 12 + (weekStart.month - 1)) + data.monthOffset;
      final year = totalMonths ~/ 12;
      final month = (totalMonths % 12) + 1;
      final cpDate = OperationalDate(year, month, data.day);

      checkpoints.add(
        Checkpoint(
          id: 'cp-$i',
          cycleId: 'cycle-p36',
          competency: data.competency,
          date: cpDate,
          status: 'pending',
        ),
      );
    }

    // Executa a política pura de filtragem para a revisão
    final eligible = policy.checkpointsForReviewMonth(checkpoints, weekStart);

    // Invariante 1: Um checkpoint é incluído se e somente se pertence ao mesmo ano e mês civil
    for (final cp in checkpoints) {
      final isSameCivilMonth =
          (cp.date.year == weekStart.year && cp.date.month == weekStart.month);
      final isIncluded = eligible.any((e) => e.id == cp.id);

      expect(
        isIncluded,
        equals(isSameCivilMonth),
        reason:
            'Checkpoint ${cp.date.iso} vs Review ${weekStart.iso}: '
            'mesmo mês=$isSameCivilMonth mas incluído=$isIncluded',
      );
    }

    // Invariante 2: Níveis Gartner aceitos são exatamente BD, B, I, A, E
    final levelWireValues = GartnerLevel.values.map((l) => l.wireValue).toSet();
    expect(levelWireValues, equals({'BD', 'B', 'I', 'A', 'E'}));
  });

  group('Propriedade 36: Níveis Gartner e persistência no banco', () {
    test('GartnerLevel.fromWire aceita apenas BD, B, I, A, E', () {
      expect(GartnerLevel.fromWire('BD'), equals(GartnerLevel.bd));
      expect(GartnerLevel.fromWire('B'), equals(GartnerLevel.b));
      expect(GartnerLevel.fromWire('I'), equals(GartnerLevel.i));
      expect(GartnerLevel.fromWire('A'), equals(GartnerLevel.a));
      expect(GartnerLevel.fromWire('E'), equals(GartnerLevel.e));

      // Qualquer outro valor é rejeitado
      expect(GartnerLevel.fromWire(''), isNull);
      expect(GartnerLevel.fromWire('bd'), isNull);
      expect(GartnerLevel.fromWire('C'), isNull);
      expect(GartnerLevel.fromWire('SENIOR'), isNull);
    });

    test(
      'tabela checkpoint_evals rejeita níveis fora do domínio no SQLite',
      () async {
        final database = db.RitmoDatabase(NativeDatabase.memory());

        try {
          expect(
            () => database.customStatement(
              "INSERT INTO checkpoint_evals (id, checkpoint_id, gartner_level) "
              "VALUES ('eval-invalid', 'checkpoint-seed-innovative', 'INVALID')",
            ),
            throwsA(isA<Exception>()),
          );
        } finally {
          await database.close();
        }
      },
    );
  });
}
