import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../data/db/database.dart' as db;
import '../../data/repositories/day_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/time/anchored_operational_clock.dart';
import '../../domain/time/operational_calendar.dart';
import '../../domain/time/operational_clock.dart';
import '../boundary_crossing_service.dart';
import '../boundary_observer.dart';
import '../editor_registry.dart';
import 'metrics_providers.dart' show ritmoDatabaseProvider;

final editorRegistryProvider = Provider<EditorRegistry>(
  (ref) => EditorRegistry(),
);

final boundaryRuntimeProvider = FutureProvider<BoundaryRuntime>((ref) async {
  final database = ref.watch(ritmoDatabaseProvider);
  final settings = SettingsRepository(database);
  final snapshot = await settings.load();
  final floor = await settings.loadOperationalDateFloor();
  final systemClock = SystemOperationalClock(calendar: snapshot.calendar);
  final runtime = BoundaryRuntime._(
    database,
    settings,
    ref.watch(editorRegistryProvider),
    systemClock: systemClock,
    operationalDateFloor: floor,
  );
  ref.onDispose(() => unawaited(runtime.dispose()));
  await runtime.start();
  return runtime;
});

final boundaryRevisionProvider = StreamProvider<int>((ref) async* {
  final runtime = await ref.watch(boundaryRuntimeProvider.future);
  yield* runtime.watchRevisions();
});

/// Mantém um único relógio e um único observador de fronteira ativos.
///
/// Inicialização, reconfiguração e descarte passam pela mesma fila. Uma troca
/// de horário para o observador antigo antes da escrita e só publica a nova
/// revisão depois que o clock persistido foi instalado.
final class BoundaryRuntime {
  BoundaryRuntime._(
    this._database,
    this._settings,
    this._editors, {
    required SystemOperationalClock systemClock,
    required OperationalDate? operationalDateFloor,
  }) : _systemClock = systemClock,
       _operationalDateFloor = operationalDateFloor,
       _clock = _withFloor(systemClock, operationalDateFloor);

  final db.RitmoDatabase _database;
  final SettingsRepository _settings;
  final EditorRegistry _editors;
  final StreamController<int> _revisions = StreamController<int>.broadcast(
    sync: true,
  );

  SystemOperationalClock _systemClock;
  OperationalDate? _operationalDateFloor;
  OperationalClock _clock;
  BoundaryObserver? _observer;
  BoundaryCrossingService? _crossing;
  StreamSubscription<BoundaryEvent>? _eventsSubscription;
  BoundaryEvent? _pendingEditBoundary;
  Future<void> _tail = Future<void>.value();
  Future<void>? _disposeFuture;
  int _revision = 0;
  bool _started = false;
  bool _disposeRequested = false;
  bool _disposed = false;

  OperationalClock get clock => _clock;

  BoundaryEvent? get pendingEditBoundary => _pendingEditBoundary;

  Future<void> start() {
    if (_started) return Future<void>.value();
    return _enqueue(() async {
      if (_started) return;
      await _startComponents();
      _started = true;
    });
  }

  /// Executa uma ação temporal com um lease do clock vigente.
  ///
  /// Reconfigurações aguardam a ação terminar; assim nenhuma escrita iniciada
  /// com o calendário antigo pode concluir depois do commit do calendário novo.
  Future<T> runWithClock<T>(
    Future<T> Function(OperationalClock clock) operation,
  ) => _enqueue(() {
    if (!_started) {
      throw StateError('BoundaryRuntime ainda não foi iniciado.');
    }
    return operation(_clock);
  });

  /// Troca as fronteiras sem permitir dois observers concorrentes.
  ///
  /// [persist] roda somente depois que o observer anterior terminou sua fila.
  /// Se a escrita falhar, o clock e o observer anteriores são restaurados. Se
  /// uma falha ocorrer depois do retorno de [persist], a escrita já foi
  /// confirmada e o novo clock permanece instalado para evitar split-brain.
  Future<T> reconfigure<T>({
    required OperationalCalendar calendar,
    required Future<T> Function() persist,
  }) => _enqueue(() async {
    if (!_started) {
      throw StateError('BoundaryRuntime ainda não foi iniciado.');
    }

    final previousSystemClock = _systemClock;
    final previousClock = _clock;
    final previousFloor = _operationalDateFloor;
    var committed = false;

    await _stopComponents();
    try {
      final nextFloor = await _settings.loadOperationalDateFloor();
      final persisted = await persist();
      committed = true;

      _systemClock = previousSystemClock.withCalendar(calendar);
      _operationalDateFloor = nextFloor;
      _clock = _withFloor(_systemClock, nextFloor);
      try {
        await _startComponents();
      } finally {
        _publishRevision();
      }
      return persisted;
    } on Object catch (error, stackTrace) {
      if (!committed) {
        _systemClock = previousSystemClock;
        _operationalDateFloor = previousFloor;
        _clock = previousClock;
        try {
          await _startComponents();
        } on Object catch (restoreError, restoreStackTrace) {
          _publishError(restoreError, restoreStackTrace);
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  });

  Stream<int> watchRevisions() => Stream<int>.multi((controller) {
    controller.add(_revision);
    final subscription = _revisions.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  /// Libera a retenção do dia anterior depois que a UI o apresentou
  /// encerrado e somente para leitura.
  void showCurrentDay() {
    if (_pendingEditBoundary == null || _disposeRequested) return;
    _pendingEditBoundary = null;
    _publishRevision();
  }

  Future<void> _startComponents() async {
    if (_observer != null || _crossing != null) return;

    final crossing = BoundaryCrossingService(
      _database,
      clock: _clock,
      days: DayRepository(_database, businessLocation: _clock.businessLocation),
    );
    final observer = BoundaryObserver(_clock, crossing, _editors);
    final subscription = observer.events.listen((event) {
      if (event.hadPendingEdit) _pendingEditBoundary = event;
      _publishRevision();
    }, onError: _publishError);

    _crossing = crossing;
    _observer = observer;
    _eventsSubscription = subscription;
    await observer.start();
  }

  Future<void> _stopComponents() async {
    final observer = _observer;
    final crossing = _crossing;
    final subscription = _eventsSubscription;
    _observer = null;
    _crossing = null;
    _eventsSubscription = null;

    await observer?.dispose();
    await subscription?.cancel();
    await crossing?.dispose();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    if (_disposeRequested) {
      return Future<T>.error(
        StateError('BoundaryRuntime já foi ou está sendo descartado.'),
      );
    }
    final result = _tail.then<T>((_) => operation());
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  void _publishRevision() {
    if (_disposeRequested || _revisions.isClosed) return;
    _revision += 1;
    _revisions.add(_revision);
  }

  void _publishError(Object error, StackTrace stackTrace) {
    if (_disposeRequested || _revisions.isClosed) return;
    _revisions.addError(error, stackTrace);
  }

  Future<void> dispose() {
    final existing = _disposeFuture;
    if (existing != null) return existing;

    _disposeRequested = true;
    final disposal = _tail.then((_) async {
      if (_disposed) return;
      _disposed = true;
      await _stopComponents();
      await _revisions.close();
    });
    _tail = disposal.then<void>((_) {}, onError: (_, _) {});
    return _disposeFuture = disposal;
  }
}

OperationalClock _withFloor(
  SystemOperationalClock clock,
  OperationalDate? floor,
) => floor == null
    ? clock
    : AnchoredOperationalClock(delegate: clock, minimumOperationalDate: floor);
