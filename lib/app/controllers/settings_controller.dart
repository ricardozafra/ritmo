import 'dart:async';

import '../../core/result.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/settings_validator.dart';
import '../providers/boundary_providers.dart';

typedef BoundaryRuntimeLoader = Future<BoundaryRuntime> Function();

/// Evento interno emitido somente depois do commit da configuração.
final class SettingsChangedEvent {
  const SettingsChangedEvent({
    required this.settings,
    required this.occurredAtMillisecondsSinceEpoch,
  });

  final SettingsSnapshot settings;
  final int occurredAtMillisecondsSinceEpoch;
}

/// Valida e coordena a persistência com a troca serial do clock global.
final class SettingsController {
  SettingsController(this._repository, this._loadRuntime);

  final SettingsRepository _repository;
  final BoundaryRuntimeLoader _loadRuntime;
  final StreamController<SettingsChangedEvent> _changes =
      StreamController<SettingsChangedEvent>.broadcast(sync: true);
  static const SettingsValidator _validator = SettingsValidator();

  bool _disposed = false;

  Stream<SettingsChangedEvent> get changes => _changes.stream;

  Future<Result<SettingsSnapshot, RitmoFailure>> updateOperationalTimes({
    required int dayCloseTimeMinutes,
    required int nightEndTimeMinutes,
  }) async {
    final validation = _validator.validateMinutes(
      dayCloseTimeMinutes: dayCloseTimeMinutes,
      nightEndTimeMinutes: nightEndTimeMinutes,
    );
    if (validation case Failure<OperationalCalendar, ConfigViolation>(
      :final failure,
    )) {
      return Result<SettingsSnapshot, RitmoFailure>.failure(failure);
    }
    final calendar =
        (validation as Success<OperationalCalendar, ConfigViolation>).value;

    SettingsSnapshot? committedSettings;
    BoundaryRuntime? runtime;
    try {
      runtime = await _loadRuntime();
      final persisted = await runtime.reconfigure(
        calendar: calendar,
        persist: () async {
          final committed = await _repository.saveCalendar(calendar);
          committedSettings = committed;
          return committed;
        },
      );
      _publishCommitted(runtime, persisted);
      return Result<SettingsSnapshot, RitmoFailure>.success(persisted);
    } on Object catch (error) {
      // A instalação do observer pode falhar depois do commit. Nesse caso o
      // novo clock já está instalado e a operação de dados continua concluída.
      final committed = committedSettings;
      if (committed != null && runtime != null) {
        _publishCommitted(runtime, committed);
        return Result<SettingsSnapshot, RitmoFailure>.success(committed);
      }
      return Result<SettingsSnapshot, RitmoFailure>.failure(
        DatabaseFailure(cause: error),
      );
    }
  }

  void _publishCommitted(BoundaryRuntime runtime, SettingsSnapshot settings) {
    if (_disposed || _changes.isClosed) return;
    _changes.add(
      SettingsChangedEvent(
        settings: settings,
        occurredAtMillisecondsSinceEpoch: runtime.clock
            .nowInBusinessZone()
            .millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _changes.close();
  }
}
