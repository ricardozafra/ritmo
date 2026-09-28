// Feature: ritmo, Property 10: Dispensa exige motivo com conteúdo
//
// Para qualquer motivo e presença ou ausência de pilar, a criação da dispensa
// é aceita se e somente se o motivo contém ao menos um caractere não branco
// após trim e um pilar foi declarado.
//
// **Validates: Requirements RF-02.9**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/core/result.dart';
import 'package:ritmo/domain/day/waiver_policy.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import '../../generators/shared.dart';

typedef WaiverInput = ({String reason, Pillar? pillar});

/// Motivos vazios, compostos apenas por diferentes brancos e com conteúdo
/// Unicode, com ou sem brancos nas bordas. O pilar varia independentemente
/// entre ausente e cada um dos três valores válidos.
final Generator<WaiverInput> anyWaiverInput = any.simple(
  generate: (random, size) {
    const whitespace = <String>['', ' ', '\t', '\n', '\r\n', '\u00a0'];
    const content = <String>[
      'a',
      'Motivo familiar',
      'á',
      '😀',
      'e\u0301',
      '理由',
    ];
    const pillars = <Pillar?>[null, Pillar.morning, Pillar.day, Pillar.night];

    final left = whitespace[random.nextInt(whitespace.length)];
    final right = whitespace[random.nextInt(whitespace.length)];
    final reason = switch (random.nextInt(5)) {
      0 => '',
      1 => List<String>.filled(
        1 + random.nextInt(8),
        whitespace[random.nextInt(whitespace.length)],
      ).join(),
      2 => content[random.nextInt(content.length)],
      3 => '$left${content[random.nextInt(content.length)]}$right',
      _ =>
        '${content[random.nextInt(content.length)]}'
            '${whitespace[1 + random.nextInt(whitespace.length - 1)]}'
            '${content[random.nextInt(content.length)]}',
    };

    return (reason: reason, pillar: pillars[random.nextInt(pillars.length)]);
  },
  shrink: (value) sync* {
    if (value.reason.isNotEmpty) {
      yield (reason: '', pillar: value.pillar);
      final trimmed = value.reason.trim();
      if (trimmed.isNotEmpty && trimmed != value.reason) {
        yield (reason: trimmed, pillar: value.pillar);
      }
    }
    if (value.pillar != null) {
      yield (reason: value.reason, pillar: null);
    }
  },
);

void main() {
  const policy = WaiverPolicy();
  final date = OperationalDate(2026, 3, 9);

  // Seed fixa 0x5249544D ("RITM") e no mínimo 100 execuções em CI.
  Glados<WaiverInput>(anyWaiverInput, RitmoGlados.ci()).test(
    'Propriedade 10: dispensa exige motivo com conteúdo',
    (WaiverInput input) {
      final trimmedReason = input.reason.trim();
      final hasDeclaredPillar = input.pillar != null;
      final hasContent = trimmedReason.isNotEmpty;
      final expectedAccepted = hasDeclaredPillar && hasContent;
      final context =
          'motivo ${input.reason.runes.toList()}, pilar ${input.pillar}';

      final result = policy.create(
        CreateWaiver(
          id: 'waiver-property-10',
          date: date,
          pillar: input.pillar,
          reasonText: input.reason,
        ),
        const DayContext(),
      );

      switch (result) {
        case Success<PillarWaiver, WaiverViolation>(:final value):
          expect(expectedAccepted, isTrue, reason: context);
          expect(value.pillar, input.pillar, reason: context);
          expect(value.reasonText, trimmedReason, reason: context);
          expect(value.reasonText, isNotEmpty, reason: context);
        case Failure<PillarWaiver, WaiverViolation>(:final failure):
          expect(expectedAccepted, isFalse, reason: context);
          expect(
            failure.code,
            hasDeclaredPillar
                ? 'waiver_reason_empty'
                : 'waiver_pillar_required',
            reason: context,
          );
      }
    },
  );
}
