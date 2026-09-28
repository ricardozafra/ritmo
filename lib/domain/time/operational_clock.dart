/// Relógio de negócio do Ritmo: única porta autorizada a ler o relógio do
/// aparelho e a única que materializa coordenadas civis como instantes
/// absolutos.
///
/// Este é o único arquivo do projeto em que `DateTime.now()` é permitido
/// (verificado por `tool/clock_lint.dart`). Todas as decisões de data e hora
/// de negócio acontecem em `America/Sao_Paulo`, independentemente do fuso do
/// aparelho (RF-05.1, RNF-04.1, RNF-04.2).
///
/// O particionamento da linha temporal continua em `OperationalCalendar`
/// (funções puras sobre coordenadas civis); aqui apenas se converte entre
/// instantes absolutos e essas coordenadas, com a normalização de horas
/// inexistentes e ambíguas exigida por RNF-04.3.
library;

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'operational_calendar.dart';

/// Instante absoluto do aparelho, em UTC.
typedef DeviceInstantSource = DateTime Function();

/// Deslocamento do fuso do aparelho em um instante absoluto.
typedef DeviceOffsetSource = Duration Function(DateTime utcInstant);

/// Identificador IANA do fuso do aparelho, quando a plataforma o informar;
/// `null` quando desconhecido.
typedef DeviceZoneIdSource = String? Function();

tz.Location? _cachedBusinessLocation;

/// Carrega a base IANA embarcada, se preciso, e devolve o fuso oficial.
///
/// Idempotente: a base só é inicializada quando ainda não há nenhuma carregada,
/// para não descartar uma inicialização feita pela camada de aplicação.
tz.Location ensureBusinessLocation() {
  final cached = _cachedBusinessLocation;
  if (cached != null) return cached;
  if (!tz.timeZoneDatabase.isInitialized) {
    tzdata.initializeTimeZones();
  }
  return _cachedBusinessLocation = tz.getLocation(kBusinessTimeZone);
}

/// Contrato de tempo operacional consumido por todas as outras camadas.
abstract interface class OperationalClock {
  /// Fronteiras configuradas (`day_close_time`, `night_end_time`).
  OperationalCalendar get calendar;

  /// Fuso oficial. Nunca o fuso do aparelho.
  tz.Location get businessLocation;

  /// Instante corrente já convertido para o fuso oficial.
  tz.TZDateTime nowInBusinessZone();

  /// Data operacional vigente (RF-05.4, RF-05.9).
  OperationalDate operationalDateNow();

  /// Data operacional de um instante arbitrário.
  OperationalDate operationalDateOf(tz.TZDateTime instant);

  /// Instante de abertura de [date] = civil `date @ day_close_time`.
  tz.TZDateTime operationalOpen(OperationalDate date);

  /// Instante de fechamento de [date] = `operationalOpen(date + 1)` (RF-05.5).
  tz.TZDateTime operationalClose(OperationalDate date);

  /// Instante de `night_end_time` dentro da janela de [date] (RF-01.12).
  tz.TZDateTime blockDeadline(OperationalDate date);

  /// Materializa uma coordenada civil como instante absoluto no fuso oficial,
  /// normalizando horas inexistentes e ambíguas (RNF-04.3).
  tz.TZDateTime resolveCivil(CivilMoment moment);

  /// Reexpressa um instante absoluto qualquer no fuso oficial.
  tz.TZDateTime toBusinessZone(DateTime instant);

  /// Coordenada civil (data + hora local) de um instante no fuso oficial.
  CivilMoment civilMomentOf(DateTime instant);

  /// Verdadeiro quando o fuso do aparelho difere do oficial (RF-05.2).
  bool get deviceZoneDiverges;
}

