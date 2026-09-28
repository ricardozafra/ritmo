import 'package:drift/drift.dart';

import '../../app/ritmo/ritmo_projection.dart' show OperationalDateCodec;
import '../../domain/cycles/cycle_policy.dart' show Competency;
import '../../domain/people/mentorship.dart';
import '../db/database.dart' as db;

/// Leitura e edição dos três cartões fixos de mentoria.
///
/// Opera exclusivamente sobre `mentorships`, sem tocar em `contacts` nem em
/// qualquer estrutura do rodízio semanal (RF-07.18, RF-07.19). Os cartões são
/// semeados na criação do banco; este repositório apenas os observa e atualiza.
final class MentorshipRepository {
  const MentorshipRepository(this._database);

  final db.RitmoDatabase _database;

  /// Fluxo dos cartões, ordenados de forma estável por competência.
  Stream<List<Mentorship>> watchAll() =>
      (_database.select(_database.mentorships)
            ..orderBy([(row) => OrderingTerm(expression: row.competency)]))
          .watch()
          .map((rows) => List<Mentorship>.unmodifiable(rows.map(_toDomain)));

  /// Atualiza nome do mentor e/ou data do último encontro de um cartão.
  ///
  /// Ambos os campos são anuláveis: passar `Value(null)` limpa o valor. A
  /// competência e o identificador nunca mudam. Retorna verdadeiro quando uma
  /// linha foi efetivamente escrita.
  Future<bool> updateCard({
    required String id,
    Value<String?> mentorName = const Value.absent(),
    Value<String?> lastMeetingDate = const Value.absent(),
  }) async {
    final changed =
        await (_database.update(
          _database.mentorships,
        )..where((row) => row.id.equals(id))).write(
          db.MentorshipsCompanion(
            mentorName: mentorName,
            lastMeetingDate: lastMeetingDate,
          ),
        );
    return changed == 1;
  }

  Mentorship _toDomain(db.Mentorship row) => Mentorship(
    id: row.id,
    competency: _competency(row.competency),
    mentorName: row.mentorName,
    lastMeetingDate: row.lastMeetingDate == null
        ? null
        : (OperationalDateCodec.tryParse(row.lastMeetingDate!) ??
              (throw StateError(
                'Data de último encontro persistida inválida em '
                '${row.id}: ${row.lastMeetingDate}.',
              ))),
  );

  Competency _competency(String value) => switch (value) {
    'ST' => Competency.st,
    'IN' => Competency.in_,
    'CA' => Competency.ca,
    _ => throw StateError(
      'Competência de mentoria persistida inválida: $value.',
    ),
  };
}
