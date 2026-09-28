/// Geradores `glados` compartilhados por todas as propriedades do Ritmo.
///
/// Cada gerador restringe a exploração ao espaço de entrada realmente válido e
/// concentra probabilidade nas bordas que os requisitos citam (fronteira
/// operacional, fim de semana, virada de mês/ano, limites textuais). Onde o
/// domínio já existe, o valor gerado é o tipo de produção.
library;

import 'dart:math';

import 'package:glados/glados.dart';
import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/day/seal_eligibility.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

import 'fixtures.dart';

/// Data operacional canônica usada como alvo de shrink.
final OperationalDate canonicalOperationalDate = OperationalDate(2026, 1, 5);

const int _minutesPerDay = Duration.minutesPerDay;

/// Configuração canônica: seed normativo (fechamento 03:00, Estudo até o
/// fechamento).
const OperationalCalendar canonicalCalendar = OperationalCalendar.seed();

final List<OperationalDate> _dateEdges = [
  OperationalDate(2026, 1, 5), // segunda
  OperationalDate(2026, 1, 9), // sexta
  OperationalDate(2026, 1, 10), // sábado
  OperationalDate(2026, 1, 11), // domingo
  OperationalDate(2026, 1, 31), // fim de mês
  OperationalDate(2026, 2, 1), // início de mês
  OperationalDate(2024, 2, 29), // ano bissexto
  OperationalDate(2026, 12, 31), // fim de ano
  OperationalDate(2027, 1, 1), // início de ano
];

/// Datas operacionais válidas, com metade das amostras nas bordas conhecidas.
final Generator<OperationalDate> anyOperationalDate = any.simple(
  generate: (random, size) {
    if (random.nextBool()) {
      return _dateEdges[random.nextInt(_dateEdges.length)];
    }
    final year = 2020 + random.nextInt(16);
    final month = 1 + random.nextInt(12);
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    return OperationalDate(year, month, 1 + random.nextInt(lastDay));
  },
  shrink: (value) sync* {
    if (value != canonicalOperationalDate) yield canonicalOperationalDate;
  },
);

/// Par de horários civis candidato à configuração das fronteiras.
typedef BoundaryCandidate = ({
  LocalTimeOfDay dayCloseTime,
  LocalTimeOfDay nightEndTime,
});

const List<int> _dayCloseBoundaryMinutes = <int>[
  0, // borda inferior aceita
  1,
  239,
  240, // borda superior aceita
  241, // primeiro minuto rejeitado
  _minutesPerDay - 1,
];

/// Pares de horários candidatos, concentrando amostras nas bordas de
/// `day_close_time` e nos deslocamentos mínimo (1 min) e máximo (24h) da
/// janela operacional. Ambos permanecem horários civis válidos.
final Generator<BoundaryCandidate> anyBoundaryCandidate = any.simple(
  generate: (random, size) {
    final closeMinutes = random.nextBool()
        ? _dayCloseBoundaryMinutes[random.nextInt(
            _dayCloseBoundaryMinutes.length,
          )]
        : random.nextInt(_minutesPerDay);
    final nightMinutes = random.nextBool()
        ? <int>[
            closeMinutes,
            (closeMinutes + 1) % _minutesPerDay,
            (closeMinutes - 1) % _minutesPerDay,
            0,
            _minutesPerDay - 1,
          ][random.nextInt(5)]
        : random.nextInt(_minutesPerDay);
    return (
      dayCloseTime: LocalTimeOfDay.fromMinutes(closeMinutes),
      nightEndTime: LocalTimeOfDay.fromMinutes(nightMinutes),
    );
  },
  shrink: (value) sync* {
    final closeMinutes = value.dayCloseTime.minutesFromMidnight;
    if (closeMinutes > 240) {
      yield (
        dayCloseTime: const LocalTimeOfDay(4, 1),
        nightEndTime: value.nightEndTime,
      );
    } else if (value.dayCloseTime != const LocalTimeOfDay(0, 0) ||
        value.nightEndTime != const LocalTimeOfDay(0, 0)) {
      yield (
        dayCloseTime: const LocalTimeOfDay(0, 0),
        nightEndTime: const LocalTimeOfDay(0, 0),
      );
    }
  },
);

