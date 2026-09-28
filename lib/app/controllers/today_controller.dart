import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/limits.dart';
import '../../core/result.dart';
import '../../data/db/database.dart' as db;
import '../../data/repositories/day_repository.dart';
import '../../data/repositories/open_day_commands_repository.dart';
import '../../data/repositories/today_repository.dart';
import '../../data/repositories/waiver_repository.dart';
import '../../domain/day/pillar_rules.dart';
import '../../domain/day/seal_eligibility.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';

typedef TodayClockLease =
    Future<Result<void, RitmoFailure>> Function(
      Future<Result<void, RitmoFailure>> Function(OperationalClock clock)
      operation,
    );

final class TodayController {
  TodayController(
    db.RitmoDatabase database,
    TodayRepository todayRepository, {
    required void Function() onChanged,
    LimitPolicy limitPolicy = const LimitPolicy(),
    Future<OperationalClock> Function()? loadClock,
    TodayClockLease? withClock,
  }) : this._(
         database,
         onChanged,
         limitPolicy,
         loadClock ??
             () async => SystemOperationalClock(
               calendar: await todayRepository.loadCalendar(),
             ),
         withClock,
       );

  TodayController._(
    this._database,
    this._onChanged,
    this._limitPolicy,
    this._loadClock,
    this._withClock,
  );

  final db.RitmoDatabase _database;
  final void Function() _onChanged;
  final LimitPolicy _limitPolicy;
  final Future<OperationalClock> Function() _loadClock;
  final TodayClockLease? _withClock;

  bool _busy = false;
  int _idCounter = 0;

  Future<Result<void, RitmoFailure>> setWorkout(
    OperationalDate date, {
    required bool done,
    bool revokeWaiver = false,
  }) => _run(date, (clock, now) async {
    if (done && revokeWaiver) {
      return _discard(
        await _waivers(clock).revokeForCompletion(
          date: date,
          pillar: Pillar.morning,
          at: now,
          confirmed: true,
          completion: db.PillarEntriesCompanion(
            workoutDone: const Value(true),
            workoutAt: Value(now.millisecondsSinceEpoch),
          ),
        ),
      );
    }
    return _discard(
      await _commands(
        clock,
      ).setWorkout(date, done: done, at: done ? now : null),
    );
  });

  Future<Result<void, RitmoFailure>> setBriefing(
    OperationalDate date, {
    required bool done,
    BriefingCompletion? mode,
    bool revokeWaiver = false,
  }) => _run(date, (clock, now) async {
    if (done && revokeWaiver) {
      return _discard(
        await _waivers(clock).revokeForCompletion(
          date: date,
          pillar: Pillar.morning,
          at: now,
          confirmed: true,
          completion: db.PillarEntriesCompanion(
            briefingDone: const Value(true),
            briefingMode: Value(mode?.name),
            briefingAt: Value(now.millisecondsSinceEpoch),
          ),
        ),
      );
    }
    return _discard(
      await _commands(
        clock,
      ).setBriefing(date, done: done, mode: mode, at: done ? now : null),
    );
  });

  Future<Result<void, RitmoFailure>> setDayToggle(
    OperationalDate date, {
    required bool on,
    bool revokeWaiver = false,
  }) => _run(date, (clock, now) async {
    if (on && revokeWaiver) {
      return _discard(
        await _waivers(clock).revokeForCompletion(
          date: date,
          pillar: Pillar.day,
          at: now,
          confirmed: true,
          completion: const db.PillarEntriesCompanion(toggleOn: Value(true)),
        ),
      );
    }
    return _discard(await _commands(clock).setDayToggle(date, on: on));
  });

  Future<Result<void, RitmoFailure>> setDayNote(
    OperationalDate date, {
    String? note,
  }) {
    final normalized = _optionalShortText(note);
    if (normalized case Failure<String?, RitmoFailure>(:final failure)) {
      return Future.value(Result<void, RitmoFailure>.failure(failure));
    }
    final value = (normalized as Success<String?, RitmoFailure>).value;
    return _run(date, (clock, now) async {
      return _discard(await _commands(clock).setDayNote(date, note: value));
    });
  }

  Future<Result<void, RitmoFailure>> startStudy(OperationalDate date) =>
      _run(date, (clock, now) async {
        return _discard(
          await _commands(
            clock,
          ).startStudy(id: _nextId('study', now), date: date, startedAt: now),
        );
      });

  Future<Result<void, RitmoFailure>> finishStudy(
    OperationalDate date, {
    bool revokeWaiver = false,
  }) => _run(date, (clock, now) async {
    if (revokeWaiver) {
      return _discard(
        await _waivers(
          clock,
        ).revokeForStudyCompletion(date: date, at: now, confirmed: true),
      );
    }
    return _discard(await _commands(clock).finishStudy(date, at: now));
  });

  Future<Result<void, RitmoFailure>> cancelStudy(OperationalDate date) =>
      _run(date, (clock, now) async {
        return _discard(await _commands(clock).cancelStudy(date));
      });

