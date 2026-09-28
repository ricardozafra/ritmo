import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/day/eligible_day.dart';
import '../../domain/protocol/failure_sequence_detector.dart';
import '../../domain/time/operational_calendar.dart';
import '../db/database.dart' as db;

/// Efeito de uma reconciliação, sempre aditivo sobre o histórico.
///
/// As listas contêm identificadores de geração (`seq:YYYY-MM-DD`). Um protocolo
/// nunca é apagado: ele é criado, atualizado em `sequence_length`/`end_date` ou
/// invalidado preservando o estado anterior e todos os seus dados.
final class ReconcileReport {
  ReconcileReport({
    required this.scopeStart,
    Iterable<String> created = const [],
    Iterable<String> updated = const [],
    Iterable<String> invalidated = const [],
  }) : created = List.unmodifiable(created),
       updated = List.unmodifiable(updated),
       invalidated = List.unmodifiable(invalidated);

  ReconcileReport.untouched() : this(scopeStart: null);

  /// Primeira data considerada, já expandida até o início da sequência.
  final OperationalDate? scopeStart;
  final List<String> created;
  final List<String> updated;
  final List<String> invalidated;

  bool get changedNothing =>
      created.isEmpty && updated.isEmpty && invalidated.isEmpty;

  @override
  String toString() =>
      'ReconcileReport(scopeStart: ${scopeStart?.iso}, '
      'created: $created, updated: $updated, invalidated: $invalidated)';
}

enum ProtocolReconcileReason {
  /// Fechamentos futuros podem ampliar a mesma sequência e a mesma revisão.
  normalProgress,

  /// Uma reclassificação por feriado cria nova revisão se qualquer parte do
  /// critério da sequência mudar, preservando o protocolo anterior.
  holidayMutation,
}

/// Reconcilia os Alarmes de Protocolo com as sequências de falha persistidas.
///
/// Determinístico, idempotente e não destrutivo (RNF-04.10): a mesma linha
/// temporal produz o mesmo conjunto de protocolos vivos, repetir a operação não
/// altera nada e nenhum protocolo invalidado é reutilizado, restaurado ou
/// reativado (RF-03.17, RD-15).
final class ProtocolReconciler {
  ProtocolReconciler(
    this._database, {
    this.detector = const FailureSequenceDetector(),
  });

  final db.RitmoDatabase _database;
  final FailureSequenceDetector detector;

  /// Mutex de processo: serializa reconciliações concorrentes (RF-03.8).
  static Future<void> _tail = Future<void>.value();

  /// Reconcilia a partir de [from], em uma única transação.
  ///
  /// [from] é a data afetada por um fechamento, selo, reabertura ou feriado.
  /// Quando nulo, todo o histórico a partir de `activation_date` é reconciliado.
  Future<ReconcileReport> reconcileProtocols({
    OperationalDate? from,
    ProtocolReconcileReason reason = ProtocolReconcileReason.normalProgress,
  }) {
    return runExclusive(
      () => _database.transaction(
        () => reconcileWithinTransaction(from: from, reason: reason),
      ),
    );
  }

  /// Executa [body] com o mutex de processo tomado.
  ///
  /// Operações compostas (recálculo de feriado, travessia de fronteira) devem
  /// envolver sua transação com este método e chamar
  /// [reconcileWithinTransaction] dentro dela, nunca [reconcileProtocols], que
  /// tomaria o mutex uma segunda vez.
  static Future<T> runExclusive<T>(Future<T> Function() body) {
    final completer = Completer<void>();
    final previous = _tail;
    _tail = completer.future;
    return previous.then((_) => body()).whenComplete(completer.complete);
  }

  /// Corpo da reconciliação. Requer transação e mutex já tomados pelo chamador.
  Future<ReconcileReport> reconcileWithinTransaction({
    OperationalDate? from,
    ProtocolReconcileReason reason = ProtocolReconcileReason.normalProgress,
  }) async {
    final activationDate = await _readActivationDate();
    if (activationDate == null) return ReconcileReport.untouched();

    final timeline = await _readTimeline();
    final scopeStart = _expandToSequenceStart(timeline, activationDate, from);
    final sequences = detector
        .detect(timeline, activationDate)
        .where((sequence) => sequence.startDate >= scopeStart)
        .toList();
    final expected = {
      for (final sequence in sequences) sequence.generationId: sequence,
    };

    final invalidated = <String>[];
    for (final live in await _readLiveProtocols(scopeStart)) {
      final expectedSequence = expected[live.generationId];
      final keepsRevision = switch (reason) {
        ProtocolReconcileReason.normalProgress => expectedSequence != null,
        ProtocolReconcileReason.holidayMutation =>
          expectedSequence != null &&
              live.startDate == expectedSequence.startDate.iso &&
              live.endDate == expectedSequence.endDate.iso &&
              live.sequenceLength == expectedSequence.length,
      };
      if (keepsRevision) continue;
      await _invalidate(live.id);
      invalidated.add(live.generationId);
    }

    final created = <String>[];
    final updated = <String>[];
    for (final sequence in sequences) {
      var live = await _readLiveProtocol(sequence.generationId);
      if (live == null) {
        await _insertPending(sequence);
        created.add(sequence.generationId);
        live = await _readLiveProtocol(sequence.generationId);
      }
      // Releitura após a inserção: uma execução concorrente pode ter criado o
      // protocolo com outro comprimento, e a convergência é obrigatória.
      if (live == null) continue;
      if (live.sequenceLength == sequence.length &&
          live.endDate == sequence.endDate.iso) {
        continue;
      }
      await _updateExtent(live.id, sequence);
      if (!created.contains(sequence.generationId)) {
        updated.add(sequence.generationId);
      }
    }

    return ReconcileReport(
      scopeStart: scopeStart,
      created: created,
      updated: updated,
      invalidated: invalidated,
    );
  }

