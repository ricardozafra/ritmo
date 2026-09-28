import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/result.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;
import '../db/guarded_writer.dart';

/// Persistência da Revisão Semanal em texto (RD-23).
///
/// A revisão nasce `draft` com autosave por campo; a finalização é explícita e
/// torna o registro read-only, garantido pelo `GuardedWriter`. Uma revisão por
/// semana operacional (`UNIQUE(week_start)`).
final class WeeklyReviewRepository {
  WeeklyReviewRepository(
    this._database, {
    GuardedWriter? writer,
    tz.Location? businessLocation,
  }) : _writer = writer ?? GuardedWriter(_database),
       _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final GuardedWriter _writer;
  final tz.Location _businessLocation;

  /// Fluxo da revisão de uma semana operacional; nulo enquanto não existir.
  Stream<WeeklyReview?> watchWeek(OperationalDate weekStart) =>
      (_database.select(_database.weeklyReviews)
            ..where((row) => row.weekStart.equals(weekStart.iso)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toDomain(row));

  /// Histórico cronológico por semana operacional, da mais recente para a mais
  /// antiga (RF-08.19). Não oferece busca nem filtro (RF-08.24).
  Stream<List<WeeklyReview>> watchHistory() =>
      (_database.select(_database.weeklyReviews)..orderBy([
            (row) => OrderingTerm(
              expression: row.weekStart,
              mode: OrderingMode.desc,
            ),
          ]))
          .watch()
          .map((rows) => List<WeeklyReview>.unmodifiable(rows.map(_toDomain)));

  /// Fluxo de uma revisão por identificador, para o detalhe read-only.
  Stream<WeeklyReview?> watchById(String id) =>
      (_database.select(_database.weeklyReviews)
            ..where((row) => row.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toDomain(row));

  /// Garante uma revisão `draft` para a semana e a retorna. Idempotente:
  /// quando já existe (draft ou finalizada), devolve a persistida sem alterar.
  Future<WeeklyReview> ensureDraft({
    required String id,
    required OperationalDate weekStart,
    required tz.TZDateTime createdAt,
  }) => _database.transaction(() async {
    final existing = await _readByWeek(weekStart);
    if (existing != null) return _toDomain(existing);

    await _database
        .into(_database.weeklyReviews)
        .insert(
          db.WeeklyReviewsCompanion.insert(
            id: id,
            weekStart: weekStart.iso,
            createdAt: createdAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await _readByWeek(weekStart);
    return _toDomain(row!);
  });

  /// Autosava um campo da revisão sem finalizá-la (RF-08.22). Rejeitado por
  /// `GuardedWriter` quando a revisão já está finalizada.
  Future<Result<void, ReviewViolation>> autosaveField({
    required String id,
    required WeeklyReviewField field,
    required String? value,
    required tz.TZDateTime at,
  }) => _writer.writeReview<void>(
    reviewId: id,
    write: () async {
      await (_database.update(
        _database.weeklyReviews,
      )..where((row) => row.id.equals(id))).write(
        db.WeeklyReviewsCompanion(
          answerFulfilled: field == WeeklyReviewField.fulfilled
              ? Value(value)
              : const Value.absent(),
          answerFailed: field == WeeklyReviewField.failed
              ? Value(value)
              : const Value.absent(),
          answerLesson: field == WeeklyReviewField.lesson
              ? Value(value)
              : const Value.absent(),
          autosavedAt: Value(at.millisecondsSinceEpoch),
        ),
      );
    },
  );

  /// Finaliza a revisão, tornando-a read-only (RF-08.23). Rejeitado quando já
  /// finalizada. A finalização e o carimbo `finalized_at` são atômicos.
  Future<Result<void, ReviewViolation>> finalize({
    required String id,
    required tz.TZDateTime at,
  }) => _writer.writeReview<void>(
    reviewId: id,
    write: () async {
      await (_database.update(
        _database.weeklyReviews,
      )..where((row) => row.id.equals(id))).write(
        db.WeeklyReviewsCompanion(
          state: const Value('finalized'),
          finalizedAt: Value(at.millisecondsSinceEpoch),
        ),
      );
    },
  );

  Future<db.WeeklyReview?> _readByWeek(OperationalDate weekStart) =>
      (_database.select(
        _database.weeklyReviews,
      )..where((row) => row.weekStart.equals(weekStart.iso))).getSingleOrNull();

  WeeklyReview _toDomain(db.WeeklyReview row) => WeeklyReview(
    id: row.id,
    weekStart: _parseDate(row.weekStart),
    state: switch (row.state) {
      'draft' => WeeklyReviewState.draft,
      'finalized' => WeeklyReviewState.finalized,
      _ => throw StateError(
        'Estado de revisão persistido inválido: ${row.state}.',
      ),
    },
    answerFulfilled: row.answerFulfilled,
    answerFailed: row.answerFailed,
    answerLesson: row.answerLesson,
    createdAt: _instant(row.createdAt)!,
    autosavedAt: _instant(row.autosavedAt),
    finalizedAt: _instant(row.finalizedAt),
  );

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : tz.TZDateTime.fromMillisecondsSinceEpoch(
          _businessLocation,
          millisecondsSinceEpoch,
        );

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw StateError('week_start persistido inválido: $iso.');
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