/// Configurações de fronteira válidas: `day_close_time ∈ [00:00, 04:00]` e
/// `offset(night_end_time) ∈ (0, 24h]` (RF-05.3, RA-01.1).
final Generator<OperationalCalendar> anySettings = any.choose(const [
  // Deslocamento mínimo de um minuto.
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(0, 0),
    nightEndTime: LocalTimeOfDay(0, 1),
  ),
  // Deslocamento máximo (24h): Estudo permitido até o fechamento.
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(0, 0),
    nightEndTime: LocalTimeOfDay(0, 0),
  ),
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(3, 0),
    nightEndTime: LocalTimeOfDay(3, 1),
  ),
  OperationalCalendar.seed(),
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(4, 0),
    nightEndTime: LocalTimeOfDay(4, 1),
  ),
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(4, 0),
    nightEndTime: LocalTimeOfDay(4, 0),
  ),
  // Janela "somente Recuperação" não vazia: offset(01:30) = 22h30.
  OperationalCalendar(
    dayCloseTime: LocalTimeOfDay(3, 0),
    nightEndTime: LocalTimeOfDay(1, 30),
  ),
]);

/// Instantes civis posicionados exatamente sobre as bordas de uma data
/// operacional, para exercitar `operationalDateOf` e `blockDeadline`.
final Generator<InstantFixture> anyInstant = any.simple(
  generate: (random, size) {
    final date = anyOperationalDate(random, size).value;
    final calendar = anySettings(random, size).value;
    final edge =
        TemporalEdge.values[random.nextInt(TemporalEdge.values.length)];
    return (
      date: date,
      civilInstant: civilInstantAt(date, calendar, edge),
      edge: edge,
      calendar: calendar,
    );
  },
  shrink: (value) sync* {
    if (value.edge != TemporalEdge.atDayClose ||
        value.date != canonicalOperationalDate) {
      yield (
        date: canonicalOperationalDate,
        civilInstant: civilInstantAt(
          canonicalOperationalDate,
          canonicalCalendar,
          TemporalEdge.atDayClose,
        ),
        edge: TemporalEdge.atDayClose,
        calendar: canonicalCalendar,
      );
    }
  },
);

/// Materializa uma borda temporal como instante civil no fuso oficial.
DateTime civilInstantAt(
  OperationalDate date,
  OperationalCalendar calendar,
  TemporalEdge edge,
) {
  final close = calendar.operationalClose(date).toCivilDateTime();
  final next = date.next;
  return switch (edge) {
    TemporalEdge.beforeDayClose => close.subtract(
      const Duration(milliseconds: 1),
    ),
    TemporalEdge.atDayClose => close,
    TemporalEdge.afterDayClose => close.add(const Duration(milliseconds: 1)),
    TemporalEdge.atNightEnd => calendar.blockDeadline(date).toCivilDateTime(),
    TemporalEdge.civilMidnight => DateTime.utc(next.year, next.month, next.day),
  };
}

final OperationalDate _workday = OperationalDate(2026, 1, 5); // segunda
final OperationalDate _weekendDay = OperationalDate(2026, 1, 10); // sábado

/// Combinações válidas de `(base_result, effective_result, mute_cause,
/// previous_result, closed_at, seal_timestamp)` da máquina de estados do Day.
final Generator<DayStateFixture> anyDayState = any.choose([
  _openOrClosed(FixtureDayResult.unsealed),
  _openOrClosed(FixtureDayResult.unsealed, closed: true),
  _openOrClosed(FixtureDayResult.sealed),
  _openOrClosed(FixtureDayResult.sealed, closed: true),
  _weekend(closed: false),
  _weekend(closed: true),
  _holiday(FixtureDayResult.unsealed, closed: false),
  _holiday(FixtureDayResult.unsealed, closed: true),
  _holiday(FixtureDayResult.sealed, closed: false),
  _holiday(FixtureDayResult.sealed, closed: true),
]);

