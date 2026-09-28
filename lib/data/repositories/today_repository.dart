import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/cycles/cycle_policy.dart';
import '../../domain/day/change_initiative.dart';
import '../../domain/day/day_state_machine.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/pillar_waiver.dart';
import '../../domain/day/study_block.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../../domain/time/settings_validator.dart';
import '../db/database.dart' as db;

final class TodaySnapshot {
  TodaySnapshot({
    required this.day,
    required this.entries,
    required this.linkedStudyBlock,
    required this.activeWaiver,
    required this.visibleInitiative,
    required this.cycle,
    required Iterable<Checkpoint> checkpoints,
  }) : checkpoints = List.unmodifiable(checkpoints);

  final Day day;
  final PillarEntriesSnapshot entries;
  final StudyBlock? linkedStudyBlock;
  final PillarWaiver? activeWaiver;
  final ChangeInitiative? visibleInitiative;
  final Cycle cycle;
  final List<Checkpoint> checkpoints;
}

final class TodayRepository {
  TodayRepository(this._database, {tz.Location? location})
    : _location = location ?? ensureBusinessLocation();

  final db.RitmoDatabase _database;
  final tz.Location _location;

  Future<OperationalCalendar> loadCalendar() async {
    final settings = await (_database.select(
      _database.settings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    if (settings == null) {
      throw StateError('Configuração persistida ausente: settings id=1.');
    }

    return const SettingsValidator()
        .validateMinutes(
          dayCloseTimeMinutes: settings.dayCloseTimeMin,
          nightEndTimeMinutes: settings.nightEndTimeMin,
        )
        .fold(
          onSuccess: (calendar) => calendar,
          onFailure: (failure) => throw StateError(
            'Configuração de horários persistida inválida '
            '(day_close_time_min=${settings.dayCloseTimeMin}, '
            'night_end_time_min=${settings.nightEndTimeMin}): '
            '${failure.code} — ${failure.message}',
          ),
        );
  }

  Stream<void> watchChanges() => _database
      .customSelect(
        'SELECT 1 AS change_marker',
        readsFrom: {
          _database.days,
          _database.pillarEntries,
          _database.studyBlocks,
          _database.pillarWaivers,
          _database.changeInitiatives,
          _database.cycles,
          _database.checkpoints,
        },
      )
      .watch()
      .map<void>((_) {});

  Future<TodaySnapshot> loadSnapshot(OperationalDate date) =>
      _database.transaction(() => _loadSnapshot(date));

  Future<TodaySnapshot> _loadSnapshot(OperationalDate date) async {
    final dayRow = await (_database.select(
      _database.days,
    )..where((row) => row.operationalDate.equals(date.iso))).getSingleOrNull();
    if (dayRow == null) {
      throw StateError('Dia operacional ${date.iso} não está materializado.');
    }

    final entryRows = await (_database.select(
      _database.pillarEntries,
    )..where((row) => row.operationalDate.equals(date.iso))).get();
    db.PillarEntry? morningRow;
    db.PillarEntry? dayEntryRow;
    db.PillarEntry? nightRow;
    for (final row in entryRows) {
      switch (row.pillar) {
        case 'morning':
          morningRow = row;
        case 'day':
          dayEntryRow = row;
        case 'night':
          nightRow = row;
        default:
          throw StateError(
            'Pilar persistido inválido em ${date.iso}: ${row.pillar}.',
          );
      }
    }

    final entries = PillarEntriesSnapshot(
      morning: morningRow == null ? null : _morningEntry(morningRow),
      day: dayEntryRow == null ? null : _dayEntry(dayEntryRow),
      night: nightRow == null ? null : _nightEntry(nightRow),
    );

    final studyBlockId = entries.night?.studyBlockId;
    final linkedStudyRow = studyBlockId == null
        ? null
        : await (_database.select(_database.studyBlocks)..where(
                (row) =>
                    row.id.equals(studyBlockId) &
                    row.operationalDate.equals(date.iso),
              ))
              .getSingleOrNull();

    final waiverRow =
        await (_database.select(_database.pillarWaivers)..where(
              (row) => row.date.equals(date.iso) & row.revokedAt.isNull(),
            ))
            .getSingleOrNull();

    final historicalInitiativeId = entries.day?.changeInitiativeId;
    final initiativeRow = historicalInitiativeId == null
        ? await (_database.select(
            _database.changeInitiatives,
          )..where((row) => row.active.equals(true))).getSingleOrNull()
        : await (_database.select(_database.changeInitiatives)
                ..where((row) => row.id.equals(historicalInitiativeId)))
              .getSingleOrNull();

    final cycleRow = await (_database.select(
      _database.cycles,
    )..where((row) => row.state.equals('active'))).getSingleOrNull();
    if (cycleRow == null) {
      throw StateError('Nenhum ciclo ativo foi encontrado na persistência.');
    }

    final checkpointRows = await (_database.select(
      _database.checkpoints,
    )..where((row) => row.cycleId.equals(cycleRow.id))).get();

    return TodaySnapshot(
      day: _day(dayRow),
      entries: entries,
      linkedStudyBlock: linkedStudyRow == null
          ? null
          : _studyBlock(linkedStudyRow),
      activeWaiver: waiverRow == null ? null : _waiver(waiverRow),
      visibleInitiative: initiativeRow == null
          ? null
          : _initiative(initiativeRow),
      cycle: _cycle(cycleRow),
      checkpoints: checkpointRows.map(_checkpoint),
    );
  }

  Day _day(db.Day row) {
    try {
      return Day(
        operationalDate: _date(row.operationalDate, 'days.operational_date'),
        baseResult: _dayResult(
          row.baseResult,
          field: 'days.base_result',
          allowMute: false,
        ),
        effectiveResult: _dayResult(
          row.effectiveResult,
          field: 'days.effective_result',
          allowMute: true,
        ),
        closedAt: _instant(row.closedAt),
        sealTimestamp: _instant(row.sealTimestamp),
        muteCause: _muteCause(row.muteCause),
        previousResult: row.previousResult == null
            ? null
            : _dayResult(
                row.previousResult!,
                field: 'days.previous_result',
                allowMute: false,
              ),
      );
    } on ArgumentError catch (error) {
      throw StateError(
        'Dia persistido inválido em ${row.operationalDate}: $error',
      );
    }
  }

  MorningEntry _morningEntry(db.PillarEntry row) => MorningEntry(
    workoutDone: row.workoutDone,
    briefingDone: row.briefingDone,
    briefingMode: switch (row.briefingMode) {
      null => null,
      'automatic' => BriefingCompletion.automatic,
      'manual' => BriefingCompletion.manual,
      final value => throw StateError(
        'Modo de briefing persistido inválido: $value.',
      ),
    },
    workoutAt: _instant(row.workoutAt),
    briefingAt: _instant(row.briefingAt),
  );

  DayEntry _dayEntry(db.PillarEntry row) => DayEntry(
    toggleOn: row.toggleOn,
    changeInitiativeId: row.changeInitiativeId,
    note: row.noteText,
    noteAudioId: row.noteAudioId,
  );

  NightEntry _nightEntry(db.PillarEntry row) => NightEntry(
    kind: switch (row.nightKind) {
      null => null,
      'study' => NightKind.study,
      'recovery' => NightKind.recovery,
      final value => throw StateError(
        'Tipo noturno persistido inválido: $value.',
      ),
    },
    recoveryNote: row.recoveryNote,
    studyBlockId: row.studyBlockId,
  );

  StudyBlock _studyBlock(db.StudyBlock row) => StudyBlock(
    id: row.id,
    operationalDate: _date(
      row.operationalDate,
      'study_blocks.operational_date',
    ),
    startedAt: _requiredInstant(row.startedAt),
    blockDeadline: _requiredInstant(row.blockDeadline),
    endedAt: _instant(row.endedAt),
  );

  PillarWaiver _waiver(db.PillarWaiver row) => PillarWaiver(
    id: row.id,
    date: _date(row.date, 'pillar_waivers.date'),
    pillar: _pillar(row.pillar),
    reasonText: row.reasonText,
    recurrenceConfirmed: row.recurrenceConfirmed,
    revokedAt: _instant(row.revokedAt),
  );

  ChangeInitiative _initiative(db.ChangeInitiative row) =>
      ChangeInitiative(id: row.id, name: row.name, active: row.active);

  Cycle _cycle(db.Cycle row) => Cycle(
    id: row.id,
    name: row.name,
    purposeText: row.purposeText,
    startDate: _date(row.startDate, 'cycles.start_date'),
    endDate: _date(row.endDate, 'cycles.end_date'),
    state: switch (row.state) {
      'active' => CycleState.active,
      'archived' => CycleState.archived,
      final value => throw StateError(
        'Estado de ciclo persistido inválido: $value.',
      ),
    },
  );

  Checkpoint _checkpoint(db.Checkpoint row) => Checkpoint(
    id: row.id,
    cycleId: row.cycleId,
    competency: switch (row.competency) {
      'ST' => Competency.st,
      'IN' => Competency.in_,
      'CA' => Competency.ca,
      final value => throw StateError(
        'Competência persistida inválida: $value.',
      ),
    },
    date: _date(row.date, 'checkpoints.date'),
    status: row.status,
  );

  DayResult _dayResult(
    String value, {
    required String field,
    required bool allowMute,
  }) {
    final result = switch (value) {
      'sealed' => DayResult.sealed,
      'unsealed' => DayResult.unsealed,
      'mute' => DayResult.mute,
      _ => throw StateError('Resultado persistido inválido em $field: $value.'),
    };
    if (!allowMute && result == DayResult.mute) {
      throw StateError('Resultado mute inválido em $field.');
    }
    return result;
  }

  MuteCause? _muteCause(String? value) => switch (value) {
    null => null,
    'weekend' => MuteCause.weekend,
    'holiday' => MuteCause.holiday,
    _ => throw StateError('Causa mute persistida inválida: $value.'),
  };

  Pillar _pillar(String value) => switch (value) {
    'morning' => Pillar.morning,
    'day' => Pillar.day,
    'night' => Pillar.night,
    _ => throw StateError('Pilar persistido inválido: $value.'),
  };

  OperationalDate _date(String value, String field) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw StateError('Data persistida inválida em $field: $value.');
    }
    try {
      return OperationalDate(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } on FormatException {
      throw StateError('Data persistida inválida em $field: $value.');
    } on ArgumentError {
      throw StateError('Data persistida inválida em $field: $value.');
    }
  }

  tz.TZDateTime _requiredInstant(int millisecondsSinceEpoch) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(
        _location,
        millisecondsSinceEpoch,
      );

  tz.TZDateTime? _instant(int? millisecondsSinceEpoch) =>
      millisecondsSinceEpoch == null
      ? null
      : _requiredInstant(millisecondsSinceEpoch);
}
