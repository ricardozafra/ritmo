/// Modelos mínimos, exclusivos de teste, para entradas cujo domínio ainda será
/// implementado. Onde o domínio já existe (`OperationalDate`, `LocalTimeOfDay`,
/// `OperationalCalendar`), os fixtures usam os tipos reais; os enums abaixo
/// cobrem apenas o que ainda não foi modelado e serão substituídos pelas
/// entidades de produção à medida que cada tarefa surgir.
library;

import 'package:ritmo/domain/day/pillar_rules.dart';
import 'package:ritmo/domain/time/operational_calendar.dart';

/// Bordas temporais relevantes em torno de uma data operacional.
enum TemporalEdge {
  /// Último instante ainda pertencente à data operacional.
  beforeDayClose,

  /// `operationalClose(d)`: abre a data seguinte.
  atDayClose,

  /// Primeiro instante já pertencente à data seguinte.
  afterDayClose,

  /// `blockDeadline(d)`: limite do bloco de Estudo.
  atNightEnd,

  /// Meia-noite civil contida na janela de `d` quando `day_close_time > 00:00`.
  civilMidnight,
}

enum FixtureDayResult { sealed, unsealed, mute }

enum FixtureMuteCause { weekend, holiday }

enum FixturePillar { morning, day, night }

enum FixtureWaiver { none, activeMorning, activeDay, activeNight, revoked }

enum StudyAction {
  start,
  cancel,
  restart,
  complete,
  replaceWithRecovery,
  orphan,
  resumeAfterDeadline,
}

enum UnicodeKind { ascii, accented, emoji, combining, whitespace }

enum FailureStage { beforeWrite, afterFirstWrite, beforeCommit, afterCommit }

/// Configuração de fronteiras. `OperationalCalendar` já é a fonte única de
/// `day_close_time` e `night_end_time`, então não há fixture paralelo.
typedef SettingsFixture = OperationalCalendar;

typedef InstantFixture = ({
  OperationalDate date,
  DateTime civilInstant,
  TemporalEdge edge,
  OperationalCalendar calendar,
});

typedef DayStateFixture = ({
  OperationalDate date,
  FixtureDayResult baseResult,
  FixtureDayResult effectiveResult,
  DateTime? closedAt,
  DateTime? sealTimestamp,
  FixtureMuteCause? muteCause,
  FixtureDayResult? previousResult,
});

typedef TimelineDayFixture = ({
  OperationalDate date,
  bool isWorkday,
  bool isClosed,
  bool isSealed,
  bool isMute,
  FixtureMuteCause? muteCause,
});

typedef TimelineFixture = ({
  OperationalDate activationDate,
  List<TimelineDayFixture> days,
});

typedef PillarStateFixture = ({
  Set<FixturePillar> completed,
  FixtureWaiver waiver,
});

/// Registros brutos dos três pilares, antes de qualquer regra de conclusão.
/// Cada campo varia livremente para que a conclusão esperada venha do modelo
/// de referência dos requisitos, e não da forma como o registro foi gerado.
typedef PillarEntriesFixture = ({
  bool workoutDone,
  bool briefingDone,
  BriefingCompletion? briefingMode,
  bool toggleOn,
  String? note,
  String? noteAudioId,
  NightKind? nightKind,
  String? studyBlockId,
  bool studyEnded,
  Duration studyDuration,
  String? recoveryNote,
  FixtureWaiver waiver,
});

typedef StudyBlockSequenceFixture = List<StudyAction>;

typedef UnicodeTextFixture = ({String text, int boundary, UnicodeKind kind});

typedef ContactFixture = ({
  String id,
  OperationalDate? lastTouchDate,
  DateTime createdAt,
});

typedef DeviceZoneFixture = ({
  String zoneId,
  Duration offset,
  bool clockMovedForward,
});

typedef FailurePointFixture = ({FailureStage stage, int writeIndex});
