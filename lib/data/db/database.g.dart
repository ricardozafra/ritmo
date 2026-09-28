// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _activationDateMeta = const VerificationMeta(
    'activationDate',
  );
  @override
  late final GeneratedColumn<String> activationDate = GeneratedColumn<String>(
    'activation_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessTimezoneMeta = const VerificationMeta(
    'businessTimezone',
  );
  @override
  late final GeneratedColumn<String> businessTimezone = GeneratedColumn<String>(
    'business_timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('America/Sao_Paulo'),
  );
  static const VerificationMeta _dayCloseTimeMinMeta = const VerificationMeta(
    'dayCloseTimeMin',
  );
  @override
  late final GeneratedColumn<int> dayCloseTimeMin = GeneratedColumn<int>(
    'day_close_time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(180),
  );
  static const VerificationMeta _nightEndTimeMinMeta = const VerificationMeta(
    'nightEndTimeMin',
  );
  @override
  late final GeneratedColumn<int> nightEndTimeMin = GeneratedColumn<int>(
    'night_end_time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(180),
  );
  static const VerificationMeta _reviewWeekdayMeta = const VerificationMeta(
    'reviewWeekday',
  );
  @override
  late final GeneratedColumn<String> reviewWeekday = GeneratedColumn<String>(
    'review_weekday',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sunday'),
  );
  static const VerificationMeta _reviewTimeMinMeta = const VerificationMeta(
    'reviewTimeMin',
  );
  @override
  late final GeneratedColumn<int> reviewTimeMin = GeneratedColumn<int>(
    'review_time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1260),
  );
  static const VerificationMeta _sundayNotificationEnabledMeta =
      const VerificationMeta('sundayNotificationEnabled');
  @override
  late final GeneratedColumn<bool> sundayNotificationEnabled =
      GeneratedColumn<bool>(
        'sunday_notification_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sunday_notification_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _syncEnabledMeta = const VerificationMeta(
    'syncEnabled',
  );
  @override
  late final GeneratedColumn<bool> syncEnabled = GeneratedColumn<bool>(
    'sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activationDate,
    businessTimezone,
    dayCloseTimeMin,
    nightEndTimeMin,
    reviewWeekday,
    reviewTimeMin,
    sundayNotificationEnabled,
    syncEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activation_date')) {
      context.handle(
        _activationDateMeta,
        activationDate.isAcceptableOrUnknown(
          data['activation_date']!,
          _activationDateMeta,
        ),
      );
    }
    if (data.containsKey('business_timezone')) {
      context.handle(
        _businessTimezoneMeta,
        businessTimezone.isAcceptableOrUnknown(
          data['business_timezone']!,
          _businessTimezoneMeta,
        ),
      );
    }
    if (data.containsKey('day_close_time_min')) {
      context.handle(
        _dayCloseTimeMinMeta,
        dayCloseTimeMin.isAcceptableOrUnknown(
          data['day_close_time_min']!,
          _dayCloseTimeMinMeta,
        ),
      );
    }
    if (data.containsKey('night_end_time_min')) {
      context.handle(
        _nightEndTimeMinMeta,
        nightEndTimeMin.isAcceptableOrUnknown(
          data['night_end_time_min']!,
          _nightEndTimeMinMeta,
        ),
      );
    }
    if (data.containsKey('review_weekday')) {
      context.handle(
        _reviewWeekdayMeta,
        reviewWeekday.isAcceptableOrUnknown(
          data['review_weekday']!,
          _reviewWeekdayMeta,
        ),
      );
    }
    if (data.containsKey('review_time_min')) {
      context.handle(
        _reviewTimeMinMeta,
        reviewTimeMin.isAcceptableOrUnknown(
          data['review_time_min']!,
          _reviewTimeMinMeta,
        ),
      );
    }
    if (data.containsKey('sunday_notification_enabled')) {
      context.handle(
        _sundayNotificationEnabledMeta,
        sundayNotificationEnabled.isAcceptableOrUnknown(
          data['sunday_notification_enabled']!,
          _sundayNotificationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sync_enabled')) {
      context.handle(
        _syncEnabledMeta,
        syncEnabled.isAcceptableOrUnknown(
          data['sync_enabled']!,
          _syncEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activation_date'],
      ),
      businessTimezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_timezone'],
      )!,
      dayCloseTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_close_time_min'],
      )!,
      nightEndTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_end_time_min'],
      )!,
      reviewWeekday: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_weekday'],
      )!,
      reviewTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_time_min'],
      )!,
      sundayNotificationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sunday_notification_enabled'],
      )!,
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_enabled'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String? activationDate;
  final String businessTimezone;
  final int dayCloseTimeMin;
  final int nightEndTimeMin;
  final String reviewWeekday;
  final int reviewTimeMin;
  final bool sundayNotificationEnabled;
  final bool syncEnabled;
  const Setting({
    required this.id,
    this.activationDate,
    required this.businessTimezone,
    required this.dayCloseTimeMin,
    required this.nightEndTimeMin,
    required this.reviewWeekday,
    required this.reviewTimeMin,
    required this.sundayNotificationEnabled,
    required this.syncEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || activationDate != null) {
      map['activation_date'] = Variable<String>(activationDate);
    }
    map['business_timezone'] = Variable<String>(businessTimezone);
    map['day_close_time_min'] = Variable<int>(dayCloseTimeMin);
    map['night_end_time_min'] = Variable<int>(nightEndTimeMin);
    map['review_weekday'] = Variable<String>(reviewWeekday);
    map['review_time_min'] = Variable<int>(reviewTimeMin);
    map['sunday_notification_enabled'] = Variable<bool>(
      sundayNotificationEnabled,
    );
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      activationDate: activationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(activationDate),
      businessTimezone: Value(businessTimezone),
      dayCloseTimeMin: Value(dayCloseTimeMin),
      nightEndTimeMin: Value(nightEndTimeMin),
      reviewWeekday: Value(reviewWeekday),
      reviewTimeMin: Value(reviewTimeMin),
      sundayNotificationEnabled: Value(sundayNotificationEnabled),
      syncEnabled: Value(syncEnabled),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      activationDate: serializer.fromJson<String?>(json['activationDate']),
      businessTimezone: serializer.fromJson<String>(json['businessTimezone']),
      dayCloseTimeMin: serializer.fromJson<int>(json['dayCloseTimeMin']),
      nightEndTimeMin: serializer.fromJson<int>(json['nightEndTimeMin']),
      reviewWeekday: serializer.fromJson<String>(json['reviewWeekday']),
      reviewTimeMin: serializer.fromJson<int>(json['reviewTimeMin']),
      sundayNotificationEnabled: serializer.fromJson<bool>(
        json['sundayNotificationEnabled'],
      ),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activationDate': serializer.toJson<String?>(activationDate),
      'businessTimezone': serializer.toJson<String>(businessTimezone),
      'dayCloseTimeMin': serializer.toJson<int>(dayCloseTimeMin),
      'nightEndTimeMin': serializer.toJson<int>(nightEndTimeMin),
      'reviewWeekday': serializer.toJson<String>(reviewWeekday),
      'reviewTimeMin': serializer.toJson<int>(reviewTimeMin),
      'sundayNotificationEnabled': serializer.toJson<bool>(
        sundayNotificationEnabled,
      ),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
    };
  }

  Setting copyWith({
    int? id,
    Value<String?> activationDate = const Value.absent(),
    String? businessTimezone,
    int? dayCloseTimeMin,
    int? nightEndTimeMin,
    String? reviewWeekday,
    int? reviewTimeMin,
    bool? sundayNotificationEnabled,
    bool? syncEnabled,
  }) => Setting(
    id: id ?? this.id,
    activationDate: activationDate.present
        ? activationDate.value
        : this.activationDate,
    businessTimezone: businessTimezone ?? this.businessTimezone,
    dayCloseTimeMin: dayCloseTimeMin ?? this.dayCloseTimeMin,
    nightEndTimeMin: nightEndTimeMin ?? this.nightEndTimeMin,
    reviewWeekday: reviewWeekday ?? this.reviewWeekday,
    reviewTimeMin: reviewTimeMin ?? this.reviewTimeMin,
    sundayNotificationEnabled:
        sundayNotificationEnabled ?? this.sundayNotificationEnabled,
    syncEnabled: syncEnabled ?? this.syncEnabled,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      activationDate: data.activationDate.present
          ? data.activationDate.value
          : this.activationDate,
      businessTimezone: data.businessTimezone.present
          ? data.businessTimezone.value
          : this.businessTimezone,
      dayCloseTimeMin: data.dayCloseTimeMin.present
          ? data.dayCloseTimeMin.value
          : this.dayCloseTimeMin,
      nightEndTimeMin: data.nightEndTimeMin.present
          ? data.nightEndTimeMin.value
          : this.nightEndTimeMin,
      reviewWeekday: data.reviewWeekday.present
          ? data.reviewWeekday.value
          : this.reviewWeekday,
      reviewTimeMin: data.reviewTimeMin.present
          ? data.reviewTimeMin.value
          : this.reviewTimeMin,
      sundayNotificationEnabled: data.sundayNotificationEnabled.present
          ? data.sundayNotificationEnabled.value
          : this.sundayNotificationEnabled,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('activationDate: $activationDate, ')
          ..write('businessTimezone: $businessTimezone, ')
          ..write('dayCloseTimeMin: $dayCloseTimeMin, ')
          ..write('nightEndTimeMin: $nightEndTimeMin, ')
          ..write('reviewWeekday: $reviewWeekday, ')
          ..write('reviewTimeMin: $reviewTimeMin, ')
          ..write('sundayNotificationEnabled: $sundayNotificationEnabled, ')
          ..write('syncEnabled: $syncEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activationDate,
    businessTimezone,
    dayCloseTimeMin,
    nightEndTimeMin,
    reviewWeekday,
    reviewTimeMin,
    sundayNotificationEnabled,
    syncEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.activationDate == this.activationDate &&
          other.businessTimezone == this.businessTimezone &&
          other.dayCloseTimeMin == this.dayCloseTimeMin &&
          other.nightEndTimeMin == this.nightEndTimeMin &&
          other.reviewWeekday == this.reviewWeekday &&
          other.reviewTimeMin == this.reviewTimeMin &&
          other.sundayNotificationEnabled == this.sundayNotificationEnabled &&
          other.syncEnabled == this.syncEnabled);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String?> activationDate;
  final Value<String> businessTimezone;
  final Value<int> dayCloseTimeMin;
  final Value<int> nightEndTimeMin;
  final Value<String> reviewWeekday;
  final Value<int> reviewTimeMin;
  final Value<bool> sundayNotificationEnabled;
  final Value<bool> syncEnabled;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.activationDate = const Value.absent(),
    this.businessTimezone = const Value.absent(),
    this.dayCloseTimeMin = const Value.absent(),
    this.nightEndTimeMin = const Value.absent(),
    this.reviewWeekday = const Value.absent(),
    this.reviewTimeMin = const Value.absent(),
    this.sundayNotificationEnabled = const Value.absent(),
    this.syncEnabled = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.activationDate = const Value.absent(),
    this.businessTimezone = const Value.absent(),
    this.dayCloseTimeMin = const Value.absent(),
    this.nightEndTimeMin = const Value.absent(),
    this.reviewWeekday = const Value.absent(),
    this.reviewTimeMin = const Value.absent(),
    this.sundayNotificationEnabled = const Value.absent(),
    this.syncEnabled = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? activationDate,
    Expression<String>? businessTimezone,
    Expression<int>? dayCloseTimeMin,
    Expression<int>? nightEndTimeMin,
    Expression<String>? reviewWeekday,
    Expression<int>? reviewTimeMin,
    Expression<bool>? sundayNotificationEnabled,
    Expression<bool>? syncEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activationDate != null) 'activation_date': activationDate,
      if (businessTimezone != null) 'business_timezone': businessTimezone,
      if (dayCloseTimeMin != null) 'day_close_time_min': dayCloseTimeMin,
      if (nightEndTimeMin != null) 'night_end_time_min': nightEndTimeMin,
      if (reviewWeekday != null) 'review_weekday': reviewWeekday,
      if (reviewTimeMin != null) 'review_time_min': reviewTimeMin,
      if (sundayNotificationEnabled != null)
        'sunday_notification_enabled': sundayNotificationEnabled,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? activationDate,
    Value<String>? businessTimezone,
    Value<int>? dayCloseTimeMin,
    Value<int>? nightEndTimeMin,
    Value<String>? reviewWeekday,
    Value<int>? reviewTimeMin,
    Value<bool>? sundayNotificationEnabled,
    Value<bool>? syncEnabled,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      activationDate: activationDate ?? this.activationDate,
      businessTimezone: businessTimezone ?? this.businessTimezone,
      dayCloseTimeMin: dayCloseTimeMin ?? this.dayCloseTimeMin,
      nightEndTimeMin: nightEndTimeMin ?? this.nightEndTimeMin,
      reviewWeekday: reviewWeekday ?? this.reviewWeekday,
      reviewTimeMin: reviewTimeMin ?? this.reviewTimeMin,
      sundayNotificationEnabled:
          sundayNotificationEnabled ?? this.sundayNotificationEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activationDate.present) {
      map['activation_date'] = Variable<String>(activationDate.value);
    }
    if (businessTimezone.present) {
      map['business_timezone'] = Variable<String>(businessTimezone.value);
    }
    if (dayCloseTimeMin.present) {
      map['day_close_time_min'] = Variable<int>(dayCloseTimeMin.value);
    }
    if (nightEndTimeMin.present) {
      map['night_end_time_min'] = Variable<int>(nightEndTimeMin.value);
    }
    if (reviewWeekday.present) {
      map['review_weekday'] = Variable<String>(reviewWeekday.value);
    }
    if (reviewTimeMin.present) {
      map['review_time_min'] = Variable<int>(reviewTimeMin.value);
    }
    if (sundayNotificationEnabled.present) {
      map['sunday_notification_enabled'] = Variable<bool>(
        sundayNotificationEnabled.value,
      );
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('activationDate: $activationDate, ')
          ..write('businessTimezone: $businessTimezone, ')
          ..write('dayCloseTimeMin: $dayCloseTimeMin, ')
          ..write('nightEndTimeMin: $nightEndTimeMin, ')
          ..write('reviewWeekday: $reviewWeekday, ')
          ..write('reviewTimeMin: $reviewTimeMin, ')
          ..write('sundayNotificationEnabled: $sundayNotificationEnabled, ')
          ..write('syncEnabled: $syncEnabled')
          ..write(')'))
        .toString();
  }
}

class $DaysTable extends Days with TableInfo<$DaysTable, Day> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationalDateMeta = const VerificationMeta(
    'operationalDate',
  );
  @override
  late final GeneratedColumn<String> operationalDate = GeneratedColumn<String>(
    'operational_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseResultMeta = const VerificationMeta(
    'baseResult',
  );
  @override
  late final GeneratedColumn<String> baseResult = GeneratedColumn<String>(
    'base_result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveResultMeta = const VerificationMeta(
    'effectiveResult',
  );
  @override
  late final GeneratedColumn<String> effectiveResult = GeneratedColumn<String>(
    'effective_result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sealTimestampMeta = const VerificationMeta(
    'sealTimestamp',
  );
  @override
  late final GeneratedColumn<int> sealTimestamp = GeneratedColumn<int>(
    'seal_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _muteCauseMeta = const VerificationMeta(
    'muteCause',
  );
  @override
  late final GeneratedColumn<String> muteCause = GeneratedColumn<String>(
    'mute_cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousResultMeta = const VerificationMeta(
    'previousResult',
  );
  @override
  late final GeneratedColumn<String> previousResult = GeneratedColumn<String>(
    'previous_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationalDate,
    baseResult,
    effectiveResult,
    closedAt,
    sealTimestamp,
    muteCause,
    previousResult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'days';
  @override
  VerificationContext validateIntegrity(
    Insertable<Day> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operational_date')) {
      context.handle(
        _operationalDateMeta,
        operationalDate.isAcceptableOrUnknown(
          data['operational_date']!,
          _operationalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationalDateMeta);
    }
    if (data.containsKey('base_result')) {
      context.handle(
        _baseResultMeta,
        baseResult.isAcceptableOrUnknown(data['base_result']!, _baseResultMeta),
      );
    } else if (isInserting) {
      context.missing(_baseResultMeta);
    }
    if (data.containsKey('effective_result')) {
      context.handle(
        _effectiveResultMeta,
        effectiveResult.isAcceptableOrUnknown(
          data['effective_result']!,
          _effectiveResultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveResultMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('seal_timestamp')) {
      context.handle(
        _sealTimestampMeta,
        sealTimestamp.isAcceptableOrUnknown(
          data['seal_timestamp']!,
          _sealTimestampMeta,
        ),
      );
    }
    if (data.containsKey('mute_cause')) {
      context.handle(
        _muteCauseMeta,
        muteCause.isAcceptableOrUnknown(data['mute_cause']!, _muteCauseMeta),
      );
    }
    if (data.containsKey('previous_result')) {
      context.handle(
        _previousResultMeta,
        previousResult.isAcceptableOrUnknown(
          data['previous_result']!,
          _previousResultMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationalDate};
  @override
  Day map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Day(
      operationalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operational_date'],
      )!,
      baseResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_result'],
      )!,
      effectiveResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_result'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at'],
      ),
      sealTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seal_timestamp'],
      ),
      muteCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mute_cause'],
      ),
      previousResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_result'],
      ),
    );
  }

  @override
  $DaysTable createAlias(String alias) {
    return $DaysTable(attachedDatabase, alias);
  }
}

