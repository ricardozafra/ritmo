import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_plan.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;

/// Persistência dos planos semanais de notificação (RD-24).
///
/// A idempotência é garantida pela chave primária `idempotency_key`
/// (`"<kind>:<week_start ISO>"`): reagendamentos e mudanças de fuso do aparelho
/// não criam duplicatas (RNF-04.3, RNF-04.8, RNF-04.9). O repositório não
/// aplica política de blackout — isso é decidido antes, pelo domínio, e
/// coordenado pelo `NotificationScheduler`.
final class NotificationPlansRepository {
  NotificationPlansRepository(this._database, {tz.Location? businessLocation})
    : _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _businessLocation;

  /// Fluxo de todos os planos, para observação (por exemplo, testes e
  /// diagnósticos). Ordena por instante planejado crescente.
  Stream<List<NotificationPlan>> watchAll() =>
      (_database.select(_database.notificationPlans)
            ..orderBy([(row) => OrderingTerm(expression: row.plannedAt)]))
          .watch()
          .map(
            (rows) => List<NotificationPlan>.unmodifiable(rows.map(_toDomain)),
          );

  /// Planos ainda agendados (`planned`), em ordem de entrega.
  Future<List<NotificationPlan>> loadPlanned() async {
    final rows =
        await (_database.select(_database.notificationPlans)
              ..where((row) => row.state.equals(PlanState.planned.wireValue))
              ..orderBy([(row) => OrderingTerm(expression: row.plannedAt)]))
            .get();
    return List<NotificationPlan>.unmodifiable(rows.map(_toDomain));
  }

  /// Plano por chave idempotente, ou `null` quando não existe.
  Future<NotificationPlan?> findByKey(String idempotencyKey) async {
    final row =
        await (_database.select(_database.notificationPlans)
              ..where((row) => row.idempotencyKey.equals(idempotencyKey)))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Insere ou atualiza um plano por chave idempotente. Idempotente por
  /// construção: a mesma chave sobrescreve o registro anterior sem duplicar.
  Future<void> upsert(NotificationPlan plan) => _database
      .into(_database.notificationPlans)
      .insert(_toCompanion(plan), mode: InsertMode.insertOrReplace);

  /// Atualiza somente o estado de um plano existente.
  Future<void> updateState(String idempotencyKey, PlanState state) =>
      (_database.update(_database.notificationPlans)
            ..where((row) => row.idempotencyKey.equals(idempotencyKey)))
          .write(db.NotificationPlansCompanion(state: Value(state.wireValue)));

  /// Remove planos cujas chaves não estão em [keepKeys], marcando-os como
  /// `cancelled` antes de descartar o agendamento. Retorna as chaves removidas.
  Future<List<String>> cancelPlansNotIn(Set<String> keepKeys) =>
      _database.transaction(() async {
        final rows = await _database.select(_database.notificationPlans).get();
        final removed = <String>[];
        for (final row in rows) {
          if (keepKeys.contains(row.idempotencyKey)) continue;
          if (row.state == PlanState.delivered.wireValue) continue;
          await (_database.update(
            _database.notificationPlans,
          )..where((r) => r.idempotencyKey.equals(row.idempotencyKey))).write(
            db.NotificationPlansCompanion(
              state: Value(PlanState.cancelled.wireValue),
            ),
          );
          removed.add(row.idempotencyKey);
        }
        return List<String>.unmodifiable(removed);
      });

  db.NotificationPlansCompanion _toCompanion(NotificationPlan plan) =>
      db.NotificationPlansCompanion.insert(
        idempotencyKey: plan.idempotencyKey,
        kind: plan.kind.wireValue,
        plannedAt: plan.plannedAt.millisecondsSinceEpoch,
        state: plan.state.wireValue,
      );

  NotificationPlan _toDomain(db.NotificationPlan row) {
    final kind = NotificationKind.fromWire(row.kind);
    if (kind == null) {
      throw StateError('Tipo de plano persistido inválido: ${row.kind}.');
    }
    final state = PlanState.fromWire(row.state);
    if (state == null) {
      throw StateError('Estado de plano persistido inválido: ${row.state}.');
    }
    return NotificationPlan(
      idempotencyKey: row.idempotencyKey,
      kind: kind,
      plannedAt: tz.TZDateTime.fromMillisecondsSinceEpoch(
        _businessLocation,
        row.plannedAt,
      ),
      state: state,
    );
  }
}
