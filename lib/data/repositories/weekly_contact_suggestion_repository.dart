import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/people/contact.dart';
import '../../domain/people/weekly_contact_suggestion.dart' as domain;
import '../../domain/time/operational_calendar.dart';
import '../db/database.dart' as db;

/// Persistência da progressão semanal de sugestões de contato (RD-19).
///
/// Toda mutação roda em transação. A unicidade `(week_start, contact_id)`
/// garante um único registro por contato na semana, o que impede reinício da
/// ordem (RF-07.11). Opera apenas sobre `weekly_contact_suggestions` e
/// `contacts`; nunca toca em mentoria.
final class WeeklyContactSuggestionRepository {
  const WeeklyContactSuggestionRepository(this._database);

  final db.RitmoDatabase _database;

  static const _progression = domain.WeeklySuggestionProgression();

  /// Fluxo das linhas persistidas de uma semana operacional.
  Stream<List<domain.WeeklyContactSuggestion>> watchWeek(
    OperationalDate weekStart,
  ) =>
      (_database.select(
        _database.weeklyContactSuggestions,
      )..where((row) => row.weekStart.equals(weekStart.iso))).watch().map(
        (rows) => List<domain.WeeklyContactSuggestion>.unmodifiable(
          rows.map(_toDomain),
        ),
      );

  /// Garante que exista uma sugestão `pending` para a semana quando ainda há
  /// contatos não registrados, sem reiniciar a ordem nem substituir uma
  /// sugestão já persistida (RF-07.7, RF-07.8, RF-07.17). É idempotente:
  /// quando já há um `pending` vigente ou a semana está esgotada, não escreve.
  Future<void> ensureCurrentSuggestion({
    required OperationalDate weekStart,
    required List<Contact> orderedContacts,
    required tz.TZDateTime at,
  }) => _database.transaction(() async {
    final rows = await _weekRows(weekStart);
    final hasPending = rows.any(
      (row) => row.status == domain.SuggestionStatus.pending,
    );
    if (hasPending) return;

    final next = _progression.nextUnrecorded(
      orderedContacts: orderedContacts,
      recordedContactIds: rows.map((row) => row.contactId),
    );
    if (next == null) return;

    await _insertPending(weekStart, next.id, at);
  });

  /// Marca a sugestão vigente como realizada e atualiza `last_touch_date` do
  /// contato para a data operacional vigente, no mesmo commit (RF-07.9).
  Future<bool> markDone({
    required OperationalDate weekStart,
    required String contactId,
    required OperationalDate touchedOn,
  }) => _database.transaction(() async {
    final updated = await _setStatus(
      weekStart,
      contactId,
      domain.SuggestionStatus.done,
    );
    if (!updated) return false;
    await (_database.update(_database.contacts)
          ..where((row) => row.id.equals(contactId)))
        .write(db.ContactsCompanion(lastTouchDate: Value(touchedOn.iso)));
    return true;
  });

  /// Marca a sugestão vigente como adiada e materializa o próximo contato da
  /// ordem como novo `pending`, sem reiniciar a semana (RF-07.10, RF-07.11).
  Future<bool> skip({
    required OperationalDate weekStart,
    required String contactId,
    required List<Contact> orderedContacts,
    required tz.TZDateTime at,
  }) => _database.transaction(() async {
    final updated = await _setStatus(
      weekStart,
      contactId,
      domain.SuggestionStatus.skipped,
    );
    if (!updated) return false;

    final rows = await _weekRows(weekStart);
    final next = _progression.nextUnrecorded(
      orderedContacts: orderedContacts,
      recordedContactIds: rows.map((row) => row.contactId),
    );
    if (next != null) {
      await _insertPending(weekStart, next.id, at);
    }
    return true;
  });

