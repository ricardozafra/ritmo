import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../domain/protocol/protocol_alarm.dart' as domain;
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../db/database.dart' as db;

/// Leitura dos protocolos e persistência das respostas do formulário.
///
/// Nada é apagado: responder apenas acrescenta data de disparo, causa,
/// classificação `plan|execution` e ajuste ao protocolo pendente e muda seu
/// estado para `answered` (RF-03.15). Protocolos `answered` e `invalidated`
/// nunca voltam a ser respondidos (RF-03.17). A camada não envia push,
/// cobrança ou alerta externo (RF-03.21).
final class ProtocolRepository {
  ProtocolRepository(
    this._database, {
    tz.Location? businessLocation,
    this._limits = const LimitPolicy(),
  }) : _businessLocation = businessLocation ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _businessLocation;
  final LimitPolicy _limits;

  /// Protocolos pendentes em ordem total determinística: `start_date`, `id`.
  ///
  /// Sequências distintas podem manter vários pendentes ao mesmo tempo
  /// (RF-03.9); a seleção de qual exibir pertence ao `ProtocolSessionGate`.
  Future<List<domain.ProtocolAlarm>> pendingProtocols() async {
    final rows =
        await (_database.select(_database.protocolAlarms)
              ..where((row) => row.state.equals(_pending))
              ..orderBy([
                (row) => OrderingTerm(expression: row.startDate),
                (row) => OrderingTerm(expression: row.id),
              ]))
            .get();
    return rows.map(_asDomain).toList();
  }

  /// Histórico completo em ordem cronológica determinística.
  ///
  /// A consulta inclui `pending`, `answered` e `invalidated` e não oferece
  /// nenhuma mutação; a apresentação da sessão continua separada.
  Stream<List<domain.ProtocolAlarm>> watchHistory() =>
      (_database.select(_database.protocolAlarms)..orderBy([
            (row) => OrderingTerm(expression: row.startDate),
            (row) => OrderingTerm(expression: row.id),
          ]))
          .watch()
          .map(
            (rows) =>
                List<domain.ProtocolAlarm>.unmodifiable(rows.map(_asDomain)),
          );

  Future<domain.ProtocolAlarm?> findById(String id) async {
    final row = await (_database.select(
      _database.protocolAlarms,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return row == null ? null : _asDomain(row);
  }

  /// Persiste a resposta e muda o estado para `answered`, em uma transação.
  ///
  /// A atualização é condicionada a `state = 'pending'`, portanto duas
  /// respostas concorrentes ao mesmo protocolo não se sobrescrevem: a segunda é
  /// rejeitada com motivo neutro.
  Future<Result<domain.ProtocolAlarm, BusinessViolation>> answer({
    required String id,
    required domain.ProtocolAnswer answer,
  }) async {
    final cause = _limits.clampRunes(answer.cause, Limits.protocolTextMaxRunes);
    if (cause.violation case final violation?) {
      return Result<domain.ProtocolAlarm, BusinessViolation>.failure(violation);
    }
    final adjustment = _limits.clampRunes(
      answer.adjustment,
      Limits.protocolTextMaxRunes,
    );
    if (adjustment.violation case final violation?) {
      return Result<domain.ProtocolAlarm, BusinessViolation>.failure(violation);
    }

    return _database.transaction(() async {
      final current = await (_database.select(
        _database.protocolAlarms,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (current == null) {
        return Result<domain.ProtocolAlarm, BusinessViolation>.failure(
          const ProtocolViolation(
            code: 'protocol_not_found',
            message: 'Este protocolo não está mais disponível.',
          ),
        );
      }
      if (current.state != _pending) {
        return Result<domain.ProtocolAlarm, BusinessViolation>.failure(
          const ProtocolViolation(
            code: 'protocol_not_pending',
            message: 'Este protocolo não está mais disponível.',
          ),
        );
      }

      final updated =
          await (_database.update(
                _database.protocolAlarms,
              )..where((row) => row.id.equals(id) & row.state.equals(_pending)))
              .write(
                db.ProtocolAlarmsCompanion(
                  state: const Value(_answered),
                  triggeredAt: Value(answer.triggeredAt.millisecondsSinceEpoch),
                  cause: Value(cause.value),
                  planOrExecution: Value(answer.planOrExecution.name),
                  adjustment: Value(adjustment.value),
                ),
              );
      if (updated != 1) {
        return Result<domain.ProtocolAlarm, BusinessViolation>.failure(
          const ProtocolViolation(
            code: 'protocol_not_pending',
            message: 'Este protocolo não está mais disponível.',
          ),
        );
      }

      final row = await (_database.select(
        _database.protocolAlarms,
      )..where((row) => row.id.equals(id))).getSingle();
      return Result<domain.ProtocolAlarm, BusinessViolation>.success(
        _asDomain(row),
      );
    });
  }

  static const String _pending = 'pending';
  static const String _answered = 'answered';

  domain.ProtocolAlarm _asDomain(db.ProtocolAlarm row) => domain.ProtocolAlarm(
    id: row.id,
    generationId: row.generationId,
    startDate: _parseDate(row.startDate),
    endDate: _parseDate(row.endDate),
    sequenceLength: row.sequenceLength,
    state: _state(row.state),
    previousState: row.previousState == null
        ? null
        : _state(row.previousState!),
    triggeredAt: row.triggeredAt == null
        ? null
        : tz.TZDateTime.fromMillisecondsSinceEpoch(
            _businessLocation,
            row.triggeredAt!,
          ),
    cause: row.cause,
    planOrExecution: row.planOrExecution == null
        ? null
        : _planOrExecution(row.planOrExecution!),
    adjustment: row.adjustment,
  );

  domain.ProtocolState _state(String value) => switch (value) {
    _pending => domain.ProtocolState.pending,
    _answered => domain.ProtocolState.answered,
    'invalidated' => domain.ProtocolState.invalidated,
    _ => throw StateError('Estado de protocolo persistido inválido: $value'),
  };

  domain.PlanOrExecution _planOrExecution(String value) => switch (value) {
    'plan' => domain.PlanOrExecution.plan,
    'execution' => domain.PlanOrExecution.execution,
    _ => throw StateError('Classificação persistida inválida: $value'),
  };

  OperationalDate _parseDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Data operacional inválida', iso);
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
