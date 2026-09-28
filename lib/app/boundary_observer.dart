import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/time/operational_calendar.dart';
import '../domain/time/operational_clock.dart';
import 'boundary_crossing_service.dart';
import 'editor_registry.dart';

/// Evento emitido somente depois que a travessia da data foi confirmada.
final class BoundaryEvent {
  const BoundaryEvent({
    required this.closedDate,
    required this.currentDate,
    required this.hadPendingEdit,
  });

  final OperationalDate closedDate;
  final OperationalDate currentDate;
  final bool hadPendingEdit;
}

/// Handle mínimo para permitir timers determinísticos em testes.
abstract interface class BoundaryTimerHandle {
  void cancel();
}

typedef BoundaryTimerFactory =
    BoundaryTimerHandle Function(Duration delay, void Function() callback);

final class _DartBoundaryTimerHandle implements BoundaryTimerHandle {
  _DartBoundaryTimerHandle(Duration delay, void Function() callback)
    : _timer = Timer(delay, callback);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

BoundaryTimerHandle _createTimer(Duration delay, void Function() callback) =>
    _DartBoundaryTimerHandle(delay, callback);

/// Observa a fronteira operacional apenas enquanto o app está em foreground.
///
/// Callbacks de timer e lifecycle são serializados para que uma retomada no
/// mesmo instante do timer não produza duas travessias concorrentes. A
/// idempotência persistida continua sendo responsabilidade de
/// [BoundaryCrossingPort].
final class BoundaryObserver with WidgetsBindingObserver {
  BoundaryObserver(
    this._clock,
    this._crossing,
    this._editors, [
    this._timerFactory = _createTimer,
  ]);

  final OperationalClock _clock;
  final BoundaryCrossingPort _crossing;
  final EditorRegistry _editors;
  final BoundaryTimerFactory _timerFactory;
  final StreamController<BoundaryEvent> _events =
      StreamController<BoundaryEvent>.broadcast(sync: true);

  BoundaryTimerHandle? _timer;
  Future<void> _tail = Future<void>.value();
  bool _started = false;
  bool _foreground = false;
  bool _disposed = false;

  Stream<BoundaryEvent> get events => _events.stream;

  /// Registra o lifecycle, reconcilia fronteiras perdidas e arma o timer.
  Future<void> start() async {
    if (_disposed) {
      throw StateError('BoundaryObserver já foi descartado.');
    }
    if (_started) return;

    _started = true;
    _foreground = true;
    WidgetsBinding.instance.addObserver(this);
    await onResumed();
  }

  /// Reconcilia todas as datas pendentes em ordem crescente.
  ///
  /// A fila também captura uma nova fronteira que eventualmente seja cruzada
  /// enquanto uma travessia anterior ainda está sendo persistida.
  Future<void> onResumed() {
    if (_disposed) return Future<void>.value();
    _foreground = true;
    _cancelTimer();
    return _enqueue(_reconcileAndArm);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _runFromLifecycle(onResumed());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _cancelTimer();
    }
  }

  Future<void> _reconcileAndArm() async {
    try {
      while (!_disposed && _foreground) {
        final current = _clock.operationalDateNow();
        final requested = await _crossing.pendingBoundaries(before: current);
        final pending =
            requested.where((date) => date < current).toSet().toList()..sort();
        if (pending.isEmpty) break;

        for (final closing in pending) {
          if (_disposed || !_foreground) return;
          final snapshot = await _editors.captureFor(closing);
          await _crossing.crossBoundary(closing, snapshot: snapshot);
          if (!_events.isClosed) {
            _events.add(
              BoundaryEvent(
                closedDate: closing,
                currentDate: _clock.operationalDateNow(),
                hadPendingEdit: snapshot != null,
              ),
            );
          }
        }
      }
    } finally {
      _armTimer();
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final current = _tail.then((_) => operation());
    _tail = current.then<void>((_) {}, onError: (_, _) {});
    return current;
  }

  void _armTimer() {
    _cancelTimer();
    if (_disposed || !_started || !_foreground) return;

    final current = _clock.operationalDateNow();
    final now = _clock.nowInBusinessZone();
    final close = _clock.operationalClose(current);
    final remaining = close.difference(now);
    final delay = remaining.isNegative ? Duration.zero : remaining;
    _timer = _timerFactory(delay, () {
      _timer = null;
      _runFromLifecycle(onResumed());
    });
  }

  void _runFromLifecycle(Future<void> operation) {
    unawaited(
      operation.catchError((Object error, StackTrace stackTrace) {
        if (!_events.isClosed) _events.addError(error, stackTrace);
      }),
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _foreground = false;
    _cancelTimer();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    await _tail;
    await _events.close();
  }
}