  /// Caminha para trás sobre dias úteis não `mute` enquanto forem falhas, para
  /// que o `generation_id` reflita o início real da sequência (RF-03.3).
  OperationalDate _expandToSequenceStart(
    List<EligibleDay> timeline,
    OperationalDate activationDate,
    OperationalDate? from,
  ) {
    if (from == null) return activationDate;
    var scopeStart = from < activationDate ? activationDate : from;

    final relevant =
        timeline
            .where(
              (day) =>
                  day.date >= activationDate && day.isWorkday && !day.isMute,
            )
            .toList()
          ..sort((left, right) => right.date.compareTo(left.date));

    for (final day in relevant) {
      if (day.date >= scopeStart) continue;
      final isFailure = day.isClosed && !day.isSealed;
      if (!isFailure) break;
      scopeStart = day.date;
    }
    return scopeStart;
  }

  Future<void> _insertPending(FailureSequence sequence) async {
    final revision = await _countProtocols(sequence.generationId);
    await _database.customInsert(
      'INSERT INTO protocol_alarms '
      '(id, generation_id, start_date, end_date, sequence_length, state) '
      "VALUES (?, ?, ?, ?, ?, 'pending') ON CONFLICT DO NOTHING",
      variables: [
        Variable.withString('${sequence.generationId}#$revision'),
        Variable.withString(sequence.generationId),
        Variable.withString(sequence.startDate.iso),
        Variable.withString(sequence.endDate.iso),
        Variable.withInt(sequence.length),
      ],
      updates: {_database.protocolAlarms},
    );
  }

  Future<void> _updateExtent(String id, FailureSequence sequence) async {
    await _database.customUpdate(
      'UPDATE protocol_alarms SET sequence_length = ?, end_date = ? '
      "WHERE id = ? AND state <> 'invalidated'",
      variables: [
        Variable.withInt(sequence.length),
        Variable.withString(sequence.endDate.iso),
        Variable.withString(id),
      ],
      updates: {_database.protocolAlarms},
    );
  }

  /// `previous_state` recebe o estado vivo anterior; nenhum dado é apagado.
  Future<void> _invalidate(String id) async {
    await _database.customUpdate(
      "UPDATE protocol_alarms SET state = 'invalidated', previous_state = state "
      "WHERE id = ? AND state <> 'invalidated'",
      variables: [Variable.withString(id)],
      updates: {_database.protocolAlarms},
    );
  }

  Future<int> _countProtocols(String generationId) async {
    final row = await _database
        .customSelect(
          'SELECT count(*) AS total FROM protocol_alarms '
          'WHERE generation_id = ?',
          variables: [Variable.withString(generationId)],
          readsFrom: {_database.protocolAlarms},
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<List<_LiveProtocol>> _readLiveProtocols(
    OperationalDate scopeStart,
  ) async {
    final rows = await _database
        .customSelect(
          'SELECT id, generation_id, start_date, end_date, sequence_length '
          "FROM protocol_alarms WHERE state <> 'invalidated' "
          'AND start_date >= ? ORDER BY start_date, id',
          variables: [Variable.withString(scopeStart.iso)],
          readsFrom: {_database.protocolAlarms},
        )
        .get();
    return rows.map(_toLiveProtocol).toList();
  }

  Future<_LiveProtocol?> _readLiveProtocol(String generationId) async {
    final row = await _database
        .customSelect(
          'SELECT id, generation_id, start_date, end_date, sequence_length '
          "FROM protocol_alarms WHERE generation_id = ? AND state <> 'invalidated' "
          'LIMIT 1',
          variables: [Variable.withString(generationId)],
          readsFrom: {_database.protocolAlarms},
        )
        .getSingleOrNull();
    return row == null ? null : _toLiveProtocol(row);
  }

  _LiveProtocol _toLiveProtocol(QueryRow row) => _LiveProtocol(
    id: row.read<String>('id'),
    generationId: row.read<String>('generation_id'),
    startDate: row.read<String>('start_date'),
    endDate: row.read<String>('end_date'),
    sequenceLength: row.read<int>('sequence_length'),
  );

  Future<OperationalDate?> _readActivationDate() async {
    final row = await _database
        .customSelect(
          'SELECT activation_date FROM settings WHERE id = 1 LIMIT 1',
          readsFrom: {_database.settings},
        )
        .getSingleOrNull();
    final value = row?.readNullable<String>('activation_date');
    return value == null ? null : _parseDate(value);
  }

  Future<List<EligibleDay>> _readTimeline() async {
    final rows = await _database
        .customSelect(
          'SELECT operational_date, base_result, effective_result, closed_at '
          'FROM days ORDER BY operational_date',
          readsFrom: {_database.days},
        )
        .get();
    return rows.map((row) {
      final date = _parseDate(row.read<String>('operational_date'));
      final isMute = row.read<String>('effective_result') == 'mute';
      return EligibleDay(
        date: date,
        isWorkday: !date.isWeekend && !isMute,
        isClosed: row.readNullable<int>('closed_at') != null,
        isSealed: row.read<String>('base_result') == 'sealed',
        isMute: isMute,
      );
    }).toList();
  }

  OperationalDate _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Data operacional inválida', value);
    }
    return OperationalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

final class _LiveProtocol {
  const _LiveProtocol({
    required this.id,
    required this.generationId,
    required this.startDate,
    required this.endDate,
    required this.sequenceLength,
  });

  final String id;
  final String generationId;
  final String startDate;
  final String endDate;
  final int sequenceLength;
}
