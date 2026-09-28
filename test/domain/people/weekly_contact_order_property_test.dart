// Feature: ritmo, Property 37: Ordem semanal é uma ordem total determinística
//
// Para qualquer lista de contatos, a ordem semanal coloca primeiro todos os
// contatos com last_touch_date nula, depois os demais por last_touch_date
// crescente, empates resolvidos por created_at crescente e empates remanescentes
// por id; a ordem é a mesma em execuções repetidas com a mesma entrada.
//
// **Validates: Requirements RF-07.5, RF-07.6, RF-07.16, RD-18**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:ritmo/domain/people/contact.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/operational_clock.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../generators/shared.dart';

final Generator<List<Contact>> _anyContactList = any.simple(
  generate: (random, size) {
    final location = ensureBusinessLocation();
    final count = random.nextInt(15);
    final baseTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
      location,
      1767225600000, // 2026-01-01
    );

    return List.generate(count, (index) {
      final hasTouch = random.nextBool();
      OperationalDate? touch;
      if (hasTouch) {
        touch = OperationalDate(
          2026,
          1 + random.nextInt(12),
          1 + random.nextInt(28),
        );
      }
      final createdOffset = random.nextInt(10000);
      final createdAt = baseTime.add(Duration(seconds: createdOffset));
      return Contact(
        id: 'c-${random.nextInt(20)}-$index',
        name: 'Contato $index',
        createdAt: createdAt,
        lastTouchDate: touch,
      );
    });
  },
  shrink: (contacts) sync* {
    if (contacts.length > 2) {
      yield contacts.sublist(0, contacts.length - 1);
    }
  },
);

void main() {
  const ordering = ContactOrdering();

  Glados<List<Contact>>(_anyContactList, RitmoGlados.ci()).test(
    'Propriedade 37: Ordem semanal é uma ordem total determinística',
    (contacts) {
      final ordered = ordering.weeklyOrder(contacts);

      // Mesma quantidade de elementos
      expect(ordered.length, equals(contacts.length));

      // Determinismo: rodando de novo dá exatamente a mesma lista
      final secondRun = ordering.weeklyOrder(contacts);
      expect(
        ordered.map((c) => c.id).toList(),
        equals(secondRun.map((c) => c.id).toList()),
      );

      // Verificação par a par da ordem total determinística
      for (var i = 0; i < ordered.length - 1; i++) {
        final a = ordered[i];
        final b = ordered[i + 1];

        // 1. Nulos primeiro
        if (a.lastTouchDate == null && b.lastTouchDate != null) {
          continue;
        }
        if (a.lastTouchDate != null && b.lastTouchDate == null) {
          fail('Contato com data não pode preceder contato com data nula');
        }

        // Se ambos tiverem datas:
        if (a.lastTouchDate != null && b.lastTouchDate != null) {
          final dateCmp = a.lastTouchDate!.compareTo(b.lastTouchDate!);
          if (dateCmp < 0) continue;
          if (dateCmp > 0) {
            fail('Data de toque de A deve ser <= data de toque de B');
          }
        }

        // Empate na data de toque: desempate por created_at
        final createdCmp = a.createdAt.millisecondsSinceEpoch.compareTo(
          b.createdAt.millisecondsSinceEpoch,
        );
        if (createdCmp < 0) continue;
        if (createdCmp > 0) {
          fail('created_at de A deve ser <= created_at de B em empate de data');
        }

        // Empate em created_at: desempate por id
        final idCmp = a.id.compareTo(b.id);
        expect(
          idCmp <= 0,
          isTrue,
          reason: 'id de A deve ser <= id de B em empate de data e created_at',
        );
      }
    },
  );

  group('Propriedade 37: Casos específicos e corner cases', () {
    final location = ensureBusinessLocation();
    final time1 = tz.TZDateTime.fromMillisecondsSinceEpoch(location, 1000000);
    final time2 = tz.TZDateTime.fromMillisecondsSinceEpoch(location, 2000000);

    test('contatos com touch nulo precedem contatos com touch preenchido', () {
      final c1 = Contact(
        id: '1',
        name: 'A',
        createdAt: time1,
        lastTouchDate: OperationalDate(2026, 1, 1),
      );
      final c2 = Contact(
        id: '2',
        name: 'B',
        createdAt: time1,
        lastTouchDate: null,
      );

      final result = ordering.weeklyOrder([c1, c2]);
      expect(result.first.id, equals('2'));
      expect(result.last.id, equals('1'));
    });

    test('empate de data desempata por created_at mais antigo', () {
      final c1 = Contact(
        id: '1',
        name: 'A',
        createdAt: time2, // mais recente
        lastTouchDate: OperationalDate(2026, 1, 1),
      );
      final c2 = Contact(
        id: '2',
        name: 'B',
        createdAt: time1, // mais antigo
        lastTouchDate: OperationalDate(2026, 1, 1),
      );

      final result = ordering.weeklyOrder([c1, c2]);
      expect(result.first.id, equals('2'));
      expect(result.last.id, equals('1'));
    });

    test('empate de data e created_at desempata por id', () {
      final c1 = Contact(
        id: 'b-id',
        name: 'A',
        createdAt: time1,
        lastTouchDate: null,
      );
      final c2 = Contact(
        id: 'a-id',
        name: 'B',
        createdAt: time1,
        lastTouchDate: null,
      );

      final result = ordering.weeklyOrder([c1, c2]);
      expect(result.first.id, equals('a-id'));
      expect(result.last.id, equals('b-id'));
    });
  });
}
