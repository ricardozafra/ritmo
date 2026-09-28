import 'dart:async';

import '../domain/time/operational_calendar.dart';

/// Snapshot imutável do estado presente de uma edição vinculada a um dia.
///
/// [persist] será chamado pela travessia de fronteira dentro da mesma
/// transação que encerra o dia. A implementação deve persistir exatamente os
/// valores capturados, sem consultar novamente o estado mutável da UI.
abstract interface class DayEditSnapshot {
  OperationalDate get operationalDate;

  Future<void> persist();
}

/// Editor que participa do autosave da fronteira operacional.
///
/// Fluxos não diários, como Revisão e Pedra, não implementam nem se registram
/// nesta porta e, portanto, atravessam a fronteira intactos.
abstract interface class DayScopedEditor {
  OperationalDate get operationalDate;

  FutureOr<DayEditSnapshot> captureSnapshot();
}

/// Registro descartável de um editor diário ativo.
final class EditorRegistration {
  EditorRegistration._(this._unregister);

  final void Function() _unregister;
  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _unregister();
  }
}

/// Mantém, no máximo, o editor diário atualmente visível.
///
/// Um novo registro substitui o anterior. O token impede que o descarte tardio
/// de uma tela antiga remova o editor que a sucedeu.
final class EditorRegistry {
  DayScopedEditor? _activeEditor;
  Object? _activeToken;

  bool get hasDayScopedEditor => _activeEditor != null;

  OperationalDate? get activeOperationalDate => _activeEditor?.operationalDate;

  EditorRegistration register(DayScopedEditor editor) {
    final token = Object();
    _activeEditor = editor;
    _activeToken = token;
    return EditorRegistration._(() {
      if (identical(_activeToken, token)) {
        _activeEditor = null;
        _activeToken = null;
      }
    });
  }

  /// Captura o estado presente somente quando o editor pertence a [date].
  Future<DayEditSnapshot?> captureFor(OperationalDate date) async {
    final editor = _activeEditor;
    if (editor == null || editor.operationalDate != date) return null;

    final snapshot = await editor.captureSnapshot();
    if (snapshot.operationalDate != date) {
      throw StateError(
        'O snapshot diário deve preservar a operational_date original.',
      );
    }
    return snapshot;
  }
}