DateTime _closeOf(OperationalDate date) =>
    canonicalCalendar.operationalClose(date).toCivilDateTime();

DayStateFixture _openOrClosed(FixtureDayResult result, {bool closed = false}) =>
    (
      date: _workday,
      baseResult: result,
      effectiveResult: result,
      closedAt: closed ? _closeOf(_workday) : null,
      sealTimestamp: result == FixtureDayResult.sealed
          ? DateTime.utc(2026, 1, 5, 23)
          : null,
      muteCause: null,
      previousResult: null,
    );

DayStateFixture _weekend({required bool closed}) => (
  date: _weekendDay,
  baseResult: FixtureDayResult.unsealed,
  effectiveResult: FixtureDayResult.mute,
  closedAt: closed ? _closeOf(_weekendDay) : null,
  sealTimestamp: null,
  muteCause: FixtureMuteCause.weekend,
  previousResult: null,
);

DayStateFixture _holiday(FixtureDayResult previous, {required bool closed}) => (
  date: _workday,
  baseResult: previous,
  effectiveResult: FixtureDayResult.mute,
  closedAt: closed ? _closeOf(_workday) : null,
  sealTimestamp: previous == FixtureDayResult.sealed
      ? DateTime.utc(2026, 1, 5, 23)
      : null,
  muteCause: FixtureMuteCause.holiday,
  previousResult: previous,
);

/// Estado dos três pilares mais a dispensa vigente do dia.
final Generator<PillarStateFixture> anyPillarState = any.simple(
  generate: (random, size) {
    final mask = random.nextInt(1 << FixturePillar.values.length);
    final completed = <FixturePillar>{
      for (var index = 0; index < FixturePillar.values.length; index++)
        if (mask & (1 << index) != 0) FixturePillar.values[index],
    };
    final waiver =
        FixtureWaiver.values[random.nextInt(FixtureWaiver.values.length)];
    return (completed: completed, waiver: waiver);
  },
  shrink: (value) sync* {
    if (value.completed.isNotEmpty || value.waiver != FixtureWaiver.none) {
      yield (completed: <FixturePillar>{}, waiver: FixtureWaiver.none);
    }
  },
);

/// Pilar efetivamente coberto pela dispensa vigente. Ausência e revogação não
/// cobrem nenhum pilar (RF-02.25).
Pillar? activeWaiverPillar(FixtureWaiver waiver) => switch (waiver) {
  FixtureWaiver.activeMorning => Pillar.morning,
  FixtureWaiver.activeDay => Pillar.day,
  FixtureWaiver.activeNight => Pillar.night,
  FixtureWaiver.none || FixtureWaiver.revoked => null,
};

const List<String?> _optionalNotes = <String?>[null, '', 'Problema complexo'];

/// Durações de Estudo incluindo zero, que precisa concluir o pilar tanto quanto
/// qualquer outra (RF-01.16).
const List<Duration> _studyDurations = <Duration>[
  Duration.zero,
  Duration(minutes: 1),
  Duration(minutes: 90),
];

const PillarEntriesFixture _emptyPillarEntries = (
  workoutDone: false,
  briefingDone: false,
  briefingMode: null,
  toggleOn: false,
  note: null,
  noteAudioId: null,
  nightKind: null,
  studyBlockId: null,
  studyEnded: false,
  studyDuration: Duration.zero,
  recoveryNote: null,
  waiver: FixtureWaiver.none,
);

