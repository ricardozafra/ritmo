// Feature: ritmo, Property 42: Autosave preserva rascunho sem finalização implícita
//
// Para qualquer sequência de mutações de texto em qualquer dos três campos
// (answer_fulfilled, answer_failed, answer_lesson), a persistência reflete
// cada valor e atualiza autosaved_at mantendo state == draft e
// finalized_at == null; a revisão só passa a finalized por chamada explícita
// de finalização.
//
// **Validates: Requirements RF-08.22, RF-08.25**

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/weekly_review_repository.dart';
import 'package:ritmo/domain/review/weekly_review.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../generators/shared.dart';

typedef _AutosaveStep = ({WeeklyReviewField field, String text});

typedef _AutosaveFixture = ({
  OperationalDate weekStart,
  List<_AutosaveStep> steps,
  bool finalizeAtEnd,
});

final Generator<_AutosaveFixture> _anyAutosaveFixture = any.simple(
  generate: (random, size) {
    final monday = anyOperationalDate(random, size).value;
    final weekStart = monday.addDays(1 - monday.weekday);
    final count = 1 + random.nextInt(8);

    final steps = List.generate(count, (idx) {
      final field = WeeklyReviewField
          .values[random.nextInt(WeeklyReviewField.values.length)];
      final text = 'Resposta passo $idx: ${random.nextInt(10000)}';
      return (field: field, text: text);
    });

    return (
      weekStart: weekStart,
      steps: steps,
      finalizeAtEnd: random.nextBool(),
    );
  },
  shrink: (fixture) sync* {},
);

void main() {
  Glados<_AutosaveFixture>(_anyAutosaveFixture, RitmoGlados.ci()).test(
    'Propriedade 42: Autosave preserva rascunho sem finalização implícita',
    (fixture) async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = WeeklyReviewRepository(database);
      final location = ensureBusinessLocation();
      final baseTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
        location,
        1767225600000,
      );

      try {
        final draft = await repository.ensureDraft(
          id: 'review-${fixture.weekStart.iso}',
          weekStart: fixture.weekStart,
          createdAt: baseTime,
        );

        expect(draft.state, equals(WeeklyReviewState.draft));
        expect(draft.finalizedAt, isNull);

        var expectedFulfilled = draft.answerFulfilled;
        var expectedFailed = draft.answerFailed;
        var expectedLesson = draft.answerLesson;

        for (var i = 0; i < fixture.steps.length; i++) {
          final step = fixture.steps[i];
          final at = baseTime.add(Duration(minutes: i + 1));

          final result = await repository.autosaveField(
            id: draft.id,
            field: step.field,
            value: step.text,
            at: at,
          );
          expect(result.isSuccess, isTrue);

          switch (step.field) {
            case WeeklyReviewField.fulfilled:
              expectedFulfilled = step.text;
            case WeeklyReviewField.failed:
              expectedFailed = step.text;
            case WeeklyReviewField.lesson:
              expectedLesson = step.text;
          }

          final current = await repository.watchById(draft.id).first;
          expect(current, isNotNull);
          expect(current!.answerFulfilled, equals(expectedFulfilled));
          expect(current.answerFailed, equals(expectedFailed));
          expect(current.answerLesson, equals(expectedLesson));
          expect(current.state, equals(WeeklyReviewState.draft));
          expect(current.finalizedAt, isNull);
          expect(
            current.autosavedAt?.millisecondsSinceEpoch,
            equals(at.millisecondsSinceEpoch),
          );
        }

        if (fixture.finalizeAtEnd) {
          final finalizeTime = baseTime.add(
            Duration(minutes: fixture.steps.length + 5),
          );
          final finalizeResult = await repository.finalize(
            id: draft.id,
            at: finalizeTime,
          );
          expect(finalizeResult.isSuccess, isTrue);

          final finalized = await repository.watchById(draft.id).first;
          expect(finalized!.state, equals(WeeklyReviewState.finalized));
          expect(
            finalized.finalizedAt?.millisecondsSinceEpoch,
            equals(finalizeTime.millisecondsSinceEpoch),
          );

          // Mutações posteriores via autosaveField são rejeitadas após finalização
          final rejected = await repository.autosaveField(
            id: draft.id,
            field: WeeklyReviewField.lesson,
            value: 'tentativa invalida',
            at: finalizeTime.add(const Duration(minutes: 1)),
          );
          expect(rejected.isFailure, isTrue);
          if (rejected case Failure(:final failure)) {
            expect(failure.code, equals('review_finalized'));
          }
        }
      } finally {
        await database.close();
      }
    },
  );

  group('Propriedade 42: Casos pontuais de autosave', () {
    test('limpar campo com null preserva draft', () async {
      final database = db.RitmoDatabase(NativeDatabase.memory());
      final repository = WeeklyReviewRepository(database);
      final location = ensureBusinessLocation();
      final at = tz.TZDateTime.fromMillisecondsSinceEpoch(
        location,
        1767225600000,
      );

      try {
        final draft = await repository.ensureDraft(
          id: 'rev-1',
          weekStart: OperationalDate(2026, 3, 9),
          createdAt: at,
        );

        await repository.autosaveField(
          id: draft.id,
          field: WeeklyReviewField.fulfilled,
          value: 'teste',
          at: at.add(const Duration(seconds: 1)),
        );
        var current = await repository.watchById(draft.id).first;
        expect(current!.answerFulfilled, equals('teste'));

        await repository.autosaveField(
          id: draft.id,
          field: WeeklyReviewField.fulfilled,
          value: null,
          at: at.add(const Duration(seconds: 2)),
        );
        current = await repository.watchById(draft.id).first;
        expect(current!.answerFulfilled, isNull);
        expect(current.state, equals(WeeklyReviewState.draft));
        expect(current.finalizedAt, isNull);
      } finally {
        await database.close();
      }
    });
  });
}