  /// Escolha manual de um contato sem penalidade (RF-07.12). O contato
  /// escolhido recebe `done`, atualizando seu `last_touch_date`; qualquer
  /// sugestão `pending` vigente é adiada para preservar a progressão.
  Future<bool> chooseManually({
    required OperationalDate weekStart,
    required String contactId,
    required OperationalDate touchedOn,
  }) => _database.transaction(() async {
    final rows = await _weekRows(weekStart);
    for (final row in rows) {
      if (row.status == domain.SuggestionStatus.pending) {
        await _setStatus(
          weekStart,
          row.contactId,
          domain.SuggestionStatus.skipped,
        );
      }
    }

    final existing = rows.where((row) => row.contactId == contactId).toList();
    if (existing.isEmpty) {
      await _insert(
        weekStart,
        contactId,
        domain.SuggestionStatus.done,
        _nowMillis(rows),
      );
    } else {
      await _forceStatus(weekStart, contactId, domain.SuggestionStatus.done);
    }

    await (_database.update(_database.contacts)
          ..where((row) => row.id.equals(contactId)))
        .write(db.ContactsCompanion(lastTouchDate: Value(touchedOn.iso)));
    return true;
  });

  Future<List<domain.WeeklyContactSuggestion>> _weekRows(
    OperationalDate weekStart,
  ) async {
    final rows = await (_database.select(
      _database.weeklyContactSuggestions,
    )..where((row) => row.weekStart.equals(weekStart.iso))).get();
    return rows.map(_toDomain).toList();
  }

  Future<bool> _setStatus(
    OperationalDate weekStart,
    String contactId,
    domain.SuggestionStatus status,
  ) async {
    final changed =
        await (_database.update(_database.weeklyContactSuggestions)..where(
              (row) =>
                  row.weekStart.equals(weekStart.iso) &
                  row.contactId.equals(contactId) &
                  row.status.equals(domain.SuggestionStatus.pending.name),
            ))
            .write(
              db.WeeklyContactSuggestionsCompanion(status: Value(status.name)),
            );
    return changed == 1;
  }

  Future<void> _forceStatus(
    OperationalDate weekStart,
    String contactId,
    domain.SuggestionStatus status,
  ) =>
      (_database.update(_database.weeklyContactSuggestions)..where(
            (row) =>
                row.weekStart.equals(weekStart.iso) &
                row.contactId.equals(contactId),
          ))
          .write(
            db.WeeklyContactSuggestionsCompanion(status: Value(status.name)),
          );

  Future<void> _insertPending(
    OperationalDate weekStart,
    String contactId,
    tz.TZDateTime at,
  ) => _insert(
    weekStart,
    contactId,
    domain.SuggestionStatus.pending,
    at.millisecondsSinceEpoch,
  );

  Future<void> _insert(
    OperationalDate weekStart,
    String contactId,
    domain.SuggestionStatus status,
    int createdAtMillis,
  ) => _database
      .into(_database.weeklyContactSuggestions)
      .insert(
        db.WeeklyContactSuggestionsCompanion.insert(
          weekStart: weekStart.iso,
          contactId: contactId,
          status: status.name,
          createdAt: createdAtMillis,
        ),
      );

  /// Instante monotônico para uma inserção manual quando não há `at` explícito:
  /// um após o maior `created_at` já registrado na semana, preservando a ordem.
  int _nowMillis(List<domain.WeeklyContactSuggestion> rows) {
    var maximum = 0;
    for (final row in rows) {
      if (row.createdAtMillisecondsSinceEpoch > maximum) {
        maximum = row.createdAtMillisecondsSinceEpoch;
      }
    }
    return maximum + 1;
  }

  domain.WeeklyContactSuggestion _toDomain(db.WeeklyContactSuggestion row) =>
      domain.WeeklyContactSuggestion(
        weekStart: _parseDate(row.weekStart),
        contactId: row.contactId,
        status: _status(row.status),
        createdAtMillisecondsSinceEpoch: row.createdAt,
      );

  domain.SuggestionStatus _status(String value) => switch (value) {
    'pending' => domain.SuggestionStatus.pending,
    'done' => domain.SuggestionStatus.done,
    'skipped' => domain.SuggestionStatus.skipped,
    _ => throw StateError('Status de sugestão persistido inválido: $value.'),
  };

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