/// Registros brutos dos três pilares mais a dispensa vigente do dia. Cobre as
/// quatro combinações da Manhã, o toggle do Dia com e sem nota/áudio, os três
/// tipos noturnos com bloco ausente, aberto ou encerrado, e cada estado de
/// dispensa.
final Generator<PillarEntriesFixture> anyPillarEntries = any.simple(
  generate: (random, size) {
    final briefingDone = random.nextBool();
    final nightKind = <NightKind?>[
      null,
      NightKind.study,
      NightKind.recovery,
    ][random.nextInt(3)];
    return (
      workoutDone: random.nextBool(),
      briefingDone: briefingDone,
      briefingMode: briefingDone
          ? BriefingCompletion.values[random.nextInt(
              BriefingCompletion.values.length,
            )]
          : null,
      toggleOn: random.nextBool(),
      note: _optionalNotes[random.nextInt(_optionalNotes.length)],
      noteAudioId: random.nextBool() ? null : 'audio-1',
      nightKind: nightKind,
      studyBlockId: random.nextBool() ? null : 'block-1',
      studyEnded: random.nextBool(),
      studyDuration: _studyDurations[random.nextInt(_studyDurations.length)],
      recoveryNote: _optionalNotes[random.nextInt(_optionalNotes.length)],
      waiver: FixtureWaiver.values[random.nextInt(FixtureWaiver.values.length)],
    );
  },
  shrink: (value) sync* {
    if (value != _emptyPillarEntries) yield _emptyPillarEntries;
  },
);

/// Linhas do tempo contíguas que sempre atravessam ao menos um fim de semana,
/// com um dia final ainda aberto e um feriado opcional no meio.
final Generator<TimelineFixture> anyTimeline = any.simple(
  generate: (random, size) {
    final start = random.nextBool()
        ? OperationalDate(2026, 1, 5) // segunda
        : OperationalDate(2026, 1, 9); // sexta: cobre sexta -> segunda
    final span = 8 + random.nextInt(13); // 8..20 dias
    final failureLength = random.nextInt(11);
    final activation = start.addDays(random.nextInt(3));
    final holidayOffset = random.nextBool() ? 4 : null;
    final days = <TimelineDayFixture>[];
    var failures = 0;
    for (var offset = -2; offset < span; offset++) {
      final date = start.addDays(offset);
      final holiday = !date.isWeekend && offset == holidayOffset;
      final mute = date.isWeekend || holiday;
      final isOpen = offset == span - 1;
      final isFailure = !mute && failures < failureLength;
      if (isFailure) failures++;
      days.add((
        date: date,
        isWorkday: !mute,
        isClosed: !isOpen,
        isSealed: !mute && !isFailure,
        isMute: mute,
        muteCause: date.isWeekend
            ? FixtureMuteCause.weekend
            : holiday
            ? FixtureMuteCause.holiday
            : null,
      ));
    }
    return (activationDate: activation, days: days);
  },
  shrink: (value) sync* {
    if (value.days.length > 1) {
      yield (activationDate: value.activationDate, days: [value.days.first]);
    }
  },
);

/// Sequências de ações sobre o bloco de Estudo, todas alcançáveis pelas regras
/// de reversibilidade do dia aberto.
final Generator<StudyBlockSequenceFixture> anyStudyBlockSeq = any.choose(const [
  [StudyAction.start, StudyAction.complete],
  [StudyAction.start, StudyAction.cancel],
  [
    StudyAction.start,
    StudyAction.cancel,
    StudyAction.restart,
    StudyAction.complete,
  ],
  [StudyAction.start, StudyAction.complete, StudyAction.replaceWithRecovery],
  [StudyAction.start, StudyAction.orphan, StudyAction.resumeAfterDeadline],
]);

/// Textos Unicode com comprimento em runes orbitando `boundary - 1`, `boundary`
/// e `boundary + 1`, cobrindo ASCII, acentos, emoji e combinantes.
Generator<UnicodeTextFixture> unicodeTextAround([int boundary = 500]) {
  if (boundary < 1) throw ArgumentError.value(boundary, 'boundary');
  final lengths = {boundary - 1, boundary, boundary + 1}.toList();
  const atoms = <(UnicodeKind, String)>[
    (UnicodeKind.ascii, 'a'),
    (UnicodeKind.accented, 'á'),
    (UnicodeKind.emoji, '😀'),
    (UnicodeKind.combining, 'e\u0301'),
    (UnicodeKind.whitespace, ' '),
  ];
  return any.simple(
    generate: (random, size) {
      final atom = atoms[random.nextInt(atoms.length)];
      final length = lengths[random.nextInt(lengths.length)];
      final runes = atom.$2.runes.toList();
      final text = String.fromCharCodes(
        List.generate(length, (index) => runes[index % runes.length]),
      );
      return (text: text, boundary: boundary, kind: atom.$1);
    },
    shrink: (value) sync* {
      if (value.text.isNotEmpty) {
        yield (text: '', boundary: boundary, kind: value.kind);
      }
    },
  );
}

