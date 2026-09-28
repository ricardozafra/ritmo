// Feature: ritmo, Property 53: Iniciativa de mudança única
//
// Para qualquer sequência de comandos sobre iniciativas de mudança, o número
// de iniciativas ativas persistidas é sempre menor ou igual a um, inclusive
// diante de uma tentativa de violar diretamente a restrição de persistência.
//
// **Validates: Requirements RF-01.7, RD-25**

import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater;
import 'package:ritmo/data/db/database.dart' hide ChangeInitiative;
import 'package:ritmo/data/repositories/change_initiatives_repository.dart';
import 'package:ritmo/domain/day/change_initiative.dart' as domain;

import '../generators/shared.dart';

enum _Operation { createAndActivate, changeActive }

typedef _Command = ({_Operation operation, int slot});

final Generator<List<_Command>> _anyInitiativeCommands = any.simple(
  generate: (random, size) {
    final tailLength = random.nextInt(max(1, min(size + 1, 16)));
    return <_Command>[
      (operation: _Operation.createAndActivate, slot: 0),
      (operation: _Operation.createAndActivate, slot: 1),
      ...List.generate(
        tailLength,
        (_) => (
          operation: _Operation.values[random.nextInt(_Operation.values.length)],
          slot: random.nextInt(8),
        ),
      ),
    ];
  },
  shrink: (commands) sync* {
    if (commands.length > 2) yield commands.take(2).toList(growable: false);
  },
);
void main() {
  Glados<List<_Command>>(
    _anyInitiativeCommands,
    RitmoGlados.ci(),
  ).test('Propriedade 53: iniciativa de mudança única', (commands) async {
    final database = RitmoDatabase(NativeDatabase.memory());
    final repository = ChangeInitiativesRepository(database);
    final sequence = commands
        .map((command) => '${command.operation.name}(${command.slot})')
        .join(' > ');

    Future<List<domain.ChangeInitiative>> expectSingleActive(String step) async {
      final all = await repository.all();
      final active = all.where((initiative) => initiative.active).toList();
      expect(active.length, lessThanOrEqualTo(1), reason: '$sequence / $step');
      expect(
        (await repository.active())?.id,
        active.isEmpty ? isNull : active.single.id,
        reason: '$sequence / $step',
      );
      return all;
    }

    try {
      await expectSingleActive('estado inicial');
      for (var index = 0; index < commands.length; index++) {
        final command = commands[index];
        final id = 'initiative-${command.slot}';
        switch (command.operation) {
          case _Operation.createAndActivate:
            await repository.createAndActivate(id: id, name: 'Iniciativa ${command.slot}');
            break;
          case _Operation.changeActive:
            await repository.changeActive(id);
            break;
        }
        await expectSingleActive('passo $index: ${command.operation.name}($id)');
      }

      // RD-25 também protege a invariável abaixo da API do repositório.
      final all = await expectSingleActive('antes da tentativa direta');
      final inactive = all.where((initiative) => !initiative.active).first;
      await expectLater(
        (database.update(database.changeInitiatives)
              ..where((initiative) => initiative.id.equals(inactive.id)))
            .write(const ChangeInitiativesCompanion(active: Value(true))),
        throwsA(isA<Exception>()),
      );
      await expectSingleActive('após tentativa direta rejeitada');
    } finally {
      await database.close();
    }
  });
}
