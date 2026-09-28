import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/ritmo/ritmo_projection.dart' show OperationalDateCodec;
import '../../domain/people/contact.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;

/// Cadastro e leitura de contatos do rodízio semanal.
///
/// Opera exclusivamente sobre `contacts`. Nunca lê, cria ou infere um contato a
/// partir de `mentorships` (RF-07.18, RF-07.19, RF-07.20).
final class ContactRepository {
  ContactRepository(this._database, {tz.Location? businessLocation})
    : _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _businessLocation;

  /// Fluxo de todos os contatos, sem ordem de negócio aplicada; a ordem semanal
  /// é responsabilidade pura de `ContactOrdering`.
  Stream<List<Contact>> watchAll() => _database
      .select(_database.contacts)
      .watch()
      .map((rows) => List<Contact>.unmodifiable(rows.map(_toDomain)));

  /// Insere um novo contato. [createdAt] vem do relógio oficial do chamador.
  Future<void> create({
    required String id,
    required String name,
    required tz.TZDateTime createdAt,
    String? contextNote,
    OperationalDate? lastTouchDate,
  }) => _database
      .into(_database.contacts)
      .insert(
        db.ContactsCompanion.insert(
          id: id,
          name: name,
          contextNote: Value(contextNote),
          lastTouchDate: Value(lastTouchDate?.iso),
          createdAt: createdAt.millisecondsSinceEpoch,
        ),
      );

  /// Atualiza os campos editáveis de um contato existente. Campos ausentes
  /// permanecem inalterados; `Value(null)` limpa. Retorna verdadeiro quando
  /// uma linha foi escrita.
  Future<bool> update({
    required String id,
    Value<String> name = const Value.absent(),
    Value<String?> contextNote = const Value.absent(),
    Value<String?> lastTouchDate = const Value.absent(),
  }) async {
    final changed =
        await (_database.update(
          _database.contacts,
        )..where((row) => row.id.equals(id))).write(
          db.ContactsCompanion(
            name: name,
            contextNote: contextNote,
            lastTouchDate: lastTouchDate,
          ),
        );
    return changed == 1;
  }

  Contact _toDomain(db.Contact row) => Contact(
    id: row.id,
    name: row.name,
    contextNote: row.contextNote,
    lastTouchDate: row.lastTouchDate == null
        ? null
        : (OperationalDateCodec.tryParse(row.lastTouchDate!) ??
              (throw StateError(
                'Data de último toque persistida inválida em '
                '${row.id}: ${row.lastTouchDate}.',
              ))),
    createdAt: tz.TZDateTime.fromMillisecondsSinceEpoch(
      _businessLocation,
      row.createdAt,
    ),
  );
}