/// Limite textual padrão dos campos livres (500 runes).
final Generator<UnicodeTextFixture> anyUnicodeText = unicodeTextAround();

/// Markdown que cobre o parser do Juramento: heading exato, linhas em branco,
/// blockquote contíguo, segundo blockquote, HTML bruto e CRLF.
final Generator<String> anyMarkdown = any.choose(const [
  '# Juramento\n\n> primeira linha',
  ' # Juramento \n\n\n> linha 1\n> linha 2',
  '# Juramento\ntexto comum\n\n> bloco tardio',
  '# Outro título\n\n> não é juramento',
  'texto sem heading',
  '# Juramento\n\n> primeiro\n\n> segundo',
  '# Juramento\n\n<script>alert(1)</script>\n\n> compromisso',
  '# Juramento\r\n\r\n> terminadores Windows',
]);

/// Listas de contatos que exercitam cada nível da ordem semanal: nulos
/// primeiro, data mais antiga, empate por `created_at` e desempate por `id`.
final Generator<List<ContactFixture>> anyContactList = any.choose([
  <ContactFixture>[],
  [
    (
      id: 'null-touch',
      lastTouchDate: null,
      createdAt: DateTime.utc(2025, 1, 1),
    ),
    (
      id: 'dated',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2025, 1, 2),
    ),
  ],
  [
    (
      id: 'older-touch',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2025, 2, 1),
    ),
    (
      id: 'newer-touch',
      lastTouchDate: OperationalDate(2025, 2, 1),
      createdAt: DateTime.utc(2025, 1, 1),
    ),
  ],
  [
    (
      id: 'older-created',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2024, 1, 1),
    ),
    (
      id: 'newer-created',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2024, 2, 1),
    ),
  ],
  [
    (
      id: 'a',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2024, 1, 1),
    ),
    (
      id: 'b',
      lastTouchDate: OperationalDate(2025, 1, 1),
      createdAt: DateTime.utc(2024, 1, 1),
    ),
  ],
]);

/// Fusos de aparelho, incluindo o oficial, para exercitar
/// `deviceZoneDiverges` e mudanças de relógio.
final Generator<DeviceZoneFixture> anyDeviceZone = any.choose(const [
  (
    zoneId: kBusinessTimeZone,
    offset: Duration(hours: -3),
    clockMovedForward: false,
  ),
  (
    zoneId: 'America/New_York',
    offset: Duration(hours: -5),
    clockMovedForward: false,
  ),
  (zoneId: 'Europe/London', offset: Duration.zero, clockMovedForward: true),
  (zoneId: 'Asia/Tokyo', offset: Duration(hours: 9), clockMovedForward: true),
  (
    zoneId: 'Pacific/Honolulu',
    offset: Duration(hours: -10),
    clockMovedForward: false,
  ),
]);

/// Pontos de injeção de falha para verificar atomicidade das transações.
final Generator<FailurePointFixture> anyFailurePoint = any.simple(
  generate: (Random random, int size) => (
    stage: FailureStage.values[random.nextInt(FailureStage.values.length)],
    writeIndex: random.nextInt(max(1, min(size, 16))),
  ),
  shrink: (value) sync* {
    if (value.stage != FailureStage.beforeWrite || value.writeIndex != 0) {
      yield (stage: FailureStage.beforeWrite, writeIndex: 0);
    }
  },
);
