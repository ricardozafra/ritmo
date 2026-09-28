// Feature: ritmo, Property 2: Validação das fronteiras configuráveis
//
// Para qualquer par de horários candidatos, a configuração é aceita se e
// somente se o fechamento está em [00:00, 04:00] e o deslocamento noturno em
// (0, 24h]; toda configuração aceita mantém o deadline até o fechamento.
//
// **Validates: Requirements RF-05.3, RA-01.1, RF-01.12**

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:ritmo/domain/time/operational_calendar.dart';
import 'package:ritmo/domain/time/settings_validator.dart';

import '../../generators/shared.dart';

void main() {
  const validator = SettingsValidator();

  Glados2<BoundaryCandidate, OperationalDate>(
    anyBoundaryCandidate,
    anyOperationalDate,
    RitmoGlados.ci(),
  ).test('Propriedade 2: validação das fronteiras configuráveis', (
    BoundaryCandidate candidate,
    OperationalDate date,
  ) {
    final closeMinutes = candidate.dayCloseTime.minutesFromMidnight;
    final nightMinutes = candidate.nightEndTime.minutesFromMidnight;
    final rawOffset = (nightMinutes - closeMinutes) % Duration.minutesPerDay;
    final expectedOffsetMinutes = rawOffset == 0
        ? Duration.minutesPerDay
        : rawOffset;
    final expectedAccepted =
        closeMinutes >= 0 &&
        closeMinutes <= 4 * Duration.minutesPerHour &&
        expectedOffsetMinutes > 0 &&
        expectedOffsetMinutes <= Duration.minutesPerDay;
    final result = validator.validate(
      dayCloseTime: candidate.dayCloseTime,
      nightEndTime: candidate.nightEndTime,
    );
    final context =
        'close=${candidate.dayCloseTime}, night=${candidate.nightEndTime}, '
        'offset=${expectedOffsetMinutes}min, date=$date';

    expect(result.isSuccess, expectedAccepted, reason: context);
    result.fold(
      onSuccess: (calendar) {
        expect(calendar.nightOffset.inMinutes, expectedOffsetMinutes,
            reason: context);
        expect(calendar.blockDeadline(date) <= calendar.operationalClose(date),
            isTrue, reason: context);
      },
      onFailure: (_) => expect(expectedAccepted, isFalse, reason: context),
    );
  });
}
