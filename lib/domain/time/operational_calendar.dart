/// Núcleo temporal do Ritmo: domínio puro, sem I/O e sem consulta ao relógio.
///
/// Todas as funções deste arquivo são determinísticas sobre coordenadas civis
/// do fuso oficial. A conversão entre instantes absolutos e coordenadas civis,
/// bem como a normalização de horas inexistentes ou ambíguas, pertence a
/// `OperationalClock` (`lib/domain/time/operational_clock.dart`).
library;

/// Fuso de negócio imutável. Nunca substituído pelo fuso do aparelho.
const String kBusinessTimeZone = 'America/Sao_Paulo';

const int _minutesPerHour = 60;
const int _minutesPerDay = 24 * _minutesPerHour;

/// Hora local sem data, comparável na linha temporal operacional.
final class LocalTimeOfDay implements Comparable<LocalTimeOfDay> {
  const LocalTimeOfDay(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hora fora de [0, 23]'),
      assert(minute >= 0 && minute < 60, 'minuto fora de [0, 59]');

  /// Constrói a partir de minutos desde a meia-noite civil, em `[0, 1440)`.
  factory LocalTimeOfDay.fromMinutes(int minutesFromMidnight) {
    if (minutesFromMidnight < 0 || minutesFromMidnight >= _minutesPerDay) {
      throw ArgumentError.value(
        minutesFromMidnight,
        'minutesFromMidnight',
        'deve estar em [0, $_minutesPerDay)',
      );
    }
    return LocalTimeOfDay(
      minutesFromMidnight ~/ _minutesPerHour,
      minutesFromMidnight % _minutesPerHour,
    );
  }

  /// Lê a hora civil de um [DateTime] já expresso no fuso oficial.
  factory LocalTimeOfDay.fromDateTime(DateTime civilInstant) =>
      LocalTimeOfDay(civilInstant.hour, civilInstant.minute);

  final int hour;
  final int minute;

  int get minutesFromMidnight => hour * _minutesPerHour + minute;

  Duration get sinceMidnight => Duration(minutes: minutesFromMidnight);

  @override
  int compareTo(LocalTimeOfDay other) =>
      minutesFromMidnight.compareTo(other.minutesFromMidnight);

  bool operator <(LocalTimeOfDay other) => compareTo(other) < 0;
  bool operator <=(LocalTimeOfDay other) => compareTo(other) <= 0;
  bool operator >(LocalTimeOfDay other) => compareTo(other) > 0;
  bool operator >=(LocalTimeOfDay other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is LocalTimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Data civil que nomeia um dia operacional. Imutável e nunca reclassificada.
final class OperationalDate implements Comparable<OperationalDate> {
  factory OperationalDate(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('data civil inexistente: $year-$month-$day');
    }
    return OperationalDate._(year, month, day);
  }

  const OperationalDate._(this.year, this.month, this.day);

  /// Data civil de um [DateTime] já expresso no fuso oficial.
  factory OperationalDate.fromCivilDateTime(DateTime civilInstant) =>
      OperationalDate._(
        civilInstant.year,
        civilInstant.month,
        civilInstant.day,
      );

  final int year;
  final int month;
  final int day;

  /// Dia da semana ISO: 1 = segunda-feira, 7 = domingo.
  int get weekday => DateTime.utc(year, month, day).weekday;

  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  OperationalDate addDays(int days) {
    final shifted = DateTime.utc(year, month, day + days);
    return OperationalDate._(shifted.year, shifted.month, shifted.day);
  }

  OperationalDate get next => addDays(1);
  OperationalDate get previous => addDays(-1);

  /// Representação `YYYY-MM-DD`, estável para chaves lógicas e comparação.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(OperationalDate other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    if (byMonth != 0) return byMonth;
    return day.compareTo(other.day);
  }

  bool operator <(OperationalDate other) => compareTo(other) < 0;
  bool operator <=(OperationalDate other) => compareTo(other) <= 0;
  bool operator >(OperationalDate other) => compareTo(other) > 0;
  bool operator >=(OperationalDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is OperationalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}

/// Coordenada civil (data + hora local) no fuso oficial.
///
/// Não é um instante absoluto: a materialização em `TZDateTime`, com a
/// normalização de horas inexistentes ou ambíguas, é feita por
/// `OperationalClock`.
final class CivilMoment implements Comparable<CivilMoment> {
  const CivilMoment({required this.date, required this.time});

  final OperationalDate date;
  final LocalTimeOfDay time;

  /// Soma uma duração em minutos inteiros, propagando o excedente para a data.
  CivilMoment plus(Duration duration) {
    if (duration.inMicroseconds % Duration.microsecondsPerMinute != 0) {
      throw ArgumentError.value(
        duration,
        'duration',
        'deve ser múltiplo de um minuto',
      );
    }
    final total = time.minutesFromMidnight + duration.inMinutes;
    final dayShift = _floorDiv(total, _minutesPerDay);
    final minutes = total - dayShift * _minutesPerDay;
    return CivilMoment(
      date: date.addDays(dayShift),
      time: LocalTimeOfDay.fromMinutes(minutes),
    );
  }

  /// Empacota as coordenadas civis como [DateTime] para aritmética e
  /// comparação. O flag UTC é apenas um invólucro: o valor não representa um
  /// instante absoluto.
  DateTime toCivilDateTime() =>
      DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);

  @override
  int compareTo(CivilMoment other) {
    final byDate = date.compareTo(other.date);
    if (byDate != 0) return byDate;
    return time.compareTo(other.time);
  }

  bool operator <(CivilMoment other) => compareTo(other) < 0;
  bool operator <=(CivilMoment other) => compareTo(other) <= 0;
  bool operator >(CivilMoment other) => compareTo(other) > 0;
  bool operator >=(CivilMoment other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is CivilMoment && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '${date.iso} $time';
}

int _floorDiv(int value, int divisor) =>
    (value >= 0) ? value ~/ divisor : -(((-value) + divisor - 1) ~/ divisor);

/// Particionamento da linha temporal operacional (RF-05.4, RF-05.5, RF-01.12).
final class OperationalCalendar {
  const OperationalCalendar({
    required this.dayCloseTime,
    required this.nightEndTime,
  });

  /// Configuração de seed: fechamento 03h00 e `night_end_time = day_close_time`
  /// (deslocamento de 24h, Estudo permitido até o fechamento).
  const OperationalCalendar.seed()
    : dayCloseTime = defaultDayCloseTime,
      nightEndTime = defaultDayCloseTime;

  /// Padrão normativo de `day_close_time` (RF-05.3).
  static const LocalTimeOfDay defaultDayCloseTime = LocalTimeOfDay(3, 0);

  /// Duração de uma janela operacional completa.
  static const Duration operationalDayLength = Duration(hours: 24);

  final LocalTimeOfDay dayCloseTime;
  final LocalTimeOfDay nightEndTime;

  /// `civilTime(t)` = hora civil de `t` no fuso oficial.
  LocalTimeOfDay civilTime(DateTime civilInstant) =>
      LocalTimeOfDay.fromDateTime(civilInstant);

  /// `operationalDateOf(t)` = data civil de `t` menos um dia quando
  /// `civilTime(t) < day_close_time`; senão a própria data civil (RF-05.4).
  OperationalDate operationalDateOf(DateTime civilInstant) {
    final civilDate = OperationalDate.fromCivilDateTime(civilInstant);
    return civilTime(civilInstant) < dayCloseTime
        ? civilDate.previous
        : civilDate;
  }

  /// Instante civil de abertura de [date]: `date @ day_close_time`.
  CivilMoment operationalOpen(OperationalDate date) =>
      CivilMoment(date: date, time: dayCloseTime);

  /// Instante civil de fechamento de [date]: `operationalOpen(date + 1)`.
  ///
  /// É o mesmo instante que preenche `closed_at` de [date] e abre a data
  /// seguinte (RF-05.5).
  CivilMoment operationalClose(OperationalDate date) =>
      operationalOpen(date.next);

  /// Deslocamento operacional de uma hora civil: `(h - day_close_time) mod 24h`,
  /// com representante em `(0, 24h]`.
  ///
  /// É a coordenada de `h` dentro da janela
  /// `[operationalOpen(d), operationalClose(d))`. Quando `h == day_close_time`,
  /// o deslocamento é 24h — o fim exclusivo da janela — e não zero, o que
  /// permite comparar `night_end_time` com `day_close_time` mesmo quando ambos
  /// cruzam a meia-noite civil (RA-01.1).
  Duration offset(LocalTimeOfDay time) {
    final delta =
        (time.minutesFromMidnight - dayCloseTime.minutesFromMidnight) %
        _minutesPerDay;
    return Duration(minutes: delta == 0 ? _minutesPerDay : delta);
  }

  /// Deslocamento operacional de `night_end_time`.
  Duration get nightOffset => offset(nightEndTime);

  /// `blockDeadline(d)` = `operationalOpen(d) + offset(night_end_time)`.
  ///
  /// Consequência direta: `blockDeadline(d) <= operationalClose(d)` para
  /// qualquer configuração válida (RF-01.12).
  CivilMoment blockDeadline(OperationalDate date) =>
      operationalOpen(date).plus(nightOffset);
}
