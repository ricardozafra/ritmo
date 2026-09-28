import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/result.dart';
import 'package:ritmo/data/db/database.dart' as db;
import 'package:ritmo/data/repositories/day_repository.dart';
import 'package:ritmo/data/repositories/pillar_entries_repository.dart';
import 'package:ritmo/data/repositories/waiver_repository.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/day/waiver_policy.dart' as domain;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late db.RitmoDatabase database;
  late WaiverRepository waivers;
  late PillarEntriesRepository pillars;
  late DayRepository days;
  late tz.Location location;
  // 2026-03-09 é segunda-feira, portanto dia útil.
  final date = OperationalDate(2026, 3, 9);
  late tz.TZDateTime at;

  setUp(() async {
    database = db.RitmoDatabase(NativeDatabase.memory());
    location = ensureBusinessLocation();
    at = tz.TZDateTime(location, 2026, 3, 9, 21, 15);
    waivers = WaiverRepository(database, businessLocation: location);
    pillars = PillarEntriesRepository(database, businessLocation: location);
    days = DayRepository(database, businessLocation: location);
    _success(await days.ensureDayMaterialized(date));
  });

  tearDown(() => database.close());

  Future<domain.PillarWaiver> createWaiver(Pillar pillar, {String? id}) async =>
      _success(
        await waivers.create(
          id: id ?? 'waiver-${pillar.name}',
          date: date,
          pillar: pillar,
          reasonText: 'Motivo de ${pillar.name}',
        ),
      );

  Future<void> completeMorning() async {
    _success(await pillars.completeWorkout(date, at: at));
    _success(await pillars.completeBriefingManually(date, at: at));
  }

  Future<int?> revokedAtOf(String id) async {
    final history = await waivers.historyFor(date);
    final stored = history.firstWhere((waiver) => waiver.id == id);
    return stored.revokedAt?.millisecondsSinceEpoch;
  }

  test(
    'revoga a dispensa, conclui o pilar e remove o efeito sobre o selo',
    () async {
      final created = await createWaiver(Pillar.night);
      await completeMorning();
      _success(await pillars.recordDay(date, toggleOn: true));

      final result = await waivers.revokeForCompletion(
        date: date,
        pillar: Pillar.night,
        at: at,
        confirmed: true,
        completion: const db.PillarEntriesCompanion(
          nightKind: Value('recovery'),
        ),
      );

      final outcome = _success(result);
      expect(outcome.completedPillar, Pillar.night);
      expect(outcome.revokedAt, at);
      expect(await revokedAtOf(created.id), at.millisecondsSinceEpoch);
      expect(await waivers.activeWaiverFor(date), isNull);
      expect((await pillars.statusForDate(date)).nightCompleted, isTrue);

      // O selo passa a valer pelos três pilares concluídos, sem dispensa.
      final sealed = _success(await days.sealDay(date, at: at));
      expect(sealed.baseResult.name, 'sealed');
    },
  );

  test('sem confirmação neutra nada é revogado nem concluído', () async {
    final created = await createWaiver(Pillar.night);

    final result = await waivers.revokeForCompletion(
      date: date,
      pillar: Pillar.night,
      at: at,
      confirmed: false,
      completion: const db.PillarEntriesCompanion(nightKind: Value('recovery')),
    );

    expect(_failure(result).code, 'waiver_revoke_confirmation_required');
    expect(await revokedAtOf(created.id), isNull);
    expect((await waivers.activeWaiverFor(date))?.id, created.id);
    expect((await pillars.entriesForDate(date)).night, isNull);
  });

  test('dia encerrado rejeita a revogação', () async {
    final created = await createWaiver(Pillar.night);
    await database.customStatement(
      'UPDATE days SET closed_at = ? WHERE operational_date = ?',
      [at.millisecondsSinceEpoch, date.iso],
    );

    final result = await waivers.revokeForCompletion(
      date: date,
      pillar: Pillar.night,
      at: at,
      confirmed: true,
      completion: const db.PillarEntriesCompanion(nightKind: Value('recovery')),
    );

    expect(_failure(result).code, 'day_closed');
    expect(await revokedAtOf(created.id), isNull);
    expect((await pillars.entriesForDate(date)).night, isNull);
  });

  test('conclusão incompleta desfaz a revogação inteira', () async {
    final created = await createWaiver(Pillar.morning);

    // Somente o treino: sem o briefing o Pilar da Manhã não fica concluído.
    final result = await waivers.revokeForCompletion(
      date: date,
      pillar: Pillar.morning,
      at: at,
      confirmed: true,
      completion: db.PillarEntriesCompanion(
        workoutDone: const Value(true),
        workoutAt: Value(at.millisecondsSinceEpoch),
      ),
    );

    expect(_failure(result).code, 'waiver_completion_incomplete');
    expect(await revokedAtOf(created.id), isNull);
    expect((await pillars.entriesForDate(date)).morning, isNull);
  });

  test('dispensa revogada permite nova dispensa e segue auditável', () async {
    final first = await createWaiver(Pillar.day, id: 'waiver-1');
    expect(
      _failure(
        await waivers.create(
          id: 'waiver-2',
          date: date,
          pillar: Pillar.night,
          reasonText: 'Segunda ativa no mesmo dia',
        ),
      ).code,
      'waiver_active_already_exists',
    );

    _success(
      await waivers.revokeForCompletion(
        date: date,
        pillar: Pillar.day,
        at: at,
        confirmed: true,
        completion: const db.PillarEntriesCompanion(toggleOn: Value(true)),
      ),
    );
    final second = await createWaiver(Pillar.night, id: 'waiver-3');

    final history = await waivers.historyFor(date);
    expect(history.map((waiver) => waiver.id), [first.id, second.id]);
    expect(history.first.isActive, isFalse);
    expect(history.first.reasonText, first.reasonText);
    expect((await waivers.activeWaiverFor(date))?.id, second.id);
    // A revogada não confirma a Regra do Retorno para a nova dispensa.
    expect(second.recurrenceConfirmed, isFalse);
  });
}

T _success<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => value,
  onFailure: (failure) => throw TestFailure(
    'Esperava sucesso, veio ${failure.code}: ${failure.message}',
  ),
);

F _failure<T, F extends RitmoFailure>(Result<T, F> result) => result.fold(
  onSuccess: (value) => throw TestFailure('Esperava falha, veio $value'),
  onFailure: (failure) => failure,
);