class Day extends DataClass implements Insertable<Day> {
  final String operationalDate;
  final String baseResult;
  final String effectiveResult;
  final int? closedAt;
  final int? sealTimestamp;
  final String? muteCause;
  final String? previousResult;
  const Day({
    required this.operationalDate,
    required this.baseResult,
    required this.effectiveResult,
    this.closedAt,
    this.sealTimestamp,
    this.muteCause,
    this.previousResult,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operational_date'] = Variable<String>(operationalDate);
    map['base_result'] = Variable<String>(baseResult);
    map['effective_result'] = Variable<String>(effectiveResult);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    if (!nullToAbsent || sealTimestamp != null) {
      map['seal_timestamp'] = Variable<int>(sealTimestamp);
    }
    if (!nullToAbsent || muteCause != null) {
      map['mute_cause'] = Variable<String>(muteCause);
    }
    if (!nullToAbsent || previousResult != null) {
      map['previous_result'] = Variable<String>(previousResult);
    }
    return map;
  }

  DaysCompanion toCompanion(bool nullToAbsent) {
    return DaysCompanion(
      operationalDate: Value(operationalDate),
      baseResult: Value(baseResult),
      effectiveResult: Value(effectiveResult),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      sealTimestamp: sealTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(sealTimestamp),
      muteCause: muteCause == null && nullToAbsent
          ? const Value.absent()
          : Value(muteCause),
      previousResult: previousResult == null && nullToAbsent
          ? const Value.absent()
          : Value(previousResult),
    );
  }

  factory Day.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Day(
      operationalDate: serializer.fromJson<String>(json['operationalDate']),
      baseResult: serializer.fromJson<String>(json['baseResult']),
      effectiveResult: serializer.fromJson<String>(json['effectiveResult']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
      sealTimestamp: serializer.fromJson<int?>(json['sealTimestamp']),
      muteCause: serializer.fromJson<String?>(json['muteCause']),
      previousResult: serializer.fromJson<String?>(json['previousResult']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationalDate': serializer.toJson<String>(operationalDate),
      'baseResult': serializer.toJson<String>(baseResult),
      'effectiveResult': serializer.toJson<String>(effectiveResult),
      'closedAt': serializer.toJson<int?>(closedAt),
      'sealTimestamp': serializer.toJson<int?>(sealTimestamp),
      'muteCause': serializer.toJson<String?>(muteCause),
      'previousResult': serializer.toJson<String?>(previousResult),
    };
  }

  Day copyWith({
    String? operationalDate,
    String? baseResult,
    String? effectiveResult,
    Value<int?> closedAt = const Value.absent(),
    Value<int?> sealTimestamp = const Value.absent(),
    Value<String?> muteCause = const Value.absent(),
    Value<String?> previousResult = const Value.absent(),
  }) => Day(
    operationalDate: operationalDate ?? this.operationalDate,
    baseResult: baseResult ?? this.baseResult,
    effectiveResult: effectiveResult ?? this.effectiveResult,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    sealTimestamp: sealTimestamp.present
        ? sealTimestamp.value
        : this.sealTimestamp,
    muteCause: muteCause.present ? muteCause.value : this.muteCause,
    previousResult: previousResult.present
        ? previousResult.value
        : this.previousResult,
  );
  Day copyWithCompanion(DaysCompanion data) {
    return Day(
      operationalDate: data.operationalDate.present
          ? data.operationalDate.value
          : this.operationalDate,
      baseResult: data.baseResult.present
          ? data.baseResult.value
          : this.baseResult,
      effectiveResult: data.effectiveResult.present
          ? data.effectiveResult.value
          : this.effectiveResult,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      sealTimestamp: data.sealTimestamp.present
          ? data.sealTimestamp.value
          : this.sealTimestamp,
      muteCause: data.muteCause.present ? data.muteCause.value : this.muteCause,
      previousResult: data.previousResult.present
          ? data.previousResult.value
          : this.previousResult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Day(')
          ..write('operationalDate: $operationalDate, ')
          ..write('baseResult: $baseResult, ')
          ..write('effectiveResult: $effectiveResult, ')
          ..write('closedAt: $closedAt, ')
          ..write('sealTimestamp: $sealTimestamp, ')
          ..write('muteCause: $muteCause, ')
          ..write('previousResult: $previousResult')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationalDate,
    baseResult,
    effectiveResult,
    closedAt,
    sealTimestamp,
    muteCause,
    previousResult,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Day &&
          other.operationalDate == this.operationalDate &&
          other.baseResult == this.baseResult &&
          other.effectiveResult == this.effectiveResult &&
          other.closedAt == this.closedAt &&
          other.sealTimestamp == this.sealTimestamp &&
          other.muteCause == this.muteCause &&
          other.previousResult == this.previousResult);
}

class DaysCompanion extends UpdateCompanion<Day> {
  final Value<String> operationalDate;
  final Value<String> baseResult;
  final Value<String> effectiveResult;
  final Value<int?> closedAt;
  final Value<int?> sealTimestamp;
  final Value<String?> muteCause;
  final Value<String?> previousResult;
  final Value<int> rowid;
  const DaysCompanion({
    this.operationalDate = const Value.absent(),
    this.baseResult = const Value.absent(),
    this.effectiveResult = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.sealTimestamp = const Value.absent(),
    this.muteCause = const Value.absent(),
    this.previousResult = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaysCompanion.insert({
    required String operationalDate,
    required String baseResult,
    required String effectiveResult,
    this.closedAt = const Value.absent(),
    this.sealTimestamp = const Value.absent(),
    this.muteCause = const Value.absent(),
    this.previousResult = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationalDate = Value(operationalDate),
       baseResult = Value(baseResult),
       effectiveResult = Value(effectiveResult);
  static Insertable<Day> custom({
    Expression<String>? operationalDate,
    Expression<String>? baseResult,
    Expression<String>? effectiveResult,
    Expression<int>? closedAt,
    Expression<int>? sealTimestamp,
    Expression<String>? muteCause,
    Expression<String>? previousResult,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationalDate != null) 'operational_date': operationalDate,
      if (baseResult != null) 'base_result': baseResult,
      if (effectiveResult != null) 'effective_result': effectiveResult,
      if (closedAt != null) 'closed_at': closedAt,
      if (sealTimestamp != null) 'seal_timestamp': sealTimestamp,
      if (muteCause != null) 'mute_cause': muteCause,
      if (previousResult != null) 'previous_result': previousResult,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaysCompanion copyWith({
    Value<String>? operationalDate,
    Value<String>? baseResult,
    Value<String>? effectiveResult,
    Value<int?>? closedAt,
    Value<int?>? sealTimestamp,
    Value<String?>? muteCause,
    Value<String?>? previousResult,
    Value<int>? rowid,
  }) {
    return DaysCompanion(
      operationalDate: operationalDate ?? this.operationalDate,
      baseResult: baseResult ?? this.baseResult,
      effectiveResult: effectiveResult ?? this.effectiveResult,
      closedAt: closedAt ?? this.closedAt,
      sealTimestamp: sealTimestamp ?? this.sealTimestamp,
      muteCause: muteCause ?? this.muteCause,
      previousResult: previousResult ?? this.previousResult,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationalDate.present) {
      map['operational_date'] = Variable<String>(operationalDate.value);
    }
    if (baseResult.present) {
      map['base_result'] = Variable<String>(baseResult.value);
    }
    if (effectiveResult.present) {
      map['effective_result'] = Variable<String>(effectiveResult.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (sealTimestamp.present) {
      map['seal_timestamp'] = Variable<int>(sealTimestamp.value);
    }
    if (muteCause.present) {
      map['mute_cause'] = Variable<String>(muteCause.value);
    }
    if (previousResult.present) {
      map['previous_result'] = Variable<String>(previousResult.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaysCompanion(')
          ..write('operationalDate: $operationalDate, ')
          ..write('baseResult: $baseResult, ')
          ..write('effectiveResult: $effectiveResult, ')
          ..write('closedAt: $closedAt, ')
          ..write('sealTimestamp: $sealTimestamp, ')
          ..write('muteCause: $muteCause, ')
          ..write('previousResult: $previousResult, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyBlocksTable extends StudyBlocks
    with TableInfo<$StudyBlocksTable, StudyBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationalDateMeta = const VerificationMeta(
    'operationalDate',
  );
  @override
  late final GeneratedColumn<String> operationalDate = GeneratedColumn<String>(
    'operational_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockDeadlineMeta = const VerificationMeta(
    'blockDeadline',
  );
  @override
  late final GeneratedColumn<int> blockDeadline = GeneratedColumn<int>(
    'block_deadline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationalDate,
    startedAt,
    blockDeadline,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operational_date')) {
      context.handle(
        _operationalDateMeta,
        operationalDate.isAcceptableOrUnknown(
          data['operational_date']!,
          _operationalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationalDateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('block_deadline')) {
      context.handle(
        _blockDeadlineMeta,
        blockDeadline.isAcceptableOrUnknown(
          data['block_deadline']!,
          _blockDeadlineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_blockDeadlineMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyBlock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operational_date'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      blockDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_deadline'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $StudyBlocksTable createAlias(String alias) {
    return $StudyBlocksTable(attachedDatabase, alias);
  }
}

class StudyBlock extends DataClass implements Insertable<StudyBlock> {
  final String id;
  final String operationalDate;
  final int startedAt;
  final int blockDeadline;
  final int? endedAt;
  const StudyBlock({
    required this.id,
    required this.operationalDate,
    required this.startedAt,
    required this.blockDeadline,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operational_date'] = Variable<String>(operationalDate);
    map['started_at'] = Variable<int>(startedAt);
    map['block_deadline'] = Variable<int>(blockDeadline);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    return map;
  }

  StudyBlocksCompanion toCompanion(bool nullToAbsent) {
    return StudyBlocksCompanion(
      id: Value(id),
      operationalDate: Value(operationalDate),
      startedAt: Value(startedAt),
      blockDeadline: Value(blockDeadline),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory StudyBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyBlock(
      id: serializer.fromJson<String>(json['id']),
      operationalDate: serializer.fromJson<String>(json['operationalDate']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      blockDeadline: serializer.fromJson<int>(json['blockDeadline']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationalDate': serializer.toJson<String>(operationalDate),
      'startedAt': serializer.toJson<int>(startedAt),
      'blockDeadline': serializer.toJson<int>(blockDeadline),
      'endedAt': serializer.toJson<int?>(endedAt),
    };
  }

  StudyBlock copyWith({
    String? id,
    String? operationalDate,
    int? startedAt,
    int? blockDeadline,
    Value<int?> endedAt = const Value.absent(),
  }) => StudyBlock(
    id: id ?? this.id,
    operationalDate: operationalDate ?? this.operationalDate,
    startedAt: startedAt ?? this.startedAt,
    blockDeadline: blockDeadline ?? this.blockDeadline,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  StudyBlock copyWithCompanion(StudyBlocksCompanion data) {
    return StudyBlock(
      id: data.id.present ? data.id.value : this.id,
      operationalDate: data.operationalDate.present
          ? data.operationalDate.value
          : this.operationalDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      blockDeadline: data.blockDeadline.present
          ? data.blockDeadline.value
          : this.blockDeadline,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyBlock(')
          ..write('id: $id, ')
          ..write('operationalDate: $operationalDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('blockDeadline: $blockDeadline, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, operationalDate, startedAt, blockDeadline, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyBlock &&
          other.id == this.id &&
          other.operationalDate == this.operationalDate &&
          other.startedAt == this.startedAt &&
          other.blockDeadline == this.blockDeadline &&
          other.endedAt == this.endedAt);
}

class StudyBlocksCompanion extends UpdateCompanion<StudyBlock> {
  final Value<String> id;
  final Value<String> operationalDate;
  final Value<int> startedAt;
  final Value<int> blockDeadline;
  final Value<int?> endedAt;
  final Value<int> rowid;
  const StudyBlocksCompanion({
    this.id = const Value.absent(),
    this.operationalDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.blockDeadline = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyBlocksCompanion.insert({
    required String id,
    required String operationalDate,
    required int startedAt,
    required int blockDeadline,
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationalDate = Value(operationalDate),
       startedAt = Value(startedAt),
       blockDeadline = Value(blockDeadline);
  static Insertable<StudyBlock> custom({
    Expression<String>? id,
    Expression<String>? operationalDate,
    Expression<int>? startedAt,
    Expression<int>? blockDeadline,
    Expression<int>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationalDate != null) 'operational_date': operationalDate,
      if (startedAt != null) 'started_at': startedAt,
      if (blockDeadline != null) 'block_deadline': blockDeadline,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? operationalDate,
    Value<int>? startedAt,
    Value<int>? blockDeadline,
    Value<int?>? endedAt,
    Value<int>? rowid,
  }) {
    return StudyBlocksCompanion(
      id: id ?? this.id,
      operationalDate: operationalDate ?? this.operationalDate,
      startedAt: startedAt ?? this.startedAt,
      blockDeadline: blockDeadline ?? this.blockDeadline,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationalDate.present) {
      map['operational_date'] = Variable<String>(operationalDate.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (blockDeadline.present) {
      map['block_deadline'] = Variable<int>(blockDeadline.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyBlocksCompanion(')
          ..write('id: $id, ')
          ..write('operationalDate: $operationalDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('blockDeadline: $blockDeadline, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioAssetsTable extends AudioAssets
    with TableInfo<$AudioAssetsTable, AudioAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    relativePath,
    kind,
    durationMs,
    byteSize,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AudioAssetsTable createAlias(String alias) {
    return $AudioAssetsTable(attachedDatabase, alias);
  }
}

class AudioAsset extends DataClass implements Insertable<AudioAsset> {
  final String id;
  final String relativePath;
  final String kind;
  final int durationMs;
  final int byteSize;
  final int createdAt;
  const AudioAsset({
    required this.id,
    required this.relativePath,
    required this.kind,
    required this.durationMs,
    required this.byteSize,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['relative_path'] = Variable<String>(relativePath);
    map['kind'] = Variable<String>(kind);
    map['duration_ms'] = Variable<int>(durationMs);
    map['byte_size'] = Variable<int>(byteSize);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AudioAssetsCompanion toCompanion(bool nullToAbsent) {
    return AudioAssetsCompanion(
      id: Value(id),
      relativePath: Value(relativePath),
      kind: Value(kind),
      durationMs: Value(durationMs),
      byteSize: Value(byteSize),
      createdAt: Value(createdAt),
    );
  }

  factory AudioAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioAsset(
      id: serializer.fromJson<String>(json['id']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      kind: serializer.fromJson<String>(json['kind']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'relativePath': serializer.toJson<String>(relativePath),
      'kind': serializer.toJson<String>(kind),
      'durationMs': serializer.toJson<int>(durationMs),
      'byteSize': serializer.toJson<int>(byteSize),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AudioAsset copyWith({
    String? id,
    String? relativePath,
    String? kind,
    int? durationMs,
    int? byteSize,
    int? createdAt,
  }) => AudioAsset(
    id: id ?? this.id,
    relativePath: relativePath ?? this.relativePath,
    kind: kind ?? this.kind,
    durationMs: durationMs ?? this.durationMs,
    byteSize: byteSize ?? this.byteSize,
    createdAt: createdAt ?? this.createdAt,
  );
  AudioAsset copyWithCompanion(AudioAssetsCompanion data) {
    return AudioAsset(
      id: data.id.present ? data.id.value : this.id,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      kind: data.kind.present ? data.kind.value : this.kind,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioAsset(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('durationMs: $durationMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, relativePath, kind, durationMs, byteSize, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioAsset &&
          other.id == this.id &&
          other.relativePath == this.relativePath &&
          other.kind == this.kind &&
          other.durationMs == this.durationMs &&
          other.byteSize == this.byteSize &&
          other.createdAt == this.createdAt);
}

class AudioAssetsCompanion extends UpdateCompanion<AudioAsset> {
  final Value<String> id;
  final Value<String> relativePath;
  final Value<String> kind;
  final Value<int> durationMs;
  final Value<int> byteSize;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AudioAssetsCompanion({
    this.id = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.kind = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioAssetsCompanion.insert({
    required String id,
    required String relativePath,
    required String kind,
    required int durationMs,
    required int byteSize,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       relativePath = Value(relativePath),
       kind = Value(kind),
       durationMs = Value(durationMs),
       byteSize = Value(byteSize),
       createdAt = Value(createdAt);
  static Insertable<AudioAsset> custom({
    Expression<String>? id,
    Expression<String>? relativePath,
    Expression<String>? kind,
    Expression<int>? durationMs,
    Expression<int>? byteSize,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relativePath != null) 'relative_path': relativePath,
      if (kind != null) 'kind': kind,
      if (durationMs != null) 'duration_ms': durationMs,
      if (byteSize != null) 'byte_size': byteSize,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? relativePath,
    Value<String>? kind,
    Value<int>? durationMs,
    Value<int>? byteSize,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AudioAssetsCompanion(
      id: id ?? this.id,
      relativePath: relativePath ?? this.relativePath,
      kind: kind ?? this.kind,
      durationMs: durationMs ?? this.durationMs,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioAssetsCompanion(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('kind: $kind, ')
          ..write('durationMs: $durationMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeInitiativesTable extends ChangeInitiatives
    with TableInfo<$ChangeInitiativesTable, ChangeInitiative> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeInitiativesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_initiatives';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeInitiative> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChangeInitiative map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeInitiative(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $ChangeInitiativesTable createAlias(String alias) {
    return $ChangeInitiativesTable(attachedDatabase, alias);
  }
}

class ChangeInitiative extends DataClass
    implements Insertable<ChangeInitiative> {
  final String id;
  final String name;
  final bool active;
  const ChangeInitiative({
    required this.id,
    required this.name,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['active'] = Variable<bool>(active);
    return map;
  }

  ChangeInitiativesCompanion toCompanion(bool nullToAbsent) {
    return ChangeInitiativesCompanion(
      id: Value(id),
      name: Value(name),
      active: Value(active),
    );
  }

  factory ChangeInitiative.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeInitiative(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'active': serializer.toJson<bool>(active),
    };
  }

  ChangeInitiative copyWith({String? id, String? name, bool? active}) =>
      ChangeInitiative(
        id: id ?? this.id,
        name: name ?? this.name,
        active: active ?? this.active,
      );
  ChangeInitiative copyWithCompanion(ChangeInitiativesCompanion data) {
    return ChangeInitiative(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeInitiative(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeInitiative &&
          other.id == this.id &&
          other.name == this.name &&
          other.active == this.active);
}

class ChangeInitiativesCompanion extends UpdateCompanion<ChangeInitiative> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> active;
  final Value<int> rowid;
  const ChangeInitiativesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChangeInitiativesCompanion.insert({
    required String id,
    required String name,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ChangeInitiative> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChangeInitiativesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return ChangeInitiativesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeInitiativesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PillarEntriesTable extends PillarEntries
    with TableInfo<$PillarEntriesTable, PillarEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PillarEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationalDateMeta = const VerificationMeta(
    'operationalDate',
  );
  @override
  late final GeneratedColumn<String> operationalDate = GeneratedColumn<String>(
    'operational_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _pillarMeta = const VerificationMeta('pillar');
  @override
  late final GeneratedColumn<String> pillar = GeneratedColumn<String>(
    'pillar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutDoneMeta = const VerificationMeta(
    'workoutDone',
  );
  @override
  late final GeneratedColumn<bool> workoutDone = GeneratedColumn<bool>(
    'workout_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("workout_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _briefingDoneMeta = const VerificationMeta(
    'briefingDone',
  );
  @override
  late final GeneratedColumn<bool> briefingDone = GeneratedColumn<bool>(
    'briefing_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("briefing_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _briefingModeMeta = const VerificationMeta(
    'briefingMode',
  );
  @override
  late final GeneratedColumn<String> briefingMode = GeneratedColumn<String>(
    'briefing_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutAtMeta = const VerificationMeta(
    'workoutAt',
  );
  @override
  late final GeneratedColumn<int> workoutAt = GeneratedColumn<int>(
    'workout_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _briefingAtMeta = const VerificationMeta(
    'briefingAt',
  );
  @override
  late final GeneratedColumn<int> briefingAt = GeneratedColumn<int>(
    'briefing_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toggleOnMeta = const VerificationMeta(
    'toggleOn',
  );
  @override
  late final GeneratedColumn<bool> toggleOn = GeneratedColumn<bool>(
    'toggle_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("toggle_on" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _changeInitiativeIdMeta =
      const VerificationMeta('changeInitiativeId');
  @override
  late final GeneratedColumn<String> changeInitiativeId =
      GeneratedColumn<String>(
        'change_initiative_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES change_initiatives (id)',
        ),
      );
  static const VerificationMeta _noteTextMeta = const VerificationMeta(
    'noteText',
  );
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
    'note_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteAudioIdMeta = const VerificationMeta(
    'noteAudioId',
  );
  @override
  late final GeneratedColumn<String> noteAudioId = GeneratedColumn<String>(
    'note_audio_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES audio_assets (id)',
    ),
  );
  static const VerificationMeta _nightKindMeta = const VerificationMeta(
    'nightKind',
  );
  @override
  late final GeneratedColumn<String> nightKind = GeneratedColumn<String>(
    'night_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryNoteMeta = const VerificationMeta(
    'recoveryNote',
  );
  @override
  late final GeneratedColumn<String> recoveryNote = GeneratedColumn<String>(
    'recovery_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studyBlockIdMeta = const VerificationMeta(
    'studyBlockId',
  );
  @override
  late final GeneratedColumn<String> studyBlockId = GeneratedColumn<String>(
    'study_block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES study_blocks (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationalDate,
    pillar,
    workoutDone,
    briefingDone,
    briefingMode,
    workoutAt,
    briefingAt,
    toggleOn,
    changeInitiativeId,
    noteText,
    noteAudioId,
    nightKind,
    recoveryNote,
    studyBlockId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pillar_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PillarEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operational_date')) {
      context.handle(
        _operationalDateMeta,
        operationalDate.isAcceptableOrUnknown(
          data['operational_date']!,
          _operationalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationalDateMeta);
    }
    if (data.containsKey('pillar')) {
      context.handle(
        _pillarMeta,
        pillar.isAcceptableOrUnknown(data['pillar']!, _pillarMeta),
      );
    } else if (isInserting) {
      context.missing(_pillarMeta);
    }
    if (data.containsKey('workout_done')) {
      context.handle(
        _workoutDoneMeta,
        workoutDone.isAcceptableOrUnknown(
          data['workout_done']!,
          _workoutDoneMeta,
        ),
      );
    }
    if (data.containsKey('briefing_done')) {
      context.handle(
        _briefingDoneMeta,
        briefingDone.isAcceptableOrUnknown(
          data['briefing_done']!,
          _briefingDoneMeta,
        ),
      );
    }
    if (data.containsKey('briefing_mode')) {
      context.handle(
        _briefingModeMeta,
        briefingMode.isAcceptableOrUnknown(
          data['briefing_mode']!,
          _briefingModeMeta,
        ),
      );
    }
    if (data.containsKey('workout_at')) {
      context.handle(
        _workoutAtMeta,
        workoutAt.isAcceptableOrUnknown(data['workout_at']!, _workoutAtMeta),
      );
    }
    if (data.containsKey('briefing_at')) {
      context.handle(
        _briefingAtMeta,
        briefingAt.isAcceptableOrUnknown(data['briefing_at']!, _briefingAtMeta),
      );
    }
    if (data.containsKey('toggle_on')) {
      context.handle(
        _toggleOnMeta,
        toggleOn.isAcceptableOrUnknown(data['toggle_on']!, _toggleOnMeta),
      );
    }
    if (data.containsKey('change_initiative_id')) {
      context.handle(
        _changeInitiativeIdMeta,
        changeInitiativeId.isAcceptableOrUnknown(
          data['change_initiative_id']!,
          _changeInitiativeIdMeta,
        ),
      );
    }
    if (data.containsKey('note_text')) {
      context.handle(
        _noteTextMeta,
        noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta),
      );
    }
    if (data.containsKey('note_audio_id')) {
      context.handle(
        _noteAudioIdMeta,
        noteAudioId.isAcceptableOrUnknown(
          data['note_audio_id']!,
          _noteAudioIdMeta,
        ),
      );
    }
    if (data.containsKey('night_kind')) {
      context.handle(
        _nightKindMeta,
        nightKind.isAcceptableOrUnknown(data['night_kind']!, _nightKindMeta),
      );
    }
    if (data.containsKey('recovery_note')) {
      context.handle(
        _recoveryNoteMeta,
        recoveryNote.isAcceptableOrUnknown(
          data['recovery_note']!,
          _recoveryNoteMeta,
        ),
      );
    }
    if (data.containsKey('study_block_id')) {
      context.handle(
        _studyBlockIdMeta,
        studyBlockId.isAcceptableOrUnknown(
          data['study_block_id']!,
          _studyBlockIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {operationalDate, pillar},
  ];
  @override
  PillarEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PillarEntry(
      operationalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operational_date'],
      )!,
      pillar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pillar'],
      )!,
      workoutDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}workout_done'],
      )!,
      briefingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}briefing_done'],
      )!,
      briefingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}briefing_mode'],
      ),
      workoutAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_at'],
      ),
      briefingAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}briefing_at'],
      ),
      toggleOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}toggle_on'],
      )!,
      changeInitiativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_initiative_id'],
      ),
      noteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_text'],
      ),
      noteAudioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_audio_id'],
      ),
      nightKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}night_kind'],
      ),
      recoveryNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_note'],
      ),
      studyBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_block_id'],
      ),
    );
  }

  @override
  $PillarEntriesTable createAlias(String alias) {
    return $PillarEntriesTable(attachedDatabase, alias);
  }
}

class PillarEntry extends DataClass implements Insertable<PillarEntry> {
  final String operationalDate;
  final String pillar;
  final bool workoutDone;
  final bool briefingDone;
  final String? briefingMode;
  final int? workoutAt;
  final int? briefingAt;
  final bool toggleOn;
  final String? changeInitiativeId;
  final String? noteText;
  final String? noteAudioId;
  final String? nightKind;
  final String? recoveryNote;
  final String? studyBlockId;
  const PillarEntry({
    required this.operationalDate,
    required this.pillar,
    required this.workoutDone,
    required this.briefingDone,
    this.briefingMode,
    this.workoutAt,
    this.briefingAt,
    required this.toggleOn,
    this.changeInitiativeId,
    this.noteText,
    this.noteAudioId,
    this.nightKind,
    this.recoveryNote,
    this.studyBlockId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operational_date'] = Variable<String>(operationalDate);
    map['pillar'] = Variable<String>(pillar);
    map['workout_done'] = Variable<bool>(workoutDone);
    map['briefing_done'] = Variable<bool>(briefingDone);
    if (!nullToAbsent || briefingMode != null) {
      map['briefing_mode'] = Variable<String>(briefingMode);
    }
    if (!nullToAbsent || workoutAt != null) {
      map['workout_at'] = Variable<int>(workoutAt);
    }
    if (!nullToAbsent || briefingAt != null) {
      map['briefing_at'] = Variable<int>(briefingAt);
    }
    map['toggle_on'] = Variable<bool>(toggleOn);
    if (!nullToAbsent || changeInitiativeId != null) {
      map['change_initiative_id'] = Variable<String>(changeInitiativeId);
    }
    if (!nullToAbsent || noteText != null) {
      map['note_text'] = Variable<String>(noteText);
    }
    if (!nullToAbsent || noteAudioId != null) {
      map['note_audio_id'] = Variable<String>(noteAudioId);
    }
    if (!nullToAbsent || nightKind != null) {
      map['night_kind'] = Variable<String>(nightKind);
    }
    if (!nullToAbsent || recoveryNote != null) {
      map['recovery_note'] = Variable<String>(recoveryNote);
    }
    if (!nullToAbsent || studyBlockId != null) {
      map['study_block_id'] = Variable<String>(studyBlockId);
    }
    return map;
  }

  PillarEntriesCompanion toCompanion(bool nullToAbsent) {
    return PillarEntriesCompanion(
      operationalDate: Value(operationalDate),
      pillar: Value(pillar),
      workoutDone: Value(workoutDone),
      briefingDone: Value(briefingDone),
      briefingMode: briefingMode == null && nullToAbsent
          ? const Value.absent()
          : Value(briefingMode),
      workoutAt: workoutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutAt),
      briefingAt: briefingAt == null && nullToAbsent
          ? const Value.absent()
          : Value(briefingAt),
      toggleOn: Value(toggleOn),
      changeInitiativeId: changeInitiativeId == null && nullToAbsent
          ? const Value.absent()
          : Value(changeInitiativeId),
      noteText: noteText == null && nullToAbsent
          ? const Value.absent()
          : Value(noteText),
      noteAudioId: noteAudioId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteAudioId),
      nightKind: nightKind == null && nullToAbsent
          ? const Value.absent()
          : Value(nightKind),
      recoveryNote: recoveryNote == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryNote),
      studyBlockId: studyBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(studyBlockId),
    );
  }

  factory PillarEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PillarEntry(
      operationalDate: serializer.fromJson<String>(json['operationalDate']),
      pillar: serializer.fromJson<String>(json['pillar']),
      workoutDone: serializer.fromJson<bool>(json['workoutDone']),
      briefingDone: serializer.fromJson<bool>(json['briefingDone']),
      briefingMode: serializer.fromJson<String?>(json['briefingMode']),
      workoutAt: serializer.fromJson<int?>(json['workoutAt']),
      briefingAt: serializer.fromJson<int?>(json['briefingAt']),
      toggleOn: serializer.fromJson<bool>(json['toggleOn']),
      changeInitiativeId: serializer.fromJson<String?>(
        json['changeInitiativeId'],
      ),
      noteText: serializer.fromJson<String?>(json['noteText']),
      noteAudioId: serializer.fromJson<String?>(json['noteAudioId']),
      nightKind: serializer.fromJson<String?>(json['nightKind']),
      recoveryNote: serializer.fromJson<String?>(json['recoveryNote']),
      studyBlockId: serializer.fromJson<String?>(json['studyBlockId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationalDate': serializer.toJson<String>(operationalDate),
      'pillar': serializer.toJson<String>(pillar),
      'workoutDone': serializer.toJson<bool>(workoutDone),
      'briefingDone': serializer.toJson<bool>(briefingDone),
      'briefingMode': serializer.toJson<String?>(briefingMode),
      'workoutAt': serializer.toJson<int?>(workoutAt),
      'briefingAt': serializer.toJson<int?>(briefingAt),
      'toggleOn': serializer.toJson<bool>(toggleOn),
      'changeInitiativeId': serializer.toJson<String?>(changeInitiativeId),
      'noteText': serializer.toJson<String?>(noteText),
      'noteAudioId': serializer.toJson<String?>(noteAudioId),
      'nightKind': serializer.toJson<String?>(nightKind),
      'recoveryNote': serializer.toJson<String?>(recoveryNote),
      'studyBlockId': serializer.toJson<String?>(studyBlockId),
    };
  }

  PillarEntry copyWith({
    String? operationalDate,
    String? pillar,
    bool? workoutDone,
    bool? briefingDone,
    Value<String?> briefingMode = const Value.absent(),
    Value<int?> workoutAt = const Value.absent(),
    Value<int?> briefingAt = const Value.absent(),
    bool? toggleOn,
    Value<String?> changeInitiativeId = const Value.absent(),
    Value<String?> noteText = const Value.absent(),
    Value<String?> noteAudioId = const Value.absent(),
    Value<String?> nightKind = const Value.absent(),
    Value<String?> recoveryNote = const Value.absent(),
    Value<String?> studyBlockId = const Value.absent(),
  }) => PillarEntry(
    operationalDate: operationalDate ?? this.operationalDate,
    pillar: pillar ?? this.pillar,
    workoutDone: workoutDone ?? this.workoutDone,
    briefingDone: briefingDone ?? this.briefingDone,
    briefingMode: briefingMode.present ? briefingMode.value : this.briefingMode,
    workoutAt: workoutAt.present ? workoutAt.value : this.workoutAt,
    briefingAt: briefingAt.present ? briefingAt.value : this.briefingAt,
    toggleOn: toggleOn ?? this.toggleOn,
    changeInitiativeId: changeInitiativeId.present
        ? changeInitiativeId.value
        : this.changeInitiativeId,
    noteText: noteText.present ? noteText.value : this.noteText,
    noteAudioId: noteAudioId.present ? noteAudioId.value : this.noteAudioId,
    nightKind: nightKind.present ? nightKind.value : this.nightKind,
    recoveryNote: recoveryNote.present ? recoveryNote.value : this.recoveryNote,
    studyBlockId: studyBlockId.present ? studyBlockId.value : this.studyBlockId,
  );
  PillarEntry copyWithCompanion(PillarEntriesCompanion data) {
    return PillarEntry(
      operationalDate: data.operationalDate.present
          ? data.operationalDate.value
          : this.operationalDate,
      pillar: data.pillar.present ? data.pillar.value : this.pillar,
      workoutDone: data.workoutDone.present
          ? data.workoutDone.value
          : this.workoutDone,
      briefingDone: data.briefingDone.present
          ? data.briefingDone.value
          : this.briefingDone,
      briefingMode: data.briefingMode.present
          ? data.briefingMode.value
          : this.briefingMode,
      workoutAt: data.workoutAt.present ? data.workoutAt.value : this.workoutAt,
      briefingAt: data.briefingAt.present
          ? data.briefingAt.value
          : this.briefingAt,
      toggleOn: data.toggleOn.present ? data.toggleOn.value : this.toggleOn,
      changeInitiativeId: data.changeInitiativeId.present
          ? data.changeInitiativeId.value
          : this.changeInitiativeId,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
      noteAudioId: data.noteAudioId.present
          ? data.noteAudioId.value
          : this.noteAudioId,
      nightKind: data.nightKind.present ? data.nightKind.value : this.nightKind,
      recoveryNote: data.recoveryNote.present
          ? data.recoveryNote.value
          : this.recoveryNote,
      studyBlockId: data.studyBlockId.present
          ? data.studyBlockId.value
          : this.studyBlockId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PillarEntry(')
          ..write('operationalDate: $operationalDate, ')
          ..write('pillar: $pillar, ')
          ..write('workoutDone: $workoutDone, ')
          ..write('briefingDone: $briefingDone, ')
          ..write('briefingMode: $briefingMode, ')
          ..write('workoutAt: $workoutAt, ')
          ..write('briefingAt: $briefingAt, ')
          ..write('toggleOn: $toggleOn, ')
          ..write('changeInitiativeId: $changeInitiativeId, ')
          ..write('noteText: $noteText, ')
          ..write('noteAudioId: $noteAudioId, ')
          ..write('nightKind: $nightKind, ')
          ..write('recoveryNote: $recoveryNote, ')
          ..write('studyBlockId: $studyBlockId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationalDate,
    pillar,
    workoutDone,
    briefingDone,
    briefingMode,
    workoutAt,
    briefingAt,
    toggleOn,
    changeInitiativeId,
    noteText,
    noteAudioId,
    nightKind,
    recoveryNote,
    studyBlockId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PillarEntry &&
          other.operationalDate == this.operationalDate &&
          other.pillar == this.pillar &&
          other.workoutDone == this.workoutDone &&
          other.briefingDone == this.briefingDone &&
          other.briefingMode == this.briefingMode &&
          other.workoutAt == this.workoutAt &&
          other.briefingAt == this.briefingAt &&
          other.toggleOn == this.toggleOn &&
          other.changeInitiativeId == this.changeInitiativeId &&
          other.noteText == this.noteText &&
          other.noteAudioId == this.noteAudioId &&
          other.nightKind == this.nightKind &&
          other.recoveryNote == this.recoveryNote &&
          other.studyBlockId == this.studyBlockId);
}

class PillarEntriesCompanion extends UpdateCompanion<PillarEntry> {
  final Value<String> operationalDate;
  final Value<String> pillar;
  final Value<bool> workoutDone;
  final Value<bool> briefingDone;
  final Value<String?> briefingMode;
  final Value<int?> workoutAt;
  final Value<int?> briefingAt;
  final Value<bool> toggleOn;
  final Value<String?> changeInitiativeId;
  final Value<String?> noteText;
  final Value<String?> noteAudioId;
  final Value<String?> nightKind;
  final Value<String?> recoveryNote;
  final Value<String?> studyBlockId;
  final Value<int> rowid;
  const PillarEntriesCompanion({
    this.operationalDate = const Value.absent(),
    this.pillar = const Value.absent(),
    this.workoutDone = const Value.absent(),
    this.briefingDone = const Value.absent(),
    this.briefingMode = const Value.absent(),
    this.workoutAt = const Value.absent(),
    this.briefingAt = const Value.absent(),
    this.toggleOn = const Value.absent(),
    this.changeInitiativeId = const Value.absent(),
    this.noteText = const Value.absent(),
    this.noteAudioId = const Value.absent(),
    this.nightKind = const Value.absent(),
    this.recoveryNote = const Value.absent(),
    this.studyBlockId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PillarEntriesCompanion.insert({
    required String operationalDate,
    required String pillar,
    this.workoutDone = const Value.absent(),
    this.briefingDone = const Value.absent(),
    this.briefingMode = const Value.absent(),
    this.workoutAt = const Value.absent(),
    this.briefingAt = const Value.absent(),
    this.toggleOn = const Value.absent(),
    this.changeInitiativeId = const Value.absent(),
    this.noteText = const Value.absent(),
    this.noteAudioId = const Value.absent(),
    this.nightKind = const Value.absent(),
    this.recoveryNote = const Value.absent(),
    this.studyBlockId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationalDate = Value(operationalDate),
       pillar = Value(pillar);
  static Insertable<PillarEntry> custom({
    Expression<String>? operationalDate,
    Expression<String>? pillar,
    Expression<bool>? workoutDone,
    Expression<bool>? briefingDone,
    Expression<String>? briefingMode,
    Expression<int>? workoutAt,
    Expression<int>? briefingAt,
    Expression<bool>? toggleOn,
    Expression<String>? changeInitiativeId,
    Expression<String>? noteText,
    Expression<String>? noteAudioId,
    Expression<String>? nightKind,
    Expression<String>? recoveryNote,
    Expression<String>? studyBlockId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationalDate != null) 'operational_date': operationalDate,
      if (pillar != null) 'pillar': pillar,
      if (workoutDone != null) 'workout_done': workoutDone,
      if (briefingDone != null) 'briefing_done': briefingDone,
      if (briefingMode != null) 'briefing_mode': briefingMode,
      if (workoutAt != null) 'workout_at': workoutAt,
      if (briefingAt != null) 'briefing_at': briefingAt,
      if (toggleOn != null) 'toggle_on': toggleOn,
      if (changeInitiativeId != null)
        'change_initiative_id': changeInitiativeId,
      if (noteText != null) 'note_text': noteText,
      if (noteAudioId != null) 'note_audio_id': noteAudioId,
      if (nightKind != null) 'night_kind': nightKind,
      if (recoveryNote != null) 'recovery_note': recoveryNote,
      if (studyBlockId != null) 'study_block_id': studyBlockId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PillarEntriesCompanion copyWith({
    Value<String>? operationalDate,
    Value<String>? pillar,
    Value<bool>? workoutDone,
    Value<bool>? briefingDone,
    Value<String?>? briefingMode,
    Value<int?>? workoutAt,
    Value<int?>? briefingAt,
    Value<bool>? toggleOn,
    Value<String?>? changeInitiativeId,
    Value<String?>? noteText,
    Value<String?>? noteAudioId,
    Value<String?>? nightKind,
    Value<String?>? recoveryNote,
    Value<String?>? studyBlockId,
    Value<int>? rowid,
  }) {
    return PillarEntriesCompanion(
      operationalDate: operationalDate ?? this.operationalDate,
      pillar: pillar ?? this.pillar,
      workoutDone: workoutDone ?? this.workoutDone,
      briefingDone: briefingDone ?? this.briefingDone,
      briefingMode: briefingMode ?? this.briefingMode,
      workoutAt: workoutAt ?? this.workoutAt,
      briefingAt: briefingAt ?? this.briefingAt,
      toggleOn: toggleOn ?? this.toggleOn,
      changeInitiativeId: changeInitiativeId ?? this.changeInitiativeId,
      noteText: noteText ?? this.noteText,
      noteAudioId: noteAudioId ?? this.noteAudioId,
      nightKind: nightKind ?? this.nightKind,
      recoveryNote: recoveryNote ?? this.recoveryNote,
      studyBlockId: studyBlockId ?? this.studyBlockId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationalDate.present) {
      map['operational_date'] = Variable<String>(operationalDate.value);
    }
    if (pillar.present) {
      map['pillar'] = Variable<String>(pillar.value);
    }
    if (workoutDone.present) {
      map['workout_done'] = Variable<bool>(workoutDone.value);
    }
    if (briefingDone.present) {
      map['briefing_done'] = Variable<bool>(briefingDone.value);
    }
    if (briefingMode.present) {
      map['briefing_mode'] = Variable<String>(briefingMode.value);
    }
    if (workoutAt.present) {
      map['workout_at'] = Variable<int>(workoutAt.value);
    }
    if (briefingAt.present) {
      map['briefing_at'] = Variable<int>(briefingAt.value);
    }
    if (toggleOn.present) {
      map['toggle_on'] = Variable<bool>(toggleOn.value);
    }
    if (changeInitiativeId.present) {
      map['change_initiative_id'] = Variable<String>(changeInitiativeId.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
    }
    if (noteAudioId.present) {
      map['note_audio_id'] = Variable<String>(noteAudioId.value);
    }
    if (nightKind.present) {
      map['night_kind'] = Variable<String>(nightKind.value);
    }
    if (recoveryNote.present) {
      map['recovery_note'] = Variable<String>(recoveryNote.value);
    }
    if (studyBlockId.present) {
      map['study_block_id'] = Variable<String>(studyBlockId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PillarEntriesCompanion(')
          ..write('operationalDate: $operationalDate, ')
          ..write('pillar: $pillar, ')
          ..write('workoutDone: $workoutDone, ')
          ..write('briefingDone: $briefingDone, ')
          ..write('briefingMode: $briefingMode, ')
          ..write('workoutAt: $workoutAt, ')
          ..write('briefingAt: $briefingAt, ')
          ..write('toggleOn: $toggleOn, ')
          ..write('changeInitiativeId: $changeInitiativeId, ')
          ..write('noteText: $noteText, ')
          ..write('noteAudioId: $noteAudioId, ')
          ..write('nightKind: $nightKind, ')
          ..write('recoveryNote: $recoveryNote, ')
          ..write('studyBlockId: $studyBlockId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PillarWaiversTable extends PillarWaivers
    with TableInfo<$PillarWaiversTable, PillarWaiver> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PillarWaiversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _pillarMeta = const VerificationMeta('pillar');
  @override
  late final GeneratedColumn<String> pillar = GeneratedColumn<String>(
    'pillar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonTextMeta = const VerificationMeta(
    'reasonText',
  );
  @override
  late final GeneratedColumn<String> reasonText = GeneratedColumn<String>(
    'reason_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceConfirmedMeta =
      const VerificationMeta('recurrenceConfirmed');
  @override
  late final GeneratedColumn<bool> recurrenceConfirmed = GeneratedColumn<bool>(
    'recurrence_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recurrence_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<int> revokedAt = GeneratedColumn<int>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    pillar,
    reasonText,
    recurrenceConfirmed,
    revokedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pillar_waivers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PillarWaiver> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('pillar')) {
      context.handle(
        _pillarMeta,
        pillar.isAcceptableOrUnknown(data['pillar']!, _pillarMeta),
      );
    } else if (isInserting) {
      context.missing(_pillarMeta);
    }
    if (data.containsKey('reason_text')) {
      context.handle(
        _reasonTextMeta,
        reasonText.isAcceptableOrUnknown(data['reason_text']!, _reasonTextMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonTextMeta);
    }
    if (data.containsKey('recurrence_confirmed')) {
      context.handle(
        _recurrenceConfirmedMeta,
        recurrenceConfirmed.isAcceptableOrUnknown(
          data['recurrence_confirmed']!,
          _recurrenceConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PillarWaiver map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PillarWaiver(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      pillar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pillar'],
      )!,
      reasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_text'],
      )!,
      recurrenceConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recurrence_confirmed'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revoked_at'],
      ),
    );
  }

  @override
  $PillarWaiversTable createAlias(String alias) {
    return $PillarWaiversTable(attachedDatabase, alias);
  }
}

class PillarWaiver extends DataClass implements Insertable<PillarWaiver> {
  final String id;
  final String date;
  final String pillar;
  final String reasonText;
  final bool recurrenceConfirmed;
  final int? revokedAt;
  const PillarWaiver({
    required this.id,
    required this.date,
    required this.pillar,
    required this.reasonText,
    required this.recurrenceConfirmed,
    this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['pillar'] = Variable<String>(pillar);
    map['reason_text'] = Variable<String>(reasonText);
    map['recurrence_confirmed'] = Variable<bool>(recurrenceConfirmed);
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<int>(revokedAt);
    }
    return map;
  }

  PillarWaiversCompanion toCompanion(bool nullToAbsent) {
    return PillarWaiversCompanion(
      id: Value(id),
      date: Value(date),
      pillar: Value(pillar),
      reasonText: Value(reasonText),
      recurrenceConfirmed: Value(recurrenceConfirmed),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
    );
  }

  factory PillarWaiver.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PillarWaiver(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      pillar: serializer.fromJson<String>(json['pillar']),
      reasonText: serializer.fromJson<String>(json['reasonText']),
      recurrenceConfirmed: serializer.fromJson<bool>(
        json['recurrenceConfirmed'],
      ),
      revokedAt: serializer.fromJson<int?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'pillar': serializer.toJson<String>(pillar),
      'reasonText': serializer.toJson<String>(reasonText),
      'recurrenceConfirmed': serializer.toJson<bool>(recurrenceConfirmed),
      'revokedAt': serializer.toJson<int?>(revokedAt),
    };
  }

  PillarWaiver copyWith({
    String? id,
    String? date,
    String? pillar,
    String? reasonText,
    bool? recurrenceConfirmed,
    Value<int?> revokedAt = const Value.absent(),
  }) => PillarWaiver(
    id: id ?? this.id,
    date: date ?? this.date,
    pillar: pillar ?? this.pillar,
    reasonText: reasonText ?? this.reasonText,
    recurrenceConfirmed: recurrenceConfirmed ?? this.recurrenceConfirmed,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
  );
  PillarWaiver copyWithCompanion(PillarWaiversCompanion data) {
    return PillarWaiver(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      pillar: data.pillar.present ? data.pillar.value : this.pillar,
      reasonText: data.reasonText.present
          ? data.reasonText.value
          : this.reasonText,
      recurrenceConfirmed: data.recurrenceConfirmed.present
          ? data.recurrenceConfirmed.value
          : this.recurrenceConfirmed,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PillarWaiver(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('pillar: $pillar, ')
          ..write('reasonText: $reasonText, ')
          ..write('recurrenceConfirmed: $recurrenceConfirmed, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, pillar, reasonText, recurrenceConfirmed, revokedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PillarWaiver &&
          other.id == this.id &&
          other.date == this.date &&
          other.pillar == this.pillar &&
          other.reasonText == this.reasonText &&
          other.recurrenceConfirmed == this.recurrenceConfirmed &&
          other.revokedAt == this.revokedAt);
}

class PillarWaiversCompanion extends UpdateCompanion<PillarWaiver> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> pillar;
  final Value<String> reasonText;
  final Value<bool> recurrenceConfirmed;
  final Value<int?> revokedAt;
  final Value<int> rowid;
  const PillarWaiversCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.pillar = const Value.absent(),
    this.reasonText = const Value.absent(),
    this.recurrenceConfirmed = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PillarWaiversCompanion.insert({
    required String id,
    required String date,
    required String pillar,
    required String reasonText,
    this.recurrenceConfirmed = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       pillar = Value(pillar),
       reasonText = Value(reasonText);
  static Insertable<PillarWaiver> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? pillar,
    Expression<String>? reasonText,
    Expression<bool>? recurrenceConfirmed,
    Expression<int>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (pillar != null) 'pillar': pillar,
      if (reasonText != null) 'reason_text': reasonText,
      if (recurrenceConfirmed != null)
        'recurrence_confirmed': recurrenceConfirmed,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PillarWaiversCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? pillar,
    Value<String>? reasonText,
    Value<bool>? recurrenceConfirmed,
    Value<int?>? revokedAt,
    Value<int>? rowid,
  }) {
    return PillarWaiversCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      pillar: pillar ?? this.pillar,
      reasonText: reasonText ?? this.reasonText,
      recurrenceConfirmed: recurrenceConfirmed ?? this.recurrenceConfirmed,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (pillar.present) {
      map['pillar'] = Variable<String>(pillar.value);
    }
    if (reasonText.present) {
      map['reason_text'] = Variable<String>(reasonText.value);
    }
    if (recurrenceConfirmed.present) {
      map['recurrence_confirmed'] = Variable<bool>(recurrenceConfirmed.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<int>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PillarWaiversCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('pillar: $pillar, ')
          ..write('reasonText: $reasonText, ')
          ..write('recurrenceConfirmed: $recurrenceConfirmed, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProtocolAlarmsTable extends ProtocolAlarms
    with TableInfo<$ProtocolAlarmsTable, ProtocolAlarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProtocolAlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generationIdMeta = const VerificationMeta(
    'generationId',
  );
  @override
  late final GeneratedColumn<String> generationId = GeneratedColumn<String>(
    'generation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _sequenceLengthMeta = const VerificationMeta(
    'sequenceLength',
  );
  @override
  late final GeneratedColumn<int> sequenceLength = GeneratedColumn<int>(
    'sequence_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousStateMeta = const VerificationMeta(
    'previousState',
  );
  @override
  late final GeneratedColumn<String> previousState = GeneratedColumn<String>(
    'previous_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggeredAtMeta = const VerificationMeta(
    'triggeredAt',
  );
  @override
  late final GeneratedColumn<int> triggeredAt = GeneratedColumn<int>(
    'triggered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _causeMeta = const VerificationMeta('cause');
  @override
  late final GeneratedColumn<String> cause = GeneratedColumn<String>(
    'cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planOrExecutionMeta = const VerificationMeta(
    'planOrExecution',
  );
  @override
  late final GeneratedColumn<String> planOrExecution = GeneratedColumn<String>(
    'plan_or_execution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjustmentMeta = const VerificationMeta(
    'adjustment',
  );
  @override
  late final GeneratedColumn<String> adjustment = GeneratedColumn<String>(
    'adjustment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    generationId,
    startDate,
    endDate,
    sequenceLength,
    state,
    previousState,
    triggeredAt,
    cause,
    planOrExecution,
    adjustment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'protocol_alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProtocolAlarm> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('generation_id')) {
      context.handle(
        _generationIdMeta,
        generationId.isAcceptableOrUnknown(
          data['generation_id']!,
          _generationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generationIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('sequence_length')) {
      context.handle(
        _sequenceLengthMeta,
        sequenceLength.isAcceptableOrUnknown(
          data['sequence_length']!,
          _sequenceLengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceLengthMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('previous_state')) {
      context.handle(
        _previousStateMeta,
        previousState.isAcceptableOrUnknown(
          data['previous_state']!,
          _previousStateMeta,
        ),
      );
    }
    if (data.containsKey('triggered_at')) {
      context.handle(
        _triggeredAtMeta,
        triggeredAt.isAcceptableOrUnknown(
          data['triggered_at']!,
          _triggeredAtMeta,
        ),
      );
    }
    if (data.containsKey('cause')) {
      context.handle(
        _causeMeta,
        cause.isAcceptableOrUnknown(data['cause']!, _causeMeta),
      );
    }
    if (data.containsKey('plan_or_execution')) {
      context.handle(
        _planOrExecutionMeta,
        planOrExecution.isAcceptableOrUnknown(
          data['plan_or_execution']!,
          _planOrExecutionMeta,
        ),
      );
    }
    if (data.containsKey('adjustment')) {
      context.handle(
        _adjustmentMeta,
        adjustment.isAcceptableOrUnknown(data['adjustment']!, _adjustmentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProtocolAlarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProtocolAlarm(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      generationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generation_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      sequenceLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_length'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      previousState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_state'],
      ),
      triggeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}triggered_at'],
      ),
      cause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cause'],
      ),
      planOrExecution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_or_execution'],
      ),
      adjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjustment'],
      ),
    );
  }

  @override
  $ProtocolAlarmsTable createAlias(String alias) {
    return $ProtocolAlarmsTable(attachedDatabase, alias);
  }
}

class ProtocolAlarm extends DataClass implements Insertable<ProtocolAlarm> {
  final String id;
  final String generationId;
  final String startDate;
  final String endDate;
  final int sequenceLength;
  final String state;
  final String? previousState;
  final int? triggeredAt;
  final String? cause;
  final String? planOrExecution;
  final String? adjustment;
  const ProtocolAlarm({
    required this.id,
    required this.generationId,
    required this.startDate,
    required this.endDate,
    required this.sequenceLength,
    required this.state,
    this.previousState,
    this.triggeredAt,
    this.cause,
    this.planOrExecution,
    this.adjustment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['generation_id'] = Variable<String>(generationId);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['sequence_length'] = Variable<int>(sequenceLength);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || previousState != null) {
      map['previous_state'] = Variable<String>(previousState);
    }
    if (!nullToAbsent || triggeredAt != null) {
      map['triggered_at'] = Variable<int>(triggeredAt);
    }
    if (!nullToAbsent || cause != null) {
      map['cause'] = Variable<String>(cause);
    }
    if (!nullToAbsent || planOrExecution != null) {
      map['plan_or_execution'] = Variable<String>(planOrExecution);
    }
    if (!nullToAbsent || adjustment != null) {
      map['adjustment'] = Variable<String>(adjustment);
    }
    return map;
  }

  ProtocolAlarmsCompanion toCompanion(bool nullToAbsent) {
    return ProtocolAlarmsCompanion(
      id: Value(id),
      generationId: Value(generationId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      sequenceLength: Value(sequenceLength),
      state: Value(state),
      previousState: previousState == null && nullToAbsent
          ? const Value.absent()
          : Value(previousState),
      triggeredAt: triggeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(triggeredAt),
      cause: cause == null && nullToAbsent
          ? const Value.absent()
          : Value(cause),
      planOrExecution: planOrExecution == null && nullToAbsent
          ? const Value.absent()
          : Value(planOrExecution),
      adjustment: adjustment == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustment),
    );
  }

  factory ProtocolAlarm.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProtocolAlarm(
      id: serializer.fromJson<String>(json['id']),
      generationId: serializer.fromJson<String>(json['generationId']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      sequenceLength: serializer.fromJson<int>(json['sequenceLength']),
      state: serializer.fromJson<String>(json['state']),
      previousState: serializer.fromJson<String?>(json['previousState']),
      triggeredAt: serializer.fromJson<int?>(json['triggeredAt']),
      cause: serializer.fromJson<String?>(json['cause']),
      planOrExecution: serializer.fromJson<String?>(json['planOrExecution']),
      adjustment: serializer.fromJson<String?>(json['adjustment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'generationId': serializer.toJson<String>(generationId),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'sequenceLength': serializer.toJson<int>(sequenceLength),
      'state': serializer.toJson<String>(state),
      'previousState': serializer.toJson<String?>(previousState),
      'triggeredAt': serializer.toJson<int?>(triggeredAt),
      'cause': serializer.toJson<String?>(cause),
      'planOrExecution': serializer.toJson<String?>(planOrExecution),
      'adjustment': serializer.toJson<String?>(adjustment),
    };
  }

  ProtocolAlarm copyWith({
    String? id,
    String? generationId,
    String? startDate,
    String? endDate,
    int? sequenceLength,
    String? state,
    Value<String?> previousState = const Value.absent(),
    Value<int?> triggeredAt = const Value.absent(),
    Value<String?> cause = const Value.absent(),
    Value<String?> planOrExecution = const Value.absent(),
    Value<String?> adjustment = const Value.absent(),
  }) => ProtocolAlarm(
    id: id ?? this.id,
    generationId: generationId ?? this.generationId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    sequenceLength: sequenceLength ?? this.sequenceLength,
    state: state ?? this.state,
    previousState: previousState.present
        ? previousState.value
        : this.previousState,
    triggeredAt: triggeredAt.present ? triggeredAt.value : this.triggeredAt,
    cause: cause.present ? cause.value : this.cause,
    planOrExecution: planOrExecution.present
        ? planOrExecution.value
        : this.planOrExecution,
    adjustment: adjustment.present ? adjustment.value : this.adjustment,
  );
  ProtocolAlarm copyWithCompanion(ProtocolAlarmsCompanion data) {
    return ProtocolAlarm(
      id: data.id.present ? data.id.value : this.id,
      generationId: data.generationId.present
          ? data.generationId.value
          : this.generationId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      sequenceLength: data.sequenceLength.present
          ? data.sequenceLength.value
          : this.sequenceLength,
      state: data.state.present ? data.state.value : this.state,
      previousState: data.previousState.present
          ? data.previousState.value
          : this.previousState,
      triggeredAt: data.triggeredAt.present
          ? data.triggeredAt.value
          : this.triggeredAt,
      cause: data.cause.present ? data.cause.value : this.cause,
      planOrExecution: data.planOrExecution.present
          ? data.planOrExecution.value
          : this.planOrExecution,
      adjustment: data.adjustment.present
          ? data.adjustment.value
          : this.adjustment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProtocolAlarm(')
          ..write('id: $id, ')
          ..write('generationId: $generationId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('sequenceLength: $sequenceLength, ')
          ..write('state: $state, ')
          ..write('previousState: $previousState, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('cause: $cause, ')
          ..write('planOrExecution: $planOrExecution, ')
          ..write('adjustment: $adjustment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    generationId,
    startDate,
    endDate,
    sequenceLength,
    state,
    previousState,
    triggeredAt,
    cause,
    planOrExecution,
    adjustment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProtocolAlarm &&
          other.id == this.id &&
          other.generationId == this.generationId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.sequenceLength == this.sequenceLength &&
          other.state == this.state &&
          other.previousState == this.previousState &&
          other.triggeredAt == this.triggeredAt &&
          other.cause == this.cause &&
          other.planOrExecution == this.planOrExecution &&
          other.adjustment == this.adjustment);
}

class ProtocolAlarmsCompanion extends UpdateCompanion<ProtocolAlarm> {
  final Value<String> id;
  final Value<String> generationId;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> sequenceLength;
  final Value<String> state;
  final Value<String?> previousState;
  final Value<int?> triggeredAt;
  final Value<String?> cause;
  final Value<String?> planOrExecution;
  final Value<String?> adjustment;
  final Value<int> rowid;
  const ProtocolAlarmsCompanion({
    this.id = const Value.absent(),
    this.generationId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.sequenceLength = const Value.absent(),
    this.state = const Value.absent(),
    this.previousState = const Value.absent(),
    this.triggeredAt = const Value.absent(),
    this.cause = const Value.absent(),
    this.planOrExecution = const Value.absent(),
    this.adjustment = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProtocolAlarmsCompanion.insert({
    required String id,
    required String generationId,
    required String startDate,
    required String endDate,
    required int sequenceLength,
    required String state,
    this.previousState = const Value.absent(),
    this.triggeredAt = const Value.absent(),
    this.cause = const Value.absent(),
    this.planOrExecution = const Value.absent(),
    this.adjustment = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       generationId = Value(generationId),
       startDate = Value(startDate),
       endDate = Value(endDate),
       sequenceLength = Value(sequenceLength),
       state = Value(state);
  static Insertable<ProtocolAlarm> custom({
    Expression<String>? id,
    Expression<String>? generationId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? sequenceLength,
    Expression<String>? state,
    Expression<String>? previousState,
    Expression<int>? triggeredAt,
    Expression<String>? cause,
    Expression<String>? planOrExecution,
    Expression<String>? adjustment,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (generationId != null) 'generation_id': generationId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (sequenceLength != null) 'sequence_length': sequenceLength,
      if (state != null) 'state': state,
      if (previousState != null) 'previous_state': previousState,
      if (triggeredAt != null) 'triggered_at': triggeredAt,
      if (cause != null) 'cause': cause,
      if (planOrExecution != null) 'plan_or_execution': planOrExecution,
      if (adjustment != null) 'adjustment': adjustment,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProtocolAlarmsCompanion copyWith({
    Value<String>? id,
    Value<String>? generationId,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int>? sequenceLength,
    Value<String>? state,
    Value<String?>? previousState,
    Value<int?>? triggeredAt,
    Value<String?>? cause,
    Value<String?>? planOrExecution,
    Value<String?>? adjustment,
    Value<int>? rowid,
  }) {
    return ProtocolAlarmsCompanion(
      id: id ?? this.id,
      generationId: generationId ?? this.generationId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      state: state ?? this.state,
      previousState: previousState ?? this.previousState,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      cause: cause ?? this.cause,
      planOrExecution: planOrExecution ?? this.planOrExecution,
      adjustment: adjustment ?? this.adjustment,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (generationId.present) {
      map['generation_id'] = Variable<String>(generationId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (sequenceLength.present) {
      map['sequence_length'] = Variable<int>(sequenceLength.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (previousState.present) {
      map['previous_state'] = Variable<String>(previousState.value);
    }
    if (triggeredAt.present) {
      map['triggered_at'] = Variable<int>(triggeredAt.value);
    }
    if (cause.present) {
      map['cause'] = Variable<String>(cause.value);
    }
    if (planOrExecution.present) {
      map['plan_or_execution'] = Variable<String>(planOrExecution.value);
    }
    if (adjustment.present) {
      map['adjustment'] = Variable<String>(adjustment.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProtocolAlarmsCompanion(')
          ..write('id: $id, ')
          ..write('generationId: $generationId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('sequenceLength: $sequenceLength, ')
          ..write('state: $state, ')
          ..write('previousState: $previousState, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('cause: $cause, ')
          ..write('planOrExecution: $planOrExecution, ')
          ..write('adjustment: $adjustment, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HolidaysTable extends Holidays with TableInfo<$HolidaysTable, Holiday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HolidaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationalDateMeta = const VerificationMeta(
    'operationalDate',
  );
  @override
  late final GeneratedColumn<String> operationalDate = GeneratedColumn<String>(
    'operational_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (operational_date)',
    ),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedAtMeta = const VerificationMeta(
    'removedAt',
  );
  @override
  late final GeneratedColumn<int> removedAt = GeneratedColumn<int>(
    'removed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _applyReasonTextMeta = const VerificationMeta(
    'applyReasonText',
  );
  @override
  late final GeneratedColumn<String> applyReasonText = GeneratedColumn<String>(
    'apply_reason_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removeReasonTextMeta = const VerificationMeta(
    'removeReasonText',
  );
  @override
  late final GeneratedColumn<String> removeReasonText = GeneratedColumn<String>(
    'remove_reason_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationalDate,
    active,
    createdAt,
    removedAt,
    applyReasonText,
    removeReasonText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holidays';
  @override
  VerificationContext validateIntegrity(
    Insertable<Holiday> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operational_date')) {
      context.handle(
        _operationalDateMeta,
        operationalDate.isAcceptableOrUnknown(
          data['operational_date']!,
          _operationalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationalDateMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('removed_at')) {
      context.handle(
        _removedAtMeta,
        removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta),
      );
    }
    if (data.containsKey('apply_reason_text')) {
      context.handle(
        _applyReasonTextMeta,
        applyReasonText.isAcceptableOrUnknown(
          data['apply_reason_text']!,
          _applyReasonTextMeta,
        ),
      );
    }
    if (data.containsKey('remove_reason_text')) {
      context.handle(
        _removeReasonTextMeta,
        removeReasonText.isAcceptableOrUnknown(
          data['remove_reason_text']!,
          _removeReasonTextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationalDate};
  @override
  Holiday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Holiday(
      operationalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operational_date'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      removedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed_at'],
      ),
      applyReasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apply_reason_text'],
      ),
      removeReasonText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remove_reason_text'],
      ),
    );
  }

  @override
  $HolidaysTable createAlias(String alias) {
    return $HolidaysTable(attachedDatabase, alias);
  }
}

class Holiday extends DataClass implements Insertable<Holiday> {
  final String operationalDate;
  final bool active;
  final int createdAt;
  final int? removedAt;
  final String? applyReasonText;
  final String? removeReasonText;
  const Holiday({
    required this.operationalDate,
    required this.active,
    required this.createdAt,
    this.removedAt,
    this.applyReasonText,
    this.removeReasonText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operational_date'] = Variable<String>(operationalDate);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<int>(removedAt);
    }
    if (!nullToAbsent || applyReasonText != null) {
      map['apply_reason_text'] = Variable<String>(applyReasonText);
    }
    if (!nullToAbsent || removeReasonText != null) {
      map['remove_reason_text'] = Variable<String>(removeReasonText);
    }
    return map;
  }

  HolidaysCompanion toCompanion(bool nullToAbsent) {
    return HolidaysCompanion(
      operationalDate: Value(operationalDate),
      active: Value(active),
      createdAt: Value(createdAt),
      removedAt: removedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedAt),
      applyReasonText: applyReasonText == null && nullToAbsent
          ? const Value.absent()
          : Value(applyReasonText),
      removeReasonText: removeReasonText == null && nullToAbsent
          ? const Value.absent()
          : Value(removeReasonText),
    );
  }

  factory Holiday.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Holiday(
      operationalDate: serializer.fromJson<String>(json['operationalDate']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      removedAt: serializer.fromJson<int?>(json['removedAt']),
      applyReasonText: serializer.fromJson<String?>(json['applyReasonText']),
      removeReasonText: serializer.fromJson<String?>(json['removeReasonText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationalDate': serializer.toJson<String>(operationalDate),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<int>(createdAt),
      'removedAt': serializer.toJson<int?>(removedAt),
      'applyReasonText': serializer.toJson<String?>(applyReasonText),
      'removeReasonText': serializer.toJson<String?>(removeReasonText),
    };
  }

  Holiday copyWith({
    String? operationalDate,
    bool? active,
    int? createdAt,
    Value<int?> removedAt = const Value.absent(),
    Value<String?> applyReasonText = const Value.absent(),
    Value<String?> removeReasonText = const Value.absent(),
  }) => Holiday(
    operationalDate: operationalDate ?? this.operationalDate,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
    applyReasonText: applyReasonText.present
        ? applyReasonText.value
        : this.applyReasonText,
    removeReasonText: removeReasonText.present
        ? removeReasonText.value
        : this.removeReasonText,
  );
  Holiday copyWithCompanion(HolidaysCompanion data) {
    return Holiday(
      operationalDate: data.operationalDate.present
          ? data.operationalDate.value
          : this.operationalDate,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
      applyReasonText: data.applyReasonText.present
          ? data.applyReasonText.value
          : this.applyReasonText,
      removeReasonText: data.removeReasonText.present
          ? data.removeReasonText.value
          : this.removeReasonText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Holiday(')
          ..write('operationalDate: $operationalDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('applyReasonText: $applyReasonText, ')
          ..write('removeReasonText: $removeReasonText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationalDate,
    active,
    createdAt,
    removedAt,
    applyReasonText,
    removeReasonText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Holiday &&
          other.operationalDate == this.operationalDate &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.removedAt == this.removedAt &&
          other.applyReasonText == this.applyReasonText &&
          other.removeReasonText == this.removeReasonText);
}

class HolidaysCompanion extends UpdateCompanion<Holiday> {
  final Value<String> operationalDate;
  final Value<bool> active;
  final Value<int> createdAt;
  final Value<int?> removedAt;
  final Value<String?> applyReasonText;
  final Value<String?> removeReasonText;
  final Value<int> rowid;
  const HolidaysCompanion({
    this.operationalDate = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.applyReasonText = const Value.absent(),
    this.removeReasonText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HolidaysCompanion.insert({
    required String operationalDate,
    required bool active,
    required int createdAt,
    this.removedAt = const Value.absent(),
    this.applyReasonText = const Value.absent(),
    this.removeReasonText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationalDate = Value(operationalDate),
       active = Value(active),
       createdAt = Value(createdAt);
  static Insertable<Holiday> custom({
    Expression<String>? operationalDate,
    Expression<bool>? active,
    Expression<int>? createdAt,
    Expression<int>? removedAt,
    Expression<String>? applyReasonText,
    Expression<String>? removeReasonText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationalDate != null) 'operational_date': operationalDate,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (applyReasonText != null) 'apply_reason_text': applyReasonText,
      if (removeReasonText != null) 'remove_reason_text': removeReasonText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HolidaysCompanion copyWith({
    Value<String>? operationalDate,
    Value<bool>? active,
    Value<int>? createdAt,
    Value<int?>? removedAt,
    Value<String?>? applyReasonText,
    Value<String?>? removeReasonText,
    Value<int>? rowid,
  }) {
    return HolidaysCompanion(
      operationalDate: operationalDate ?? this.operationalDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      removedAt: removedAt ?? this.removedAt,
      applyReasonText: applyReasonText ?? this.applyReasonText,
      removeReasonText: removeReasonText ?? this.removeReasonText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationalDate.present) {
      map['operational_date'] = Variable<String>(operationalDate.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<int>(removedAt.value);
    }
    if (applyReasonText.present) {
      map['apply_reason_text'] = Variable<String>(applyReasonText.value);
    }
    if (removeReasonText.present) {
      map['remove_reason_text'] = Variable<String>(removeReasonText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HolidaysCompanion(')
          ..write('operationalDate: $operationalDate, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('applyReasonText: $applyReasonText, ')
          ..write('removeReasonText: $removeReasonText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MentorshipsTable extends Mentorships
    with TableInfo<$MentorshipsTable, Mentorship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MentorshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _competencyMeta = const VerificationMeta(
    'competency',
  );
  @override
  late final GeneratedColumn<String> competency = GeneratedColumn<String>(
    'competency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mentorNameMeta = const VerificationMeta(
    'mentorName',
  );
  @override
  late final GeneratedColumn<String> mentorName = GeneratedColumn<String>(
    'mentor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMeetingDateMeta = const VerificationMeta(
    'lastMeetingDate',
  );
  @override
  late final GeneratedColumn<String> lastMeetingDate = GeneratedColumn<String>(
    'last_meeting_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    competency,
    mentorName,
    lastMeetingDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mentorships';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mentorship> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('competency')) {
      context.handle(
        _competencyMeta,
        competency.isAcceptableOrUnknown(data['competency']!, _competencyMeta),
      );
    } else if (isInserting) {
      context.missing(_competencyMeta);
    }
    if (data.containsKey('mentor_name')) {
      context.handle(
        _mentorNameMeta,
        mentorName.isAcceptableOrUnknown(data['mentor_name']!, _mentorNameMeta),
      );
    }
    if (data.containsKey('last_meeting_date')) {
      context.handle(
        _lastMeetingDateMeta,
        lastMeetingDate.isAcceptableOrUnknown(
          data['last_meeting_date']!,
          _lastMeetingDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {competency},
  ];
  @override
  Mentorship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mentorship(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      competency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competency'],
      )!,
      mentorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mentor_name'],
      ),
      lastMeetingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_meeting_date'],
      ),
    );
  }

  @override
  $MentorshipsTable createAlias(String alias) {
    return $MentorshipsTable(attachedDatabase, alias);
  }
}

class Mentorship extends DataClass implements Insertable<Mentorship> {
  final String id;
  final String competency;
  final String? mentorName;
  final String? lastMeetingDate;
  const Mentorship({
    required this.id,
    required this.competency,
    this.mentorName,
    this.lastMeetingDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['competency'] = Variable<String>(competency);
    if (!nullToAbsent || mentorName != null) {
      map['mentor_name'] = Variable<String>(mentorName);
    }
    if (!nullToAbsent || lastMeetingDate != null) {
      map['last_meeting_date'] = Variable<String>(lastMeetingDate);
    }
    return map;
  }

  MentorshipsCompanion toCompanion(bool nullToAbsent) {
    return MentorshipsCompanion(
      id: Value(id),
      competency: Value(competency),
      mentorName: mentorName == null && nullToAbsent
          ? const Value.absent()
          : Value(mentorName),
      lastMeetingDate: lastMeetingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMeetingDate),
    );
  }

  factory Mentorship.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mentorship(
      id: serializer.fromJson<String>(json['id']),
      competency: serializer.fromJson<String>(json['competency']),
      mentorName: serializer.fromJson<String?>(json['mentorName']),
      lastMeetingDate: serializer.fromJson<String?>(json['lastMeetingDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'competency': serializer.toJson<String>(competency),
      'mentorName': serializer.toJson<String?>(mentorName),
      'lastMeetingDate': serializer.toJson<String?>(lastMeetingDate),
    };
  }

  Mentorship copyWith({
    String? id,
    String? competency,
    Value<String?> mentorName = const Value.absent(),
    Value<String?> lastMeetingDate = const Value.absent(),
  }) => Mentorship(
    id: id ?? this.id,
    competency: competency ?? this.competency,
    mentorName: mentorName.present ? mentorName.value : this.mentorName,
    lastMeetingDate: lastMeetingDate.present
        ? lastMeetingDate.value
        : this.lastMeetingDate,
  );
  Mentorship copyWithCompanion(MentorshipsCompanion data) {
    return Mentorship(
      id: data.id.present ? data.id.value : this.id,
      competency: data.competency.present
          ? data.competency.value
          : this.competency,
      mentorName: data.mentorName.present
          ? data.mentorName.value
          : this.mentorName,
      lastMeetingDate: data.lastMeetingDate.present
          ? data.lastMeetingDate.value
          : this.lastMeetingDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mentorship(')
          ..write('id: $id, ')
          ..write('competency: $competency, ')
          ..write('mentorName: $mentorName, ')
          ..write('lastMeetingDate: $lastMeetingDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, competency, mentorName, lastMeetingDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mentorship &&
          other.id == this.id &&
          other.competency == this.competency &&
          other.mentorName == this.mentorName &&
          other.lastMeetingDate == this.lastMeetingDate);
}

class MentorshipsCompanion extends UpdateCompanion<Mentorship> {
  final Value<String> id;
  final Value<String> competency;
  final Value<String?> mentorName;
  final Value<String?> lastMeetingDate;
  final Value<int> rowid;
  const MentorshipsCompanion({
    this.id = const Value.absent(),
    this.competency = const Value.absent(),
    this.mentorName = const Value.absent(),
    this.lastMeetingDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MentorshipsCompanion.insert({
    required String id,
    required String competency,
    this.mentorName = const Value.absent(),
    this.lastMeetingDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       competency = Value(competency);
  static Insertable<Mentorship> custom({
    Expression<String>? id,
    Expression<String>? competency,
    Expression<String>? mentorName,
    Expression<String>? lastMeetingDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (competency != null) 'competency': competency,
      if (mentorName != null) 'mentor_name': mentorName,
      if (lastMeetingDate != null) 'last_meeting_date': lastMeetingDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MentorshipsCompanion copyWith({
    Value<String>? id,
    Value<String>? competency,
    Value<String?>? mentorName,
    Value<String?>? lastMeetingDate,
    Value<int>? rowid,
  }) {
    return MentorshipsCompanion(
      id: id ?? this.id,
      competency: competency ?? this.competency,
      mentorName: mentorName ?? this.mentorName,
      lastMeetingDate: lastMeetingDate ?? this.lastMeetingDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (competency.present) {
      map['competency'] = Variable<String>(competency.value);
    }
    if (mentorName.present) {
      map['mentor_name'] = Variable<String>(mentorName.value);
    }
    if (lastMeetingDate.present) {
      map['last_meeting_date'] = Variable<String>(lastMeetingDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MentorshipsCompanion(')
          ..write('id: $id, ')
          ..write('competency: $competency, ')
          ..write('mentorName: $mentorName, ')
          ..write('lastMeetingDate: $lastMeetingDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextNoteMeta = const VerificationMeta(
    'contextNote',
  );
  @override
  late final GeneratedColumn<String> contextNote = GeneratedColumn<String>(
    'context_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTouchDateMeta = const VerificationMeta(
    'lastTouchDate',
  );
  @override
  late final GeneratedColumn<String> lastTouchDate = GeneratedColumn<String>(
    'last_touch_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    contextNote,
    lastTouchDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('context_note')) {
      context.handle(
        _contextNoteMeta,
        contextNote.isAcceptableOrUnknown(
          data['context_note']!,
          _contextNoteMeta,
        ),
      );
    }
    if (data.containsKey('last_touch_date')) {
      context.handle(
        _lastTouchDateMeta,
        lastTouchDate.isAcceptableOrUnknown(
          data['last_touch_date']!,
          _lastTouchDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contextNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_note'],
      ),
      lastTouchDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_touch_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;
  final String name;
  final String? contextNote;
  final String? lastTouchDate;
  final int createdAt;
  const Contact({
    required this.id,
    required this.name,
    this.contextNote,
    this.lastTouchDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contextNote != null) {
      map['context_note'] = Variable<String>(contextNote);
    }
    if (!nullToAbsent || lastTouchDate != null) {
      map['last_touch_date'] = Variable<String>(lastTouchDate);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      name: Value(name),
      contextNote: contextNote == null && nullToAbsent
          ? const Value.absent()
          : Value(contextNote),
      lastTouchDate: lastTouchDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTouchDate),
      createdAt: Value(createdAt),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contextNote: serializer.fromJson<String?>(json['contextNote']),
      lastTouchDate: serializer.fromJson<String?>(json['lastTouchDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'contextNote': serializer.toJson<String?>(contextNote),
      'lastTouchDate': serializer.toJson<String?>(lastTouchDate),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    Value<String?> contextNote = const Value.absent(),
    Value<String?> lastTouchDate = const Value.absent(),
    int? createdAt,
  }) => Contact(
    id: id ?? this.id,
    name: name ?? this.name,
    contextNote: contextNote.present ? contextNote.value : this.contextNote,
    lastTouchDate: lastTouchDate.present
        ? lastTouchDate.value
        : this.lastTouchDate,
    createdAt: createdAt ?? this.createdAt,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contextNote: data.contextNote.present
          ? data.contextNote.value
          : this.contextNote,
      lastTouchDate: data.lastTouchDate.present
          ? data.lastTouchDate.value
          : this.lastTouchDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contextNote: $contextNote, ')
          ..write('lastTouchDate: $lastTouchDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, contextNote, lastTouchDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.name == this.name &&
          other.contextNote == this.contextNote &&
          other.lastTouchDate == this.lastTouchDate &&
          other.createdAt == this.createdAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> contextNote;
  final Value<String?> lastTouchDate;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contextNote = const Value.absent(),
    this.lastTouchDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String name,
    this.contextNote = const Value.absent(),
    this.lastTouchDate = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? contextNote,
    Expression<String>? lastTouchDate,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contextNote != null) 'context_note': contextNote,
      if (lastTouchDate != null) 'last_touch_date': lastTouchDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? contextNote,
    Value<String?>? lastTouchDate,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contextNote: contextNote ?? this.contextNote,
      lastTouchDate: lastTouchDate ?? this.lastTouchDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contextNote.present) {
      map['context_note'] = Variable<String>(contextNote.value);
    }
    if (lastTouchDate.present) {
      map['last_touch_date'] = Variable<String>(lastTouchDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contextNote: $contextNote, ')
          ..write('lastTouchDate: $lastTouchDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyContactSuggestionsTable extends WeeklyContactSuggestions
    with TableInfo<$WeeklyContactSuggestionsTable, WeeklyContactSuggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyContactSuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    weekStart,
    contactId,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_contact_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyContactSuggestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {weekStart, contactId},
  ];
  @override
  WeeklyContactSuggestion map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyContactSuggestion(
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WeeklyContactSuggestionsTable createAlias(String alias) {
    return $WeeklyContactSuggestionsTable(attachedDatabase, alias);
  }
}

class WeeklyContactSuggestion extends DataClass
    implements Insertable<WeeklyContactSuggestion> {
  final String weekStart;
  final String contactId;
  final String status;
  final int createdAt;
  const WeeklyContactSuggestion({
    required this.weekStart,
    required this.contactId,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week_start'] = Variable<String>(weekStart);
    map['contact_id'] = Variable<String>(contactId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WeeklyContactSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyContactSuggestionsCompanion(
      weekStart: Value(weekStart),
      contactId: Value(contactId),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory WeeklyContactSuggestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyContactSuggestion(
      weekStart: serializer.fromJson<String>(json['weekStart']),
      contactId: serializer.fromJson<String>(json['contactId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekStart': serializer.toJson<String>(weekStart),
      'contactId': serializer.toJson<String>(contactId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WeeklyContactSuggestion copyWith({
    String? weekStart,
    String? contactId,
    String? status,
    int? createdAt,
  }) => WeeklyContactSuggestion(
    weekStart: weekStart ?? this.weekStart,
    contactId: contactId ?? this.contactId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  WeeklyContactSuggestion copyWithCompanion(
    WeeklyContactSuggestionsCompanion data,
  ) {
    return WeeklyContactSuggestion(
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyContactSuggestion(')
          ..write('weekStart: $weekStart, ')
          ..write('contactId: $contactId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(weekStart, contactId, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyContactSuggestion &&
          other.weekStart == this.weekStart &&
          other.contactId == this.contactId &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class WeeklyContactSuggestionsCompanion
    extends UpdateCompanion<WeeklyContactSuggestion> {
  final Value<String> weekStart;
  final Value<String> contactId;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const WeeklyContactSuggestionsCompanion({
    this.weekStart = const Value.absent(),
    this.contactId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyContactSuggestionsCompanion.insert({
    required String weekStart,
    required String contactId,
    required String status,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : weekStart = Value(weekStart),
       contactId = Value(contactId),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<WeeklyContactSuggestion> custom({
    Expression<String>? weekStart,
    Expression<String>? contactId,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weekStart != null) 'week_start': weekStart,
      if (contactId != null) 'contact_id': contactId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyContactSuggestionsCompanion copyWith({
    Value<String>? weekStart,
    Value<String>? contactId,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return WeeklyContactSuggestionsCompanion(
      weekStart: weekStart ?? this.weekStart,
      contactId: contactId ?? this.contactId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyContactSuggestionsCompanion(')
          ..write('weekStart: $weekStart, ')
          ..write('contactId: $contactId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CyclesTable extends Cycles with TableInfo<$CyclesTable, Cycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purposeTextMeta = const VerificationMeta(
    'purposeText',
  );
  @override
  late final GeneratedColumn<String> purposeText = GeneratedColumn<String>(
    'purpose_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    purposeText,
    startDate,
    endDate,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('purpose_text')) {
      context.handle(
        _purposeTextMeta,
        purposeText.isAcceptableOrUnknown(
          data['purpose_text']!,
          _purposeTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purposeTextMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      purposeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose_text'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $CyclesTable createAlias(String alias) {
    return $CyclesTable(attachedDatabase, alias);
  }
}

class Cycle extends DataClass implements Insertable<Cycle> {
  final String id;
  final String name;
  final String purposeText;
  final String startDate;
  final String endDate;
  final String state;
  const Cycle({
    required this.id,
    required this.name,
    required this.purposeText,
    required this.startDate,
    required this.endDate,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['purpose_text'] = Variable<String>(purposeText);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['state'] = Variable<String>(state);
    return map;
  }

  CyclesCompanion toCompanion(bool nullToAbsent) {
    return CyclesCompanion(
      id: Value(id),
      name: Value(name),
      purposeText: Value(purposeText),
      startDate: Value(startDate),
      endDate: Value(endDate),
      state: Value(state),
    );
  }

  factory Cycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cycle(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      purposeText: serializer.fromJson<String>(json['purposeText']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'purposeText': serializer.toJson<String>(purposeText),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'state': serializer.toJson<String>(state),
    };
  }

  Cycle copyWith({
    String? id,
    String? name,
    String? purposeText,
    String? startDate,
    String? endDate,
    String? state,
  }) => Cycle(
    id: id ?? this.id,
    name: name ?? this.name,
    purposeText: purposeText ?? this.purposeText,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    state: state ?? this.state,
  );
  Cycle copyWithCompanion(CyclesCompanion data) {
    return Cycle(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      purposeText: data.purposeText.present
          ? data.purposeText.value
          : this.purposeText,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cycle(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('purposeText: $purposeText, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, purposeText, startDate, endDate, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cycle &&
          other.id == this.id &&
          other.name == this.name &&
          other.purposeText == this.purposeText &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.state == this.state);
}

class CyclesCompanion extends UpdateCompanion<Cycle> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> purposeText;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> state;
  final Value<int> rowid;
  const CyclesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.purposeText = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CyclesCompanion.insert({
    required String id,
    required String name,
    required String purposeText,
    required String startDate,
    required String endDate,
    required String state,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       purposeText = Value(purposeText),
       startDate = Value(startDate),
       endDate = Value(endDate),
       state = Value(state);
  static Insertable<Cycle> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? purposeText,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (purposeText != null) 'purpose_text': purposeText,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CyclesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? purposeText,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return CyclesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      purposeText: purposeText ?? this.purposeText,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (purposeText.present) {
      map['purpose_text'] = Variable<String>(purposeText.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CyclesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('purposeText: $purposeText, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckpointsTable extends Checkpoints
    with TableInfo<$CheckpointsTable, Checkpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _competencyMeta = const VerificationMeta(
    'competency',
  );
  @override
  late final GeneratedColumn<String> competency = GeneratedColumn<String>(
    'competency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cycleId, competency, date, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<Checkpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('competency')) {
      context.handle(
        _competencyMeta,
        competency.isAcceptableOrUnknown(data['competency']!, _competencyMeta),
      );
    } else if (isInserting) {
      context.missing(_competencyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Checkpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Checkpoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      competency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competency'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CheckpointsTable createAlias(String alias) {
    return $CheckpointsTable(attachedDatabase, alias);
  }
}

class Checkpoint extends DataClass implements Insertable<Checkpoint> {
  final String id;
  final String cycleId;
  final String competency;
  final String date;
  final String status;
  const Checkpoint({
    required this.id,
    required this.cycleId,
    required this.competency,
    required this.date,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['competency'] = Variable<String>(competency);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    return map;
  }

  CheckpointsCompanion toCompanion(bool nullToAbsent) {
    return CheckpointsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      competency: Value(competency),
      date: Value(date),
      status: Value(status),
    );
  }

  factory Checkpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checkpoint(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      competency: serializer.fromJson<String>(json['competency']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'competency': serializer.toJson<String>(competency),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
    };
  }

  Checkpoint copyWith({
    String? id,
    String? cycleId,
    String? competency,
    String? date,
    String? status,
  }) => Checkpoint(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    competency: competency ?? this.competency,
    date: date ?? this.date,
    status: status ?? this.status,
  );
  Checkpoint copyWithCompanion(CheckpointsCompanion data) {
    return Checkpoint(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      competency: data.competency.present
          ? data.competency.value
          : this.competency,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checkpoint(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('competency: $competency, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cycleId, competency, date, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checkpoint &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.competency == this.competency &&
          other.date == this.date &&
          other.status == this.status);
}

class CheckpointsCompanion extends UpdateCompanion<Checkpoint> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<String> competency;
  final Value<String> date;
  final Value<String> status;
  final Value<int> rowid;
  const CheckpointsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.competency = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckpointsCompanion.insert({
    required String id,
    required String cycleId,
    required String competency,
    required String date,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       competency = Value(competency),
       date = Value(date),
       status = Value(status);
  static Insertable<Checkpoint> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<String>? competency,
    Expression<String>? date,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (competency != null) 'competency': competency,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckpointsCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<String>? competency,
    Value<String>? date,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return CheckpointsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      competency: competency ?? this.competency,
      date: date ?? this.date,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (competency.present) {
      map['competency'] = Variable<String>(competency.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('competency: $competency, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyReviewsTable extends WeeklyReviews
    with TableInfo<$WeeklyReviewsTable, WeeklyReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerFulfilledMeta = const VerificationMeta(
    'answerFulfilled',
  );
  @override
  late final GeneratedColumn<String> answerFulfilled = GeneratedColumn<String>(
    'answer_fulfilled',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerFailedMeta = const VerificationMeta(
    'answerFailed',
  );
  @override
  late final GeneratedColumn<String> answerFailed = GeneratedColumn<String>(
    'answer_failed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerLessonMeta = const VerificationMeta(
    'answerLesson',
  );
  @override
  late final GeneratedColumn<String> answerLesson = GeneratedColumn<String>(
    'answer_lesson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioIdMeta = const VerificationMeta(
    'audioId',
  );
  @override
  late final GeneratedColumn<String> audioId = GeneratedColumn<String>(
    'audio_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES audio_assets (id)',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autosavedAtMeta = const VerificationMeta(
    'autosavedAt',
  );
  @override
  late final GeneratedColumn<int> autosavedAt = GeneratedColumn<int>(
    'autosaved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  @override
  late final GeneratedColumn<int> finalizedAt = GeneratedColumn<int>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekStart,
    answerFulfilled,
    answerFailed,
    answerLesson,
    audioId,
    state,
    createdAt,
    autosavedAt,
    finalizedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('answer_fulfilled')) {
      context.handle(
        _answerFulfilledMeta,
        answerFulfilled.isAcceptableOrUnknown(
          data['answer_fulfilled']!,
          _answerFulfilledMeta,
        ),
      );
    }
    if (data.containsKey('answer_failed')) {
      context.handle(
        _answerFailedMeta,
        answerFailed.isAcceptableOrUnknown(
          data['answer_failed']!,
          _answerFailedMeta,
        ),
      );
    }
    if (data.containsKey('answer_lesson')) {
      context.handle(
        _answerLessonMeta,
        answerLesson.isAcceptableOrUnknown(
          data['answer_lesson']!,
          _answerLessonMeta,
        ),
      );
    }
    if (data.containsKey('audio_id')) {
      context.handle(
        _audioIdMeta,
        audioId.isAcceptableOrUnknown(data['audio_id']!, _audioIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('autosaved_at')) {
      context.handle(
        _autosavedAtMeta,
        autosavedAt.isAcceptableOrUnknown(
          data['autosaved_at']!,
          _autosavedAtMeta,
        ),
      );
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {weekStart},
  ];
  @override
  WeeklyReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      answerFulfilled: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_fulfilled'],
      ),
      answerFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_failed'],
      ),
      answerLesson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_lesson'],
      ),
      audioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      autosavedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}autosaved_at'],
      ),
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finalized_at'],
      ),
    );
  }

  @override
  $WeeklyReviewsTable createAlias(String alias) {
    return $WeeklyReviewsTable(attachedDatabase, alias);
  }
}

class WeeklyReview extends DataClass implements Insertable<WeeklyReview> {
  final String id;
  final String weekStart;
  final String? answerFulfilled;
  final String? answerFailed;
  final String? answerLesson;
  final String? audioId;
  final String state;
  final int createdAt;
  final int? autosavedAt;
  final int? finalizedAt;
  const WeeklyReview({
    required this.id,
    required this.weekStart,
    this.answerFulfilled,
    this.answerFailed,
    this.answerLesson,
    this.audioId,
    required this.state,
    required this.createdAt,
    this.autosavedAt,
    this.finalizedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['week_start'] = Variable<String>(weekStart);
    if (!nullToAbsent || answerFulfilled != null) {
      map['answer_fulfilled'] = Variable<String>(answerFulfilled);
    }
    if (!nullToAbsent || answerFailed != null) {
      map['answer_failed'] = Variable<String>(answerFailed);
    }
    if (!nullToAbsent || answerLesson != null) {
      map['answer_lesson'] = Variable<String>(answerLesson);
    }
    if (!nullToAbsent || audioId != null) {
      map['audio_id'] = Variable<String>(audioId);
    }
    map['state'] = Variable<String>(state);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || autosavedAt != null) {
      map['autosaved_at'] = Variable<int>(autosavedAt);
    }
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<int>(finalizedAt);
    }
    return map;
  }

  WeeklyReviewsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyReviewsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      answerFulfilled: answerFulfilled == null && nullToAbsent
          ? const Value.absent()
          : Value(answerFulfilled),
      answerFailed: answerFailed == null && nullToAbsent
          ? const Value.absent()
          : Value(answerFailed),
      answerLesson: answerLesson == null && nullToAbsent
          ? const Value.absent()
          : Value(answerLesson),
      audioId: audioId == null && nullToAbsent
          ? const Value.absent()
          : Value(audioId),
      state: Value(state),
      createdAt: Value(createdAt),
      autosavedAt: autosavedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(autosavedAt),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
    );
  }

  factory WeeklyReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyReview(
      id: serializer.fromJson<String>(json['id']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      answerFulfilled: serializer.fromJson<String?>(json['answerFulfilled']),
      answerFailed: serializer.fromJson<String?>(json['answerFailed']),
      answerLesson: serializer.fromJson<String?>(json['answerLesson']),
      audioId: serializer.fromJson<String?>(json['audioId']),
      state: serializer.fromJson<String>(json['state']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      autosavedAt: serializer.fromJson<int?>(json['autosavedAt']),
      finalizedAt: serializer.fromJson<int?>(json['finalizedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weekStart': serializer.toJson<String>(weekStart),
      'answerFulfilled': serializer.toJson<String?>(answerFulfilled),
      'answerFailed': serializer.toJson<String?>(answerFailed),
      'answerLesson': serializer.toJson<String?>(answerLesson),
      'audioId': serializer.toJson<String?>(audioId),
      'state': serializer.toJson<String>(state),
      'createdAt': serializer.toJson<int>(createdAt),
      'autosavedAt': serializer.toJson<int?>(autosavedAt),
      'finalizedAt': serializer.toJson<int?>(finalizedAt),
    };
  }

  WeeklyReview copyWith({
    String? id,
    String? weekStart,
    Value<String?> answerFulfilled = const Value.absent(),
    Value<String?> answerFailed = const Value.absent(),
    Value<String?> answerLesson = const Value.absent(),
    Value<String?> audioId = const Value.absent(),
    String? state,
    int? createdAt,
    Value<int?> autosavedAt = const Value.absent(),
    Value<int?> finalizedAt = const Value.absent(),
  }) => WeeklyReview(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    answerFulfilled: answerFulfilled.present
        ? answerFulfilled.value
        : this.answerFulfilled,
    answerFailed: answerFailed.present ? answerFailed.value : this.answerFailed,
    answerLesson: answerLesson.present ? answerLesson.value : this.answerLesson,
    audioId: audioId.present ? audioId.value : this.audioId,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
    autosavedAt: autosavedAt.present ? autosavedAt.value : this.autosavedAt,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
  );
  WeeklyReview copyWithCompanion(WeeklyReviewsCompanion data) {
    return WeeklyReview(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      answerFulfilled: data.answerFulfilled.present
          ? data.answerFulfilled.value
          : this.answerFulfilled,
      answerFailed: data.answerFailed.present
          ? data.answerFailed.value
          : this.answerFailed,
      answerLesson: data.answerLesson.present
          ? data.answerLesson.value
          : this.answerLesson,
      audioId: data.audioId.present ? data.audioId.value : this.audioId,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      autosavedAt: data.autosavedAt.present
          ? data.autosavedAt.value
          : this.autosavedAt,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReview(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('answerFulfilled: $answerFulfilled, ')
          ..write('answerFailed: $answerFailed, ')
          ..write('answerLesson: $answerLesson, ')
          ..write('audioId: $audioId, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('autosavedAt: $autosavedAt, ')
          ..write('finalizedAt: $finalizedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weekStart,
    answerFulfilled,
    answerFailed,
    answerLesson,
    audioId,
    state,
    createdAt,
    autosavedAt,
    finalizedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyReview &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.answerFulfilled == this.answerFulfilled &&
          other.answerFailed == this.answerFailed &&
          other.answerLesson == this.answerLesson &&
          other.audioId == this.audioId &&
          other.state == this.state &&
          other.createdAt == this.createdAt &&
          other.autosavedAt == this.autosavedAt &&
          other.finalizedAt == this.finalizedAt);
}

class WeeklyReviewsCompanion extends UpdateCompanion<WeeklyReview> {
  final Value<String> id;
  final Value<String> weekStart;
  final Value<String?> answerFulfilled;
  final Value<String?> answerFailed;
  final Value<String?> answerLesson;
  final Value<String?> audioId;
  final Value<String> state;
  final Value<int> createdAt;
  final Value<int?> autosavedAt;
  final Value<int?> finalizedAt;
  final Value<int> rowid;
  const WeeklyReviewsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.answerFulfilled = const Value.absent(),
    this.answerFailed = const Value.absent(),
    this.answerLesson = const Value.absent(),
    this.audioId = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.autosavedAt = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyReviewsCompanion.insert({
    required String id,
    required String weekStart,
    this.answerFulfilled = const Value.absent(),
    this.answerFailed = const Value.absent(),
    this.answerLesson = const Value.absent(),
    this.audioId = const Value.absent(),
    this.state = const Value.absent(),
    required int createdAt,
    this.autosavedAt = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       weekStart = Value(weekStart),
       createdAt = Value(createdAt);
  static Insertable<WeeklyReview> custom({
    Expression<String>? id,
    Expression<String>? weekStart,
    Expression<String>? answerFulfilled,
    Expression<String>? answerFailed,
    Expression<String>? answerLesson,
    Expression<String>? audioId,
    Expression<String>? state,
    Expression<int>? createdAt,
    Expression<int>? autosavedAt,
    Expression<int>? finalizedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (answerFulfilled != null) 'answer_fulfilled': answerFulfilled,
      if (answerFailed != null) 'answer_failed': answerFailed,
      if (answerLesson != null) 'answer_lesson': answerLesson,
      if (audioId != null) 'audio_id': audioId,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
      if (autosavedAt != null) 'autosaved_at': autosavedAt,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? weekStart,
    Value<String?>? answerFulfilled,
    Value<String?>? answerFailed,
    Value<String?>? answerLesson,
    Value<String?>? audioId,
    Value<String>? state,
    Value<int>? createdAt,
    Value<int?>? autosavedAt,
    Value<int?>? finalizedAt,
    Value<int>? rowid,
  }) {
    return WeeklyReviewsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      answerFulfilled: answerFulfilled ?? this.answerFulfilled,
      answerFailed: answerFailed ?? this.answerFailed,
      answerLesson: answerLesson ?? this.answerLesson,
      audioId: audioId ?? this.audioId,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      autosavedAt: autosavedAt ?? this.autosavedAt,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (answerFulfilled.present) {
      map['answer_fulfilled'] = Variable<String>(answerFulfilled.value);
    }
    if (answerFailed.present) {
      map['answer_failed'] = Variable<String>(answerFailed.value);
    }
    if (answerLesson.present) {
      map['answer_lesson'] = Variable<String>(answerLesson.value);
    }
    if (audioId.present) {
      map['audio_id'] = Variable<String>(audioId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (autosavedAt.present) {
      map['autosaved_at'] = Variable<int>(autosavedAt.value);
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<int>(finalizedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReviewsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('answerFulfilled: $answerFulfilled, ')
          ..write('answerFailed: $answerFailed, ')
          ..write('answerLesson: $answerLesson, ')
          ..write('audioId: $audioId, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('autosavedAt: $autosavedAt, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckpointEvalsTable extends CheckpointEvals
    with TableInfo<$CheckpointEvalsTable, CheckpointEval> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckpointEvalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkpointIdMeta = const VerificationMeta(
    'checkpointId',
  );
  @override
  late final GeneratedColumn<String> checkpointId = GeneratedColumn<String>(
    'checkpoint_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES checkpoints (id)',
    ),
  );
  static const VerificationMeta _weeklyReviewIdMeta = const VerificationMeta(
    'weeklyReviewId',
  );
  @override
  late final GeneratedColumn<String> weeklyReviewId = GeneratedColumn<String>(
    'weekly_review_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES weekly_reviews (id)',
    ),
  );
  static const VerificationMeta _gartnerLevelMeta = const VerificationMeta(
    'gartnerLevel',
  );
  @override
  late final GeneratedColumn<String> gartnerLevel = GeneratedColumn<String>(
    'gartner_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    checkpointId,
    weeklyReviewId,
    gartnerLevel,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checkpoint_evals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckpointEval> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checkpoint_id')) {
      context.handle(
        _checkpointIdMeta,
        checkpointId.isAcceptableOrUnknown(
          data['checkpoint_id']!,
          _checkpointIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checkpointIdMeta);
    }
    if (data.containsKey('weekly_review_id')) {
      context.handle(
        _weeklyReviewIdMeta,
        weeklyReviewId.isAcceptableOrUnknown(
          data['weekly_review_id']!,
          _weeklyReviewIdMeta,
        ),
      );
    }
    if (data.containsKey('gartner_level')) {
      context.handle(
        _gartnerLevelMeta,
        gartnerLevel.isAcceptableOrUnknown(
          data['gartner_level']!,
          _gartnerLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gartnerLevelMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckpointEval map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckpointEval(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      checkpointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkpoint_id'],
      )!,
      weeklyReviewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekly_review_id'],
      ),
      gartnerLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gartner_level'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CheckpointEvalsTable createAlias(String alias) {
    return $CheckpointEvalsTable(attachedDatabase, alias);
  }
}

class CheckpointEval extends DataClass implements Insertable<CheckpointEval> {
  final String id;
  final String checkpointId;
  final String? weeklyReviewId;
  final String gartnerLevel;
  final String? notes;
  const CheckpointEval({
    required this.id,
    required this.checkpointId,
    this.weeklyReviewId,
    required this.gartnerLevel,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['checkpoint_id'] = Variable<String>(checkpointId);
    if (!nullToAbsent || weeklyReviewId != null) {
      map['weekly_review_id'] = Variable<String>(weeklyReviewId);
    }
    map['gartner_level'] = Variable<String>(gartnerLevel);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CheckpointEvalsCompanion toCompanion(bool nullToAbsent) {
    return CheckpointEvalsCompanion(
      id: Value(id),
      checkpointId: Value(checkpointId),
      weeklyReviewId: weeklyReviewId == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyReviewId),
      gartnerLevel: Value(gartnerLevel),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory CheckpointEval.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckpointEval(
      id: serializer.fromJson<String>(json['id']),
      checkpointId: serializer.fromJson<String>(json['checkpointId']),
      weeklyReviewId: serializer.fromJson<String?>(json['weeklyReviewId']),
      gartnerLevel: serializer.fromJson<String>(json['gartnerLevel']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'checkpointId': serializer.toJson<String>(checkpointId),
      'weeklyReviewId': serializer.toJson<String?>(weeklyReviewId),
      'gartnerLevel': serializer.toJson<String>(gartnerLevel),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CheckpointEval copyWith({
    String? id,
    String? checkpointId,
    Value<String?> weeklyReviewId = const Value.absent(),
    String? gartnerLevel,
    Value<String?> notes = const Value.absent(),
  }) => CheckpointEval(
    id: id ?? this.id,
    checkpointId: checkpointId ?? this.checkpointId,
    weeklyReviewId: weeklyReviewId.present
        ? weeklyReviewId.value
        : this.weeklyReviewId,
    gartnerLevel: gartnerLevel ?? this.gartnerLevel,
    notes: notes.present ? notes.value : this.notes,
  );
  CheckpointEval copyWithCompanion(CheckpointEvalsCompanion data) {
    return CheckpointEval(
      id: data.id.present ? data.id.value : this.id,
      checkpointId: data.checkpointId.present
          ? data.checkpointId.value
          : this.checkpointId,
      weeklyReviewId: data.weeklyReviewId.present
          ? data.weeklyReviewId.value
          : this.weeklyReviewId,
      gartnerLevel: data.gartnerLevel.present
          ? data.gartnerLevel.value
          : this.gartnerLevel,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointEval(')
          ..write('id: $id, ')
          ..write('checkpointId: $checkpointId, ')
          ..write('weeklyReviewId: $weeklyReviewId, ')
          ..write('gartnerLevel: $gartnerLevel, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, checkpointId, weeklyReviewId, gartnerLevel, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckpointEval &&
          other.id == this.id &&
          other.checkpointId == this.checkpointId &&
          other.weeklyReviewId == this.weeklyReviewId &&
          other.gartnerLevel == this.gartnerLevel &&
          other.notes == this.notes);
}

class CheckpointEvalsCompanion extends UpdateCompanion<CheckpointEval> {
  final Value<String> id;
  final Value<String> checkpointId;
  final Value<String?> weeklyReviewId;
  final Value<String> gartnerLevel;
  final Value<String?> notes;
  final Value<int> rowid;
  const CheckpointEvalsCompanion({
    this.id = const Value.absent(),
    this.checkpointId = const Value.absent(),
    this.weeklyReviewId = const Value.absent(),
    this.gartnerLevel = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckpointEvalsCompanion.insert({
    required String id,
    required String checkpointId,
    this.weeklyReviewId = const Value.absent(),
    required String gartnerLevel,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       checkpointId = Value(checkpointId),
       gartnerLevel = Value(gartnerLevel);
  static Insertable<CheckpointEval> custom({
    Expression<String>? id,
    Expression<String>? checkpointId,
    Expression<String>? weeklyReviewId,
    Expression<String>? gartnerLevel,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (checkpointId != null) 'checkpoint_id': checkpointId,
      if (weeklyReviewId != null) 'weekly_review_id': weeklyReviewId,
      if (gartnerLevel != null) 'gartner_level': gartnerLevel,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckpointEvalsCompanion copyWith({
    Value<String>? id,
    Value<String>? checkpointId,
    Value<String?>? weeklyReviewId,
    Value<String>? gartnerLevel,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return CheckpointEvalsCompanion(
      id: id ?? this.id,
      checkpointId: checkpointId ?? this.checkpointId,
      weeklyReviewId: weeklyReviewId ?? this.weeklyReviewId,
      gartnerLevel: gartnerLevel ?? this.gartnerLevel,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (checkpointId.present) {
      map['checkpoint_id'] = Variable<String>(checkpointId.value);
    }
    if (weeklyReviewId.present) {
      map['weekly_review_id'] = Variable<String>(weeklyReviewId.value);
    }
    if (gartnerLevel.present) {
      map['gartner_level'] = Variable<String>(gartnerLevel.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointEvalsCompanion(')
          ..write('id: $id, ')
          ..write('checkpointId: $checkpointId, ')
          ..write('weeklyReviewId: $weeklyReviewId, ')
          ..write('gartnerLevel: $gartnerLevel, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CycleClosureInvitesTable extends CycleClosureInvites
    with TableInfo<$CycleClosureInvitesTable, CycleClosureInvite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CycleClosureInvitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cycleId, weekStart];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycle_closure_invites';
  @override
  VerificationContext validateIntegrity(
    Insertable<CycleClosureInvite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cycleId, weekStart};
  @override
  CycleClosureInvite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleClosureInvite(
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
    );
  }

  @override
  $CycleClosureInvitesTable createAlias(String alias) {
    return $CycleClosureInvitesTable(attachedDatabase, alias);
  }
}

class CycleClosureInvite extends DataClass
    implements Insertable<CycleClosureInvite> {
  final String cycleId;
  final String weekStart;
  const CycleClosureInvite({required this.cycleId, required this.weekStart});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cycle_id'] = Variable<String>(cycleId);
    map['week_start'] = Variable<String>(weekStart);
    return map;
  }

  CycleClosureInvitesCompanion toCompanion(bool nullToAbsent) {
    return CycleClosureInvitesCompanion(
      cycleId: Value(cycleId),
      weekStart: Value(weekStart),
    );
  }

  factory CycleClosureInvite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleClosureInvite(
      cycleId: serializer.fromJson<String>(json['cycleId']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cycleId': serializer.toJson<String>(cycleId),
      'weekStart': serializer.toJson<String>(weekStart),
    };
  }

  CycleClosureInvite copyWith({String? cycleId, String? weekStart}) =>
      CycleClosureInvite(
        cycleId: cycleId ?? this.cycleId,
        weekStart: weekStart ?? this.weekStart,
      );
  CycleClosureInvite copyWithCompanion(CycleClosureInvitesCompanion data) {
    return CycleClosureInvite(
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleClosureInvite(')
          ..write('cycleId: $cycleId, ')
          ..write('weekStart: $weekStart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cycleId, weekStart);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleClosureInvite &&
          other.cycleId == this.cycleId &&
          other.weekStart == this.weekStart);
}

class CycleClosureInvitesCompanion extends UpdateCompanion<CycleClosureInvite> {
  final Value<String> cycleId;
  final Value<String> weekStart;
  final Value<int> rowid;
  const CycleClosureInvitesCompanion({
    this.cycleId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CycleClosureInvitesCompanion.insert({
    required String cycleId,
    required String weekStart,
    this.rowid = const Value.absent(),
  }) : cycleId = Value(cycleId),
       weekStart = Value(weekStart);
  static Insertable<CycleClosureInvite> custom({
    Expression<String>? cycleId,
    Expression<String>? weekStart,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cycleId != null) 'cycle_id': cycleId,
      if (weekStart != null) 'week_start': weekStart,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CycleClosureInvitesCompanion copyWith({
    Value<String>? cycleId,
    Value<String>? weekStart,
    Value<int>? rowid,
  }) {
    return CycleClosureInvitesCompanion(
      cycleId: cycleId ?? this.cycleId,
      weekStart: weekStart ?? this.weekStart,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CycleClosureInvitesCompanion(')
          ..write('cycleId: $cycleId, ')
          ..write('weekStart: $weekStart, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManifestsTable extends Manifests
    with TableInfo<$ManifestsTable, Manifest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManifestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMarkdownMeta = const VerificationMeta(
    'contentMarkdown',
  );
  @override
  late final GeneratedColumn<String> contentMarkdown = GeneratedColumn<String>(
    'content_markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetVersionMeta = const VerificationMeta(
    'assetVersion',
  );
  @override
  late final GeneratedColumn<String> assetVersion = GeneratedColumn<String>(
    'asset_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstCopiedAtMeta = const VerificationMeta(
    'firstCopiedAt',
  );
  @override
  late final GeneratedColumn<int> firstCopiedAt = GeneratedColumn<int>(
    'first_copied_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastEditedAtMeta = const VerificationMeta(
    'lastEditedAt',
  );
  @override
  late final GeneratedColumn<int> lastEditedAt = GeneratedColumn<int>(
    'last_edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentMarkdown,
    assetVersion,
    firstCopiedAt,
    lastEditedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manifests';
  @override
  VerificationContext validateIntegrity(
    Insertable<Manifest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_markdown')) {
      context.handle(
        _contentMarkdownMeta,
        contentMarkdown.isAcceptableOrUnknown(
          data['content_markdown']!,
          _contentMarkdownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentMarkdownMeta);
    }
    if (data.containsKey('asset_version')) {
      context.handle(
        _assetVersionMeta,
        assetVersion.isAcceptableOrUnknown(
          data['asset_version']!,
          _assetVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assetVersionMeta);
    }
    if (data.containsKey('first_copied_at')) {
      context.handle(
        _firstCopiedAtMeta,
        firstCopiedAt.isAcceptableOrUnknown(
          data['first_copied_at']!,
          _firstCopiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstCopiedAtMeta);
    }
    if (data.containsKey('last_edited_at')) {
      context.handle(
        _lastEditedAtMeta,
        lastEditedAt.isAcceptableOrUnknown(
          data['last_edited_at']!,
          _lastEditedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Manifest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Manifest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contentMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_markdown'],
      )!,
      assetVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_version'],
      )!,
      firstCopiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_copied_at'],
      )!,
      lastEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_edited_at'],
      ),
    );
  }

  @override
  $ManifestsTable createAlias(String alias) {
    return $ManifestsTable(attachedDatabase, alias);
  }
}

class Manifest extends DataClass implements Insertable<Manifest> {
  final String id;
  final String contentMarkdown;
  final String assetVersion;
  final int firstCopiedAt;
  final int? lastEditedAt;
  const Manifest({
    required this.id,
    required this.contentMarkdown,
    required this.assetVersion,
    required this.firstCopiedAt,
    this.lastEditedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content_markdown'] = Variable<String>(contentMarkdown);
    map['asset_version'] = Variable<String>(assetVersion);
    map['first_copied_at'] = Variable<int>(firstCopiedAt);
    if (!nullToAbsent || lastEditedAt != null) {
      map['last_edited_at'] = Variable<int>(lastEditedAt);
    }
    return map;
  }

  ManifestsCompanion toCompanion(bool nullToAbsent) {
    return ManifestsCompanion(
      id: Value(id),
      contentMarkdown: Value(contentMarkdown),
      assetVersion: Value(assetVersion),
      firstCopiedAt: Value(firstCopiedAt),
      lastEditedAt: lastEditedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEditedAt),
    );
  }

  factory Manifest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Manifest(
      id: serializer.fromJson<String>(json['id']),
      contentMarkdown: serializer.fromJson<String>(json['contentMarkdown']),
      assetVersion: serializer.fromJson<String>(json['assetVersion']),
      firstCopiedAt: serializer.fromJson<int>(json['firstCopiedAt']),
      lastEditedAt: serializer.fromJson<int?>(json['lastEditedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contentMarkdown': serializer.toJson<String>(contentMarkdown),
      'assetVersion': serializer.toJson<String>(assetVersion),
      'firstCopiedAt': serializer.toJson<int>(firstCopiedAt),
      'lastEditedAt': serializer.toJson<int?>(lastEditedAt),
    };
  }

  Manifest copyWith({
    String? id,
    String? contentMarkdown,
    String? assetVersion,
    int? firstCopiedAt,
    Value<int?> lastEditedAt = const Value.absent(),
  }) => Manifest(
    id: id ?? this.id,
    contentMarkdown: contentMarkdown ?? this.contentMarkdown,
    assetVersion: assetVersion ?? this.assetVersion,
    firstCopiedAt: firstCopiedAt ?? this.firstCopiedAt,
    lastEditedAt: lastEditedAt.present ? lastEditedAt.value : this.lastEditedAt,
  );
  Manifest copyWithCompanion(ManifestsCompanion data) {
    return Manifest(
      id: data.id.present ? data.id.value : this.id,
      contentMarkdown: data.contentMarkdown.present
          ? data.contentMarkdown.value
          : this.contentMarkdown,
      assetVersion: data.assetVersion.present
          ? data.assetVersion.value
          : this.assetVersion,
      firstCopiedAt: data.firstCopiedAt.present
          ? data.firstCopiedAt.value
          : this.firstCopiedAt,
      lastEditedAt: data.lastEditedAt.present
          ? data.lastEditedAt.value
          : this.lastEditedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Manifest(')
          ..write('id: $id, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('assetVersion: $assetVersion, ')
          ..write('firstCopiedAt: $firstCopiedAt, ')
          ..write('lastEditedAt: $lastEditedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentMarkdown,
    assetVersion,
    firstCopiedAt,
    lastEditedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Manifest &&
          other.id == this.id &&
          other.contentMarkdown == this.contentMarkdown &&
          other.assetVersion == this.assetVersion &&
          other.firstCopiedAt == this.firstCopiedAt &&
          other.lastEditedAt == this.lastEditedAt);
}

class ManifestsCompanion extends UpdateCompanion<Manifest> {
  final Value<String> id;
  final Value<String> contentMarkdown;
  final Value<String> assetVersion;
  final Value<int> firstCopiedAt;
  final Value<int?> lastEditedAt;
  final Value<int> rowid;
  const ManifestsCompanion({
    this.id = const Value.absent(),
    this.contentMarkdown = const Value.absent(),
    this.assetVersion = const Value.absent(),
    this.firstCopiedAt = const Value.absent(),
    this.lastEditedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManifestsCompanion.insert({
    required String id,
    required String contentMarkdown,
    required String assetVersion,
    required int firstCopiedAt,
    this.lastEditedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contentMarkdown = Value(contentMarkdown),
       assetVersion = Value(assetVersion),
       firstCopiedAt = Value(firstCopiedAt);
  static Insertable<Manifest> custom({
    Expression<String>? id,
    Expression<String>? contentMarkdown,
    Expression<String>? assetVersion,
    Expression<int>? firstCopiedAt,
    Expression<int>? lastEditedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentMarkdown != null) 'content_markdown': contentMarkdown,
      if (assetVersion != null) 'asset_version': assetVersion,
      if (firstCopiedAt != null) 'first_copied_at': firstCopiedAt,
      if (lastEditedAt != null) 'last_edited_at': lastEditedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManifestsCompanion copyWith({
    Value<String>? id,
    Value<String>? contentMarkdown,
    Value<String>? assetVersion,
    Value<int>? firstCopiedAt,
    Value<int?>? lastEditedAt,
    Value<int>? rowid,
  }) {
    return ManifestsCompanion(
      id: id ?? this.id,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      assetVersion: assetVersion ?? this.assetVersion,
      firstCopiedAt: firstCopiedAt ?? this.firstCopiedAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contentMarkdown.present) {
      map['content_markdown'] = Variable<String>(contentMarkdown.value);
    }
    if (assetVersion.present) {
      map['asset_version'] = Variable<String>(assetVersion.value);
    }
    if (firstCopiedAt.present) {
      map['first_copied_at'] = Variable<int>(firstCopiedAt.value);
    }
    if (lastEditedAt.present) {
      map['last_edited_at'] = Variable<int>(lastEditedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManifestsCompanion(')
          ..write('id: $id, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('assetVersion: $assetVersion, ')
          ..write('firstCopiedAt: $firstCopiedAt, ')
          ..write('lastEditedAt: $lastEditedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationPlansTable extends NotificationPlans
    with TableInfo<$NotificationPlansTable, NotificationPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedAtMeta = const VerificationMeta(
    'plannedAt',
  );
  @override
  late final GeneratedColumn<int> plannedAt = GeneratedColumn<int>(
    'planned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idempotencyKey,
    kind,
    plannedAt,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('planned_at')) {
      context.handle(
        _plannedAtMeta,
        plannedAt.isAcceptableOrUnknown(data['planned_at']!, _plannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  NotificationPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationPlan(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      plannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $NotificationPlansTable createAlias(String alias) {
    return $NotificationPlansTable(attachedDatabase, alias);
  }
}

class NotificationPlan extends DataClass
    implements Insertable<NotificationPlan> {
  final String idempotencyKey;
  final String kind;
  final int plannedAt;
  final String state;
  const NotificationPlan({
    required this.idempotencyKey,
    required this.kind,
    required this.plannedAt,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['kind'] = Variable<String>(kind);
    map['planned_at'] = Variable<int>(plannedAt);
    map['state'] = Variable<String>(state);
    return map;
  }

  NotificationPlansCompanion toCompanion(bool nullToAbsent) {
    return NotificationPlansCompanion(
      idempotencyKey: Value(idempotencyKey),
      kind: Value(kind),
      plannedAt: Value(plannedAt),
      state: Value(state),
    );
  }

  factory NotificationPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationPlan(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      kind: serializer.fromJson<String>(json['kind']),
      plannedAt: serializer.fromJson<int>(json['plannedAt']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'kind': serializer.toJson<String>(kind),
      'plannedAt': serializer.toJson<int>(plannedAt),
      'state': serializer.toJson<String>(state),
    };
  }

  NotificationPlan copyWith({
    String? idempotencyKey,
    String? kind,
    int? plannedAt,
    String? state,
  }) => NotificationPlan(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    kind: kind ?? this.kind,
    plannedAt: plannedAt ?? this.plannedAt,
    state: state ?? this.state,
  );
  NotificationPlan copyWithCompanion(NotificationPlansCompanion data) {
    return NotificationPlan(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      plannedAt: data.plannedAt.present ? data.plannedAt.value : this.plannedAt,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPlan(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('kind: $kind, ')
          ..write('plannedAt: $plannedAt, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idempotencyKey, kind, plannedAt, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPlan &&
          other.idempotencyKey == this.idempotencyKey &&
          other.kind == this.kind &&
          other.plannedAt == this.plannedAt &&
          other.state == this.state);
}

class NotificationPlansCompanion extends UpdateCompanion<NotificationPlan> {
  final Value<String> idempotencyKey;
  final Value<String> kind;
  final Value<int> plannedAt;
  final Value<String> state;
  final Value<int> rowid;
  const NotificationPlansCompanion({
    this.idempotencyKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.plannedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationPlansCompanion.insert({
    required String idempotencyKey,
    required String kind,
    required int plannedAt,
    required String state,
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       kind = Value(kind),
       plannedAt = Value(plannedAt),
       state = Value(state);
  static Insertable<NotificationPlan> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? kind,
    Expression<int>? plannedAt,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (kind != null) 'kind': kind,
      if (plannedAt != null) 'planned_at': plannedAt,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationPlansCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String>? kind,
    Value<int>? plannedAt,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return NotificationPlansCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      kind: kind ?? this.kind,
      plannedAt: plannedAt ?? this.plannedAt,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (plannedAt.present) {
      map['planned_at'] = Variable<int>(plannedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPlansCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('kind: $kind, ')
          ..write('plannedAt: $plannedAt, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RitmoDatabase extends GeneratedDatabase {
  _$RitmoDatabase(QueryExecutor e) : super(e);
  $RitmoDatabaseManager get managers => $RitmoDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DaysTable days = $DaysTable(this);
  late final $StudyBlocksTable studyBlocks = $StudyBlocksTable(this);
  late final $AudioAssetsTable audioAssets = $AudioAssetsTable(this);
  late final $ChangeInitiativesTable changeInitiatives =
      $ChangeInitiativesTable(this);
  late final $PillarEntriesTable pillarEntries = $PillarEntriesTable(this);
  late final $PillarWaiversTable pillarWaivers = $PillarWaiversTable(this);
  late final $ProtocolAlarmsTable protocolAlarms = $ProtocolAlarmsTable(this);
  late final $HolidaysTable holidays = $HolidaysTable(this);
  late final $MentorshipsTable mentorships = $MentorshipsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $WeeklyContactSuggestionsTable weeklyContactSuggestions =
      $WeeklyContactSuggestionsTable(this);
  late final $CyclesTable cycles = $CyclesTable(this);
  late final $CheckpointsTable checkpoints = $CheckpointsTable(this);
  late final $WeeklyReviewsTable weeklyReviews = $WeeklyReviewsTable(this);
  late final $CheckpointEvalsTable checkpointEvals = $CheckpointEvalsTable(
    this,
  );
  late final $CycleClosureInvitesTable cycleClosureInvites =
      $CycleClosureInvitesTable(this);
  late final $ManifestsTable manifests = $ManifestsTable(this);
  late final $NotificationPlansTable notificationPlans =
      $NotificationPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    days,
    studyBlocks,
    audioAssets,
    changeInitiatives,
    pillarEntries,
    pillarWaivers,
    protocolAlarms,
    holidays,
    mentorships,
    contacts,
    weeklyContactSuggestions,
    cycles,
    checkpoints,
    weeklyReviews,
    checkpointEvals,
    cycleClosureInvites,
    manifests,
    notificationPlans,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String?> activationDate,
      Value<String> businessTimezone,
      Value<int> dayCloseTimeMin,
      Value<int> nightEndTimeMin,
      Value<String> reviewWeekday,
      Value<int> reviewTimeMin,
      Value<bool> sundayNotificationEnabled,
      Value<bool> syncEnabled,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String?> activationDate,
      Value<String> businessTimezone,
      Value<int> dayCloseTimeMin,
      Value<int> nightEndTimeMin,
      Value<String> reviewWeekday,
      Value<int> reviewTimeMin,
      Value<bool> sundayNotificationEnabled,
      Value<bool> syncEnabled,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$RitmoDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activationDate => $composableBuilder(
    column: $table.activationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessTimezone => $composableBuilder(
    column: $table.businessTimezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayCloseTimeMin => $composableBuilder(
    column: $table.dayCloseTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nightEndTimeMin => $composableBuilder(
    column: $table.nightEndTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewWeekday => $composableBuilder(
    column: $table.reviewWeekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewTimeMin => $composableBuilder(
    column: $table.reviewTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sundayNotificationEnabled => $composableBuilder(
    column: $table.sundayNotificationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activationDate => $composableBuilder(
    column: $table.activationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessTimezone => $composableBuilder(
    column: $table.businessTimezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayCloseTimeMin => $composableBuilder(
    column: $table.dayCloseTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nightEndTimeMin => $composableBuilder(
    column: $table.nightEndTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewWeekday => $composableBuilder(
    column: $table.reviewWeekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewTimeMin => $composableBuilder(
    column: $table.reviewTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sundayNotificationEnabled => $composableBuilder(
    column: $table.sundayNotificationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activationDate => $composableBuilder(
    column: $table.activationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessTimezone => $composableBuilder(
    column: $table.businessTimezone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayCloseTimeMin => $composableBuilder(
    column: $table.dayCloseTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nightEndTimeMin => $composableBuilder(
    column: $table.nightEndTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewWeekday => $composableBuilder(
    column: $table.reviewWeekday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewTimeMin => $composableBuilder(
    column: $table.reviewTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sundayNotificationEnabled => $composableBuilder(
    column: $table.sundayNotificationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$RitmoDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$RitmoDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activationDate = const Value.absent(),
                Value<String> businessTimezone = const Value.absent(),
                Value<int> dayCloseTimeMin = const Value.absent(),
                Value<int> nightEndTimeMin = const Value.absent(),
                Value<String> reviewWeekday = const Value.absent(),
                Value<int> reviewTimeMin = const Value.absent(),
                Value<bool> sundayNotificationEnabled = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                activationDate: activationDate,
                businessTimezone: businessTimezone,
                dayCloseTimeMin: dayCloseTimeMin,
                nightEndTimeMin: nightEndTimeMin,
                reviewWeekday: reviewWeekday,
                reviewTimeMin: reviewTimeMin,
                sundayNotificationEnabled: sundayNotificationEnabled,
                syncEnabled: syncEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activationDate = const Value.absent(),
                Value<String> businessTimezone = const Value.absent(),
                Value<int> dayCloseTimeMin = const Value.absent(),
                Value<int> nightEndTimeMin = const Value.absent(),
                Value<String> reviewWeekday = const Value.absent(),
                Value<int> reviewTimeMin = const Value.absent(),
                Value<bool> sundayNotificationEnabled = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                activationDate: activationDate,
                businessTimezone: businessTimezone,
                dayCloseTimeMin: dayCloseTimeMin,
                nightEndTimeMin: nightEndTimeMin,
                reviewWeekday: reviewWeekday,
                reviewTimeMin: reviewTimeMin,
                sundayNotificationEnabled: sundayNotificationEnabled,
                syncEnabled: syncEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$RitmoDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$DaysTableCreateCompanionBuilder =
    DaysCompanion Function({
      required String operationalDate,
      required String baseResult,
      required String effectiveResult,
      Value<int?> closedAt,
      Value<int?> sealTimestamp,
      Value<String?> muteCause,
      Value<String?> previousResult,
      Value<int> rowid,
    });
typedef $$DaysTableUpdateCompanionBuilder =
    DaysCompanion Function({
      Value<String> operationalDate,
      Value<String> baseResult,
      Value<String> effectiveResult,
      Value<int?> closedAt,
      Value<int?> sealTimestamp,
      Value<String?> muteCause,
      Value<String?> previousResult,
      Value<int> rowid,
    });

final class $$DaysTableReferences
    extends BaseReferences<_$RitmoDatabase, $DaysTable, Day> {
  $$DaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StudyBlocksTable, List<StudyBlock>>
  _studyBlocksRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.studyBlocks,
    aliasName: 'days__operational_date__study_blocks__operational_date',
  );

  $$StudyBlocksTableProcessedTableManager get studyBlocksRefs {
    final manager = $$StudyBlocksTableTableManager($_db, $_db.studyBlocks)
        .filter(
          (f) => f.operationalDate.operationalDate.sqlEquals(
            $_itemColumn<String>('operational_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_studyBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PillarEntriesTable, List<PillarEntry>>
  _pillarEntriesRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.pillarEntries,
    aliasName: 'days__operational_date__pillar_entries__operational_date',
  );

  $$PillarEntriesTableProcessedTableManager get pillarEntriesRefs {
    final manager = $$PillarEntriesTableTableManager($_db, $_db.pillarEntries)
        .filter(
          (f) => f.operationalDate.operationalDate.sqlEquals(
            $_itemColumn<String>('operational_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_pillarEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PillarWaiversTable, List<PillarWaiver>>
  _pillarWaiversRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.pillarWaivers,
    aliasName: 'days__operational_date__pillar_waivers__date',
  );

  $$PillarWaiversTableProcessedTableManager get pillarWaiversRefs {
    final manager = $$PillarWaiversTableTableManager($_db, $_db.pillarWaivers)
        .filter(
          (f) => f.date.operationalDate.sqlEquals(
            $_itemColumn<String>('operational_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_pillarWaiversRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProtocolAlarmsTable, List<ProtocolAlarm>>
  _protocolStartTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.protocolAlarms,
    aliasName: 'days__operational_date__protocol_alarms__start_date',
  );

  $$ProtocolAlarmsTableProcessedTableManager get protocolStart {
    final manager = $$ProtocolAlarmsTableTableManager($_db, $_db.protocolAlarms)
        .filter(
          (f) => f.startDate.operationalDate.sqlEquals(
            $_itemColumn<String>('operational_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_protocolStartTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProtocolAlarmsTable, List<ProtocolAlarm>>
  _protocolEndTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.protocolAlarms,
    aliasName: 'days__operational_date__protocol_alarms__end_date',
  );

  $$ProtocolAlarmsTableProcessedTableManager get protocolEnd {
    final manager = $$ProtocolAlarmsTableTableManager($_db, $_db.protocolAlarms)
        .filter(
          (f) => f.endDate.operationalDate.sqlEquals(
            $_itemColumn<String>('operational_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_protocolEndTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HolidaysTable, List<Holiday>> _holidaysRefsTable(
    _$RitmoDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.holidays,
    aliasName: 'days__operational_date__holidays__operational_date',
  );

  $$HolidaysTableProcessedTableManager get holidaysRefs {
    final manager = $$HolidaysTableTableManager($_db, $_db.holidays).filter(
      (f) => f.operationalDate.operationalDate.sqlEquals(
        $_itemColumn<String>('operational_date')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_holidaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DaysTableFilterComposer extends Composer<_$RitmoDatabase, $DaysTable> {
  $$DaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationalDate => $composableBuilder(
    column: $table.operationalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseResult => $composableBuilder(
    column: $table.baseResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveResult => $composableBuilder(
    column: $table.effectiveResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sealTimestamp => $composableBuilder(
    column: $table.sealTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muteCause => $composableBuilder(
    column: $table.muteCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousResult => $composableBuilder(
    column: $table.previousResult,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> studyBlocksRefs(
    Expression<bool> Function($$StudyBlocksTableFilterComposer f) f,
  ) {
    final $$StudyBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.studyBlocks,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyBlocksTableFilterComposer(
            $db: $db,
            $table: $db.studyBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pillarEntriesRefs(
    Expression<bool> Function($$PillarEntriesTableFilterComposer f) f,
  ) {
    final $$PillarEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableFilterComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pillarWaiversRefs(
    Expression<bool> Function($$PillarWaiversTableFilterComposer f) f,
  ) {
    final $$PillarWaiversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.pillarWaivers,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarWaiversTableFilterComposer(
            $db: $db,
            $table: $db.pillarWaivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> protocolStart(
    Expression<bool> Function($$ProtocolAlarmsTableFilterComposer f) f,
  ) {
    final $$ProtocolAlarmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.protocolAlarms,
      getReferencedColumn: (t) => t.startDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProtocolAlarmsTableFilterComposer(
            $db: $db,
            $table: $db.protocolAlarms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> protocolEnd(
    Expression<bool> Function($$ProtocolAlarmsTableFilterComposer f) f,
  ) {
    final $$ProtocolAlarmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.protocolAlarms,
      getReferencedColumn: (t) => t.endDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProtocolAlarmsTableFilterComposer(
            $db: $db,
            $table: $db.protocolAlarms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> holidaysRefs(
    Expression<bool> Function($$HolidaysTableFilterComposer f) f,
  ) {
    final $$HolidaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.holidays,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HolidaysTableFilterComposer(
            $db: $db,
            $table: $db.holidays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableOrderingComposer
    extends Composer<_$RitmoDatabase, $DaysTable> {
  $$DaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationalDate => $composableBuilder(
    column: $table.operationalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseResult => $composableBuilder(
    column: $table.baseResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveResult => $composableBuilder(
    column: $table.effectiveResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sealTimestamp => $composableBuilder(
    column: $table.sealTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muteCause => $composableBuilder(
    column: $table.muteCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousResult => $composableBuilder(
    column: $table.previousResult,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DaysTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $DaysTable> {
  $$DaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationalDate => $composableBuilder(
    column: $table.operationalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseResult => $composableBuilder(
    column: $table.baseResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get effectiveResult => $composableBuilder(
    column: $table.effectiveResult,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get sealTimestamp => $composableBuilder(
    column: $table.sealTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get muteCause =>
      $composableBuilder(column: $table.muteCause, builder: (column) => column);

  GeneratedColumn<String> get previousResult => $composableBuilder(
    column: $table.previousResult,
    builder: (column) => column,
  );

  Expression<T> studyBlocksRefs<T extends Object>(
    Expression<T> Function($$StudyBlocksTableAnnotationComposer a) f,
  ) {
    final $$StudyBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.studyBlocks,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.studyBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pillarEntriesRefs<T extends Object>(
    Expression<T> Function($$PillarEntriesTableAnnotationComposer a) f,
  ) {
    final $$PillarEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pillarWaiversRefs<T extends Object>(
    Expression<T> Function($$PillarWaiversTableAnnotationComposer a) f,
  ) {
    final $$PillarWaiversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.pillarWaivers,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarWaiversTableAnnotationComposer(
            $db: $db,
            $table: $db.pillarWaivers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> protocolStart<T extends Object>(
    Expression<T> Function($$ProtocolAlarmsTableAnnotationComposer a) f,
  ) {
    final $$ProtocolAlarmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.protocolAlarms,
      getReferencedColumn: (t) => t.startDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProtocolAlarmsTableAnnotationComposer(
            $db: $db,
            $table: $db.protocolAlarms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> protocolEnd<T extends Object>(
    Expression<T> Function($$ProtocolAlarmsTableAnnotationComposer a) f,
  ) {
    final $$ProtocolAlarmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.protocolAlarms,
      getReferencedColumn: (t) => t.endDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProtocolAlarmsTableAnnotationComposer(
            $db: $db,
            $table: $db.protocolAlarms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> holidaysRefs<T extends Object>(
    Expression<T> Function($$HolidaysTableAnnotationComposer a) f,
  ) {
    final $$HolidaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.holidays,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HolidaysTableAnnotationComposer(
            $db: $db,
            $table: $db.holidays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $DaysTable,
          Day,
          $$DaysTableFilterComposer,
          $$DaysTableOrderingComposer,
          $$DaysTableAnnotationComposer,
          $$DaysTableCreateCompanionBuilder,
          $$DaysTableUpdateCompanionBuilder,
          (Day, $$DaysTableReferences),
          Day,
          PrefetchHooks Function({
            bool studyBlocksRefs,
            bool pillarEntriesRefs,
            bool pillarWaiversRefs,
            bool protocolStart,
            bool protocolEnd,
            bool holidaysRefs,
          })
        > {
  $$DaysTableTableManager(_$RitmoDatabase db, $DaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationalDate = const Value.absent(),
                Value<String> baseResult = const Value.absent(),
                Value<String> effectiveResult = const Value.absent(),
                Value<int?> closedAt = const Value.absent(),
                Value<int?> sealTimestamp = const Value.absent(),
                Value<String?> muteCause = const Value.absent(),
                Value<String?> previousResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaysCompanion(
                operationalDate: operationalDate,
                baseResult: baseResult,
                effectiveResult: effectiveResult,
                closedAt: closedAt,
                sealTimestamp: sealTimestamp,
                muteCause: muteCause,
                previousResult: previousResult,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationalDate,
                required String baseResult,
                required String effectiveResult,
                Value<int?> closedAt = const Value.absent(),
                Value<int?> sealTimestamp = const Value.absent(),
                Value<String?> muteCause = const Value.absent(),
                Value<String?> previousResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaysCompanion.insert(
                operationalDate: operationalDate,
                baseResult: baseResult,
                effectiveResult: effectiveResult,
                closedAt: closedAt,
                sealTimestamp: sealTimestamp,
                muteCause: muteCause,
                previousResult: previousResult,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DaysTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                studyBlocksRefs = false,
                pillarEntriesRefs = false,
                pillarWaiversRefs = false,
                protocolStart = false,
                protocolEnd = false,
                holidaysRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (studyBlocksRefs) db.studyBlocks,
                    if (pillarEntriesRefs) db.pillarEntries,
                    if (pillarWaiversRefs) db.pillarWaivers,
                    if (protocolStart) db.protocolAlarms,
                    if (protocolEnd) db.protocolAlarms,
                    if (holidaysRefs) db.holidays,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (studyBlocksRefs)
                        await $_getPrefetchedData<Day, $DaysTable, StudyBlock>(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._studyBlocksRefsTable(db),
                          managerFromTypedResult: (p0) => $$DaysTableReferences(
                            db,
                            table,
                            p0,
                          ).studyBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.operationalDate == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                      if (pillarEntriesRefs)
                        await $_getPrefetchedData<Day, $DaysTable, PillarEntry>(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._pillarEntriesRefsTable(db),
                          managerFromTypedResult: (p0) => $$DaysTableReferences(
                            db,
                            table,
                            p0,
                          ).pillarEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.operationalDate == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                      if (pillarWaiversRefs)
                        await $_getPrefetchedData<
                          Day,
                          $DaysTable,
                          PillarWaiver
                        >(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._pillarWaiversRefsTable(db),
                          managerFromTypedResult: (p0) => $$DaysTableReferences(
                            db,
                            table,
                            p0,
                          ).pillarWaiversRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.date == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                      if (protocolStart)
                        await $_getPrefetchedData<
                          Day,
                          $DaysTable,
                          ProtocolAlarm
                        >(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._protocolStartTable(db),
                          managerFromTypedResult: (p0) => $$DaysTableReferences(
                            db,
                            table,
                            p0,
                          ).protocolStart,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.startDate == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                      if (protocolEnd)
                        await $_getPrefetchedData<
                          Day,
                          $DaysTable,
                          ProtocolAlarm
                        >(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._protocolEndTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DaysTableReferences(db, table, p0).protocolEnd,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.endDate == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                      if (holidaysRefs)
                        await $_getPrefetchedData<Day, $DaysTable, Holiday>(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._holidaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DaysTableReferences(db, table, p0).holidaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.operationalDate == item.operationalDate,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DaysTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $DaysTable,
      Day,
      $$DaysTableFilterComposer,
      $$DaysTableOrderingComposer,
      $$DaysTableAnnotationComposer,
      $$DaysTableCreateCompanionBuilder,
      $$DaysTableUpdateCompanionBuilder,
      (Day, $$DaysTableReferences),
      Day,
      PrefetchHooks Function({
        bool studyBlocksRefs,
        bool pillarEntriesRefs,
        bool pillarWaiversRefs,
        bool protocolStart,
        bool protocolEnd,
        bool holidaysRefs,
      })
    >;
typedef $$StudyBlocksTableCreateCompanionBuilder =
    StudyBlocksCompanion Function({
      required String id,
      required String operationalDate,
      required int startedAt,
      required int blockDeadline,
      Value<int?> endedAt,
      Value<int> rowid,
    });
typedef $$StudyBlocksTableUpdateCompanionBuilder =
    StudyBlocksCompanion Function({
      Value<String> id,
      Value<String> operationalDate,
      Value<int> startedAt,
      Value<int> blockDeadline,
      Value<int?> endedAt,
      Value<int> rowid,
    });

final class $$StudyBlocksTableReferences
    extends BaseReferences<_$RitmoDatabase, $StudyBlocksTable, StudyBlock> {
  $$StudyBlocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _operationalDateTable(_$RitmoDatabase db) => db.days
      .createAlias('study_blocks__operational_date__days__operational_date');

  $$DaysTableProcessedTableManager get operationalDate {
    final $_column = $_itemColumn<String>('operational_date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operationalDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PillarEntriesTable, List<PillarEntry>>
  _pillarEntriesRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.pillarEntries,
    aliasName: 'study_blocks__id__pillar_entries__study_block_id',
  );

  $$PillarEntriesTableProcessedTableManager get pillarEntriesRefs {
    final manager = $$PillarEntriesTableTableManager(
      $_db,
      $_db.pillarEntries,
    ).filter((f) => f.studyBlockId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pillarEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudyBlocksTableFilterComposer
    extends Composer<_$RitmoDatabase, $StudyBlocksTable> {
  $$StudyBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockDeadline => $composableBuilder(
    column: $table.blockDeadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get operationalDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pillarEntriesRefs(
    Expression<bool> Function($$PillarEntriesTableFilterComposer f) f,
  ) {
    final $$PillarEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.studyBlockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableFilterComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudyBlocksTableOrderingComposer
    extends Composer<_$RitmoDatabase, $StudyBlocksTable> {
  $$StudyBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockDeadline => $composableBuilder(
    column: $table.blockDeadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get operationalDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudyBlocksTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $StudyBlocksTable> {
  $$StudyBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get blockDeadline => $composableBuilder(
    column: $table.blockDeadline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  $$DaysTableAnnotationComposer get operationalDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pillarEntriesRefs<T extends Object>(
    Expression<T> Function($$PillarEntriesTableAnnotationComposer a) f,
  ) {
    final $$PillarEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.studyBlockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudyBlocksTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $StudyBlocksTable,
          StudyBlock,
          $$StudyBlocksTableFilterComposer,
          $$StudyBlocksTableOrderingComposer,
          $$StudyBlocksTableAnnotationComposer,
          $$StudyBlocksTableCreateCompanionBuilder,
          $$StudyBlocksTableUpdateCompanionBuilder,
          (StudyBlock, $$StudyBlocksTableReferences),
          StudyBlock,
          PrefetchHooks Function({bool operationalDate, bool pillarEntriesRefs})
        > {
  $$StudyBlocksTableTableManager(_$RitmoDatabase db, $StudyBlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationalDate = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> blockDeadline = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyBlocksCompanion(
                id: id,
                operationalDate: operationalDate,
                startedAt: startedAt,
                blockDeadline: blockDeadline,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationalDate,
                required int startedAt,
                required int blockDeadline,
                Value<int?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyBlocksCompanion.insert(
                id: id,
                operationalDate: operationalDate,
                startedAt: startedAt,
                blockDeadline: blockDeadline,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudyBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({operationalDate = false, pillarEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pillarEntriesRefs) db.pillarEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (operationalDate) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.operationalDate,
                                    referencedTable:
                                        $$StudyBlocksTableReferences
                                            ._operationalDateTable(db),
                                    referencedColumn:
                                        $$StudyBlocksTableReferences
                                            ._operationalDateTable(db)
                                            .operationalDate,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pillarEntriesRefs)
                        await $_getPrefetchedData<
                          StudyBlock,
                          $StudyBlocksTable,
                          PillarEntry
                        >(
                          currentTable: table,
                          referencedTable: $$StudyBlocksTableReferences
                              ._pillarEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudyBlocksTableReferences(
                                db,
                                table,
                                p0,
                              ).pillarEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studyBlockId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudyBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $StudyBlocksTable,
      StudyBlock,
      $$StudyBlocksTableFilterComposer,
      $$StudyBlocksTableOrderingComposer,
      $$StudyBlocksTableAnnotationComposer,
      $$StudyBlocksTableCreateCompanionBuilder,
      $$StudyBlocksTableUpdateCompanionBuilder,
      (StudyBlock, $$StudyBlocksTableReferences),
      StudyBlock,
      PrefetchHooks Function({bool operationalDate, bool pillarEntriesRefs})
    >;
typedef $$AudioAssetsTableCreateCompanionBuilder =
    AudioAssetsCompanion Function({
      required String id,
      required String relativePath,
      required String kind,
      required int durationMs,
      required int byteSize,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$AudioAssetsTableUpdateCompanionBuilder =
    AudioAssetsCompanion Function({
      Value<String> id,
      Value<String> relativePath,
      Value<String> kind,
      Value<int> durationMs,
      Value<int> byteSize,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$AudioAssetsTableReferences
    extends BaseReferences<_$RitmoDatabase, $AudioAssetsTable, AudioAsset> {
  $$AudioAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PillarEntriesTable, List<PillarEntry>>
  _pillarEntriesRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.pillarEntries,
    aliasName: 'audio_assets__id__pillar_entries__note_audio_id',
  );

  $$PillarEntriesTableProcessedTableManager get pillarEntriesRefs {
    final manager = $$PillarEntriesTableTableManager(
      $_db,
      $_db.pillarEntries,
    ).filter((f) => f.noteAudioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pillarEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeeklyReviewsTable, List<WeeklyReview>>
  _weeklyReviewsRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.weeklyReviews,
    aliasName: 'audio_assets__id__weekly_reviews__audio_id',
  );

  $$WeeklyReviewsTableProcessedTableManager get weeklyReviewsRefs {
    final manager = $$WeeklyReviewsTableTableManager(
      $_db,
      $_db.weeklyReviews,
    ).filter((f) => f.audioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_weeklyReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AudioAssetsTableFilterComposer
    extends Composer<_$RitmoDatabase, $AudioAssetsTable> {
  $$AudioAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pillarEntriesRefs(
    Expression<bool> Function($$PillarEntriesTableFilterComposer f) f,
  ) {
    final $$PillarEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.noteAudioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableFilterComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weeklyReviewsRefs(
    Expression<bool> Function($$WeeklyReviewsTableFilterComposer f) f,
  ) {
    final $$WeeklyReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeklyReviews,
      getReferencedColumn: (t) => t.audioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyReviewsTableFilterComposer(
            $db: $db,
            $table: $db.weeklyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AudioAssetsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $AudioAssetsTable> {
  $$AudioAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioAssetsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $AudioAssetsTable> {
  $$AudioAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> pillarEntriesRefs<T extends Object>(
    Expression<T> Function($$PillarEntriesTableAnnotationComposer a) f,
  ) {
    final $$PillarEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.noteAudioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> weeklyReviewsRefs<T extends Object>(
    Expression<T> Function($$WeeklyReviewsTableAnnotationComposer a) f,
  ) {
    final $$WeeklyReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeklyReviews,
      getReferencedColumn: (t) => t.audioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.weeklyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AudioAssetsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $AudioAssetsTable,
          AudioAsset,
          $$AudioAssetsTableFilterComposer,
          $$AudioAssetsTableOrderingComposer,
          $$AudioAssetsTableAnnotationComposer,
          $$AudioAssetsTableCreateCompanionBuilder,
          $$AudioAssetsTableUpdateCompanionBuilder,
          (AudioAsset, $$AudioAssetsTableReferences),
          AudioAsset,
          PrefetchHooks Function({
            bool pillarEntriesRefs,
            bool weeklyReviewsRefs,
          })
        > {
  $$AudioAssetsTableTableManager(_$RitmoDatabase db, $AudioAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioAssetsCompanion(
                id: id,
                relativePath: relativePath,
                kind: kind,
                durationMs: durationMs,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String relativePath,
                required String kind,
                required int durationMs,
                required int byteSize,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AudioAssetsCompanion.insert(
                id: id,
                relativePath: relativePath,
                kind: kind,
                durationMs: durationMs,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AudioAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({pillarEntriesRefs = false, weeklyReviewsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pillarEntriesRefs) db.pillarEntries,
                    if (weeklyReviewsRefs) db.weeklyReviews,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pillarEntriesRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          $AudioAssetsTable,
                          PillarEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AudioAssetsTableReferences
                              ._pillarEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AudioAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).pillarEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteAudioId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (weeklyReviewsRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          $AudioAssetsTable,
                          WeeklyReview
                        >(
                          currentTable: table,
                          referencedTable: $$AudioAssetsTableReferences
                              ._weeklyReviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AudioAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).weeklyReviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.audioId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AudioAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $AudioAssetsTable,
      AudioAsset,
      $$AudioAssetsTableFilterComposer,
      $$AudioAssetsTableOrderingComposer,
      $$AudioAssetsTableAnnotationComposer,
      $$AudioAssetsTableCreateCompanionBuilder,
      $$AudioAssetsTableUpdateCompanionBuilder,
      (AudioAsset, $$AudioAssetsTableReferences),
      AudioAsset,
      PrefetchHooks Function({bool pillarEntriesRefs, bool weeklyReviewsRefs})
    >;
typedef $$ChangeInitiativesTableCreateCompanionBuilder =
    ChangeInitiativesCompanion Function({
      required String id,
      required String name,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$ChangeInitiativesTableUpdateCompanionBuilder =
    ChangeInitiativesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$ChangeInitiativesTableReferences
    extends
        BaseReferences<
          _$RitmoDatabase,
          $ChangeInitiativesTable,
          ChangeInitiative
        > {
  $$ChangeInitiativesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PillarEntriesTable, List<PillarEntry>>
  _pillarEntriesRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.pillarEntries,
    aliasName: 'change_initiatives__id__pillar_entries__change_initiative_id',
  );

  $$PillarEntriesTableProcessedTableManager get pillarEntriesRefs {
    final manager = $$PillarEntriesTableTableManager($_db, $_db.pillarEntries)
        .filter(
          (f) => f.changeInitiativeId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_pillarEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChangeInitiativesTableFilterComposer
    extends Composer<_$RitmoDatabase, $ChangeInitiativesTable> {
  $$ChangeInitiativesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pillarEntriesRefs(
    Expression<bool> Function($$PillarEntriesTableFilterComposer f) f,
  ) {
    final $$PillarEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.changeInitiativeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableFilterComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChangeInitiativesTableOrderingComposer
    extends Composer<_$RitmoDatabase, $ChangeInitiativesTable> {
  $$ChangeInitiativesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChangeInitiativesTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $ChangeInitiativesTable> {
  $$ChangeInitiativesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> pillarEntriesRefs<T extends Object>(
    Expression<T> Function($$PillarEntriesTableAnnotationComposer a) f,
  ) {
    final $$PillarEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pillarEntries,
      getReferencedColumn: (t) => t.changeInitiativeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PillarEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.pillarEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChangeInitiativesTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $ChangeInitiativesTable,
          ChangeInitiative,
          $$ChangeInitiativesTableFilterComposer,
          $$ChangeInitiativesTableOrderingComposer,
          $$ChangeInitiativesTableAnnotationComposer,
          $$ChangeInitiativesTableCreateCompanionBuilder,
          $$ChangeInitiativesTableUpdateCompanionBuilder,
          (ChangeInitiative, $$ChangeInitiativesTableReferences),
          ChangeInitiative,
          PrefetchHooks Function({bool pillarEntriesRefs})
        > {
  $$ChangeInitiativesTableTableManager(
    _$RitmoDatabase db,
    $ChangeInitiativesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeInitiativesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeInitiativesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeInitiativesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeInitiativesCompanion(
                id: id,
                name: name,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeInitiativesCompanion.insert(
                id: id,
                name: name,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChangeInitiativesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pillarEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pillarEntriesRefs) db.pillarEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pillarEntriesRefs)
                    await $_getPrefetchedData<
                      ChangeInitiative,
                      $ChangeInitiativesTable,
                      PillarEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ChangeInitiativesTableReferences
                          ._pillarEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChangeInitiativesTableReferences(
                            db,
                            table,
                            p0,
                          ).pillarEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.changeInitiativeId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChangeInitiativesTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $ChangeInitiativesTable,
      ChangeInitiative,
      $$ChangeInitiativesTableFilterComposer,
      $$ChangeInitiativesTableOrderingComposer,
      $$ChangeInitiativesTableAnnotationComposer,
      $$ChangeInitiativesTableCreateCompanionBuilder,
      $$ChangeInitiativesTableUpdateCompanionBuilder,
      (ChangeInitiative, $$ChangeInitiativesTableReferences),
      ChangeInitiative,
      PrefetchHooks Function({bool pillarEntriesRefs})
    >;
typedef $$PillarEntriesTableCreateCompanionBuilder =
    PillarEntriesCompanion Function({
      required String operationalDate,
      required String pillar,
      Value<bool> workoutDone,
      Value<bool> briefingDone,
      Value<String?> briefingMode,
      Value<int?> workoutAt,
      Value<int?> briefingAt,
      Value<bool> toggleOn,
      Value<String?> changeInitiativeId,
      Value<String?> noteText,
      Value<String?> noteAudioId,
      Value<String?> nightKind,
      Value<String?> recoveryNote,
      Value<String?> studyBlockId,
      Value<int> rowid,
    });
typedef $$PillarEntriesTableUpdateCompanionBuilder =
    PillarEntriesCompanion Function({
      Value<String> operationalDate,
      Value<String> pillar,
      Value<bool> workoutDone,
      Value<bool> briefingDone,
      Value<String?> briefingMode,
      Value<int?> workoutAt,
      Value<int?> briefingAt,
      Value<bool> toggleOn,
      Value<String?> changeInitiativeId,
      Value<String?> noteText,
      Value<String?> noteAudioId,
      Value<String?> nightKind,
      Value<String?> recoveryNote,
      Value<String?> studyBlockId,
      Value<int> rowid,
    });

final class $$PillarEntriesTableReferences
    extends BaseReferences<_$RitmoDatabase, $PillarEntriesTable, PillarEntry> {
  $$PillarEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DaysTable _operationalDateTable(_$RitmoDatabase db) => db.days
      .createAlias('pillar_entries__operational_date__days__operational_date');

  $$DaysTableProcessedTableManager get operationalDate {
    final $_column = $_itemColumn<String>('operational_date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operationalDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChangeInitiativesTable _changeInitiativeIdTable(_$RitmoDatabase db) =>
      db.changeInitiatives.createAlias(
        'pillar_entries__change_initiative_id__change_initiatives__id',
      );

  $$ChangeInitiativesTableProcessedTableManager? get changeInitiativeId {
    final $_column = $_itemColumn<String>('change_initiative_id');
    if ($_column == null) return null;
    final manager = $$ChangeInitiativesTableTableManager(
      $_db,
      $_db.changeInitiatives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_changeInitiativeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AudioAssetsTable _noteAudioIdTable(_$RitmoDatabase db) => db
      .audioAssets
      .createAlias('pillar_entries__note_audio_id__audio_assets__id');

  $$AudioAssetsTableProcessedTableManager? get noteAudioId {
    final $_column = $_itemColumn<String>('note_audio_id');
    if ($_column == null) return null;
    final manager = $$AudioAssetsTableTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteAudioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudyBlocksTable _studyBlockIdTable(_$RitmoDatabase db) => db
      .studyBlocks
      .createAlias('pillar_entries__study_block_id__study_blocks__id');

  $$StudyBlocksTableProcessedTableManager? get studyBlockId {
    final $_column = $_itemColumn<String>('study_block_id');
    if ($_column == null) return null;
    final manager = $$StudyBlocksTableTableManager(
      $_db,
      $_db.studyBlocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studyBlockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PillarEntriesTableFilterComposer
    extends Composer<_$RitmoDatabase, $PillarEntriesTable> {
  $$PillarEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pillar => $composableBuilder(
    column: $table.pillar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get workoutDone => $composableBuilder(
    column: $table.workoutDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get briefingDone => $composableBuilder(
    column: $table.briefingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get briefingMode => $composableBuilder(
    column: $table.briefingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workoutAt => $composableBuilder(
    column: $table.workoutAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get briefingAt => $composableBuilder(
    column: $table.briefingAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get toggleOn => $composableBuilder(
    column: $table.toggleOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nightKind => $composableBuilder(
    column: $table.nightKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryNote => $composableBuilder(
    column: $table.recoveryNote,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get operationalDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChangeInitiativesTableFilterComposer get changeInitiativeId {
    final $$ChangeInitiativesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changeInitiativeId,
      referencedTable: $db.changeInitiatives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeInitiativesTableFilterComposer(
            $db: $db,
            $table: $db.changeInitiatives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AudioAssetsTableFilterComposer get noteAudioId {
    final $$AudioAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteAudioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudyBlocksTableFilterComposer get studyBlockId {
    final $$StudyBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studyBlockId,
      referencedTable: $db.studyBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyBlocksTableFilterComposer(
            $db: $db,
            $table: $db.studyBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarEntriesTableOrderingComposer
    extends Composer<_$RitmoDatabase, $PillarEntriesTable> {
  $$PillarEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pillar => $composableBuilder(
    column: $table.pillar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get workoutDone => $composableBuilder(
    column: $table.workoutDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get briefingDone => $composableBuilder(
    column: $table.briefingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get briefingMode => $composableBuilder(
    column: $table.briefingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workoutAt => $composableBuilder(
    column: $table.workoutAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get briefingAt => $composableBuilder(
    column: $table.briefingAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get toggleOn => $composableBuilder(
    column: $table.toggleOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nightKind => $composableBuilder(
    column: $table.nightKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryNote => $composableBuilder(
    column: $table.recoveryNote,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get operationalDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChangeInitiativesTableOrderingComposer get changeInitiativeId {
    final $$ChangeInitiativesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changeInitiativeId,
      referencedTable: $db.changeInitiatives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeInitiativesTableOrderingComposer(
            $db: $db,
            $table: $db.changeInitiatives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AudioAssetsTableOrderingComposer get noteAudioId {
    final $$AudioAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteAudioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudyBlocksTableOrderingComposer get studyBlockId {
    final $$StudyBlocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studyBlockId,
      referencedTable: $db.studyBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyBlocksTableOrderingComposer(
            $db: $db,
            $table: $db.studyBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarEntriesTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $PillarEntriesTable> {
  $$PillarEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pillar =>
      $composableBuilder(column: $table.pillar, builder: (column) => column);

  GeneratedColumn<bool> get workoutDone => $composableBuilder(
    column: $table.workoutDone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get briefingDone => $composableBuilder(
    column: $table.briefingDone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get briefingMode => $composableBuilder(
    column: $table.briefingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workoutAt =>
      $composableBuilder(column: $table.workoutAt, builder: (column) => column);

  GeneratedColumn<int> get briefingAt => $composableBuilder(
    column: $table.briefingAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get toggleOn =>
      $composableBuilder(column: $table.toggleOn, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

  GeneratedColumn<String> get nightKind =>
      $composableBuilder(column: $table.nightKind, builder: (column) => column);

  GeneratedColumn<String> get recoveryNote => $composableBuilder(
    column: $table.recoveryNote,
    builder: (column) => column,
  );

  $$DaysTableAnnotationComposer get operationalDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChangeInitiativesTableAnnotationComposer get changeInitiativeId {
    final $$ChangeInitiativesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.changeInitiativeId,
          referencedTable: $db.changeInitiatives,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChangeInitiativesTableAnnotationComposer(
                $db: $db,
                $table: $db.changeInitiatives,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AudioAssetsTableAnnotationComposer get noteAudioId {
    final $$AudioAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteAudioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudyBlocksTableAnnotationComposer get studyBlockId {
    final $$StudyBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studyBlockId,
      referencedTable: $db.studyBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.studyBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarEntriesTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $PillarEntriesTable,
          PillarEntry,
          $$PillarEntriesTableFilterComposer,
          $$PillarEntriesTableOrderingComposer,
          $$PillarEntriesTableAnnotationComposer,
          $$PillarEntriesTableCreateCompanionBuilder,
          $$PillarEntriesTableUpdateCompanionBuilder,
          (PillarEntry, $$PillarEntriesTableReferences),
          PillarEntry,
          PrefetchHooks Function({
            bool operationalDate,
            bool changeInitiativeId,
            bool noteAudioId,
            bool studyBlockId,
          })
        > {
  $$PillarEntriesTableTableManager(
    _$RitmoDatabase db,
    $PillarEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PillarEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PillarEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PillarEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationalDate = const Value.absent(),
                Value<String> pillar = const Value.absent(),
                Value<bool> workoutDone = const Value.absent(),
                Value<bool> briefingDone = const Value.absent(),
                Value<String?> briefingMode = const Value.absent(),
                Value<int?> workoutAt = const Value.absent(),
                Value<int?> briefingAt = const Value.absent(),
                Value<bool> toggleOn = const Value.absent(),
                Value<String?> changeInitiativeId = const Value.absent(),
                Value<String?> noteText = const Value.absent(),
                Value<String?> noteAudioId = const Value.absent(),
                Value<String?> nightKind = const Value.absent(),
                Value<String?> recoveryNote = const Value.absent(),
                Value<String?> studyBlockId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PillarEntriesCompanion(
                operationalDate: operationalDate,
                pillar: pillar,
                workoutDone: workoutDone,
                briefingDone: briefingDone,
                briefingMode: briefingMode,
                workoutAt: workoutAt,
                briefingAt: briefingAt,
                toggleOn: toggleOn,
                changeInitiativeId: changeInitiativeId,
                noteText: noteText,
                noteAudioId: noteAudioId,
                nightKind: nightKind,
                recoveryNote: recoveryNote,
                studyBlockId: studyBlockId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationalDate,
                required String pillar,
                Value<bool> workoutDone = const Value.absent(),
                Value<bool> briefingDone = const Value.absent(),
                Value<String?> briefingMode = const Value.absent(),
                Value<int?> workoutAt = const Value.absent(),
                Value<int?> briefingAt = const Value.absent(),
                Value<bool> toggleOn = const Value.absent(),
                Value<String?> changeInitiativeId = const Value.absent(),
                Value<String?> noteText = const Value.absent(),
                Value<String?> noteAudioId = const Value.absent(),
                Value<String?> nightKind = const Value.absent(),
                Value<String?> recoveryNote = const Value.absent(),
                Value<String?> studyBlockId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PillarEntriesCompanion.insert(
                operationalDate: operationalDate,
                pillar: pillar,
                workoutDone: workoutDone,
                briefingDone: briefingDone,
                briefingMode: briefingMode,
                workoutAt: workoutAt,
                briefingAt: briefingAt,
                toggleOn: toggleOn,
                changeInitiativeId: changeInitiativeId,
                noteText: noteText,
                noteAudioId: noteAudioId,
                nightKind: nightKind,
                recoveryNote: recoveryNote,
                studyBlockId: studyBlockId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PillarEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                operationalDate = false,
                changeInitiativeId = false,
                noteAudioId = false,
                studyBlockId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (operationalDate) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.operationalDate,
                                    referencedTable:
                                        $$PillarEntriesTableReferences
                                            ._operationalDateTable(db),
                                    referencedColumn:
                                        $$PillarEntriesTableReferences
                                            ._operationalDateTable(db)
                                            .operationalDate,
                                  )
                                  as T;
                        }
                        if (changeInitiativeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.changeInitiativeId,
                                    referencedTable:
                                        $$PillarEntriesTableReferences
                                            ._changeInitiativeIdTable(db),
                                    referencedColumn:
                                        $$PillarEntriesTableReferences
                                            ._changeInitiativeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (noteAudioId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.noteAudioId,
                                    referencedTable:
                                        $$PillarEntriesTableReferences
                                            ._noteAudioIdTable(db),
                                    referencedColumn:
                                        $$PillarEntriesTableReferences
                                            ._noteAudioIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (studyBlockId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studyBlockId,
                                    referencedTable:
                                        $$PillarEntriesTableReferences
                                            ._studyBlockIdTable(db),
                                    referencedColumn:
                                        $$PillarEntriesTableReferences
                                            ._studyBlockIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PillarEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $PillarEntriesTable,
      PillarEntry,
      $$PillarEntriesTableFilterComposer,
      $$PillarEntriesTableOrderingComposer,
      $$PillarEntriesTableAnnotationComposer,
      $$PillarEntriesTableCreateCompanionBuilder,
      $$PillarEntriesTableUpdateCompanionBuilder,
      (PillarEntry, $$PillarEntriesTableReferences),
      PillarEntry,
      PrefetchHooks Function({
        bool operationalDate,
        bool changeInitiativeId,
        bool noteAudioId,
        bool studyBlockId,
      })
    >;
typedef $$PillarWaiversTableCreateCompanionBuilder =
    PillarWaiversCompanion Function({
      required String id,
      required String date,
      required String pillar,
      required String reasonText,
      Value<bool> recurrenceConfirmed,
      Value<int?> revokedAt,
      Value<int> rowid,
    });
typedef $$PillarWaiversTableUpdateCompanionBuilder =
    PillarWaiversCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> pillar,
      Value<String> reasonText,
      Value<bool> recurrenceConfirmed,
      Value<int?> revokedAt,
      Value<int> rowid,
    });

final class $$PillarWaiversTableReferences
    extends BaseReferences<_$RitmoDatabase, $PillarWaiversTable, PillarWaiver> {
  $$PillarWaiversTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DaysTable _dateTable(_$RitmoDatabase db) =>
      db.days.createAlias('pillar_waivers__date__days__operational_date');

  $$DaysTableProcessedTableManager get date {
    final $_column = $_itemColumn<String>('date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PillarWaiversTableFilterComposer
    extends Composer<_$RitmoDatabase, $PillarWaiversTable> {
  $$PillarWaiversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pillar => $composableBuilder(
    column: $table.pillar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recurrenceConfirmed => $composableBuilder(
    column: $table.recurrenceConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get date {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarWaiversTableOrderingComposer
    extends Composer<_$RitmoDatabase, $PillarWaiversTable> {
  $$PillarWaiversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pillar => $composableBuilder(
    column: $table.pillar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recurrenceConfirmed => $composableBuilder(
    column: $table.recurrenceConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get date {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarWaiversTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $PillarWaiversTable> {
  $$PillarWaiversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pillar =>
      $composableBuilder(column: $table.pillar, builder: (column) => column);

  GeneratedColumn<String> get reasonText => $composableBuilder(
    column: $table.reasonText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recurrenceConfirmed => $composableBuilder(
    column: $table.recurrenceConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  $$DaysTableAnnotationComposer get date {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PillarWaiversTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $PillarWaiversTable,
          PillarWaiver,
          $$PillarWaiversTableFilterComposer,
          $$PillarWaiversTableOrderingComposer,
          $$PillarWaiversTableAnnotationComposer,
          $$PillarWaiversTableCreateCompanionBuilder,
          $$PillarWaiversTableUpdateCompanionBuilder,
          (PillarWaiver, $$PillarWaiversTableReferences),
          PillarWaiver,
          PrefetchHooks Function({bool date})
        > {
  $$PillarWaiversTableTableManager(
    _$RitmoDatabase db,
    $PillarWaiversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PillarWaiversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PillarWaiversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PillarWaiversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> pillar = const Value.absent(),
                Value<String> reasonText = const Value.absent(),
                Value<bool> recurrenceConfirmed = const Value.absent(),
                Value<int?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PillarWaiversCompanion(
                id: id,
                date: date,
                pillar: pillar,
                reasonText: reasonText,
                recurrenceConfirmed: recurrenceConfirmed,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String pillar,
                required String reasonText,
                Value<bool> recurrenceConfirmed = const Value.absent(),
                Value<int?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PillarWaiversCompanion.insert(
                id: id,
                date: date,
                pillar: pillar,
                reasonText: reasonText,
                recurrenceConfirmed: recurrenceConfirmed,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PillarWaiversTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({date = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (date) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.date,
                                referencedTable: $$PillarWaiversTableReferences
                                    ._dateTable(db),
                                referencedColumn: $$PillarWaiversTableReferences
                                    ._dateTable(db)
                                    .operationalDate,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PillarWaiversTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $PillarWaiversTable,
      PillarWaiver,
      $$PillarWaiversTableFilterComposer,
      $$PillarWaiversTableOrderingComposer,
      $$PillarWaiversTableAnnotationComposer,
      $$PillarWaiversTableCreateCompanionBuilder,
      $$PillarWaiversTableUpdateCompanionBuilder,
      (PillarWaiver, $$PillarWaiversTableReferences),
      PillarWaiver,
      PrefetchHooks Function({bool date})
    >;
typedef $$ProtocolAlarmsTableCreateCompanionBuilder =
    ProtocolAlarmsCompanion Function({
      required String id,
      required String generationId,
      required String startDate,
      required String endDate,
      required int sequenceLength,
      required String state,
      Value<String?> previousState,
      Value<int?> triggeredAt,
      Value<String?> cause,
      Value<String?> planOrExecution,
      Value<String?> adjustment,
      Value<int> rowid,
    });
typedef $$ProtocolAlarmsTableUpdateCompanionBuilder =
    ProtocolAlarmsCompanion Function({
      Value<String> id,
      Value<String> generationId,
      Value<String> startDate,
      Value<String> endDate,
      Value<int> sequenceLength,
      Value<String> state,
      Value<String?> previousState,
      Value<int?> triggeredAt,
      Value<String?> cause,
      Value<String?> planOrExecution,
      Value<String?> adjustment,
      Value<int> rowid,
    });

final class $$ProtocolAlarmsTableReferences
    extends
        BaseReferences<_$RitmoDatabase, $ProtocolAlarmsTable, ProtocolAlarm> {
  $$ProtocolAlarmsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DaysTable _startDateTable(_$RitmoDatabase db) => db.days.createAlias(
    'protocol_alarms__start_date__days__operational_date',
  );

  $$DaysTableProcessedTableManager get startDate {
    final $_column = $_itemColumn<String>('start_date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_startDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DaysTable _endDateTable(_$RitmoDatabase db) =>
      db.days.createAlias('protocol_alarms__end_date__days__operational_date');

  $$DaysTableProcessedTableManager get endDate {
    final $_column = $_itemColumn<String>('end_date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_endDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProtocolAlarmsTableFilterComposer
    extends Composer<_$RitmoDatabase, $ProtocolAlarmsTable> {
  $$ProtocolAlarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceLength => $composableBuilder(
    column: $table.sequenceLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggeredAt => $composableBuilder(
    column: $table.triggeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planOrExecution => $composableBuilder(
    column: $table.planOrExecution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adjustment => $composableBuilder(
    column: $table.adjustment,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get startDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DaysTableFilterComposer get endDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProtocolAlarmsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $ProtocolAlarmsTable> {
  $$ProtocolAlarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceLength => $composableBuilder(
    column: $table.sequenceLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggeredAt => $composableBuilder(
    column: $table.triggeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planOrExecution => $composableBuilder(
    column: $table.planOrExecution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjustment => $composableBuilder(
    column: $table.adjustment,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get startDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DaysTableOrderingComposer get endDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProtocolAlarmsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $ProtocolAlarmsTable> {
  $$ProtocolAlarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get generationId => $composableBuilder(
    column: $table.generationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequenceLength => $composableBuilder(
    column: $table.sequenceLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get previousState => $composableBuilder(
    column: $table.previousState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get triggeredAt => $composableBuilder(
    column: $table.triggeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cause =>
      $composableBuilder(column: $table.cause, builder: (column) => column);

  GeneratedColumn<String> get planOrExecution => $composableBuilder(
    column: $table.planOrExecution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adjustment => $composableBuilder(
    column: $table.adjustment,
    builder: (column) => column,
  );

  $$DaysTableAnnotationComposer get startDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DaysTableAnnotationComposer get endDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProtocolAlarmsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $ProtocolAlarmsTable,
          ProtocolAlarm,
          $$ProtocolAlarmsTableFilterComposer,
          $$ProtocolAlarmsTableOrderingComposer,
          $$ProtocolAlarmsTableAnnotationComposer,
          $$ProtocolAlarmsTableCreateCompanionBuilder,
          $$ProtocolAlarmsTableUpdateCompanionBuilder,
          (ProtocolAlarm, $$ProtocolAlarmsTableReferences),
          ProtocolAlarm,
          PrefetchHooks Function({bool startDate, bool endDate})
        > {
  $$ProtocolAlarmsTableTableManager(
    _$RitmoDatabase db,
    $ProtocolAlarmsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProtocolAlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProtocolAlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProtocolAlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> generationId = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int> sequenceLength = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> previousState = const Value.absent(),
                Value<int?> triggeredAt = const Value.absent(),
                Value<String?> cause = const Value.absent(),
                Value<String?> planOrExecution = const Value.absent(),
                Value<String?> adjustment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProtocolAlarmsCompanion(
                id: id,
                generationId: generationId,
                startDate: startDate,
                endDate: endDate,
                sequenceLength: sequenceLength,
                state: state,
                previousState: previousState,
                triggeredAt: triggeredAt,
                cause: cause,
                planOrExecution: planOrExecution,
                adjustment: adjustment,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String generationId,
                required String startDate,
                required String endDate,
                required int sequenceLength,
                required String state,
                Value<String?> previousState = const Value.absent(),
                Value<int?> triggeredAt = const Value.absent(),
                Value<String?> cause = const Value.absent(),
                Value<String?> planOrExecution = const Value.absent(),
                Value<String?> adjustment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProtocolAlarmsCompanion.insert(
                id: id,
                generationId: generationId,
                startDate: startDate,
                endDate: endDate,
                sequenceLength: sequenceLength,
                state: state,
                previousState: previousState,
                triggeredAt: triggeredAt,
                cause: cause,
                planOrExecution: planOrExecution,
                adjustment: adjustment,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProtocolAlarmsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({startDate = false, endDate = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (startDate) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.startDate,
                                referencedTable: $$ProtocolAlarmsTableReferences
                                    ._startDateTable(db),
                                referencedColumn:
                                    $$ProtocolAlarmsTableReferences
                                        ._startDateTable(db)
                                        .operationalDate,
                              )
                              as T;
                    }
                    if (endDate) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.endDate,
                                referencedTable: $$ProtocolAlarmsTableReferences
                                    ._endDateTable(db),
                                referencedColumn:
                                    $$ProtocolAlarmsTableReferences
                                        ._endDateTable(db)
                                        .operationalDate,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProtocolAlarmsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $ProtocolAlarmsTable,
      ProtocolAlarm,
      $$ProtocolAlarmsTableFilterComposer,
      $$ProtocolAlarmsTableOrderingComposer,
      $$ProtocolAlarmsTableAnnotationComposer,
      $$ProtocolAlarmsTableCreateCompanionBuilder,
      $$ProtocolAlarmsTableUpdateCompanionBuilder,
      (ProtocolAlarm, $$ProtocolAlarmsTableReferences),
      ProtocolAlarm,
      PrefetchHooks Function({bool startDate, bool endDate})
    >;
typedef $$HolidaysTableCreateCompanionBuilder =
    HolidaysCompanion Function({
      required String operationalDate,
      required bool active,
      required int createdAt,
      Value<int?> removedAt,
      Value<String?> applyReasonText,
      Value<String?> removeReasonText,
      Value<int> rowid,
    });
typedef $$HolidaysTableUpdateCompanionBuilder =
    HolidaysCompanion Function({
      Value<String> operationalDate,
      Value<bool> active,
      Value<int> createdAt,
      Value<int?> removedAt,
      Value<String?> applyReasonText,
      Value<String?> removeReasonText,
      Value<int> rowid,
    });

final class $$HolidaysTableReferences
    extends BaseReferences<_$RitmoDatabase, $HolidaysTable, Holiday> {
  $$HolidaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _operationalDateTable(_$RitmoDatabase db) =>
      db.days.createAlias('holidays__operational_date__days__operational_date');

  $$DaysTableProcessedTableManager get operationalDate {
    final $_column = $_itemColumn<String>('operational_date')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.operationalDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operationalDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HolidaysTableFilterComposer
    extends Composer<_$RitmoDatabase, $HolidaysTable> {
  $$HolidaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applyReasonText => $composableBuilder(
    column: $table.applyReasonText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get removeReasonText => $composableBuilder(
    column: $table.removeReasonText,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get operationalDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HolidaysTableOrderingComposer
    extends Composer<_$RitmoDatabase, $HolidaysTable> {
  $$HolidaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applyReasonText => $composableBuilder(
    column: $table.applyReasonText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get removeReasonText => $composableBuilder(
    column: $table.removeReasonText,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get operationalDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HolidaysTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $HolidaysTable> {
  $$HolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);

  GeneratedColumn<String> get applyReasonText => $composableBuilder(
    column: $table.applyReasonText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get removeReasonText => $composableBuilder(
    column: $table.removeReasonText,
    builder: (column) => column,
  );

  $$DaysTableAnnotationComposer get operationalDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationalDate,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.operationalDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HolidaysTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $HolidaysTable,
          Holiday,
          $$HolidaysTableFilterComposer,
          $$HolidaysTableOrderingComposer,
          $$HolidaysTableAnnotationComposer,
          $$HolidaysTableCreateCompanionBuilder,
          $$HolidaysTableUpdateCompanionBuilder,
          (Holiday, $$HolidaysTableReferences),
          Holiday,
          PrefetchHooks Function({bool operationalDate})
        > {
  $$HolidaysTableTableManager(_$RitmoDatabase db, $HolidaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationalDate = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> removedAt = const Value.absent(),
                Value<String?> applyReasonText = const Value.absent(),
                Value<String?> removeReasonText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HolidaysCompanion(
                operationalDate: operationalDate,
                active: active,
                createdAt: createdAt,
                removedAt: removedAt,
                applyReasonText: applyReasonText,
                removeReasonText: removeReasonText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationalDate,
                required bool active,
                required int createdAt,
                Value<int?> removedAt = const Value.absent(),
                Value<String?> applyReasonText = const Value.absent(),
                Value<String?> removeReasonText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HolidaysCompanion.insert(
                operationalDate: operationalDate,
                active: active,
                createdAt: createdAt,
                removedAt: removedAt,
                applyReasonText: applyReasonText,
                removeReasonText: removeReasonText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HolidaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({operationalDate = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (operationalDate) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.operationalDate,
                                referencedTable: $$HolidaysTableReferences
                                    ._operationalDateTable(db),
                                referencedColumn: $$HolidaysTableReferences
                                    ._operationalDateTable(db)
                                    .operationalDate,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HolidaysTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $HolidaysTable,
      Holiday,
      $$HolidaysTableFilterComposer,
      $$HolidaysTableOrderingComposer,
      $$HolidaysTableAnnotationComposer,
      $$HolidaysTableCreateCompanionBuilder,
      $$HolidaysTableUpdateCompanionBuilder,
      (Holiday, $$HolidaysTableReferences),
      Holiday,
      PrefetchHooks Function({bool operationalDate})
    >;
typedef $$MentorshipsTableCreateCompanionBuilder =
    MentorshipsCompanion Function({
      required String id,
      required String competency,
      Value<String?> mentorName,
      Value<String?> lastMeetingDate,
      Value<int> rowid,
    });
typedef $$MentorshipsTableUpdateCompanionBuilder =
    MentorshipsCompanion Function({
      Value<String> id,
      Value<String> competency,
      Value<String?> mentorName,
      Value<String?> lastMeetingDate,
      Value<int> rowid,
    });

class $$MentorshipsTableFilterComposer
    extends Composer<_$RitmoDatabase, $MentorshipsTable> {
  $$MentorshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mentorName => $composableBuilder(
    column: $table.mentorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMeetingDate => $composableBuilder(
    column: $table.lastMeetingDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MentorshipsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $MentorshipsTable> {
  $$MentorshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mentorName => $composableBuilder(
    column: $table.mentorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMeetingDate => $composableBuilder(
    column: $table.lastMeetingDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MentorshipsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $MentorshipsTable> {
  $$MentorshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mentorName => $composableBuilder(
    column: $table.mentorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMeetingDate => $composableBuilder(
    column: $table.lastMeetingDate,
    builder: (column) => column,
  );
}

class $$MentorshipsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $MentorshipsTable,
          Mentorship,
          $$MentorshipsTableFilterComposer,
          $$MentorshipsTableOrderingComposer,
          $$MentorshipsTableAnnotationComposer,
          $$MentorshipsTableCreateCompanionBuilder,
          $$MentorshipsTableUpdateCompanionBuilder,
          (
            Mentorship,
            BaseReferences<_$RitmoDatabase, $MentorshipsTable, Mentorship>,
          ),
          Mentorship,
          PrefetchHooks Function()
        > {
  $$MentorshipsTableTableManager(_$RitmoDatabase db, $MentorshipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MentorshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MentorshipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MentorshipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> competency = const Value.absent(),
                Value<String?> mentorName = const Value.absent(),
                Value<String?> lastMeetingDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MentorshipsCompanion(
                id: id,
                competency: competency,
                mentorName: mentorName,
                lastMeetingDate: lastMeetingDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String competency,
                Value<String?> mentorName = const Value.absent(),
                Value<String?> lastMeetingDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MentorshipsCompanion.insert(
                id: id,
                competency: competency,
                mentorName: mentorName,
                lastMeetingDate: lastMeetingDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MentorshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $MentorshipsTable,
      Mentorship,
      $$MentorshipsTableFilterComposer,
      $$MentorshipsTableOrderingComposer,
      $$MentorshipsTableAnnotationComposer,
      $$MentorshipsTableCreateCompanionBuilder,
      $$MentorshipsTableUpdateCompanionBuilder,
      (
        Mentorship,
        BaseReferences<_$RitmoDatabase, $MentorshipsTable, Mentorship>,
      ),
      Mentorship,
      PrefetchHooks Function()
    >;
typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      required String id,
      required String name,
      Value<String?> contextNote,
      Value<String?> lastTouchDate,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> contextNote,
      Value<String?> lastTouchDate,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$ContactsTableReferences
    extends BaseReferences<_$RitmoDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $WeeklyContactSuggestionsTable,
    List<WeeklyContactSuggestion>
  >
  _weeklyContactSuggestionsRefsTable(_$RitmoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.weeklyContactSuggestions,
        aliasName: 'contacts__id__weekly_contact_suggestions__contact_id',
      );

  $$WeeklyContactSuggestionsTableProcessedTableManager
  get weeklyContactSuggestionsRefs {
    final manager = $$WeeklyContactSuggestionsTableTableManager(
      $_db,
      $_db.weeklyContactSuggestions,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _weeklyContactSuggestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$RitmoDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextNote => $composableBuilder(
    column: $table.contextNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTouchDate => $composableBuilder(
    column: $table.lastTouchDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weeklyContactSuggestionsRefs(
    Expression<bool> Function($$WeeklyContactSuggestionsTableFilterComposer f)
    f,
  ) {
    final $$WeeklyContactSuggestionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.weeklyContactSuggestions,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WeeklyContactSuggestionsTableFilterComposer(
                $db: $db,
                $table: $db.weeklyContactSuggestions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextNote => $composableBuilder(
    column: $table.contextNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTouchDate => $composableBuilder(
    column: $table.lastTouchDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contextNote => $composableBuilder(
    column: $table.contextNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTouchDate => $composableBuilder(
    column: $table.lastTouchDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> weeklyContactSuggestionsRefs<T extends Object>(
    Expression<T> Function($$WeeklyContactSuggestionsTableAnnotationComposer a)
    f,
  ) {
    final $$WeeklyContactSuggestionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.weeklyContactSuggestions,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WeeklyContactSuggestionsTableAnnotationComposer(
                $db: $db,
                $table: $db.weeklyContactSuggestions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({bool weeklyContactSuggestionsRefs})
        > {
  $$ContactsTableTableManager(_$RitmoDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> contextNote = const Value.absent(),
                Value<String?> lastTouchDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                name: name,
                contextNote: contextNote,
                lastTouchDate: lastTouchDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> contextNote = const Value.absent(),
                Value<String?> lastTouchDate = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                name: name,
                contextNote: contextNote,
                lastTouchDate: lastTouchDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({weeklyContactSuggestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weeklyContactSuggestionsRefs) db.weeklyContactSuggestions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weeklyContactSuggestionsRefs)
                    await $_getPrefetchedData<
                      Contact,
                      $ContactsTable,
                      WeeklyContactSuggestion
                    >(
                      currentTable: table,
                      referencedTable: $$ContactsTableReferences
                          ._weeklyContactSuggestionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ContactsTableReferences(
                        db,
                        table,
                        p0,
                      ).weeklyContactSuggestionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.contactId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({bool weeklyContactSuggestionsRefs})
    >;
typedef $$WeeklyContactSuggestionsTableCreateCompanionBuilder =
    WeeklyContactSuggestionsCompanion Function({
      required String weekStart,
      required String contactId,
      required String status,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$WeeklyContactSuggestionsTableUpdateCompanionBuilder =
    WeeklyContactSuggestionsCompanion Function({
      Value<String> weekStart,
      Value<String> contactId,
      Value<String> status,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$WeeklyContactSuggestionsTableReferences
    extends
        BaseReferences<
          _$RitmoDatabase,
          $WeeklyContactSuggestionsTable,
          WeeklyContactSuggestion
        > {
  $$WeeklyContactSuggestionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContactsTable _contactIdTable(_$RitmoDatabase db) => db.contacts
      .createAlias('weekly_contact_suggestions__contact_id__contacts__id');

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<String>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeeklyContactSuggestionsTableFilterComposer
    extends Composer<_$RitmoDatabase, $WeeklyContactSuggestionsTable> {
  $$WeeklyContactSuggestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyContactSuggestionsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $WeeklyContactSuggestionsTable> {
  $$WeeklyContactSuggestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyContactSuggestionsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $WeeklyContactSuggestionsTable> {
  $$WeeklyContactSuggestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyContactSuggestionsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $WeeklyContactSuggestionsTable,
          WeeklyContactSuggestion,
          $$WeeklyContactSuggestionsTableFilterComposer,
          $$WeeklyContactSuggestionsTableOrderingComposer,
          $$WeeklyContactSuggestionsTableAnnotationComposer,
          $$WeeklyContactSuggestionsTableCreateCompanionBuilder,
          $$WeeklyContactSuggestionsTableUpdateCompanionBuilder,
          (WeeklyContactSuggestion, $$WeeklyContactSuggestionsTableReferences),
          WeeklyContactSuggestion,
          PrefetchHooks Function({bool contactId})
        > {
  $$WeeklyContactSuggestionsTableTableManager(
    _$RitmoDatabase db,
    $WeeklyContactSuggestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyContactSuggestionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WeeklyContactSuggestionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeeklyContactSuggestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> weekStart = const Value.absent(),
                Value<String> contactId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyContactSuggestionsCompanion(
                weekStart: weekStart,
                contactId: contactId,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weekStart,
                required String contactId,
                required String status,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WeeklyContactSuggestionsCompanion.insert(
                weekStart: weekStart,
                contactId: contactId,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeeklyContactSuggestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contactId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contactId,
                                referencedTable:
                                    $$WeeklyContactSuggestionsTableReferences
                                        ._contactIdTable(db),
                                referencedColumn:
                                    $$WeeklyContactSuggestionsTableReferences
                                        ._contactIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeeklyContactSuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $WeeklyContactSuggestionsTable,
      WeeklyContactSuggestion,
      $$WeeklyContactSuggestionsTableFilterComposer,
      $$WeeklyContactSuggestionsTableOrderingComposer,
      $$WeeklyContactSuggestionsTableAnnotationComposer,
      $$WeeklyContactSuggestionsTableCreateCompanionBuilder,
      $$WeeklyContactSuggestionsTableUpdateCompanionBuilder,
      (WeeklyContactSuggestion, $$WeeklyContactSuggestionsTableReferences),
      WeeklyContactSuggestion,
      PrefetchHooks Function({bool contactId})
    >;
typedef $$CyclesTableCreateCompanionBuilder =
    CyclesCompanion Function({
      required String id,
      required String name,
      required String purposeText,
      required String startDate,
      required String endDate,
      required String state,
      Value<int> rowid,
    });
typedef $$CyclesTableUpdateCompanionBuilder =
    CyclesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> purposeText,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> state,
      Value<int> rowid,
    });

final class $$CyclesTableReferences
    extends BaseReferences<_$RitmoDatabase, $CyclesTable, Cycle> {
  $$CyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CheckpointsTable, List<Checkpoint>>
  _checkpointsRefsTable(_$RitmoDatabase db) => MultiTypedResultKey.fromTable(
    db.checkpoints,
    aliasName: 'cycles__id__checkpoints__cycle_id',
  );

  $$CheckpointsTableProcessedTableManager get checkpointsRefs {
    final manager = $$CheckpointsTableTableManager(
      $_db,
      $_db.checkpoints,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkpointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CycleClosureInvitesTable,
    List<CycleClosureInvite>
  >
  _cycleClosureInvitesRefsTable(_$RitmoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cycleClosureInvites,
        aliasName: 'cycles__id__cycle_closure_invites__cycle_id',
      );

  $$CycleClosureInvitesTableProcessedTableManager get cycleClosureInvitesRefs {
    final manager = $$CycleClosureInvitesTableTableManager(
      $_db,
      $_db.cycleClosureInvites,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cycleClosureInvitesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CyclesTableFilterComposer
    extends Composer<_$RitmoDatabase, $CyclesTable> {
  $$CyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purposeText => $composableBuilder(
    column: $table.purposeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checkpointsRefs(
    Expression<bool> Function($$CheckpointsTableFilterComposer f) f,
  ) {
    final $$CheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpoints,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.checkpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cycleClosureInvitesRefs(
    Expression<bool> Function($$CycleClosureInvitesTableFilterComposer f) f,
  ) {
    final $$CycleClosureInvitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cycleClosureInvites,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CycleClosureInvitesTableFilterComposer(
            $db: $db,
            $table: $db.cycleClosureInvites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CyclesTableOrderingComposer
    extends Composer<_$RitmoDatabase, $CyclesTable> {
  $$CyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purposeText => $composableBuilder(
    column: $table.purposeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CyclesTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $CyclesTable> {
  $$CyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get purposeText => $composableBuilder(
    column: $table.purposeText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  Expression<T> checkpointsRefs<T extends Object>(
    Expression<T> Function($$CheckpointsTableAnnotationComposer a) f,
  ) {
    final $$CheckpointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpoints,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cycleClosureInvitesRefs<T extends Object>(
    Expression<T> Function($$CycleClosureInvitesTableAnnotationComposer a) f,
  ) {
    final $$CycleClosureInvitesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cycleClosureInvites,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CycleClosureInvitesTableAnnotationComposer(
                $db: $db,
                $table: $db.cycleClosureInvites,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CyclesTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $CyclesTable,
          Cycle,
          $$CyclesTableFilterComposer,
          $$CyclesTableOrderingComposer,
          $$CyclesTableAnnotationComposer,
          $$CyclesTableCreateCompanionBuilder,
          $$CyclesTableUpdateCompanionBuilder,
          (Cycle, $$CyclesTableReferences),
          Cycle,
          PrefetchHooks Function({
            bool checkpointsRefs,
            bool cycleClosureInvitesRefs,
          })
        > {
  $$CyclesTableTableManager(_$RitmoDatabase db, $CyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> purposeText = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion(
                id: id,
                name: name,
                purposeText: purposeText,
                startDate: startDate,
                endDate: endDate,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String purposeText,
                required String startDate,
                required String endDate,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion.insert(
                id: id,
                name: name,
                purposeText: purposeText,
                startDate: startDate,
                endDate: endDate,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CyclesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({checkpointsRefs = false, cycleClosureInvitesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checkpointsRefs) db.checkpoints,
                    if (cycleClosureInvitesRefs) db.cycleClosureInvites,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkpointsRefs)
                        await $_getPrefetchedData<
                          Cycle,
                          $CyclesTable,
                          Checkpoint
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._checkpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).checkpointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cycleClosureInvitesRefs)
                        await $_getPrefetchedData<
                          Cycle,
                          $CyclesTable,
                          CycleClosureInvite
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._cycleClosureInvitesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).cycleClosureInvitesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $CyclesTable,
      Cycle,
      $$CyclesTableFilterComposer,
      $$CyclesTableOrderingComposer,
      $$CyclesTableAnnotationComposer,
      $$CyclesTableCreateCompanionBuilder,
      $$CyclesTableUpdateCompanionBuilder,
      (Cycle, $$CyclesTableReferences),
      Cycle,
      PrefetchHooks Function({
        bool checkpointsRefs,
        bool cycleClosureInvitesRefs,
      })
    >;
typedef $$CheckpointsTableCreateCompanionBuilder =
    CheckpointsCompanion Function({
      required String id,
      required String cycleId,
      required String competency,
      required String date,
      required String status,
      Value<int> rowid,
    });
typedef $$CheckpointsTableUpdateCompanionBuilder =
    CheckpointsCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<String> competency,
      Value<String> date,
      Value<String> status,
      Value<int> rowid,
    });

final class $$CheckpointsTableReferences
    extends BaseReferences<_$RitmoDatabase, $CheckpointsTable, Checkpoint> {
  $$CheckpointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CyclesTable _cycleIdTable(_$RitmoDatabase db) =>
      db.cycles.createAlias('checkpoints__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CheckpointEvalsTable, List<CheckpointEval>>
  _checkpointEvalsRefsTable(_$RitmoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.checkpointEvals,
        aliasName: 'checkpoints__id__checkpoint_evals__checkpoint_id',
      );

  $$CheckpointEvalsTableProcessedTableManager get checkpointEvalsRefs {
    final manager = $$CheckpointEvalsTableTableManager(
      $_db,
      $_db.checkpointEvals,
    ).filter((f) => f.checkpointId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _checkpointEvalsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CheckpointsTableFilterComposer
    extends Composer<_$RitmoDatabase, $CheckpointsTable> {
  $$CheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> checkpointEvalsRefs(
    Expression<bool> Function($$CheckpointEvalsTableFilterComposer f) f,
  ) {
    final $$CheckpointEvalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpointEvals,
      getReferencedColumn: (t) => t.checkpointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointEvalsTableFilterComposer(
            $db: $db,
            $table: $db.checkpointEvals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CheckpointsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $CheckpointsTable> {
  $$CheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckpointsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $CheckpointsTable> {
  $$CheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> checkpointEvalsRefs<T extends Object>(
    Expression<T> Function($$CheckpointEvalsTableAnnotationComposer a) f,
  ) {
    final $$CheckpointEvalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpointEvals,
      getReferencedColumn: (t) => t.checkpointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointEvalsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkpointEvals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CheckpointsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $CheckpointsTable,
          Checkpoint,
          $$CheckpointsTableFilterComposer,
          $$CheckpointsTableOrderingComposer,
          $$CheckpointsTableAnnotationComposer,
          $$CheckpointsTableCreateCompanionBuilder,
          $$CheckpointsTableUpdateCompanionBuilder,
          (Checkpoint, $$CheckpointsTableReferences),
          Checkpoint,
          PrefetchHooks Function({bool cycleId, bool checkpointEvalsRefs})
        > {
  $$CheckpointsTableTableManager(_$RitmoDatabase db, $CheckpointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> competency = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckpointsCompanion(
                id: id,
                cycleId: cycleId,
                competency: competency,
                date: date,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required String competency,
                required String date,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => CheckpointsCompanion.insert(
                id: id,
                cycleId: cycleId,
                competency: competency,
                date: date,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CheckpointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cycleId = false, checkpointEvalsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checkpointEvalsRefs) db.checkpointEvals,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$CheckpointsTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$CheckpointsTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkpointEvalsRefs)
                        await $_getPrefetchedData<
                          Checkpoint,
                          $CheckpointsTable,
                          CheckpointEval
                        >(
                          currentTable: table,
                          referencedTable: $$CheckpointsTableReferences
                              ._checkpointEvalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CheckpointsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkpointEvalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.checkpointId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $CheckpointsTable,
      Checkpoint,
      $$CheckpointsTableFilterComposer,
      $$CheckpointsTableOrderingComposer,
      $$CheckpointsTableAnnotationComposer,
      $$CheckpointsTableCreateCompanionBuilder,
      $$CheckpointsTableUpdateCompanionBuilder,
      (Checkpoint, $$CheckpointsTableReferences),
      Checkpoint,
      PrefetchHooks Function({bool cycleId, bool checkpointEvalsRefs})
    >;
typedef $$WeeklyReviewsTableCreateCompanionBuilder =
    WeeklyReviewsCompanion Function({
      required String id,
      required String weekStart,
      Value<String?> answerFulfilled,
      Value<String?> answerFailed,
      Value<String?> answerLesson,
      Value<String?> audioId,
      Value<String> state,
      required int createdAt,
      Value<int?> autosavedAt,
      Value<int?> finalizedAt,
      Value<int> rowid,
    });
typedef $$WeeklyReviewsTableUpdateCompanionBuilder =
    WeeklyReviewsCompanion Function({
      Value<String> id,
      Value<String> weekStart,
      Value<String?> answerFulfilled,
      Value<String?> answerFailed,
      Value<String?> answerLesson,
      Value<String?> audioId,
      Value<String> state,
      Value<int> createdAt,
      Value<int?> autosavedAt,
      Value<int?> finalizedAt,
      Value<int> rowid,
    });

final class $$WeeklyReviewsTableReferences
    extends BaseReferences<_$RitmoDatabase, $WeeklyReviewsTable, WeeklyReview> {
  $$WeeklyReviewsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AudioAssetsTable _audioIdTable(_$RitmoDatabase db) =>
      db.audioAssets.createAlias('weekly_reviews__audio_id__audio_assets__id');

  $$AudioAssetsTableProcessedTableManager? get audioId {
    final $_column = $_itemColumn<String>('audio_id');
    if ($_column == null) return null;
    final manager = $$AudioAssetsTableTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_audioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CheckpointEvalsTable, List<CheckpointEval>>
  _checkpointEvalsRefsTable(_$RitmoDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.checkpointEvals,
        aliasName: 'weekly_reviews__id__checkpoint_evals__weekly_review_id',
      );

  $$CheckpointEvalsTableProcessedTableManager get checkpointEvalsRefs {
    final manager = $$CheckpointEvalsTableTableManager(
      $_db,
      $_db.checkpointEvals,
    ).filter((f) => f.weeklyReviewId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _checkpointEvalsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WeeklyReviewsTableFilterComposer
    extends Composer<_$RitmoDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerFulfilled => $composableBuilder(
    column: $table.answerFulfilled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerFailed => $composableBuilder(
    column: $table.answerFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerLesson => $composableBuilder(
    column: $table.answerLesson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autosavedAt => $composableBuilder(
    column: $table.autosavedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AudioAssetsTableFilterComposer get audioId {
    final $$AudioAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.audioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> checkpointEvalsRefs(
    Expression<bool> Function($$CheckpointEvalsTableFilterComposer f) f,
  ) {
    final $$CheckpointEvalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpointEvals,
      getReferencedColumn: (t) => t.weeklyReviewId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointEvalsTableFilterComposer(
            $db: $db,
            $table: $db.checkpointEvals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeklyReviewsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerFulfilled => $composableBuilder(
    column: $table.answerFulfilled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerFailed => $composableBuilder(
    column: $table.answerFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerLesson => $composableBuilder(
    column: $table.answerLesson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autosavedAt => $composableBuilder(
    column: $table.autosavedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AudioAssetsTableOrderingComposer get audioId {
    final $$AudioAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.audioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyReviewsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $WeeklyReviewsTable> {
  $$WeeklyReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get answerFulfilled => $composableBuilder(
    column: $table.answerFulfilled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerFailed => $composableBuilder(
    column: $table.answerFailed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerLesson => $composableBuilder(
    column: $table.answerLesson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get autosavedAt => $composableBuilder(
    column: $table.autosavedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => column,
  );

  $$AudioAssetsTableAnnotationComposer get audioId {
    final $$AudioAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.audioId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> checkpointEvalsRefs<T extends Object>(
    Expression<T> Function($$CheckpointEvalsTableAnnotationComposer a) f,
  ) {
    final $$CheckpointEvalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkpointEvals,
      getReferencedColumn: (t) => t.weeklyReviewId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointEvalsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkpointEvals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeklyReviewsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $WeeklyReviewsTable,
          WeeklyReview,
          $$WeeklyReviewsTableFilterComposer,
          $$WeeklyReviewsTableOrderingComposer,
          $$WeeklyReviewsTableAnnotationComposer,
          $$WeeklyReviewsTableCreateCompanionBuilder,
          $$WeeklyReviewsTableUpdateCompanionBuilder,
          (WeeklyReview, $$WeeklyReviewsTableReferences),
          WeeklyReview,
          PrefetchHooks Function({bool audioId, bool checkpointEvalsRefs})
        > {
  $$WeeklyReviewsTableTableManager(
    _$RitmoDatabase db,
    $WeeklyReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<String?> answerFulfilled = const Value.absent(),
                Value<String?> answerFailed = const Value.absent(),
                Value<String?> answerLesson = const Value.absent(),
                Value<String?> audioId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> autosavedAt = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyReviewsCompanion(
                id: id,
                weekStart: weekStart,
                answerFulfilled: answerFulfilled,
                answerFailed: answerFailed,
                answerLesson: answerLesson,
                audioId: audioId,
                state: state,
                createdAt: createdAt,
                autosavedAt: autosavedAt,
                finalizedAt: finalizedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String weekStart,
                Value<String?> answerFulfilled = const Value.absent(),
                Value<String?> answerFailed = const Value.absent(),
                Value<String?> answerLesson = const Value.absent(),
                Value<String?> audioId = const Value.absent(),
                Value<String> state = const Value.absent(),
                required int createdAt,
                Value<int?> autosavedAt = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeeklyReviewsCompanion.insert(
                id: id,
                weekStart: weekStart,
                answerFulfilled: answerFulfilled,
                answerFailed: answerFailed,
                answerLesson: answerLesson,
                audioId: audioId,
                state: state,
                createdAt: createdAt,
                autosavedAt: autosavedAt,
                finalizedAt: finalizedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeeklyReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({audioId = false, checkpointEvalsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checkpointEvalsRefs) db.checkpointEvals,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (audioId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.audioId,
                                    referencedTable:
                                        $$WeeklyReviewsTableReferences
                                            ._audioIdTable(db),
                                    referencedColumn:
                                        $$WeeklyReviewsTableReferences
                                            ._audioIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkpointEvalsRefs)
                        await $_getPrefetchedData<
                          WeeklyReview,
                          $WeeklyReviewsTable,
                          CheckpointEval
                        >(
                          currentTable: table,
                          referencedTable: $$WeeklyReviewsTableReferences
                              ._checkpointEvalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WeeklyReviewsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkpointEvalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.weeklyReviewId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WeeklyReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $WeeklyReviewsTable,
      WeeklyReview,
      $$WeeklyReviewsTableFilterComposer,
      $$WeeklyReviewsTableOrderingComposer,
      $$WeeklyReviewsTableAnnotationComposer,
      $$WeeklyReviewsTableCreateCompanionBuilder,
      $$WeeklyReviewsTableUpdateCompanionBuilder,
      (WeeklyReview, $$WeeklyReviewsTableReferences),
      WeeklyReview,
      PrefetchHooks Function({bool audioId, bool checkpointEvalsRefs})
    >;
typedef $$CheckpointEvalsTableCreateCompanionBuilder =
    CheckpointEvalsCompanion Function({
      required String id,
      required String checkpointId,
      Value<String?> weeklyReviewId,
      required String gartnerLevel,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$CheckpointEvalsTableUpdateCompanionBuilder =
    CheckpointEvalsCompanion Function({
      Value<String> id,
      Value<String> checkpointId,
      Value<String?> weeklyReviewId,
      Value<String> gartnerLevel,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$CheckpointEvalsTableReferences
    extends
        BaseReferences<_$RitmoDatabase, $CheckpointEvalsTable, CheckpointEval> {
  $$CheckpointEvalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CheckpointsTable _checkpointIdTable(_$RitmoDatabase db) => db
      .checkpoints
      .createAlias('checkpoint_evals__checkpoint_id__checkpoints__id');

  $$CheckpointsTableProcessedTableManager get checkpointId {
    final $_column = $_itemColumn<String>('checkpoint_id')!;

    final manager = $$CheckpointsTableTableManager(
      $_db,
      $_db.checkpoints,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_checkpointIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WeeklyReviewsTable _weeklyReviewIdTable(_$RitmoDatabase db) => db
      .weeklyReviews
      .createAlias('checkpoint_evals__weekly_review_id__weekly_reviews__id');

  $$WeeklyReviewsTableProcessedTableManager? get weeklyReviewId {
    final $_column = $_itemColumn<String>('weekly_review_id');
    if ($_column == null) return null;
    final manager = $$WeeklyReviewsTableTableManager(
      $_db,
      $_db.weeklyReviews,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_weeklyReviewIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckpointEvalsTableFilterComposer
    extends Composer<_$RitmoDatabase, $CheckpointEvalsTable> {
  $$CheckpointEvalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gartnerLevel => $composableBuilder(
    column: $table.gartnerLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$CheckpointsTableFilterComposer get checkpointId {
    final $$CheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checkpointId,
      referencedTable: $db.checkpoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.checkpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WeeklyReviewsTableFilterComposer get weeklyReviewId {
    final $$WeeklyReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weeklyReviewId,
      referencedTable: $db.weeklyReviews,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyReviewsTableFilterComposer(
            $db: $db,
            $table: $db.weeklyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckpointEvalsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $CheckpointEvalsTable> {
  $$CheckpointEvalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gartnerLevel => $composableBuilder(
    column: $table.gartnerLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$CheckpointsTableOrderingComposer get checkpointId {
    final $$CheckpointsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checkpointId,
      referencedTable: $db.checkpoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointsTableOrderingComposer(
            $db: $db,
            $table: $db.checkpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WeeklyReviewsTableOrderingComposer get weeklyReviewId {
    final $$WeeklyReviewsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weeklyReviewId,
      referencedTable: $db.weeklyReviews,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyReviewsTableOrderingComposer(
            $db: $db,
            $table: $db.weeklyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckpointEvalsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $CheckpointEvalsTable> {
  $$CheckpointEvalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gartnerLevel => $composableBuilder(
    column: $table.gartnerLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$CheckpointsTableAnnotationComposer get checkpointId {
    final $$CheckpointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checkpointId,
      referencedTable: $db.checkpoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckpointsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WeeklyReviewsTableAnnotationComposer get weeklyReviewId {
    final $$WeeklyReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.weeklyReviewId,
      referencedTable: $db.weeklyReviews,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.weeklyReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckpointEvalsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $CheckpointEvalsTable,
          CheckpointEval,
          $$CheckpointEvalsTableFilterComposer,
          $$CheckpointEvalsTableOrderingComposer,
          $$CheckpointEvalsTableAnnotationComposer,
          $$CheckpointEvalsTableCreateCompanionBuilder,
          $$CheckpointEvalsTableUpdateCompanionBuilder,
          (CheckpointEval, $$CheckpointEvalsTableReferences),
          CheckpointEval,
          PrefetchHooks Function({bool checkpointId, bool weeklyReviewId})
        > {
  $$CheckpointEvalsTableTableManager(
    _$RitmoDatabase db,
    $CheckpointEvalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckpointEvalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckpointEvalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckpointEvalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> checkpointId = const Value.absent(),
                Value<String?> weeklyReviewId = const Value.absent(),
                Value<String> gartnerLevel = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckpointEvalsCompanion(
                id: id,
                checkpointId: checkpointId,
                weeklyReviewId: weeklyReviewId,
                gartnerLevel: gartnerLevel,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String checkpointId,
                Value<String?> weeklyReviewId = const Value.absent(),
                required String gartnerLevel,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckpointEvalsCompanion.insert(
                id: id,
                checkpointId: checkpointId,
                weeklyReviewId: weeklyReviewId,
                gartnerLevel: gartnerLevel,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CheckpointEvalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({checkpointId = false, weeklyReviewId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (checkpointId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.checkpointId,
                                    referencedTable:
                                        $$CheckpointEvalsTableReferences
                                            ._checkpointIdTable(db),
                                    referencedColumn:
                                        $$CheckpointEvalsTableReferences
                                            ._checkpointIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (weeklyReviewId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.weeklyReviewId,
                                    referencedTable:
                                        $$CheckpointEvalsTableReferences
                                            ._weeklyReviewIdTable(db),
                                    referencedColumn:
                                        $$CheckpointEvalsTableReferences
                                            ._weeklyReviewIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CheckpointEvalsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $CheckpointEvalsTable,
      CheckpointEval,
      $$CheckpointEvalsTableFilterComposer,
      $$CheckpointEvalsTableOrderingComposer,
      $$CheckpointEvalsTableAnnotationComposer,
      $$CheckpointEvalsTableCreateCompanionBuilder,
      $$CheckpointEvalsTableUpdateCompanionBuilder,
      (CheckpointEval, $$CheckpointEvalsTableReferences),
      CheckpointEval,
      PrefetchHooks Function({bool checkpointId, bool weeklyReviewId})
    >;
typedef $$CycleClosureInvitesTableCreateCompanionBuilder =
    CycleClosureInvitesCompanion Function({
      required String cycleId,
      required String weekStart,
      Value<int> rowid,
    });
typedef $$CycleClosureInvitesTableUpdateCompanionBuilder =
    CycleClosureInvitesCompanion Function({
      Value<String> cycleId,
      Value<String> weekStart,
      Value<int> rowid,
    });

final class $$CycleClosureInvitesTableReferences
    extends
        BaseReferences<
          _$RitmoDatabase,
          $CycleClosureInvitesTable,
          CycleClosureInvite
        > {
  $$CycleClosureInvitesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$RitmoDatabase db) =>
      db.cycles.createAlias('cycle_closure_invites__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CycleClosureInvitesTableFilterComposer
    extends Composer<_$RitmoDatabase, $CycleClosureInvitesTable> {
  $$CycleClosureInvitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleClosureInvitesTableOrderingComposer
    extends Composer<_$RitmoDatabase, $CycleClosureInvitesTable> {
  $$CycleClosureInvitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleClosureInvitesTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $CycleClosureInvitesTable> {
  $$CycleClosureInvitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleClosureInvitesTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $CycleClosureInvitesTable,
          CycleClosureInvite,
          $$CycleClosureInvitesTableFilterComposer,
          $$CycleClosureInvitesTableOrderingComposer,
          $$CycleClosureInvitesTableAnnotationComposer,
          $$CycleClosureInvitesTableCreateCompanionBuilder,
          $$CycleClosureInvitesTableUpdateCompanionBuilder,
          (CycleClosureInvite, $$CycleClosureInvitesTableReferences),
          CycleClosureInvite,
          PrefetchHooks Function({bool cycleId})
        > {
  $$CycleClosureInvitesTableTableManager(
    _$RitmoDatabase db,
    $CycleClosureInvitesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CycleClosureInvitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CycleClosureInvitesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CycleClosureInvitesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cycleId = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CycleClosureInvitesCompanion(
                cycleId: cycleId,
                weekStart: weekStart,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cycleId,
                required String weekStart,
                Value<int> rowid = const Value.absent(),
              }) => CycleClosureInvitesCompanion.insert(
                cycleId: cycleId,
                weekStart: weekStart,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CycleClosureInvitesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable:
                                    $$CycleClosureInvitesTableReferences
                                        ._cycleIdTable(db),
                                referencedColumn:
                                    $$CycleClosureInvitesTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CycleClosureInvitesTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $CycleClosureInvitesTable,
      CycleClosureInvite,
      $$CycleClosureInvitesTableFilterComposer,
      $$CycleClosureInvitesTableOrderingComposer,
      $$CycleClosureInvitesTableAnnotationComposer,
      $$CycleClosureInvitesTableCreateCompanionBuilder,
      $$CycleClosureInvitesTableUpdateCompanionBuilder,
      (CycleClosureInvite, $$CycleClosureInvitesTableReferences),
      CycleClosureInvite,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$ManifestsTableCreateCompanionBuilder =
    ManifestsCompanion Function({
      required String id,
      required String contentMarkdown,
      required String assetVersion,
      required int firstCopiedAt,
      Value<int?> lastEditedAt,
      Value<int> rowid,
    });
typedef $$ManifestsTableUpdateCompanionBuilder =
    ManifestsCompanion Function({
      Value<String> id,
      Value<String> contentMarkdown,
      Value<String> assetVersion,
      Value<int> firstCopiedAt,
      Value<int?> lastEditedAt,
      Value<int> rowid,
    });

class $$ManifestsTableFilterComposer
    extends Composer<_$RitmoDatabase, $ManifestsTable> {
  $$ManifestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetVersion => $composableBuilder(
    column: $table.assetVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstCopiedAt => $composableBuilder(
    column: $table.firstCopiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEditedAt => $composableBuilder(
    column: $table.lastEditedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManifestsTableOrderingComposer
    extends Composer<_$RitmoDatabase, $ManifestsTable> {
  $$ManifestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetVersion => $composableBuilder(
    column: $table.assetVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstCopiedAt => $composableBuilder(
    column: $table.firstCopiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEditedAt => $composableBuilder(
    column: $table.lastEditedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManifestsTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $ManifestsTable> {
  $$ManifestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetVersion => $composableBuilder(
    column: $table.assetVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstCopiedAt => $composableBuilder(
    column: $table.firstCopiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastEditedAt => $composableBuilder(
    column: $table.lastEditedAt,
    builder: (column) => column,
  );
}

class $$ManifestsTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $ManifestsTable,
          Manifest,
          $$ManifestsTableFilterComposer,
          $$ManifestsTableOrderingComposer,
          $$ManifestsTableAnnotationComposer,
          $$ManifestsTableCreateCompanionBuilder,
          $$ManifestsTableUpdateCompanionBuilder,
          (
            Manifest,
            BaseReferences<_$RitmoDatabase, $ManifestsTable, Manifest>,
          ),
          Manifest,
          PrefetchHooks Function()
        > {
  $$ManifestsTableTableManager(_$RitmoDatabase db, $ManifestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManifestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManifestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManifestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contentMarkdown = const Value.absent(),
                Value<String> assetVersion = const Value.absent(),
                Value<int> firstCopiedAt = const Value.absent(),
                Value<int?> lastEditedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManifestsCompanion(
                id: id,
                contentMarkdown: contentMarkdown,
                assetVersion: assetVersion,
                firstCopiedAt: firstCopiedAt,
                lastEditedAt: lastEditedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contentMarkdown,
                required String assetVersion,
                required int firstCopiedAt,
                Value<int?> lastEditedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManifestsCompanion.insert(
                id: id,
                contentMarkdown: contentMarkdown,
                assetVersion: assetVersion,
                firstCopiedAt: firstCopiedAt,
                lastEditedAt: lastEditedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManifestsTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $ManifestsTable,
      Manifest,
      $$ManifestsTableFilterComposer,
      $$ManifestsTableOrderingComposer,
      $$ManifestsTableAnnotationComposer,
      $$ManifestsTableCreateCompanionBuilder,
      $$ManifestsTableUpdateCompanionBuilder,
      (Manifest, BaseReferences<_$RitmoDatabase, $ManifestsTable, Manifest>),
      Manifest,
      PrefetchHooks Function()
    >;
typedef $$NotificationPlansTableCreateCompanionBuilder =
    NotificationPlansCompanion Function({
      required String idempotencyKey,
      required String kind,
      required int plannedAt,
      required String state,
      Value<int> rowid,
    });
typedef $$NotificationPlansTableUpdateCompanionBuilder =
    NotificationPlansCompanion Function({
      Value<String> idempotencyKey,
      Value<String> kind,
      Value<int> plannedAt,
      Value<String> state,
      Value<int> rowid,
    });

class $$NotificationPlansTableFilterComposer
    extends Composer<_$RitmoDatabase, $NotificationPlansTable> {
  $$NotificationPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedAt => $composableBuilder(
    column: $table.plannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationPlansTableOrderingComposer
    extends Composer<_$RitmoDatabase, $NotificationPlansTable> {
  $$NotificationPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedAt => $composableBuilder(
    column: $table.plannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationPlansTableAnnotationComposer
    extends Composer<_$RitmoDatabase, $NotificationPlansTable> {
  $$NotificationPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get plannedAt =>
      $composableBuilder(column: $table.plannedAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$NotificationPlansTableTableManager
    extends
        RootTableManager<
          _$RitmoDatabase,
          $NotificationPlansTable,
          NotificationPlan,
          $$NotificationPlansTableFilterComposer,
          $$NotificationPlansTableOrderingComposer,
          $$NotificationPlansTableAnnotationComposer,
          $$NotificationPlansTableCreateCompanionBuilder,
          $$NotificationPlansTableUpdateCompanionBuilder,
          (
            NotificationPlan,
            BaseReferences<
              _$RitmoDatabase,
              $NotificationPlansTable,
              NotificationPlan
            >,
          ),
          NotificationPlan,
          PrefetchHooks Function()
        > {
  $$NotificationPlansTableTableManager(
    _$RitmoDatabase db,
    $NotificationPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> plannedAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationPlansCompanion(
                idempotencyKey: idempotencyKey,
                kind: kind,
                plannedAt: plannedAt,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                required String kind,
                required int plannedAt,
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => NotificationPlansCompanion.insert(
                idempotencyKey: idempotencyKey,
                kind: kind,
                plannedAt: plannedAt,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$RitmoDatabase,
      $NotificationPlansTable,
      NotificationPlan,
      $$NotificationPlansTableFilterComposer,
      $$NotificationPlansTableOrderingComposer,
      $$NotificationPlansTableAnnotationComposer,
      $$NotificationPlansTableCreateCompanionBuilder,
      $$NotificationPlansTableUpdateCompanionBuilder,
      (
        NotificationPlan,
        BaseReferences<
          _$RitmoDatabase,
          $NotificationPlansTable,
          NotificationPlan
        >,
      ),
      NotificationPlan,
      PrefetchHooks Function()
    >;

class $RitmoDatabaseManager {
  final _$RitmoDatabase _db;
  $RitmoDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$DaysTableTableManager get days => $$DaysTableTableManager(_db, _db.days);
  $$StudyBlocksTableTableManager get studyBlocks =>
      $$StudyBlocksTableTableManager(_db, _db.studyBlocks);
  $$AudioAssetsTableTableManager get audioAssets =>
      $$AudioAssetsTableTableManager(_db, _db.audioAssets);
  $$ChangeInitiativesTableTableManager get changeInitiatives =>
      $$ChangeInitiativesTableTableManager(_db, _db.changeInitiatives);
  $$PillarEntriesTableTableManager get pillarEntries =>
      $$PillarEntriesTableTableManager(_db, _db.pillarEntries);
  $$PillarWaiversTableTableManager get pillarWaivers =>
      $$PillarWaiversTableTableManager(_db, _db.pillarWaivers);
  $$ProtocolAlarmsTableTableManager get protocolAlarms =>
      $$ProtocolAlarmsTableTableManager(_db, _db.protocolAlarms);
  $$HolidaysTableTableManager get holidays =>
      $$HolidaysTableTableManager(_db, _db.holidays);
  $$MentorshipsTableTableManager get mentorships =>
      $$MentorshipsTableTableManager(_db, _db.mentorships);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$WeeklyContactSuggestionsTableTableManager get weeklyContactSuggestions =>
      $$WeeklyContactSuggestionsTableTableManager(
        _db,
        _db.weeklyContactSuggestions,
      );
  $$CyclesTableTableManager get cycles =>
      $$CyclesTableTableManager(_db, _db.cycles);
  $$CheckpointsTableTableManager get checkpoints =>
      $$CheckpointsTableTableManager(_db, _db.checkpoints);
  $$WeeklyReviewsTableTableManager get weeklyReviews =>
      $$WeeklyReviewsTableTableManager(_db, _db.weeklyReviews);
  $$CheckpointEvalsTableTableManager get checkpointEvals =>
      $$CheckpointEvalsTableTableManager(_db, _db.checkpointEvals);
  $$CycleClosureInvitesTableTableManager get cycleClosureInvites =>
      $$CycleClosureInvitesTableTableManager(_db, _db.cycleClosureInvites);
  $$ManifestsTableTableManager get manifests =>
      $$ManifestsTableTableManager(_db, _db.manifests);
  $$NotificationPlansTableTableManager get notificationPlans =>
      $$NotificationPlansTableTableManager(_db, _db.notificationPlans);
}
