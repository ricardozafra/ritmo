// Feature: ritmo, Property 43: Histórico de revisões é uma lista cronológica simples
//
// Para qualquer conjunto de revisões persistidas, a consulta do histórico
// devolve exatamente a lista ordenada por week_start decrescente, sem filtros,
// paginação ou busca textual.
//
// **Validates: Requirements RF-08.19, RF-08.20, RF-08.24, RF-08.26**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/weekly_review_repository.dart';
import 'package:ritmo/domain/review/weekly_review.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

typedef _HistoryFixture = ({
  List<OperationalDate> weekStarts,
});

final Generator<_HistoryFixture> _anyHistoryFixture = any.simple(
  generate: (random, size) {
    final count = random.nextInt(12);
    final baseMonday = OperationalDate(2026, 1, 5);
    final weekStartsSet = <OperationalDate>{};

    for (var i = 0; i < count; i++) {
      final weekOffset = random.nextInt(52);
      weekStartsSet.add(baseMonday.addDays(weekOffset * 7));
    }

    final list = weekStartsSet.toList()..shuffle(random);
    return (weekStarts: list);
  },
  shrink: (fixture) sync* {
    if (fixture.weekStarts.length > 2) {
      yield (weekStarts: fixture.weekStarts.sublist(0, fixture.weekStarts.length - 1));
    }
  },
);

void main() {
  Glados<_HistoryFixture>(
    _anyHistoryFixture,
    RitmoGlados.ci(),
  ).test('Propriedade 43: Histórico de revisões é uma lista cronológica simples', (fixture) async {
    final database = db.RitmoDatabase(NativeDatabase.memory());
    final repository = WeeklyReviewRepository(database);
    final location = ensureBusinessLocation();
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(location, 1767225600000);

    try {
      // Insere as revisões na ordem embaralhada gerada
      for (var i = 0; i < fixture.weekStarts.length; i++) {
        final weekStart = fixture.weekStarts[i];
        await repository.ensureDraft(
          id: 'rev-$i-${weekStart.iso}',
          weekStart: weekStart,
          createdAt: at.add(Duration(days: i)),
        );
      }

      final history = await repository.watchHistory().first;

      // 1. Devolve exatamente a mesma quantidade de revisões
      expect(history.length, equals(fixture.weekStarts.length));

      // 2. Contém todos os weekStarts persistidos
      final returnedWeeks = history.map((r) => r.weekStart).toList();
      final expectedWeeksSet = fixture.weekStarts.toSet();
      expect(returnedWeeks.toSet(), equals(expectedWeeksSet));

      // 3. Ordenado estritamente por week_start decrescente (mais recente primeiro)
      for (var i = 0; i < history.length - 1; i++) {
        final current = history[i].weekStart;
        final next = history[i + 1].weekStart;
        expect(
          current > next,
          isTrue,
          reason: 'Semana $current deve ser estritamente posterior a $next no histórico decrescente',
        );
      }
    } finally {
      await database.close();
    }
  });

  group('Propriedade 43: Casos específicos de histórico', () {
    test('histórico vazio retorna lista vazia', () async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = WeeklyReviewRepository(database);

      try {
        final history = await repository.watchHistory().first;
        expect(history, isEmpty);
      } finally {
        await database.close();
      }
    });

    test('revisões draft e finalized aparecem no histórico sem filtros', () async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = WeeklyReviewRepository(database);
      final location = ensureBusinessLocation();
      final at = tz.TZDateTime.fromMillisecondsSinceEpoch(location, 1767225600000);

      try {
        final w1 = OperationalDate(2026, 1, 5);
        final w2 = OperationalDate(2026, 1, 12);

        final r1 = await repository.ensureDraft(
          id: 'r1',
          weekStart: w1,
          createdAt: at,
        );
        await repository.ensureDraft(
          id: 'r2',
          weekStart: w2,
          createdAt: at,
        );
        await repository.finalize(
          id: r1.id,
          at: at.add(const Duration(hours: 1)),
        );

        final history = await repository.watchHistory().first;
        expect(history.length, equals(2));
        expect(history[0].weekStart, equals(w2));
        expect(history[0].state, equals(WeeklyReviewState.draft));
        expect(history[1].weekStart, equals(w1));
        expect(history[1].state, equals(WeeklyReviewState.finalized));
      } finally {
        await database.close();
      }
    });
  });
}
