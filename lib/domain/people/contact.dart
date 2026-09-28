import 'package:timezone/timezone.dart' as tz;

import '../time/operational_calendar.dart';

/// Contato explícito do rodízio semanal (RF-07.4).
///
/// Entidade separada de `Mentorship`: nunca é criada, inferida ou sincronizada
/// a partir de um mentor (RF-07.18, RF-07.19, RF-07.20).
final class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.createdAt,
    this.contextNote,
    this.lastTouchDate,
  });

  final String id;
  final String name;
  final String? contextNote;

  /// Data do último toque; nula quando o contato nunca foi visitado.
  final OperationalDate? lastTouchDate;

  /// Instante de criação no fuso oficial, desempate determinístico da ordem.
  final tz.TZDateTime createdAt;
}

/// Ordena os contatos por carência semanal, de forma total e determinística.
///
/// Critérios, em ordem (RF-07.5, RF-07.6, RD-18):
/// 1. `last_touch_date` nula primeiro (maior carência);
/// 2. depois, `last_touch_date` mais antiga primeiro;
/// 3. empate de data resolve pelo menor `created_at` (criado há mais tempo);
/// 4. desempate final estável pelo menor `id`.
///
/// Não consulta relógio nem persistência e não deriva nada de mentoria.
final class ContactOrdering {
  const ContactOrdering();

  List<Contact> weeklyOrder(Iterable<Contact> contacts) {
    final ordered = contacts.toList()..sort(_compare);
    return List<Contact>.unmodifiable(ordered);
  }

  int _compare(Contact a, Contact b) {
    final byTouch = _compareLastTouch(a.lastTouchDate, b.lastTouchDate);
    if (byTouch != 0) return byTouch;

    final byCreated = a.createdAt.millisecondsSinceEpoch.compareTo(
      b.createdAt.millisecondsSinceEpoch,
    );
    if (byCreated != 0) return byCreated;

    return a.id.compareTo(b.id);
  }

  /// Nula precede qualquer data; entre datas, a mais antiga precede.
  int _compareLastTouch(OperationalDate? a, OperationalDate? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}