  Future<Result<void, RitmoFailure>> chooseRecovery(
    OperationalDate date, {
    String? note,
    bool revokeWaiver = false,
  }) {
    final normalized = _optionalShortText(note);
    if (normalized case Failure<String?, RitmoFailure>(:final failure)) {
      return Future.value(Result<void, RitmoFailure>.failure(failure));
    }
    final value = (normalized as Success<String?, RitmoFailure>).value;
    return _run(date, (clock, now) async {
      if (revokeWaiver) {
        return _discard(
          await _waivers(clock).revokeForRecovery(
            date: date,
            at: now,
            confirmed: true,
            note: value,
          ),
        );
      }
      return _discard(
        await _commands(clock).chooseRecovery(date, at: now, note: value),
      );
    });
  }

  Future<Result<void, RitmoFailure>> removeNightChoice(OperationalDate date) =>
      _run(date, (clock, now) async {
        return _discard(await _commands(clock).removeNightChoice(date));
      });

  Future<Result<void, RitmoFailure>> createWaiver(
    OperationalDate date, {
    required Pillar pillar,
    required String reasonText,
    bool recurrenceConfirmed = false,
  }) {
    final normalized = _requiredShortText(reasonText);
    if (normalized case Failure<String, RitmoFailure>(:final failure)) {
      return Future.value(Result<void, RitmoFailure>.failure(failure));
    }
    final value = (normalized as Success<String, RitmoFailure>).value;
    return _run(date, (clock, now) async {
      return _discard(
        await _waivers(clock).create(
          id: _nextId('waiver', now),
          date: date,
          pillar: pillar,
          reasonText: value,
          recurrenceConfirmed: recurrenceConfirmed,
        ),
      );
    });
  }

  Future<Result<void, RitmoFailure>> sealDay(OperationalDate date) =>
      _run(date, (clock, now) async {
        return _discard(
          await DayRepository(
            _database,
            businessLocation: clock.businessLocation,
          ).sealDay(date, at: now),
        );
      });

  Future<Result<void, RitmoFailure>> reopenDay(OperationalDate date) =>
      _run(date, (clock, now) async {
        return _discard(
          await DayRepository(
            _database,
            businessLocation: clock.businessLocation,
          ).reopenDay(date),
        );
      });

  Future<Result<void, RitmoFailure>> _run(
    OperationalDate date,
    Future<Result<void, BusinessViolation>> Function(
      OperationalClock clock,
      tz.TZDateTime now,
    )
    operation,
  ) async {
    if (_busy) {
      return const Result<void, RitmoFailure>.failure(
        DayViolation(
          code: 'today_action_in_progress',
          message: 'Aguarde a conclusão da ação em andamento.',
        ),
      );
    }

    _busy = true;
    try {
      Future<Result<void, RitmoFailure>> execute(OperationalClock clock) async {
        final now = clock.nowInBusinessZone();
        if (clock.operationalDateNow() != date) {
          _onChanged();
          return const Result<void, RitmoFailure>.failure(
            DayViolation(
              code: 'operational_date_changed',
              message: 'A data operacional mudou. Revise a tela antes de agir.',
            ),
          );
        }

        final result = await operation(clock, now);
        return result.fold(
          onSuccess: (_) {
            _onChanged();
            return const Result<void, RitmoFailure>.success(null);
          },
          onFailure: Result<void, RitmoFailure>.failure,
        );
      }

      final withClock = _withClock;
      return withClock == null
          ? await execute(await _loadClock())
          : await withClock(execute);
    } on Object catch (error) {
      return Result<void, RitmoFailure>.failure(DatabaseFailure(cause: error));
    } finally {
      _busy = false;
    }
  }

  OpenDayCommandsRepository _commands(OperationalClock clock) =>
      OpenDayCommandsRepository(_database, clock: clock);

  WaiverRepository _waivers(OperationalClock clock) =>
      WaiverRepository(_database, businessLocation: clock.businessLocation);

  Result<void, BusinessViolation> _discard<T>(
    Result<T, BusinessViolation> result,
  ) => result.map((_) {});

  Result<String?, RitmoFailure> _optionalShortText(String? raw) {
    final normalized = raw?.trim();
    final value = normalized == null || normalized.isEmpty ? null : normalized;
    if (value == null) {
      return const Result<String?, RitmoFailure>.success(null);
    }
    final clamped = _limitPolicy.clampRunes(value, Limits.shortTextMaxRunes);
    final violation = clamped.violation;
    return violation == null
        ? Result<String?, RitmoFailure>.success(value)
        : Result<String?, RitmoFailure>.failure(violation);
  }

  Result<String, RitmoFailure> _requiredShortText(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const Result<String, RitmoFailure>.failure(
        WaiverViolation(
          code: 'waiver_reason_empty',
          message: 'Informe o motivo da dispensa.',
        ),
      );
    }
    final clamped = _limitPolicy.clampRunes(value, Limits.shortTextMaxRunes);
    final violation = clamped.violation;
    return violation == null
        ? Result<String, RitmoFailure>.success(value)
        : Result<String, RitmoFailure>.failure(violation);
  }

  String _nextId(String prefix, tz.TZDateTime now) =>
      '$prefix-${now.microsecondsSinceEpoch}-${_idCounter++}';
}
