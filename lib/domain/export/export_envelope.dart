import 'dart:convert';

import 'export_day.dart';
import 'export_records.dart';
import 'export_values.dart';

export 'export_day.dart';
export 'export_records.dart';
export 'export_values.dart';

/// Contrato puro e versionado. Não executa exportação nem acessa persistência.
final class RitmoExportEnvelope {
  RitmoExportEnvelope({
    required this.generatedAt,
    required this.settings,
    required Iterable<ExportDay> days,
    required Iterable<ExportHoliday> holidays,
    required Iterable<ExportProtocolAlarm> protocolAlarms,
    required Iterable<ExportCycle> cycles,
    required Iterable<ExportMentorship> mentorships,
    required Iterable<ExportContact> contacts,
    required Iterable<ExportWeeklyReview> weeklyReviews,
    required this.manifest,
    required Iterable<ExportChangeInitiative> changeInitiatives,
    required Iterable<ExportAudioAsset> audioAssets,
    required Iterable<ExportNotificationPlan> notificationPlans,
    required this.metricsSnapshot,
  }) : days = List.unmodifiable(days),
       holidays = List.unmodifiable(holidays),
       protocolAlarms = List.unmodifiable(protocolAlarms),
       cycles = List.unmodifiable(cycles),
       mentorships = List.unmodifiable(mentorships),
       contacts = List.unmodifiable(contacts),
       weeklyReviews = List.unmodifiable(weeklyReviews),
       changeInitiatives = List.unmodifiable(changeInitiatives),
       audioAssets = List.unmodifiable(audioAssets),
       notificationPlans = List.unmodifiable(notificationPlans);

  factory RitmoExportEnvelope.fromJson(JsonMap json) {
    final schema = readString(json, 'schema');
    final version = readInt(json, 'schema_version');
    final timezone = readString(json, 'business_timezone');
    if (schema != schemaName || version != schemaVersion) {
      throw FormatException('Contrato não suportado: $schema v$version');
    }
    if (timezone != businessTimezone) {
      throw FormatException('Fuso de negócio não suportado: $timezone');
    }
    return RitmoExportEnvelope(
      generatedAt: readInstant(json, 'generated_at'),
      settings: ExportSettings.fromJson(readObject(json, 'settings')),
      days: readObjectList(json, 'days', ExportDay.fromJson),
      holidays: readObjectList(json, 'holidays', ExportHoliday.fromJson),
      protocolAlarms: readObjectList(
        json,
        'protocol_alarms',
        ExportProtocolAlarm.fromJson,
      ),
      cycles: readObjectList(json, 'cycles', ExportCycle.fromJson),
      mentorships: readObjectList(
        json,
        'mentorships',
        ExportMentorship.fromJson,
      ),
      contacts: readObjectList(json, 'contacts', ExportContact.fromJson),
      weeklyReviews: readObjectList(
        json,
        'weekly_reviews',
        ExportWeeklyReview.fromJson,
      ),
      manifest: ExportManifest.fromJson(readObject(json, 'manifest')),
      changeInitiatives: readObjectList(
        json,
        'change_initiatives',
        ExportChangeInitiative.fromJson,
      ),
      audioAssets: readObjectList(
        json,
        'audio_assets',
        ExportAudioAsset.fromJson,
      ),
      notificationPlans: readObjectList(
        json,
        'notification_plans',
        ExportNotificationPlan.fromJson,
      ),
      metricsSnapshot: ExportMetricsSnapshot.fromJson(
        readObject(json, 'metrics_snapshot'),
      ),
    );
  }

  factory RitmoExportEnvelope.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Envelope deve ser um objeto JSON');
    }
    return RitmoExportEnvelope.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static const String schemaName = 'ritmo.export';
  static const int schemaVersion = 1;
  static const String businessTimezone = 'America/Sao_Paulo';

  final ExportOfficialInstant generatedAt;
  final ExportSettings settings;
  final List<ExportDay> days;
  final List<ExportHoliday> holidays;
  final List<ExportProtocolAlarm> protocolAlarms;
  final List<ExportCycle> cycles;
  final List<ExportMentorship> mentorships;
  final List<ExportContact> contacts;
  final List<ExportWeeklyReview> weeklyReviews;
  final ExportManifest manifest;
  final List<ExportChangeInitiative> changeInitiatives;
  final List<ExportAudioAsset> audioAssets;
  final List<ExportNotificationPlan> notificationPlans;
  final ExportMetricsSnapshot metricsSnapshot;

  JsonMap toJson() => {
    'schema': schemaName,
    'schema_version': schemaVersion,
    'generated_at': generatedAt.value,
    'business_timezone': businessTimezone,
    'settings': settings.toJson(),
    'days': days.map((value) => value.toJson()).toList(),
    'holidays': holidays.map((value) => value.toJson()).toList(),
    'protocol_alarms': protocolAlarms.map((value) => value.toJson()).toList(),
    'cycles': cycles.map((value) => value.toJson()).toList(),
    'mentorships': mentorships.map((value) => value.toJson()).toList(),
    'contacts': contacts.map((value) => value.toJson()).toList(),
    'weekly_reviews': weeklyReviews.map((value) => value.toJson()).toList(),
    'manifest': manifest.toJson(),
    'change_initiatives': changeInitiatives
        .map((value) => value.toJson())
        .toList(),
    'audio_assets': audioAssets.map((value) => value.toJson()).toList(),
    'notification_plans': notificationPlans
        .map((value) => value.toJson())
        .toList(),
    'metrics_snapshot': metricsSnapshot.toJson(),
  };

  /// JSON compacto e determinístico: chaves e campos seguem a ordem da v1.
  String toCanonicalJson() => jsonEncode(toJson());

  /// Representação legível com a mesma ordem canônica de campos.
  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
