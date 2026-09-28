typedef JsonMap = Map<String, Object?>;

/// Data civil que identifica um dia operacional no contrato de exportação.
final class ExportOperationalDate {
  ExportOperationalDate(this.value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw FormatException('Data operacional inválida: $value');
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('Data operacional inválida: $value');
    }
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final String value;

  @override
  String toString() => value;
}

/// Instante ISO-8601 que mantém explicitamente o offset oficial de São Paulo.
final class ExportOfficialInstant {
  ExportOfficialInstant(this.value) {
    if (!_pattern.hasMatch(value)) {
      throw FormatException('Instante oficial inválido: $value');
    }
    DateTime.parse(value);
  }

  static final RegExp _pattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?-0[23]:00$',
  );

  final String value;

  @override
  String toString() => value;
}

/// Horário civil em formato canônico HH:mm.
final class ExportCivilTime {
  ExportCivilTime(this.value) {
    final match = _pattern.firstMatch(value);
    if (match == null || int.parse(match.group(1)!) > 23) {
      throw FormatException('Horário civil inválido: $value');
    }
  }

  static final RegExp _pattern = RegExp(r'^(\d{2}):[0-5]\d$');

  final String value;

  @override
  String toString() => value;
}

/// Referência ao áudio no pacote, sem carregar ou embutir bytes.
final class ExportAudioReference {
  ExportAudioReference({required this.id, required this.relativePath}) {
    requireNonEmpty(id, 'audio_ref.id');
    validateRelativeAudioPath(relativePath);
  }

  factory ExportAudioReference.fromJson(JsonMap json) => ExportAudioReference(
    id: readString(json, 'id'),
    relativePath: readString(json, 'relative_path'),
  );

  final String id;
  final String relativePath;

  JsonMap toJson() => {'id': id, 'relative_path': relativePath};
}

enum ExportReviewWeekday { sunday, monday }

enum ExportDayResult { sealed, unsealed, mute }

enum ExportMuteCause { weekend, holiday }

enum ExportPillar { morning, day, night }

enum ExportBriefingMode { automatic, manual }

enum ExportNightKind { study, recovery }

enum ExportProtocolState { pending, answered, invalidated }

enum ExportPlanOrExecution { plan, execution }

// Os nomes são códigos normativos persistidos no wire format.
// ignore: constant_identifier_names
enum ExportCompetency { ST, IN, CA }

enum ExportSuggestionStatus { pending, done, skipped }

enum ExportCycleState { active, archived }

// Os nomes são códigos normativos persistidos no wire format.
// ignore: constant_identifier_names
enum ExportGartnerLevel { BD, B, I, A, E }

enum ExportWeeklyReviewState { draft, finalized }

enum ExportAudioKind { dayNote, weeklyReview }

enum ExportNotificationKind { weeklyReviewSunday, weeklyReviewMonday }

enum ExportNotificationState { planned, delivered, cancelled, suppressed }

extension ExportAudioKindWire on ExportAudioKind {
  String get wireName => switch (this) {
    ExportAudioKind.dayNote => 'day_note',
    ExportAudioKind.weeklyReview => 'weekly_review',
  };
}

extension ExportNotificationKindWire on ExportNotificationKind {
  String get wireName => switch (this) {
    ExportNotificationKind.weeklyReviewSunday => 'weekly_review_sunday',
    ExportNotificationKind.weeklyReviewMonday => 'weekly_review_monday',
  };
}

T readEnum<T extends Enum>(
  JsonMap json,
  String key,
  List<T> values, {
  String Function(T value)? wireName,
}) {
  final raw = readString(json, key);
  final nameOf = wireName ?? (value) => value.name;
  for (final value in values) {
    if (nameOf(value) == raw) return value;
  }
  throw FormatException('$key possui valor desconhecido: $raw');
}

T? readNullableEnum<T extends Enum>(
  JsonMap json,
  String key,
  List<T> values, {
  String Function(T value)? wireName,
}) {
  if (json[key] == null) return null;
  return readEnum(json, key, values, wireName: wireName);
}

JsonMap readObject(JsonMap json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key deve ser um objeto JSON');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

JsonMap? readNullableObject(JsonMap json, String key) {
  if (json[key] == null) return null;
  return readObject(json, key);
}

List<T> readObjectList<T>(
  JsonMap json,
  String key,
  T Function(JsonMap value) decode,
) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('$key deve ser uma lista JSON');
  }
  return List<T>.unmodifiable(
    value.map((item) {
      if (item is! Map) {
        throw FormatException('$key deve conter somente objetos JSON');
      }
      return decode(item.map((key, value) => MapEntry(key.toString(), value)));
    }),
  );
}

String readString(JsonMap json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key deve ser texto');
  return value;
}

String? readNullableString(JsonMap json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key deve ser texto ou nulo');
  return value;
}

int readInt(JsonMap json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key deve ser inteiro');
  return value;
}

bool readBool(JsonMap json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key deve ser booleano');
  return value;
}

ExportOperationalDate readDate(JsonMap json, String key) =>
    ExportOperationalDate(readString(json, key));

ExportOperationalDate? readNullableDate(JsonMap json, String key) {
  final value = readNullableString(json, key);
  return value == null ? null : ExportOperationalDate(value);
}

ExportOfficialInstant readInstant(JsonMap json, String key) =>
    ExportOfficialInstant(readString(json, key));

ExportOfficialInstant? readNullableInstant(JsonMap json, String key) {
  final value = readNullableString(json, key);
  return value == null ? null : ExportOfficialInstant(value);
}

void requireNonEmpty(String value, String field) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, field, 'não pode ser vazio');
  }
}

void validateRelativeAudioPath(String value) {
  if (!value.startsWith('audio/') ||
      value.contains('\\') ||
      value.split('/').any((segment) => segment.isEmpty || segment == '..')) {
    throw ArgumentError.value(
      value,
      'relativePath',
      'deve ser relativo ao pacote e iniciar com audio/',
    );
  }
}