/// Implementação sobre a base IANA embarcada do pacote `timezone`.
///
/// **Normalização de horário de verão.** `America/Sao_Paulo` não observa DST
/// hoje, mas a base contém as regras históricas. Toda coordenada civil é
/// materializada por `TZDateTime`, que desloca horas inexistentes para frente
/// (a hora saltada passa a valer com o deslocamento posterior) e resolve horas
/// ambíguas na primeira ocorrência (o deslocamento anterior à transição).
/// Consequência: cada data operacional tem exatamente um instante de abertura
/// e um de fechamento, logo exatamente um `closed_at` lógico (RNF-04.3,
/// RNF-04.4).
final class SystemOperationalClock implements OperationalClock {
  SystemOperationalClock({
    this.calendar = const OperationalCalendar.seed(),
    tz.Location? businessLocation,
    DeviceInstantSource? deviceInstant,
    DeviceOffsetSource? deviceOffset,
    DeviceZoneIdSource? deviceZoneId,
  }) : businessLocation = businessLocation ?? ensureBusinessLocation(),
       _deviceInstant = deviceInstant ?? _systemInstant,
       _deviceOffset = deviceOffset ?? _systemOffset,
       _deviceZoneId = deviceZoneId ?? _unknownZoneId;

  /// Mesmas fronteiras, outro `day_close_time`/`night_end_time` (RF-05.23).
  SystemOperationalClock withCalendar(OperationalCalendar calendar) =>
      SystemOperationalClock(
        calendar: calendar,
        businessLocation: businessLocation,
        deviceInstant: _deviceInstant,
        deviceOffset: _deviceOffset,
        deviceZoneId: _deviceZoneId,
      );

  @override
  final OperationalCalendar calendar;

  @override
  final tz.Location businessLocation;

  final DeviceInstantSource _deviceInstant;
  final DeviceOffsetSource _deviceOffset;
  final DeviceZoneIdSource _deviceZoneId;

  // Único ponto do projeto que consulta o relógio do aparelho.
  static DateTime _systemInstant() => DateTime.now().toUtc();

  static Duration _systemOffset(DateTime utcInstant) =>
      utcInstant.toLocal().timeZoneOffset;

  static String? _unknownZoneId() => null;

  @override
  tz.TZDateTime nowInBusinessZone() => toBusinessZone(_deviceInstant());

  @override
  OperationalDate operationalDateNow() =>
      operationalDateOf(nowInBusinessZone());

  @override
  OperationalDate operationalDateOf(tz.TZDateTime instant) =>
      calendar.operationalDateOf(civilMomentOf(instant).toCivilDateTime());

  @override
  tz.TZDateTime operationalOpen(OperationalDate date) =>
      resolveCivil(calendar.operationalOpen(date));

  @override
  tz.TZDateTime operationalClose(OperationalDate date) =>
      resolveCivil(calendar.operationalClose(date));

  @override
  tz.TZDateTime blockDeadline(OperationalDate date) =>
      resolveCivil(calendar.blockDeadline(date));

  @override
  tz.TZDateTime resolveCivil(CivilMoment moment) => tz.TZDateTime(
    businessLocation,
    moment.date.year,
    moment.date.month,
    moment.date.day,
    moment.time.hour,
    moment.time.minute,
  );

  @override
  tz.TZDateTime toBusinessZone(DateTime instant) =>
      tz.TZDateTime.from(instant, businessLocation);

  @override
  CivilMoment civilMomentOf(DateTime instant) {
    final local = toBusinessZone(instant);
    return CivilMoment(
      date: OperationalDate(local.year, local.month, local.day),
      time: LocalTimeOfDay(local.hour, local.minute),
    );
  }

  /// Deslocamento do fuso oficial em um instante absoluto.
  Duration businessOffsetAt(DateTime instant) => businessLocation
      .timeZone(instant.toUtc().millisecondsSinceEpoch)
      .offset;

  /// Divergência de fuso (RF-05.2).
  ///
  /// Quando a plataforma informa o identificador IANA do aparelho, a
  /// comparação é feita por nome. Sem esse dado, a divergência é observada
  /// pelo deslocamento vigente: fusos que coincidem no instante corrente
  /// produzem exatamente as mesmas datas e horas, e por isso não há o que
  /// sinalizar ao usuário.
  @override
  bool get deviceZoneDiverges {
    final zoneId = _deviceZoneId();
    if (zoneId != null) return zoneId != kBusinessTimeZone;
    final instant = _deviceInstant().toUtc();
    return _deviceOffset(instant) != businessOffsetAt(instant);
  }
}
