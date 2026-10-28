// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemType>($ItemsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<String> presetId = GeneratedColumn<String>(
    'preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($ItemsTable.$convertercurrency);
  @override
  late final GeneratedColumnWithTypeConverter<CycleUnit, String> cycleUnit =
      GeneratedColumn<String>(
        'cycle_unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CycleUnit>($ItemsTable.$convertercycleUnit);
  static const VerificationMeta _cycleEveryMeta = const VerificationMeta(
    'cycleEvery',
  );
  @override
  late final GeneratedColumn<int> cycleEvery = GeneratedColumn<int>(
    'cycle_every',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> anchorOn =
      GeneratedColumn<String>(
        'anchor_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($ItemsTable.$converteranchorOn);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> paidUntil =
      GeneratedColumn<String>(
        'paid_until',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($ItemsTable.$converterpaidUntiln);
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemStatus>($ItemsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> statusSince =
      GeneratedColumn<String>(
        'status_since',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($ItemsTable.$converterstatusSincen);
  static const VerificationMeta _reminderRulesMeta = const VerificationMeta(
    'reminderRules',
  );
  @override
  late final GeneratedColumn<String> reminderRules = GeneratedColumn<String>(
    'reminder_rules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _typeFieldsMeta = const VerificationMeta(
    'typeFields',
  );
  @override
  late final GeneratedColumn<String> typeFields = GeneratedColumn<String>(
    'type_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _sharingMeta = const VerificationMeta(
    'sharing',
  );
  @override
  late final GeneratedColumn<String> sharing = GeneratedColumn<String>(
    'sharing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    type,
    name,
    presetId,
    categoryId,
    accountId,
    currency,
    cycleUnit,
    cycleEvery,
    anchorOn,
    paidUntil,
    status,
    statusSince,
    reminderRules,
    typeFields,
    sharing,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
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
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('cycle_every')) {
      context.handle(
        _cycleEveryMeta,
        cycleEvery.isAcceptableOrUnknown(data['cycle_every']!, _cycleEveryMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleEveryMeta);
    }
    if (data.containsKey('reminder_rules')) {
      context.handle(
        _reminderRulesMeta,
        reminderRules.isAcceptableOrUnknown(
          data['reminder_rules']!,
          _reminderRulesMeta,
        ),
      );
    }
    if (data.containsKey('type_fields')) {
      context.handle(
        _typeFieldsMeta,
        typeFields.isAcceptableOrUnknown(data['type_fields']!, _typeFieldsMeta),
      );
    }
    if (data.containsKey('sharing')) {
      context.handle(
        _sharingMeta,
        sharing.isAcceptableOrUnknown(data['sharing']!, _sharingMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $ItemsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      currency: $ItemsTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
      cycleUnit: $ItemsTable.$convertercycleUnit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cycle_unit'],
        )!,
      ),
      cycleEvery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_every'],
      )!,
      anchorOn: $ItemsTable.$converteranchorOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}anchor_on'],
        )!,
      ),
      paidUntil: $ItemsTable.$converterpaidUntiln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}paid_until'],
        ),
      ),
      status: $ItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      statusSince: $ItemsTable.$converterstatusSincen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status_since'],
        ),
      ),
      reminderRules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_rules'],
      )!,
      typeFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_fields'],
      )!,
      sharing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sharing'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemType, String, String> $convertertype =
      const EnumNameConverter<ItemType>(ItemType.values);
  static TypeConverter<Currency, String> $convertercurrency =
      const CurrencyConverter();
  static JsonTypeConverter2<CycleUnit, String, String> $convertercycleUnit =
      const EnumNameConverter<CycleUnit>(CycleUnit.values);
  static TypeConverter<LocalDate, String> $converteranchorOn =
      const LocalDateConverter();
  static TypeConverter<LocalDate, String> $converterpaidUntil =
      const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converterpaidUntiln =
      NullAwareTypeConverter.wrap($converterpaidUntil);
  static JsonTypeConverter2<ItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ItemStatus>(ItemStatus.values);
  static TypeConverter<LocalDate, String> $converterstatusSince =
      const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converterstatusSincen =
      NullAwareTypeConverter.wrap($converterstatusSince);
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final int createdAt;
  final int updatedAt;
  final String id;
  final ItemType type;
  final String name;
  final String? presetId;
  final String? categoryId;
  final String? accountId;

  /// Currency of every price phase.
  final Currency currency;
  final CycleUnit cycleUnit;
  final int cycleEvery;
  final LocalDate anchorOn;
  final LocalDate? paidUntil;
  final ItemStatus status;
  final LocalDate? statusSince;

  /// JSON list of reminder rules (days before, kinds). Shape defined in M3.
  final String reminderRules;

  /// JSON object of type-specific fields (domain registrar, VPS specs,
  /// repayment periods …). Shapes defined with the item editor in M2.
  final String typeFields;

  /// JSON cost-sharing settings (total, people, my share, who has paid).
  final String? sharing;
  final String note;
  const ItemRow({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.type,
    required this.name,
    this.presetId,
    this.categoryId,
    this.accountId,
    required this.currency,
    required this.cycleUnit,
    required this.cycleEvery,
    required this.anchorOn,
    this.paidUntil,
    required this.status,
    this.statusSince,
    required this.reminderRules,
    required this.typeFields,
    this.sharing,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>($ItemsTable.$convertertype.toSql(type));
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || presetId != null) {
      map['preset_id'] = Variable<String>(presetId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    {
      map['currency'] = Variable<String>(
        $ItemsTable.$convertercurrency.toSql(currency),
      );
    }
    {
      map['cycle_unit'] = Variable<String>(
        $ItemsTable.$convertercycleUnit.toSql(cycleUnit),
      );
    }
    map['cycle_every'] = Variable<int>(cycleEvery);
    {
      map['anchor_on'] = Variable<String>(
        $ItemsTable.$converteranchorOn.toSql(anchorOn),
      );
    }
    if (!nullToAbsent || paidUntil != null) {
      map['paid_until'] = Variable<String>(
        $ItemsTable.$converterpaidUntiln.toSql(paidUntil),
      );
    }
    {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || statusSince != null) {
      map['status_since'] = Variable<String>(
        $ItemsTable.$converterstatusSincen.toSql(statusSince),
      );
    }
    map['reminder_rules'] = Variable<String>(reminderRules);
    map['type_fields'] = Variable<String>(typeFields);
    if (!nullToAbsent || sharing != null) {
      map['sharing'] = Variable<String>(sharing);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      type: Value(type),
      name: Value(name),
      presetId: presetId == null && nullToAbsent
          ? const Value.absent()
          : Value(presetId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      currency: Value(currency),
      cycleUnit: Value(cycleUnit),
      cycleEvery: Value(cycleEvery),
      anchorOn: Value(anchorOn),
      paidUntil: paidUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(paidUntil),
      status: Value(status),
      statusSince: statusSince == null && nullToAbsent
          ? const Value.absent()
          : Value(statusSince),
      reminderRules: Value(reminderRules),
      typeFields: Value(typeFields),
      sharing: sharing == null && nullToAbsent
          ? const Value.absent()
          : Value(sharing),
      note: Value(note),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      id: serializer.fromJson<String>(json['id']),
      type: $ItemsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      name: serializer.fromJson<String>(json['name']),
      presetId: serializer.fromJson<String?>(json['presetId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      currency: serializer.fromJson<Currency>(json['currency']),
      cycleUnit: $ItemsTable.$convertercycleUnit.fromJson(
        serializer.fromJson<String>(json['cycleUnit']),
      ),
      cycleEvery: serializer.fromJson<int>(json['cycleEvery']),
      anchorOn: serializer.fromJson<LocalDate>(json['anchorOn']),
      paidUntil: serializer.fromJson<LocalDate?>(json['paidUntil']),
      status: $ItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      statusSince: serializer.fromJson<LocalDate?>(json['statusSince']),
      reminderRules: serializer.fromJson<String>(json['reminderRules']),
      typeFields: serializer.fromJson<String>(json['typeFields']),
      sharing: serializer.fromJson<String?>(json['sharing']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $ItemsTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String>(name),
      'presetId': serializer.toJson<String?>(presetId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'currency': serializer.toJson<Currency>(currency),
      'cycleUnit': serializer.toJson<String>(
        $ItemsTable.$convertercycleUnit.toJson(cycleUnit),
      ),
      'cycleEvery': serializer.toJson<int>(cycleEvery),
      'anchorOn': serializer.toJson<LocalDate>(anchorOn),
      'paidUntil': serializer.toJson<LocalDate?>(paidUntil),
      'status': serializer.toJson<String>(
        $ItemsTable.$converterstatus.toJson(status),
      ),
      'statusSince': serializer.toJson<LocalDate?>(statusSince),
      'reminderRules': serializer.toJson<String>(reminderRules),
      'typeFields': serializer.toJson<String>(typeFields),
      'sharing': serializer.toJson<String?>(sharing),
      'note': serializer.toJson<String>(note),
    };
  }

  ItemRow copyWith({
    int? createdAt,
    int? updatedAt,
    String? id,
    ItemType? type,
    String? name,
    Value<String?> presetId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Currency? currency,
    CycleUnit? cycleUnit,
    int? cycleEvery,
    LocalDate? anchorOn,
    Value<LocalDate?> paidUntil = const Value.absent(),
    ItemStatus? status,
    Value<LocalDate?> statusSince = const Value.absent(),
    String? reminderRules,
    String? typeFields,
    Value<String?> sharing = const Value.absent(),
    String? note,
  }) => ItemRow(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    presetId: presetId.present ? presetId.value : this.presetId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    currency: currency ?? this.currency,
    cycleUnit: cycleUnit ?? this.cycleUnit,
    cycleEvery: cycleEvery ?? this.cycleEvery,
    anchorOn: anchorOn ?? this.anchorOn,
    paidUntil: paidUntil.present ? paidUntil.value : this.paidUntil,
    status: status ?? this.status,
    statusSince: statusSince.present ? statusSince.value : this.statusSince,
    reminderRules: reminderRules ?? this.reminderRules,
    typeFields: typeFields ?? this.typeFields,
    sharing: sharing.present ? sharing.value : this.sharing,
    note: note ?? this.note,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      currency: data.currency.present ? data.currency.value : this.currency,
      cycleUnit: data.cycleUnit.present ? data.cycleUnit.value : this.cycleUnit,
      cycleEvery: data.cycleEvery.present
          ? data.cycleEvery.value
          : this.cycleEvery,
      anchorOn: data.anchorOn.present ? data.anchorOn.value : this.anchorOn,
      paidUntil: data.paidUntil.present ? data.paidUntil.value : this.paidUntil,
      status: data.status.present ? data.status.value : this.status,
      statusSince: data.statusSince.present
          ? data.statusSince.value
          : this.statusSince,
      reminderRules: data.reminderRules.present
          ? data.reminderRules.value
          : this.reminderRules,
      typeFields: data.typeFields.present
          ? data.typeFields.value
          : this.typeFields,
      sharing: data.sharing.present ? data.sharing.value : this.sharing,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('presetId: $presetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('currency: $currency, ')
          ..write('cycleUnit: $cycleUnit, ')
          ..write('cycleEvery: $cycleEvery, ')
          ..write('anchorOn: $anchorOn, ')
          ..write('paidUntil: $paidUntil, ')
          ..write('status: $status, ')
          ..write('statusSince: $statusSince, ')
          ..write('reminderRules: $reminderRules, ')
          ..write('typeFields: $typeFields, ')
          ..write('sharing: $sharing, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    type,
    name,
    presetId,
    categoryId,
    accountId,
    currency,
    cycleUnit,
    cycleEvery,
    anchorOn,
    paidUntil,
    status,
    statusSince,
    reminderRules,
    typeFields,
    sharing,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.presetId == this.presetId &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.currency == this.currency &&
          other.cycleUnit == this.cycleUnit &&
          other.cycleEvery == this.cycleEvery &&
          other.anchorOn == this.anchorOn &&
          other.paidUntil == this.paidUntil &&
          other.status == this.status &&
          other.statusSince == this.statusSince &&
          other.reminderRules == this.reminderRules &&
          other.typeFields == this.typeFields &&
          other.sharing == this.sharing &&
          other.note == this.note);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> id;
  final Value<ItemType> type;
  final Value<String> name;
  final Value<String?> presetId;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<Currency> currency;
  final Value<CycleUnit> cycleUnit;
  final Value<int> cycleEvery;
  final Value<LocalDate> anchorOn;
  final Value<LocalDate?> paidUntil;
  final Value<ItemStatus> status;
  final Value<LocalDate?> statusSince;
  final Value<String> reminderRules;
  final Value<String> typeFields;
  final Value<String?> sharing;
  final Value<String> note;
  final Value<int> rowid;
  const ItemsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.presetId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.currency = const Value.absent(),
    this.cycleUnit = const Value.absent(),
    this.cycleEvery = const Value.absent(),
    this.anchorOn = const Value.absent(),
    this.paidUntil = const Value.absent(),
    this.status = const Value.absent(),
    this.statusSince = const Value.absent(),
    this.reminderRules = const Value.absent(),
    this.typeFields = const Value.absent(),
    this.sharing = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required int createdAt,
    required int updatedAt,
    required String id,
    required ItemType type,
    required String name,
    this.presetId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    required Currency currency,
    required CycleUnit cycleUnit,
    required int cycleEvery,
    required LocalDate anchorOn,
    this.paidUntil = const Value.absent(),
    required ItemStatus status,
    this.statusSince = const Value.absent(),
    this.reminderRules = const Value.absent(),
    this.typeFields = const Value.absent(),
    this.sharing = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       id = Value(id),
       type = Value(type),
       name = Value(name),
       currency = Value(currency),
       cycleUnit = Value(cycleUnit),
       cycleEvery = Value(cycleEvery),
       anchorOn = Value(anchorOn),
       status = Value(status);
  static Insertable<ItemRow> custom({
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? presetId,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? currency,
    Expression<String>? cycleUnit,
    Expression<int>? cycleEvery,
    Expression<String>? anchorOn,
    Expression<String>? paidUntil,
    Expression<String>? status,
    Expression<String>? statusSince,
    Expression<String>? reminderRules,
    Expression<String>? typeFields,
    Expression<String>? sharing,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (presetId != null) 'preset_id': presetId,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (currency != null) 'currency': currency,
      if (cycleUnit != null) 'cycle_unit': cycleUnit,
      if (cycleEvery != null) 'cycle_every': cycleEvery,
      if (anchorOn != null) 'anchor_on': anchorOn,
      if (paidUntil != null) 'paid_until': paidUntil,
      if (status != null) 'status': status,
      if (statusSince != null) 'status_since': statusSince,
      if (reminderRules != null) 'reminder_rules': reminderRules,
      if (typeFields != null) 'type_fields': typeFields,
      if (sharing != null) 'sharing': sharing,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? id,
    Value<ItemType>? type,
    Value<String>? name,
    Value<String?>? presetId,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<Currency>? currency,
    Value<CycleUnit>? cycleUnit,
    Value<int>? cycleEvery,
    Value<LocalDate>? anchorOn,
    Value<LocalDate?>? paidUntil,
    Value<ItemStatus>? status,
    Value<LocalDate?>? statusSince,
    Value<String>? reminderRules,
    Value<String>? typeFields,
    Value<String?>? sharing,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      presetId: presetId ?? this.presetId,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      currency: currency ?? this.currency,
      cycleUnit: cycleUnit ?? this.cycleUnit,
      cycleEvery: cycleEvery ?? this.cycleEvery,
      anchorOn: anchorOn ?? this.anchorOn,
      paidUntil: paidUntil ?? this.paidUntil,
      status: status ?? this.status,
      statusSince: statusSince ?? this.statusSince,
      reminderRules: reminderRules ?? this.reminderRules,
      typeFields: typeFields ?? this.typeFields,
      sharing: sharing ?? this.sharing,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ItemsTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<String>(presetId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $ItemsTable.$convertercurrency.toSql(currency.value),
      );
    }
    if (cycleUnit.present) {
      map['cycle_unit'] = Variable<String>(
        $ItemsTable.$convertercycleUnit.toSql(cycleUnit.value),
      );
    }
    if (cycleEvery.present) {
      map['cycle_every'] = Variable<int>(cycleEvery.value);
    }
    if (anchorOn.present) {
      map['anchor_on'] = Variable<String>(
        $ItemsTable.$converteranchorOn.toSql(anchorOn.value),
      );
    }
    if (paidUntil.present) {
      map['paid_until'] = Variable<String>(
        $ItemsTable.$converterpaidUntiln.toSql(paidUntil.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (statusSince.present) {
      map['status_since'] = Variable<String>(
        $ItemsTable.$converterstatusSincen.toSql(statusSince.value),
      );
    }
    if (reminderRules.present) {
      map['reminder_rules'] = Variable<String>(reminderRules.value);
    }
    if (typeFields.present) {
      map['type_fields'] = Variable<String>(typeFields.value);
    }
    if (sharing.present) {
      map['sharing'] = Variable<String>(sharing.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('presetId: $presetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('currency: $currency, ')
          ..write('cycleUnit: $cycleUnit, ')
          ..write('cycleEvery: $cycleEvery, ')
          ..write('anchorOn: $anchorOn, ')
          ..write('paidUntil: $paidUntil, ')
          ..write('status: $status, ')
          ..write('statusSince: $statusSince, ')
          ..write('reminderRules: $reminderRules, ')
          ..write('typeFields: $typeFields, ')
          ..write('sharing: $sharing, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PricePhasesTable extends PricePhases
    with TableInfo<$PricePhasesTable, PricePhaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PricePhasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthKindMeta = const VerificationMeta(
    'lengthKind',
  );
  @override
  late final GeneratedColumn<String> lengthKind = GeneratedColumn<String>(
    'length_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodsMeta = const VerificationMeta(
    'periods',
  );
  @override
  late final GeneratedColumn<int> periods = GeneratedColumn<int>(
    'periods',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> untilOn =
      GeneratedColumn<String>(
        'until_on',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($PricePhasesTable.$converteruntilOnn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    seq,
    amountMinor,
    lengthKind,
    periods,
    untilOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_phases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PricePhaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('length_kind')) {
      context.handle(
        _lengthKindMeta,
        lengthKind.isAcceptableOrUnknown(data['length_kind']!, _lengthKindMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthKindMeta);
    }
    if (data.containsKey('periods')) {
      context.handle(
        _periodsMeta,
        periods.isAcceptableOrUnknown(data['periods']!, _periodsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, seq},
  ];
  @override
  PricePhaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PricePhaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      lengthKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}length_kind'],
      )!,
      periods: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}periods'],
      ),
      untilOn: $PricePhasesTable.$converteruntilOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}until_on'],
        ),
      ),
    );
  }

  @override
  $PricePhasesTable createAlias(String alias) {
    return $PricePhasesTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converteruntilOn =
      const LocalDateConverter();
  static TypeConverter<LocalDate?, String?> $converteruntilOnn =
      NullAwareTypeConverter.wrap($converteruntilOn);
}

class PricePhaseRow extends DataClass implements Insertable<PricePhaseRow> {
  /// `<itemId>:<seq>`.
  final String id;
  final String itemId;
  final int seq;
  final int amountMinor;

  /// `periods`, `until` or `open`.
  final String lengthKind;
  final int? periods;
  final LocalDate? untilOn;
  const PricePhaseRow({
    required this.id,
    required this.itemId,
    required this.seq,
    required this.amountMinor,
    required this.lengthKind,
    this.periods,
    this.untilOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['seq'] = Variable<int>(seq);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['length_kind'] = Variable<String>(lengthKind);
    if (!nullToAbsent || periods != null) {
      map['periods'] = Variable<int>(periods);
    }
    if (!nullToAbsent || untilOn != null) {
      map['until_on'] = Variable<String>(
        $PricePhasesTable.$converteruntilOnn.toSql(untilOn),
      );
    }
    return map;
  }

  PricePhasesCompanion toCompanion(bool nullToAbsent) {
    return PricePhasesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      seq: Value(seq),
      amountMinor: Value(amountMinor),
      lengthKind: Value(lengthKind),
      periods: periods == null && nullToAbsent
          ? const Value.absent()
          : Value(periods),
      untilOn: untilOn == null && nullToAbsent
          ? const Value.absent()
          : Value(untilOn),
    );
  }

  factory PricePhaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PricePhaseRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      seq: serializer.fromJson<int>(json['seq']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      lengthKind: serializer.fromJson<String>(json['lengthKind']),
      periods: serializer.fromJson<int?>(json['periods']),
      untilOn: serializer.fromJson<LocalDate?>(json['untilOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'seq': serializer.toJson<int>(seq),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'lengthKind': serializer.toJson<String>(lengthKind),
      'periods': serializer.toJson<int?>(periods),
      'untilOn': serializer.toJson<LocalDate?>(untilOn),
    };
  }

  PricePhaseRow copyWith({
    String? id,
    String? itemId,
    int? seq,
    int? amountMinor,
    String? lengthKind,
    Value<int?> periods = const Value.absent(),
    Value<LocalDate?> untilOn = const Value.absent(),
  }) => PricePhaseRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    seq: seq ?? this.seq,
    amountMinor: amountMinor ?? this.amountMinor,
    lengthKind: lengthKind ?? this.lengthKind,
    periods: periods.present ? periods.value : this.periods,
    untilOn: untilOn.present ? untilOn.value : this.untilOn,
  );
  PricePhaseRow copyWithCompanion(PricePhasesCompanion data) {
    return PricePhaseRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seq: data.seq.present ? data.seq.value : this.seq,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      lengthKind: data.lengthKind.present
          ? data.lengthKind.value
          : this.lengthKind,
      periods: data.periods.present ? data.periods.value : this.periods,
      untilOn: data.untilOn.present ? data.untilOn.value : this.untilOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PricePhaseRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('seq: $seq, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('lengthKind: $lengthKind, ')
          ..write('periods: $periods, ')
          ..write('untilOn: $untilOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, seq, amountMinor, lengthKind, periods, untilOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PricePhaseRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.seq == this.seq &&
          other.amountMinor == this.amountMinor &&
          other.lengthKind == this.lengthKind &&
          other.periods == this.periods &&
          other.untilOn == this.untilOn);
}

class PricePhasesCompanion extends UpdateCompanion<PricePhaseRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<int> seq;
  final Value<int> amountMinor;
  final Value<String> lengthKind;
  final Value<int?> periods;
  final Value<LocalDate?> untilOn;
  final Value<int> rowid;
  const PricePhasesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.seq = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.lengthKind = const Value.absent(),
    this.periods = const Value.absent(),
    this.untilOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PricePhasesCompanion.insert({
    required String id,
    required String itemId,
    required int seq,
    required int amountMinor,
    required String lengthKind,
    this.periods = const Value.absent(),
    this.untilOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       seq = Value(seq),
       amountMinor = Value(amountMinor),
       lengthKind = Value(lengthKind);
  static Insertable<PricePhaseRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<int>? seq,
    Expression<int>? amountMinor,
    Expression<String>? lengthKind,
    Expression<int>? periods,
    Expression<String>? untilOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (seq != null) 'seq': seq,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (lengthKind != null) 'length_kind': lengthKind,
      if (periods != null) 'periods': periods,
      if (untilOn != null) 'until_on': untilOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PricePhasesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<int>? seq,
    Value<int>? amountMinor,
    Value<String>? lengthKind,
    Value<int?>? periods,
    Value<LocalDate?>? untilOn,
    Value<int>? rowid,
  }) {
    return PricePhasesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      seq: seq ?? this.seq,
      amountMinor: amountMinor ?? this.amountMinor,
      lengthKind: lengthKind ?? this.lengthKind,
      periods: periods ?? this.periods,
      untilOn: untilOn ?? this.untilOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (lengthKind.present) {
      map['length_kind'] = Variable<String>(lengthKind.value);
    }
    if (periods.present) {
      map['periods'] = Variable<int>(periods.value);
    }
    if (untilOn.present) {
      map['until_on'] = Variable<String>(
        $PricePhasesTable.$converteruntilOnn.toSql(untilOn.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PricePhasesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('seq: $seq, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('lengthKind: $lengthKind, ')
          ..write('periods: $periods, ')
          ..write('untilOn: $untilOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences
    with TableInfo<$OccurrencesTable, OccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cycleIndexMeta = const VerificationMeta(
    'cycleIndex',
  );
  @override
  late final GeneratedColumn<int> cycleIndex = GeneratedColumn<int>(
    'cycle_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> dueOn =
      GeneratedColumn<String>(
        'due_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($OccurrencesTable.$converterdueOn);
  static const VerificationMeta _expectedMinorMeta = const VerificationMeta(
    'expectedMinor',
  );
  @override
  late final GeneratedColumn<int> expectedMinor = GeneratedColumn<int>(
    'expected_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($OccurrencesTable.$convertercurrency);
  @override
  late final GeneratedColumnWithTypeConverter<OccurrenceState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OccurrenceState>($OccurrencesTable.$converterstate);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    cycleIndex,
    dueOn,
    expectedMinor,
    currency,
    state,
    transactionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('cycle_index')) {
      context.handle(
        _cycleIndexMeta,
        cycleIndex.isAcceptableOrUnknown(data['cycle_index']!, _cycleIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIndexMeta);
    }
    if (data.containsKey('expected_minor')) {
      context.handle(
        _expectedMinorMeta,
        expectedMinor.isAcceptableOrUnknown(
          data['expected_minor']!,
          _expectedMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedMinorMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, cycleIndex},
  ];
  @override
  OccurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      cycleIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_index'],
      )!,
      dueOn: $OccurrencesTable.$converterdueOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_on'],
        )!,
      ),
      expectedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_minor'],
      )!,
      currency: $OccurrencesTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
      state: $OccurrencesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdueOn =
      const LocalDateConverter();
  static TypeConverter<Currency, String> $convertercurrency =
      const CurrencyConverter();
  static JsonTypeConverter2<OccurrenceState, String, String> $converterstate =
      const EnumNameConverter<OccurrenceState>(OccurrenceState.values);
}

class OccurrenceRow extends DataClass implements Insertable<OccurrenceRow> {
  /// `<itemId>:<cycleIndex>`, so every device plans the same row.
  final String id;
  final String itemId;
  final int cycleIndex;
  final LocalDate dueOn;
  final int expectedMinor;
  final Currency currency;
  final OccurrenceState state;
  final String? transactionId;
  const OccurrenceRow({
    required this.id,
    required this.itemId,
    required this.cycleIndex,
    required this.dueOn,
    required this.expectedMinor,
    required this.currency,
    required this.state,
    this.transactionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['cycle_index'] = Variable<int>(cycleIndex);
    {
      map['due_on'] = Variable<String>(
        $OccurrencesTable.$converterdueOn.toSql(dueOn),
      );
    }
    map['expected_minor'] = Variable<int>(expectedMinor);
    {
      map['currency'] = Variable<String>(
        $OccurrencesTable.$convertercurrency.toSql(currency),
      );
    }
    {
      map['state'] = Variable<String>(
        $OccurrencesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      cycleIndex: Value(cycleIndex),
      dueOn: Value(dueOn),
      expectedMinor: Value(expectedMinor),
      currency: Value(currency),
      state: Value(state),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
    );
  }

  factory OccurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      cycleIndex: serializer.fromJson<int>(json['cycleIndex']),
      dueOn: serializer.fromJson<LocalDate>(json['dueOn']),
      expectedMinor: serializer.fromJson<int>(json['expectedMinor']),
      currency: serializer.fromJson<Currency>(json['currency']),
      state: $OccurrencesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'cycleIndex': serializer.toJson<int>(cycleIndex),
      'dueOn': serializer.toJson<LocalDate>(dueOn),
      'expectedMinor': serializer.toJson<int>(expectedMinor),
      'currency': serializer.toJson<Currency>(currency),
      'state': serializer.toJson<String>(
        $OccurrencesTable.$converterstate.toJson(state),
      ),
      'transactionId': serializer.toJson<String?>(transactionId),
    };
  }

  OccurrenceRow copyWith({
    String? id,
    String? itemId,
    int? cycleIndex,
    LocalDate? dueOn,
    int? expectedMinor,
    Currency? currency,
    OccurrenceState? state,
    Value<String?> transactionId = const Value.absent(),
  }) => OccurrenceRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    cycleIndex: cycleIndex ?? this.cycleIndex,
    dueOn: dueOn ?? this.dueOn,
    expectedMinor: expectedMinor ?? this.expectedMinor,
    currency: currency ?? this.currency,
    state: state ?? this.state,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
  );
  OccurrenceRow copyWithCompanion(OccurrencesCompanion data) {
    return OccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      cycleIndex: data.cycleIndex.present
          ? data.cycleIndex.value
          : this.cycleIndex,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      expectedMinor: data.expectedMinor.present
          ? data.expectedMinor.value
          : this.expectedMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      state: data.state.present ? data.state.value : this.state,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('cycleIndex: $cycleIndex, ')
          ..write('dueOn: $dueOn, ')
          ..write('expectedMinor: $expectedMinor, ')
          ..write('currency: $currency, ')
          ..write('state: $state, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    cycleIndex,
    dueOn,
    expectedMinor,
    currency,
    state,
    transactionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.cycleIndex == this.cycleIndex &&
          other.dueOn == this.dueOn &&
          other.expectedMinor == this.expectedMinor &&
          other.currency == this.currency &&
          other.state == this.state &&
          other.transactionId == this.transactionId);
}

class OccurrencesCompanion extends UpdateCompanion<OccurrenceRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<int> cycleIndex;
  final Value<LocalDate> dueOn;
  final Value<int> expectedMinor;
  final Value<Currency> currency;
  final Value<OccurrenceState> state;
  final Value<String?> transactionId;
  final Value<int> rowid;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.cycleIndex = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.expectedMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.state = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    required String id,
    required String itemId,
    required int cycleIndex,
    required LocalDate dueOn,
    required int expectedMinor,
    required Currency currency,
    required OccurrenceState state,
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       cycleIndex = Value(cycleIndex),
       dueOn = Value(dueOn),
       expectedMinor = Value(expectedMinor),
       currency = Value(currency),
       state = Value(state);
  static Insertable<OccurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<int>? cycleIndex,
    Expression<String>? dueOn,
    Expression<int>? expectedMinor,
    Expression<String>? currency,
    Expression<String>? state,
    Expression<String>? transactionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (cycleIndex != null) 'cycle_index': cycleIndex,
      if (dueOn != null) 'due_on': dueOn,
      if (expectedMinor != null) 'expected_minor': expectedMinor,
      if (currency != null) 'currency': currency,
      if (state != null) 'state': state,
      if (transactionId != null) 'transaction_id': transactionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<int>? cycleIndex,
    Value<LocalDate>? dueOn,
    Value<int>? expectedMinor,
    Value<Currency>? currency,
    Value<OccurrenceState>? state,
    Value<String?>? transactionId,
    Value<int>? rowid,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      dueOn: dueOn ?? this.dueOn,
      expectedMinor: expectedMinor ?? this.expectedMinor,
      currency: currency ?? this.currency,
      state: state ?? this.state,
      transactionId: transactionId ?? this.transactionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (cycleIndex.present) {
      map['cycle_index'] = Variable<int>(cycleIndex.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<String>(
        $OccurrencesTable.$converterdueOn.toSql(dueOn.value),
      );
    }
    if (expectedMinor.present) {
      map['expected_minor'] = Variable<int>(expectedMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $OccurrencesTable.$convertercurrency.toSql(currency.value),
      );
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $OccurrencesTable.$converterstate.toSql(state.value),
      );
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('cycleIndex: $cycleIndex, ')
          ..write('dueOn: $dueOn, ')
          ..write('expectedMinor: $expectedMinor, ')
          ..write('currency: $currency, ')
          ..write('state: $state, ')
          ..write('transactionId: $transactionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceHistoryTable extends PriceHistory
    with TableInfo<$PriceHistoryTable, PriceHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromCycleIndexMeta = const VerificationMeta(
    'fromCycleIndex',
  );
  @override
  late final GeneratedColumn<int> fromCycleIndex = GeneratedColumn<int>(
    'from_cycle_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> effectiveOn =
      GeneratedColumn<String>(
        'effective_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($PriceHistoryTable.$convertereffectiveOn);
  static const VerificationMeta _oldMinorMeta = const VerificationMeta(
    'oldMinor',
  );
  @override
  late final GeneratedColumn<int> oldMinor = GeneratedColumn<int>(
    'old_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newMinorMeta = const VerificationMeta(
    'newMinor',
  );
  @override
  late final GeneratedColumn<int> newMinor = GeneratedColumn<int>(
    'new_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($PriceHistoryTable.$convertercurrency);
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    fromCycleIndex,
    effectiveOn,
    oldMinor,
    newMinor,
    currency,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('from_cycle_index')) {
      context.handle(
        _fromCycleIndexMeta,
        fromCycleIndex.isAcceptableOrUnknown(
          data['from_cycle_index']!,
          _fromCycleIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCycleIndexMeta);
    }
    if (data.containsKey('old_minor')) {
      context.handle(
        _oldMinorMeta,
        oldMinor.isAcceptableOrUnknown(data['old_minor']!, _oldMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_oldMinorMeta);
    }
    if (data.containsKey('new_minor')) {
      context.handle(
        _newMinorMeta,
        newMinor.isAcceptableOrUnknown(data['new_minor']!, _newMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_newMinorMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      fromCycleIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_cycle_index'],
      )!,
      effectiveOn: $PriceHistoryTable.$convertereffectiveOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}effective_on'],
        )!,
      ),
      oldMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}old_minor'],
      )!,
      newMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_minor'],
      )!,
      currency: $PriceHistoryTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $PriceHistoryTable createAlias(String alias) {
    return $PriceHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $convertereffectiveOn =
      const LocalDateConverter();
  static TypeConverter<Currency, String> $convertercurrency =
      const CurrencyConverter();
}

class PriceHistoryRow extends DataClass implements Insertable<PriceHistoryRow> {
  final String id;
  final String itemId;
  final int fromCycleIndex;
  final LocalDate effectiveOn;
  final int oldMinor;
  final int newMinor;
  final Currency currency;
  final int recordedAt;
  const PriceHistoryRow({
    required this.id,
    required this.itemId,
    required this.fromCycleIndex,
    required this.effectiveOn,
    required this.oldMinor,
    required this.newMinor,
    required this.currency,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['from_cycle_index'] = Variable<int>(fromCycleIndex);
    {
      map['effective_on'] = Variable<String>(
        $PriceHistoryTable.$convertereffectiveOn.toSql(effectiveOn),
      );
    }
    map['old_minor'] = Variable<int>(oldMinor);
    map['new_minor'] = Variable<int>(newMinor);
    {
      map['currency'] = Variable<String>(
        $PriceHistoryTable.$convertercurrency.toSql(currency),
      );
    }
    map['recorded_at'] = Variable<int>(recordedAt);
    return map;
  }

  PriceHistoryCompanion toCompanion(bool nullToAbsent) {
    return PriceHistoryCompanion(
      id: Value(id),
      itemId: Value(itemId),
      fromCycleIndex: Value(fromCycleIndex),
      effectiveOn: Value(effectiveOn),
      oldMinor: Value(oldMinor),
      newMinor: Value(newMinor),
      currency: Value(currency),
      recordedAt: Value(recordedAt),
    );
  }

  factory PriceHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      fromCycleIndex: serializer.fromJson<int>(json['fromCycleIndex']),
      effectiveOn: serializer.fromJson<LocalDate>(json['effectiveOn']),
      oldMinor: serializer.fromJson<int>(json['oldMinor']),
      newMinor: serializer.fromJson<int>(json['newMinor']),
      currency: serializer.fromJson<Currency>(json['currency']),
      recordedAt: serializer.fromJson<int>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'fromCycleIndex': serializer.toJson<int>(fromCycleIndex),
      'effectiveOn': serializer.toJson<LocalDate>(effectiveOn),
      'oldMinor': serializer.toJson<int>(oldMinor),
      'newMinor': serializer.toJson<int>(newMinor),
      'currency': serializer.toJson<Currency>(currency),
      'recordedAt': serializer.toJson<int>(recordedAt),
    };
  }

  PriceHistoryRow copyWith({
    String? id,
    String? itemId,
    int? fromCycleIndex,
    LocalDate? effectiveOn,
    int? oldMinor,
    int? newMinor,
    Currency? currency,
    int? recordedAt,
  }) => PriceHistoryRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    fromCycleIndex: fromCycleIndex ?? this.fromCycleIndex,
    effectiveOn: effectiveOn ?? this.effectiveOn,
    oldMinor: oldMinor ?? this.oldMinor,
    newMinor: newMinor ?? this.newMinor,
    currency: currency ?? this.currency,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  PriceHistoryRow copyWithCompanion(PriceHistoryCompanion data) {
    return PriceHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      fromCycleIndex: data.fromCycleIndex.present
          ? data.fromCycleIndex.value
          : this.fromCycleIndex,
      effectiveOn: data.effectiveOn.present
          ? data.effectiveOn.value
          : this.effectiveOn,
      oldMinor: data.oldMinor.present ? data.oldMinor.value : this.oldMinor,
      newMinor: data.newMinor.present ? data.newMinor.value : this.newMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('fromCycleIndex: $fromCycleIndex, ')
          ..write('effectiveOn: $effectiveOn, ')
          ..write('oldMinor: $oldMinor, ')
          ..write('newMinor: $newMinor, ')
          ..write('currency: $currency, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    fromCycleIndex,
    effectiveOn,
    oldMinor,
    newMinor,
    currency,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceHistoryRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.fromCycleIndex == this.fromCycleIndex &&
          other.effectiveOn == this.effectiveOn &&
          other.oldMinor == this.oldMinor &&
          other.newMinor == this.newMinor &&
          other.currency == this.currency &&
          other.recordedAt == this.recordedAt);
}

class PriceHistoryCompanion extends UpdateCompanion<PriceHistoryRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<int> fromCycleIndex;
  final Value<LocalDate> effectiveOn;
  final Value<int> oldMinor;
  final Value<int> newMinor;
  final Value<Currency> currency;
  final Value<int> recordedAt;
  final Value<int> rowid;
  const PriceHistoryCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.fromCycleIndex = const Value.absent(),
    this.effectiveOn = const Value.absent(),
    this.oldMinor = const Value.absent(),
    this.newMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceHistoryCompanion.insert({
    required String id,
    required String itemId,
    required int fromCycleIndex,
    required LocalDate effectiveOn,
    required int oldMinor,
    required int newMinor,
    required Currency currency,
    required int recordedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       fromCycleIndex = Value(fromCycleIndex),
       effectiveOn = Value(effectiveOn),
       oldMinor = Value(oldMinor),
       newMinor = Value(newMinor),
       currency = Value(currency),
       recordedAt = Value(recordedAt);
  static Insertable<PriceHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<int>? fromCycleIndex,
    Expression<String>? effectiveOn,
    Expression<int>? oldMinor,
    Expression<int>? newMinor,
    Expression<String>? currency,
    Expression<int>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (fromCycleIndex != null) 'from_cycle_index': fromCycleIndex,
      if (effectiveOn != null) 'effective_on': effectiveOn,
      if (oldMinor != null) 'old_minor': oldMinor,
      if (newMinor != null) 'new_minor': newMinor,
      if (currency != null) 'currency': currency,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<int>? fromCycleIndex,
    Value<LocalDate>? effectiveOn,
    Value<int>? oldMinor,
    Value<int>? newMinor,
    Value<Currency>? currency,
    Value<int>? recordedAt,
    Value<int>? rowid,
  }) {
    return PriceHistoryCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      fromCycleIndex: fromCycleIndex ?? this.fromCycleIndex,
      effectiveOn: effectiveOn ?? this.effectiveOn,
      oldMinor: oldMinor ?? this.oldMinor,
      newMinor: newMinor ?? this.newMinor,
      currency: currency ?? this.currency,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (fromCycleIndex.present) {
      map['from_cycle_index'] = Variable<int>(fromCycleIndex.value);
    }
    if (effectiveOn.present) {
      map['effective_on'] = Variable<String>(
        $PriceHistoryTable.$convertereffectiveOn.toSql(effectiveOn.value),
      );
    }
    if (oldMinor.present) {
      map['old_minor'] = Variable<int>(oldMinor.value);
    }
    if (newMinor.present) {
      map['new_minor'] = Variable<int>(newMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $PriceHistoryTable.$convertercurrency.toSql(currency.value),
      );
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('fromCycleIndex: $fromCycleIndex, ')
          ..write('effectiveOn: $effectiveOn, ')
          ..write('oldMinor: $oldMinor, ')
          ..write('newMinor: $newMinor, ')
          ..write('currency: $currency, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($AccountsTable.$convertercurrency);
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditLimitMinorMeta = const VerificationMeta(
    'creditLimitMinor',
  );
  @override
  late final GeneratedColumn<int> creditLimitMinor = GeneratedColumn<int>(
    'credit_limit_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDueDayMeta = const VerificationMeta(
    'paymentDueDay',
  );
  @override
  late final GeneratedColumn<int> paymentDueDay = GeneratedColumn<int>(
    'payment_due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fxFeeBasisPointsMeta = const VerificationMeta(
    'fxFeeBasisPoints',
  );
  @override
  late final GeneratedColumn<int> fxFeeBasisPoints = GeneratedColumn<int>(
    'fx_fee_basis_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    type,
    name,
    currency,
    openingBalanceMinor,
    creditLimitMinor,
    statementDay,
    paymentDueDay,
    fxFeeBasisPoints,
    archived,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
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
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit_minor')) {
      context.handle(
        _creditLimitMinorMeta,
        creditLimitMinor.isAcceptableOrUnknown(
          data['credit_limit_minor']!,
          _creditLimitMinorMeta,
        ),
      );
    }
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    if (data.containsKey('payment_due_day')) {
      context.handle(
        _paymentDueDayMeta,
        paymentDueDay.isAcceptableOrUnknown(
          data['payment_due_day']!,
          _paymentDueDayMeta,
        ),
      );
    }
    if (data.containsKey('fx_fee_basis_points')) {
      context.handle(
        _fxFeeBasisPointsMeta,
        fxFeeBasisPoints.isAcceptableOrUnknown(
          data['fx_fee_basis_points']!,
          _fxFeeBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: $AccountsTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      creditLimitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_minor'],
      ),
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
      paymentDueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_due_day'],
      ),
      fxFeeBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fx_fee_basis_points'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
  static TypeConverter<Currency, String> $convertercurrency =
      const CurrencyConverter();
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int createdAt;
  final int updatedAt;
  final String id;
  final AccountType type;
  final String name;
  final Currency currency;

  /// Balance = opening balance + transactions; never stored separately.
  final int openingBalanceMinor;
  final int? creditLimitMinor;

  /// Day of month the statement closes / payment is due (credit cards).
  final int? statementDay;
  final int? paymentDueDay;

  /// Foreign transaction fee in basis points (150 = 1.5%).
  final int? fxFeeBasisPoints;
  final bool archived;
  final int sortOrder;
  const AccountRow({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.type,
    required this.name,
    required this.currency,
    required this.openingBalanceMinor,
    this.creditLimitMinor,
    this.statementDay,
    this.paymentDueDay,
    this.fxFeeBasisPoints,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['name'] = Variable<String>(name);
    {
      map['currency'] = Variable<String>(
        $AccountsTable.$convertercurrency.toSql(currency),
      );
    }
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    if (!nullToAbsent || creditLimitMinor != null) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor);
    }
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || paymentDueDay != null) {
      map['payment_due_day'] = Variable<int>(paymentDueDay);
    }
    if (!nullToAbsent || fxFeeBasisPoints != null) {
      map['fx_fee_basis_points'] = Variable<int>(fxFeeBasisPoints);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      type: Value(type),
      name: Value(name),
      currency: Value(currency),
      openingBalanceMinor: Value(openingBalanceMinor),
      creditLimitMinor: creditLimitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitMinor),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      paymentDueDay: paymentDueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDueDay),
      fxFeeBasisPoints: fxFeeBasisPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(fxFeeBasisPoints),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      id: serializer.fromJson<String>(json['id']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<Currency>(json['currency']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      creditLimitMinor: serializer.fromJson<int?>(json['creditLimitMinor']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      paymentDueDay: serializer.fromJson<int?>(json['paymentDueDay']),
      fxFeeBasisPoints: serializer.fromJson<int?>(json['fxFeeBasisPoints']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<Currency>(currency),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'creditLimitMinor': serializer.toJson<int?>(creditLimitMinor),
      'statementDay': serializer.toJson<int?>(statementDay),
      'paymentDueDay': serializer.toJson<int?>(paymentDueDay),
      'fxFeeBasisPoints': serializer.toJson<int?>(fxFeeBasisPoints),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AccountRow copyWith({
    int? createdAt,
    int? updatedAt,
    String? id,
    AccountType? type,
    String? name,
    Currency? currency,
    int? openingBalanceMinor,
    Value<int?> creditLimitMinor = const Value.absent(),
    Value<int?> statementDay = const Value.absent(),
    Value<int?> paymentDueDay = const Value.absent(),
    Value<int?> fxFeeBasisPoints = const Value.absent(),
    bool? archived,
    int? sortOrder,
  }) => AccountRow(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    creditLimitMinor: creditLimitMinor.present
        ? creditLimitMinor.value
        : this.creditLimitMinor,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    paymentDueDay: paymentDueDay.present
        ? paymentDueDay.value
        : this.paymentDueDay,
    fxFeeBasisPoints: fxFeeBasisPoints.present
        ? fxFeeBasisPoints.value
        : this.fxFeeBasisPoints,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      creditLimitMinor: data.creditLimitMinor.present
          ? data.creditLimitMinor.value
          : this.creditLimitMinor,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      paymentDueDay: data.paymentDueDay.present
          ? data.paymentDueDay.value
          : this.paymentDueDay,
      fxFeeBasisPoints: data.fxFeeBasisPoints.present
          ? data.fxFeeBasisPoints.value
          : this.fxFeeBasisPoints,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write('fxFeeBasisPoints: $fxFeeBasisPoints, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    type,
    name,
    currency,
    openingBalanceMinor,
    creditLimitMinor,
    statementDay,
    paymentDueDay,
    fxFeeBasisPoints,
    archived,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.creditLimitMinor == this.creditLimitMinor &&
          other.statementDay == this.statementDay &&
          other.paymentDueDay == this.paymentDueDay &&
          other.fxFeeBasisPoints == this.fxFeeBasisPoints &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> id;
  final Value<AccountType> type;
  final Value<String> name;
  final Value<Currency> currency;
  final Value<int> openingBalanceMinor;
  final Value<int?> creditLimitMinor;
  final Value<int?> statementDay;
  final Value<int?> paymentDueDay;
  final Value<int?> fxFeeBasisPoints;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AccountsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.fxFeeBasisPoints = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required int createdAt,
    required int updatedAt,
    required String id,
    required AccountType type,
    required String name,
    required Currency currency,
    this.openingBalanceMinor = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.fxFeeBasisPoints = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       id = Value(id),
       type = Value(type),
       name = Value(name),
       currency = Value(currency);
  static Insertable<AccountRow> custom({
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<int>? openingBalanceMinor,
    Expression<int>? creditLimitMinor,
    Expression<int>? statementDay,
    Expression<int>? paymentDueDay,
    Expression<int>? fxFeeBasisPoints,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (creditLimitMinor != null) 'credit_limit_minor': creditLimitMinor,
      if (statementDay != null) 'statement_day': statementDay,
      if (paymentDueDay != null) 'payment_due_day': paymentDueDay,
      if (fxFeeBasisPoints != null) 'fx_fee_basis_points': fxFeeBasisPoints,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? id,
    Value<AccountType>? type,
    Value<String>? name,
    Value<Currency>? currency,
    Value<int>? openingBalanceMinor,
    Value<int?>? creditLimitMinor,
    Value<int?>? statementDay,
    Value<int?>? paymentDueDay,
    Value<int?>? fxFeeBasisPoints,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      statementDay: statementDay ?? this.statementDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      fxFeeBasisPoints: fxFeeBasisPoints ?? this.fxFeeBasisPoints,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $AccountsTable.$convertercurrency.toSql(currency.value),
      );
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (creditLimitMinor.present) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor.value);
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (paymentDueDay.present) {
      map['payment_due_day'] = Variable<int>(paymentDueDay.value);
    }
    if (fxFeeBasisPoints.present) {
      map['fx_fee_basis_points'] = Variable<int>(fxFeeBasisPoints.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write('fxFeeBasisPoints: $fxFeeBasisPoints, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _builtinKeyMeta = const VerificationMeta(
    'builtinKey',
  );
  @override
  late final GeneratedColumn<String> builtinKey = GeneratedColumn<String>(
    'builtin_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _excludeFromWorkIncomeMeta =
      const VerificationMeta('excludeFromWorkIncome');
  @override
  late final GeneratedColumn<bool> excludeFromWorkIncome =
      GeneratedColumn<bool>(
        'exclude_from_work_income',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("exclude_from_work_income" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    kind,
    name,
    builtinKey,
    icon,
    sortOrder,
    excludeFromWorkIncome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('builtin_key')) {
      context.handle(
        _builtinKeyMeta,
        builtinKey.isAcceptableOrUnknown(data['builtin_key']!, _builtinKeyMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('exclude_from_work_income')) {
      context.handle(
        _excludeFromWorkIncomeMeta,
        excludeFromWorkIncome.isAcceptableOrUnknown(
          data['exclude_from_work_income']!,
          _excludeFromWorkIncomeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      builtinKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}builtin_key'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      excludeFromWorkIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_work_income'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String? parentId;
  final CategoryKind kind;

  /// User-entered name; empty for built-ins, which use [builtinKey].
  final String name;

  /// Localisation key of a built-in category, e.g. `streaming`.
  final String? builtinKey;
  final String? icon;
  final int sortOrder;

  /// Income that reports can leave out of work income (e.g. item sales).
  final bool excludeFromWorkIncome;
  const CategoryRow({
    required this.id,
    this.parentId,
    required this.kind,
    required this.name,
    this.builtinKey,
    this.icon,
    required this.sortOrder,
    required this.excludeFromWorkIncome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || builtinKey != null) {
      map['builtin_key'] = Variable<String>(builtinKey);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['exclude_from_work_income'] = Variable<bool>(excludeFromWorkIncome);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      kind: Value(kind),
      name: Value(name),
      builtinKey: builtinKey == null && nullToAbsent
          ? const Value.absent()
          : Value(builtinKey),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
      excludeFromWorkIncome: Value(excludeFromWorkIncome),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      name: serializer.fromJson<String>(json['name']),
      builtinKey: serializer.fromJson<String?>(json['builtinKey']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      excludeFromWorkIncome: serializer.fromJson<bool>(
        json['excludeFromWorkIncome'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'name': serializer.toJson<String>(name),
      'builtinKey': serializer.toJson<String?>(builtinKey),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'excludeFromWorkIncome': serializer.toJson<bool>(excludeFromWorkIncome),
    };
  }

  CategoryRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    CategoryKind? kind,
    String? name,
    Value<String?> builtinKey = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    int? sortOrder,
    bool? excludeFromWorkIncome,
  }) => CategoryRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    builtinKey: builtinKey.present ? builtinKey.value : this.builtinKey,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
    excludeFromWorkIncome: excludeFromWorkIncome ?? this.excludeFromWorkIncome,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      builtinKey: data.builtinKey.present
          ? data.builtinKey.value
          : this.builtinKey,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      excludeFromWorkIncome: data.excludeFromWorkIncome.present
          ? data.excludeFromWorkIncome.value
          : this.excludeFromWorkIncome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('builtinKey: $builtinKey, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('excludeFromWorkIncome: $excludeFromWorkIncome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    kind,
    name,
    builtinKey,
    icon,
    sortOrder,
    excludeFromWorkIncome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.builtinKey == this.builtinKey &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.excludeFromWorkIncome == this.excludeFromWorkIncome);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<CategoryKind> kind;
  final Value<String> name;
  final Value<String?> builtinKey;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<bool> excludeFromWorkIncome;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.builtinKey = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.excludeFromWorkIncome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required CategoryKind kind,
    this.name = const Value.absent(),
    this.builtinKey = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.excludeFromWorkIncome = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? builtinKey,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<bool>? excludeFromWorkIncome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (builtinKey != null) 'builtin_key': builtinKey,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (excludeFromWorkIncome != null)
        'exclude_from_work_income': excludeFromWorkIncome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<CategoryKind>? kind,
    Value<String>? name,
    Value<String?>? builtinKey,
    Value<String?>? icon,
    Value<int>? sortOrder,
    Value<bool>? excludeFromWorkIncome,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      builtinKey: builtinKey ?? this.builtinKey,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      excludeFromWorkIncome:
          excludeFromWorkIncome ?? this.excludeFromWorkIncome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (builtinKey.present) {
      map['builtin_key'] = Variable<String>(builtinKey.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (excludeFromWorkIncome.present) {
      map['exclude_from_work_income'] = Variable<bool>(
        excludeFromWorkIncome.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('builtinKey: $builtinKey, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('excludeFromWorkIncome: $excludeFromWorkIncome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TransactionStatus>($TransactionsTable.$converterstatus);
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency, String> currency =
      GeneratedColumn<String>(
        'currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Currency>($TransactionsTable.$convertercurrency);
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  @override
  late final GeneratedColumn<String> fxRate = GeneratedColumn<String>(
    'fx_rate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Currency?, String>
  fxMainCurrency = GeneratedColumn<String>(
    'fx_main_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Currency?>($TransactionsTable.$converterfxMainCurrencyn);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAmountMinorMeta = const VerificationMeta(
    'toAmountMinor',
  );
  @override
  late final GeneratedColumn<int> toAmountMinor = GeneratedColumn<int>(
    'to_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdjustmentMeta = const VerificationMeta(
    'isAdjustment',
  );
  @override
  late final GeneratedColumn<bool> isAdjustment = GeneratedColumn<bool>(
    'is_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adjustment" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    type,
    status,
    amountMinor,
    currency,
    fxRate,
    fxMainCurrency,
    accountId,
    toAccountId,
    toAmountMinor,
    categoryId,
    occurredAt,
    note,
    occurrenceId,
    isAdjustment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('fx_rate')) {
      context.handle(
        _fxRateMeta,
        fxRate.isAcceptableOrUnknown(data['fx_rate']!, _fxRateMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_amount_minor')) {
      context.handle(
        _toAmountMinorMeta,
        toAmountMinor.isAcceptableOrUnknown(
          data['to_amount_minor']!,
          _toAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('is_adjustment')) {
      context.handle(
        _isAdjustmentMeta,
        isAdjustment.isAcceptableOrUnknown(
          data['is_adjustment']!,
          _isAdjustmentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      status: $TransactionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: $TransactionsTable.$convertercurrency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}currency'],
        )!,
      ),
      fxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fx_rate'],
      ),
      fxMainCurrency: $TransactionsTable.$converterfxMainCurrencyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fx_main_currency'],
        ),
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      toAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_amount_minor'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      ),
      isAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adjustment'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
  static JsonTypeConverter2<TransactionStatus, String, String>
  $converterstatus = const EnumNameConverter<TransactionStatus>(
    TransactionStatus.values,
  );
  static TypeConverter<Currency, String> $convertercurrency =
      const CurrencyConverter();
  static TypeConverter<Currency, String> $converterfxMainCurrency =
      const CurrencyConverter();
  static TypeConverter<Currency?, String?> $converterfxMainCurrencyn =
      NullAwareTypeConverter.wrap($converterfxMainCurrency);
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int createdAt;
  final int updatedAt;
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final int amountMinor;
  final Currency currency;

  /// Main-currency units per one unit of [currency] at the time, as a decimal
  /// string. Fixed once confirmed; later rate changes never rewrite it.
  final String? fxRate;
  final Currency? fxMainCurrency;
  final String accountId;

  /// Transfers only.
  final String? toAccountId;
  final int? toAmountMinor;
  final String? categoryId;
  final int occurredAt;
  final String note;
  final String? occurrenceId;

  /// Created by reconciling a balance.
  final bool isAdjustment;
  const TransactionRow({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.type,
    required this.status,
    required this.amountMinor,
    required this.currency,
    this.fxRate,
    this.fxMainCurrency,
    required this.accountId,
    this.toAccountId,
    this.toAmountMinor,
    this.categoryId,
    required this.occurredAt,
    required this.note,
    this.occurrenceId,
    required this.isAdjustment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    {
      map['status'] = Variable<String>(
        $TransactionsTable.$converterstatus.toSql(status),
      );
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    {
      map['currency'] = Variable<String>(
        $TransactionsTable.$convertercurrency.toSql(currency),
      );
    }
    if (!nullToAbsent || fxRate != null) {
      map['fx_rate'] = Variable<String>(fxRate);
    }
    if (!nullToAbsent || fxMainCurrency != null) {
      map['fx_main_currency'] = Variable<String>(
        $TransactionsTable.$converterfxMainCurrencyn.toSql(fxMainCurrency),
      );
    }
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || toAmountMinor != null) {
      map['to_amount_minor'] = Variable<int>(toAmountMinor);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || occurrenceId != null) {
      map['occurrence_id'] = Variable<String>(occurrenceId);
    }
    map['is_adjustment'] = Variable<bool>(isAdjustment);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      type: Value(type),
      status: Value(status),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      fxRate: fxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(fxRate),
      fxMainCurrency: fxMainCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(fxMainCurrency),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      toAmountMinor: toAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(toAmountMinor),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      occurredAt: Value(occurredAt),
      note: Value(note),
      occurrenceId: occurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceId),
      isAdjustment: Value(isAdjustment),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      id: serializer.fromJson<String>(json['id']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      status: $TransactionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<Currency>(json['currency']),
      fxRate: serializer.fromJson<String?>(json['fxRate']),
      fxMainCurrency: serializer.fromJson<Currency?>(json['fxMainCurrency']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      toAmountMinor: serializer.fromJson<int?>(json['toAmountMinor']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      note: serializer.fromJson<String>(json['note']),
      occurrenceId: serializer.fromJson<String?>(json['occurrenceId']),
      isAdjustment: serializer.fromJson<bool>(json['isAdjustment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'status': serializer.toJson<String>(
        $TransactionsTable.$converterstatus.toJson(status),
      ),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<Currency>(currency),
      'fxRate': serializer.toJson<String?>(fxRate),
      'fxMainCurrency': serializer.toJson<Currency?>(fxMainCurrency),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'toAmountMinor': serializer.toJson<int?>(toAmountMinor),
      'categoryId': serializer.toJson<String?>(categoryId),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'note': serializer.toJson<String>(note),
      'occurrenceId': serializer.toJson<String?>(occurrenceId),
      'isAdjustment': serializer.toJson<bool>(isAdjustment),
    };
  }

  TransactionRow copyWith({
    int? createdAt,
    int? updatedAt,
    String? id,
    TransactionType? type,
    TransactionStatus? status,
    int? amountMinor,
    Currency? currency,
    Value<String?> fxRate = const Value.absent(),
    Value<Currency?> fxMainCurrency = const Value.absent(),
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<int?> toAmountMinor = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    int? occurredAt,
    String? note,
    Value<String?> occurrenceId = const Value.absent(),
    bool? isAdjustment,
  }) => TransactionRow(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    type: type ?? this.type,
    status: status ?? this.status,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    fxRate: fxRate.present ? fxRate.value : this.fxRate,
    fxMainCurrency: fxMainCurrency.present
        ? fxMainCurrency.value
        : this.fxMainCurrency,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    toAmountMinor: toAmountMinor.present
        ? toAmountMinor.value
        : this.toAmountMinor,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    occurredAt: occurredAt ?? this.occurredAt,
    note: note ?? this.note,
    occurrenceId: occurrenceId.present ? occurrenceId.value : this.occurrenceId,
    isAdjustment: isAdjustment ?? this.isAdjustment,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      fxMainCurrency: data.fxMainCurrency.present
          ? data.fxMainCurrency.value
          : this.fxMainCurrency,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      toAmountMinor: data.toAmountMinor.present
          ? data.toAmountMinor.value
          : this.toAmountMinor,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      note: data.note.present ? data.note.value : this.note,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      isAdjustment: data.isAdjustment.present
          ? data.isAdjustment.value
          : this.isAdjustment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('fxRate: $fxRate, ')
          ..write('fxMainCurrency: $fxMainCurrency, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('toAmountMinor: $toAmountMinor, ')
          ..write('categoryId: $categoryId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('isAdjustment: $isAdjustment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    type,
    status,
    amountMinor,
    currency,
    fxRate,
    fxMainCurrency,
    accountId,
    toAccountId,
    toAmountMinor,
    categoryId,
    occurredAt,
    note,
    occurrenceId,
    isAdjustment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.type == this.type &&
          other.status == this.status &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.fxRate == this.fxRate &&
          other.fxMainCurrency == this.fxMainCurrency &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.toAmountMinor == this.toAmountMinor &&
          other.categoryId == this.categoryId &&
          other.occurredAt == this.occurredAt &&
          other.note == this.note &&
          other.occurrenceId == this.occurrenceId &&
          other.isAdjustment == this.isAdjustment);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> id;
  final Value<TransactionType> type;
  final Value<TransactionStatus> status;
  final Value<int> amountMinor;
  final Value<Currency> currency;
  final Value<String?> fxRate;
  final Value<Currency?> fxMainCurrency;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<int?> toAmountMinor;
  final Value<String?> categoryId;
  final Value<int> occurredAt;
  final Value<String> note;
  final Value<String?> occurrenceId;
  final Value<bool> isAdjustment;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.fxMainCurrency = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.toAmountMinor = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.isAdjustment = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required int createdAt,
    required int updatedAt,
    required String id,
    required TransactionType type,
    required TransactionStatus status,
    required int amountMinor,
    required Currency currency,
    this.fxRate = const Value.absent(),
    this.fxMainCurrency = const Value.absent(),
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.toAmountMinor = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int occurredAt,
    this.note = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.isAdjustment = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       id = Value(id),
       type = Value(type),
       status = Value(status),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       accountId = Value(accountId),
       occurredAt = Value(occurredAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? status,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? fxRate,
    Expression<String>? fxMainCurrency,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<int>? toAmountMinor,
    Expression<String>? categoryId,
    Expression<int>? occurredAt,
    Expression<String>? note,
    Expression<String>? occurrenceId,
    Expression<bool>? isAdjustment,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (fxRate != null) 'fx_rate': fxRate,
      if (fxMainCurrency != null) 'fx_main_currency': fxMainCurrency,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (toAmountMinor != null) 'to_amount_minor': toAmountMinor,
      if (categoryId != null) 'category_id': categoryId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (note != null) 'note': note,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (isAdjustment != null) 'is_adjustment': isAdjustment,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? id,
    Value<TransactionType>? type,
    Value<TransactionStatus>? status,
    Value<int>? amountMinor,
    Value<Currency>? currency,
    Value<String?>? fxRate,
    Value<Currency?>? fxMainCurrency,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<int?>? toAmountMinor,
    Value<String?>? categoryId,
    Value<int>? occurredAt,
    Value<String>? note,
    Value<String?>? occurrenceId,
    Value<bool>? isAdjustment,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      fxRate: fxRate ?? this.fxRate,
      fxMainCurrency: fxMainCurrency ?? this.fxMainCurrency,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      toAmountMinor: toAmountMinor ?? this.toAmountMinor,
      categoryId: categoryId ?? this.categoryId,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      isAdjustment: isAdjustment ?? this.isAdjustment,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TransactionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(
        $TransactionsTable.$convertercurrency.toSql(currency.value),
      );
    }
    if (fxRate.present) {
      map['fx_rate'] = Variable<String>(fxRate.value);
    }
    if (fxMainCurrency.present) {
      map['fx_main_currency'] = Variable<String>(
        $TransactionsTable.$converterfxMainCurrencyn.toSql(
          fxMainCurrency.value,
        ),
      );
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (toAmountMinor.present) {
      map['to_amount_minor'] = Variable<int>(toAmountMinor.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (isAdjustment.present) {
      map['is_adjustment'] = Variable<bool>(isAdjustment.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('fxRate: $fxRate, ')
          ..write('fxMainCurrency: $fxMainCurrency, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('toAmountMinor: $toAmountMinor, ')
          ..write('categoryId: $categoryId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('isAdjustment: $isAdjustment, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  const TagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({String? id, String? name}) =>
      TagRow(id: id ?? this.id, name: name ?? this.name);
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionTagsTable extends TransactionTags
    with TableInfo<$TransactionTagsTable, TransactionTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [transactionId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, tagId};
  @override
  TransactionTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionTagRow(
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $TransactionTagsTable createAlias(String alias) {
    return $TransactionTagsTable(attachedDatabase, alias);
  }
}

class TransactionTagRow extends DataClass
    implements Insertable<TransactionTagRow> {
  final String transactionId;
  final String tagId;
  const TransactionTagRow({required this.transactionId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  TransactionTagsCompanion toCompanion(bool nullToAbsent) {
    return TransactionTagsCompanion(
      transactionId: Value(transactionId),
      tagId: Value(tagId),
    );
  }

  factory TransactionTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionTagRow(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  TransactionTagRow copyWith({String? transactionId, String? tagId}) =>
      TransactionTagRow(
        transactionId: transactionId ?? this.transactionId,
        tagId: tagId ?? this.tagId,
      );
  TransactionTagRow copyWithCompanion(TransactionTagsCompanion data) {
    return TransactionTagRow(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagRow(')
          ..write('transactionId: $transactionId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(transactionId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionTagRow &&
          other.transactionId == this.transactionId &&
          other.tagId == this.tagId);
}

class TransactionTagsCompanion extends UpdateCompanion<TransactionTagRow> {
  final Value<String> transactionId;
  final Value<String> tagId;
  final Value<int> rowid;
  const TransactionTagsCompanion({
    this.transactionId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionTagsCompanion.insert({
    required String transactionId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : transactionId = Value(transactionId),
       tagId = Value(tagId);
  static Insertable<TransactionTagRow> custom({
    Expression<String>? transactionId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionTagsCompanion copyWith({
    Value<String>? transactionId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return TransactionTagsCompanion(
      transactionId: transactionId ?? this.transactionId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
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
    transactionId,
    fileName,
    mimeType,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
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
  AttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentRow extends DataClass implements Insertable<AttachmentRow> {
  final String id;
  final String transactionId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final int createdAt;
  const AttachmentRow({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentRow(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AttachmentRow copyWith({
    String? id,
    String? transactionId,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    int? createdAt,
  }) => AttachmentRow(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentRow copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, fileName, mimeType, sizeBytes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentRow> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String transactionId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       createdAt = Value(createdAt);
  static Insertable<AttachmentRow> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
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
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
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
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AliasesTable extends Aliases with TableInfo<$AliasesTable, AliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<String> presetId = GeneratedColumn<String>(
    'preset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
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
  List<GeneratedColumn> get $columns => [id, presetId, alias, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<AliasRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_presetIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {alias},
  ];
  @override
  AliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AliasRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AliasesTable createAlias(String alias) {
    return $AliasesTable(attachedDatabase, alias);
  }
}

class AliasRow extends DataClass implements Insertable<AliasRow> {
  final String id;
  final String presetId;

  /// Normalised (case-folded, trimmed) text that should match the preset.
  final String alias;
  final int createdAt;
  const AliasRow({
    required this.id,
    required this.presetId,
    required this.alias,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['preset_id'] = Variable<String>(presetId);
    map['alias'] = Variable<String>(alias);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AliasesCompanion toCompanion(bool nullToAbsent) {
    return AliasesCompanion(
      id: Value(id),
      presetId: Value(presetId),
      alias: Value(alias),
      createdAt: Value(createdAt),
    );
  }

  factory AliasRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AliasRow(
      id: serializer.fromJson<String>(json['id']),
      presetId: serializer.fromJson<String>(json['presetId']),
      alias: serializer.fromJson<String>(json['alias']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'presetId': serializer.toJson<String>(presetId),
      'alias': serializer.toJson<String>(alias),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AliasRow copyWith({
    String? id,
    String? presetId,
    String? alias,
    int? createdAt,
  }) => AliasRow(
    id: id ?? this.id,
    presetId: presetId ?? this.presetId,
    alias: alias ?? this.alias,
    createdAt: createdAt ?? this.createdAt,
  );
  AliasRow copyWithCompanion(AliasesCompanion data) {
    return AliasRow(
      id: data.id.present ? data.id.value : this.id,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      alias: data.alias.present ? data.alias.value : this.alias,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AliasRow(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('alias: $alias, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, presetId, alias, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AliasRow &&
          other.id == this.id &&
          other.presetId == this.presetId &&
          other.alias == this.alias &&
          other.createdAt == this.createdAt);
}

class AliasesCompanion extends UpdateCompanion<AliasRow> {
  final Value<String> id;
  final Value<String> presetId;
  final Value<String> alias;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AliasesCompanion({
    this.id = const Value.absent(),
    this.presetId = const Value.absent(),
    this.alias = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AliasesCompanion.insert({
    required String id,
    required String presetId,
    required String alias,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       presetId = Value(presetId),
       alias = Value(alias),
       createdAt = Value(createdAt);
  static Insertable<AliasRow> custom({
    Expression<String>? id,
    Expression<String>? presetId,
    Expression<String>? alias,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presetId != null) 'preset_id': presetId,
      if (alias != null) 'alias': alias,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? presetId,
    Value<String>? alias,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AliasesCompanion(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      alias: alias ?? this.alias,
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
    if (presetId.present) {
      map['preset_id'] = Variable<String>(presetId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
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
    return (StringBuffer('AliasesCompanion(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('alias: $alias, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderLogTable extends ReminderLog
    with TableInfo<$ReminderLogTable, ReminderLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<int> scheduledAt = GeneratedColumn<int>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<int> deliveredAt = GeneratedColumn<int>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    occurrenceId,
    kind,
    scheduledAt,
    deliveredAt,
    action,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_at'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivered_at'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      ),
    );
  }

  @override
  $ReminderLogTable createAlias(String alias) {
    return $ReminderLogTable(attachedDatabase, alias);
  }
}

class ReminderLogRow extends DataClass implements Insertable<ReminderLogRow> {
  final String id;
  final String? itemId;
  final String? occurrenceId;
  final String kind;
  final int scheduledAt;
  final int? deliveredAt;

  /// What the user did from the notification: `paid`, `snoozed`, or null.
  final String? action;
  const ReminderLogRow({
    required this.id,
    this.itemId,
    this.occurrenceId,
    required this.kind,
    required this.scheduledAt,
    this.deliveredAt,
    this.action,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || occurrenceId != null) {
      map['occurrence_id'] = Variable<String>(occurrenceId);
    }
    map['kind'] = Variable<String>(kind);
    map['scheduled_at'] = Variable<int>(scheduledAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<int>(deliveredAt);
    }
    if (!nullToAbsent || action != null) {
      map['action'] = Variable<String>(action);
    }
    return map;
  }

  ReminderLogCompanion toCompanion(bool nullToAbsent) {
    return ReminderLogCompanion(
      id: Value(id),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      occurrenceId: occurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceId),
      kind: Value(kind),
      scheduledAt: Value(scheduledAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      action: action == null && nullToAbsent
          ? const Value.absent()
          : Value(action),
    );
  }

  factory ReminderLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderLogRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      occurrenceId: serializer.fromJson<String?>(json['occurrenceId']),
      kind: serializer.fromJson<String>(json['kind']),
      scheduledAt: serializer.fromJson<int>(json['scheduledAt']),
      deliveredAt: serializer.fromJson<int?>(json['deliveredAt']),
      action: serializer.fromJson<String?>(json['action']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String?>(itemId),
      'occurrenceId': serializer.toJson<String?>(occurrenceId),
      'kind': serializer.toJson<String>(kind),
      'scheduledAt': serializer.toJson<int>(scheduledAt),
      'deliveredAt': serializer.toJson<int?>(deliveredAt),
      'action': serializer.toJson<String?>(action),
    };
  }

  ReminderLogRow copyWith({
    String? id,
    Value<String?> itemId = const Value.absent(),
    Value<String?> occurrenceId = const Value.absent(),
    String? kind,
    int? scheduledAt,
    Value<int?> deliveredAt = const Value.absent(),
    Value<String?> action = const Value.absent(),
  }) => ReminderLogRow(
    id: id ?? this.id,
    itemId: itemId.present ? itemId.value : this.itemId,
    occurrenceId: occurrenceId.present ? occurrenceId.value : this.occurrenceId,
    kind: kind ?? this.kind,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
    action: action.present ? action.value : this.action,
  );
  ReminderLogRow copyWithCompanion(ReminderLogCompanion data) {
    return ReminderLogRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
      action: data.action.present ? data.action.value : this.action,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderLogRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('kind: $kind, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('action: $action')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    occurrenceId,
    kind,
    scheduledAt,
    deliveredAt,
    action,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderLogRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.occurrenceId == this.occurrenceId &&
          other.kind == this.kind &&
          other.scheduledAt == this.scheduledAt &&
          other.deliveredAt == this.deliveredAt &&
          other.action == this.action);
}

class ReminderLogCompanion extends UpdateCompanion<ReminderLogRow> {
  final Value<String> id;
  final Value<String?> itemId;
  final Value<String?> occurrenceId;
  final Value<String> kind;
  final Value<int> scheduledAt;
  final Value<int?> deliveredAt;
  final Value<String?> action;
  final Value<int> rowid;
  const ReminderLogCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.action = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderLogCompanion.insert({
    required String id,
    this.itemId = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    required String kind,
    required int scheduledAt,
    this.deliveredAt = const Value.absent(),
    this.action = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       scheduledAt = Value(scheduledAt);
  static Insertable<ReminderLogRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? occurrenceId,
    Expression<String>? kind,
    Expression<int>? scheduledAt,
    Expression<int>? deliveredAt,
    Expression<String>? action,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (kind != null) 'kind': kind,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (action != null) 'action': action,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderLogCompanion copyWith({
    Value<String>? id,
    Value<String?>? itemId,
    Value<String?>? occurrenceId,
    Value<String>? kind,
    Value<int>? scheduledAt,
    Value<int?>? deliveredAt,
    Value<String?>? action,
    Value<int>? rowid,
  }) {
    return ReminderLogCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      kind: kind ?? this.kind,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      action: action ?? this.action,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(scheduledAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<int>(deliveredAt.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderLogCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('kind: $kind, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('action: $action, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeLogTable extends ChangeLog
    with TableInfo<$ChangeLogTable, ChangeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    entity,
    rowId,
    field,
    value,
    hlc,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  ChangeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $ChangeLogTable createAlias(String alias) {
    return $ChangeLogTable(attachedDatabase, alias);
  }
}

class ChangeLogRow extends DataClass implements Insertable<ChangeLogRow> {
  final int seq;
  final String entity;
  final String rowId;

  /// SQL column name, or `_deleted` for a tombstone.
  final String field;

  /// JSON-encoded SQL value.
  final String value;

  /// Packed HLC; the newer one wins when devices merge.
  final String hlc;
  final bool uploaded;
  const ChangeLogRow({
    required this.seq,
    required this.entity,
    required this.rowId,
    required this.field,
    required this.value,
    required this.hlc,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['field'] = Variable<String>(field);
    map['value'] = Variable<String>(value);
    map['hlc'] = Variable<String>(hlc);
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  ChangeLogCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogCompanion(
      seq: Value(seq),
      entity: Value(entity),
      rowId: Value(rowId),
      field: Value(field),
      value: Value(value),
      hlc: Value(hlc),
      uploaded: Value(uploaded),
    );
  }

  factory ChangeLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogRow(
      seq: serializer.fromJson<int>(json['seq']),
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      field: serializer.fromJson<String>(json['field']),
      value: serializer.fromJson<String>(json['value']),
      hlc: serializer.fromJson<String>(json['hlc']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'field': serializer.toJson<String>(field),
      'value': serializer.toJson<String>(value),
      'hlc': serializer.toJson<String>(hlc),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  ChangeLogRow copyWith({
    int? seq,
    String? entity,
    String? rowId,
    String? field,
    String? value,
    String? hlc,
    bool? uploaded,
  }) => ChangeLogRow(
    seq: seq ?? this.seq,
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    field: field ?? this.field,
    value: value ?? this.value,
    hlc: hlc ?? this.hlc,
    uploaded: uploaded ?? this.uploaded,
  );
  ChangeLogRow copyWithCompanion(ChangeLogCompanion data) {
    return ChangeLogRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      field: data.field.present ? data.field.value : this.field,
      value: data.value.present ? data.value.value : this.value,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogRow(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('hlc: $hlc, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, entity, rowId, field, value, hlc, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogRow &&
          other.seq == this.seq &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.field == this.field &&
          other.value == this.value &&
          other.hlc == this.hlc &&
          other.uploaded == this.uploaded);
}

class ChangeLogCompanion extends UpdateCompanion<ChangeLogRow> {
  final Value<int> seq;
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> field;
  final Value<String> value;
  final Value<String> hlc;
  final Value<bool> uploaded;
  const ChangeLogCompanion({
    this.seq = const Value.absent(),
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.field = const Value.absent(),
    this.value = const Value.absent(),
    this.hlc = const Value.absent(),
    this.uploaded = const Value.absent(),
  });
  ChangeLogCompanion.insert({
    this.seq = const Value.absent(),
    required String entity,
    required String rowId,
    required String field,
    required String value,
    required String hlc,
    this.uploaded = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId),
       field = Value(field),
       value = Value(value),
       hlc = Value(hlc);
  static Insertable<ChangeLogRow> custom({
    Expression<int>? seq,
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? field,
    Expression<String>? value,
    Expression<String>? hlc,
    Expression<bool>? uploaded,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (field != null) 'field': field,
      if (value != null) 'value': value,
      if (hlc != null) 'hlc': hlc,
      if (uploaded != null) 'uploaded': uploaded,
    });
  }

  ChangeLogCompanion copyWith({
    Value<int>? seq,
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? field,
    Value<String>? value,
    Value<String>? hlc,
    Value<bool>? uploaded,
  }) {
    return ChangeLogCompanion(
      seq: seq ?? this.seq,
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      field: field ?? this.field,
      value: value ?? this.value,
      hlc: hlc ?? this.hlc,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogCompanion(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('hlc: $hlc, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $PricePhasesTable pricePhases = $PricePhasesTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $PriceHistoryTable priceHistory = $PriceHistoryTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TransactionTagsTable transactionTags = $TransactionTagsTable(
    this,
  );
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AliasesTable aliases = $AliasesTable(this);
  late final $ReminderLogTable reminderLog = $ReminderLogTable(this);
  late final $ChangeLogTable changeLog = $ChangeLogTable(this);
  late final $MetaTable meta = $MetaTable(this);
  late final Index occurrencesDue = Index(
    'occurrences_due',
    'CREATE INDEX occurrences_due ON occurrences (due_on)',
  );
  late final Index transactionsOccurred = Index(
    'transactions_occurred',
    'CREATE INDEX transactions_occurred ON transactions (occurred_at)',
  );
  late final Index transactionsAccount = Index(
    'transactions_account',
    'CREATE INDEX transactions_account ON transactions (account_id)',
  );
  late final Index changeLogRow = Index(
    'change_log_row',
    'CREATE INDEX change_log_row ON change_log (entity, row_id, field)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    items,
    pricePhases,
    occurrences,
    priceHistory,
    accounts,
    categories,
    transactions,
    tags,
    transactionTags,
    attachments,
    aliases,
    reminderLog,
    changeLog,
    meta,
    occurrencesDue,
    transactionsOccurred,
    transactionsAccount,
    changeLogRow,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('price_phases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('occurrences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('price_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required int createdAt,
  required int updatedAt,
  required String id,
  required ItemType type,
  required String name,
  Value<String?> presetId,
  Value<String?> categoryId,
  Value<String?> accountId,
  required Currency currency,
  required CycleUnit cycleUnit,
  required int cycleEvery,
  required LocalDate anchorOn,
  Value<LocalDate?> paidUntil,
  required ItemStatus status,
  Value<LocalDate?> statusSince,
  Value<String> reminderRules,
  Value<String> typeFields,
  Value<String?> sharing,
  Value<String> note,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> id,
  Value<ItemType> type,
  Value<String> name,
  Value<String?> presetId,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<Currency> currency,
  Value<CycleUnit> cycleUnit,
  Value<int> cycleEvery,
  Value<LocalDate> anchorOn,
  Value<LocalDate?> paidUntil,
  Value<ItemStatus> status,
  Value<LocalDate?> statusSince,
  Value<String> reminderRules,
  Value<String> typeFields,
  Value<String?> sharing,
  Value<String> note,
  Value<int> rowid,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, ItemRow> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PricePhasesTable, List<PricePhaseRow>>
  _pricePhasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pricePhases,
    aliasName: 'items__id__price_phases__item_id',
  );

  $$PricePhasesTableProcessedTableManager get pricePhasesRefs {
    final manager = $$PricePhasesTableTableManager(
      $_db,
      $_db.pricePhases,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pricePhasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OccurrencesTable, List<OccurrenceRow>>
  _occurrencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.occurrences,
    aliasName: 'items__id__occurrences__item_id',
  );

  $$OccurrencesTableProcessedTableManager get occurrencesRefs {
    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_occurrencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PriceHistoryTable, List<PriceHistoryRow>>
  _priceHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceHistory,
    aliasName: 'items__id__price_history__item_id',
  );

  $$PriceHistoryTableProcessedTableManager get priceHistoryRefs {
    final manager = $$PriceHistoryTableTableManager(
      $_db,
      $_db.priceHistory,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemType, ItemType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CycleUnit, CycleUnit, String> get cycleUnit =>
      $composableBuilder(
        column: $table.cycleUnit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get cycleEvery => $composableBuilder(
    column: $table.cycleEvery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get anchorOn =>
      $composableBuilder(
        column: $table.anchorOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get paidUntil =>
      $composableBuilder(
        column: $table.paidUntil,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String>
  get statusSince => $composableBuilder(
    column: $table.statusSince,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reminderRules => $composableBuilder(
    column: $table.reminderRules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeFields => $composableBuilder(
    column: $table.typeFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharing => $composableBuilder(
    column: $table.sharing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pricePhasesRefs(
    Expression<bool> Function($$PricePhasesTableFilterComposer f) f,
  ) {
    final $$PricePhasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePhases,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePhasesTableFilterComposer(
            $db: $db,
            $table: $db.pricePhases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> occurrencesRefs(
    Expression<bool> Function($$OccurrencesTableFilterComposer f) f,
  ) {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> priceHistoryRefs(
    Expression<bool> Function($$PriceHistoryTableFilterComposer f) f,
  ) {
    final $$PriceHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableFilterComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleUnit => $composableBuilder(
    column: $table.cycleUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleEvery => $composableBuilder(
    column: $table.cycleEvery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorOn => $composableBuilder(
    column: $table.anchorOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidUntil => $composableBuilder(
    column: $table.paidUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusSince => $composableBuilder(
    column: $table.statusSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderRules => $composableBuilder(
    column: $table.reminderRules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeFields => $composableBuilder(
    column: $table.typeFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharing => $composableBuilder(
    column: $table.sharing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CycleUnit, String> get cycleUnit =>
      $composableBuilder(column: $table.cycleUnit, builder: (column) => column);

  GeneratedColumn<int> get cycleEvery => $composableBuilder(
    column: $table.cycleEvery,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get anchorOn =>
      $composableBuilder(column: $table.anchorOn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get paidUntil =>
      $composableBuilder(column: $table.paidUntil, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get statusSince =>
      $composableBuilder(
        column: $table.statusSince,
        builder: (column) => column,
      );

  GeneratedColumn<String> get reminderRules => $composableBuilder(
    column: $table.reminderRules,
    builder: (column) => column,
  );

  GeneratedColumn<String> get typeFields => $composableBuilder(
    column: $table.typeFields,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharing =>
      $composableBuilder(column: $table.sharing, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> pricePhasesRefs<T extends Object>(
    Expression<T> Function($$PricePhasesTableAnnotationComposer a) f,
  ) {
    final $$PricePhasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePhases,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePhasesTableAnnotationComposer(
            $db: $db,
            $table: $db.pricePhases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> occurrencesRefs<T extends Object>(
    Expression<T> Function($$OccurrencesTableAnnotationComposer a) f,
  ) {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> priceHistoryRefs<T extends Object>(
    Expression<T> Function($$PriceHistoryTableAnnotationComposer a) f,
  ) {
    final $$PriceHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          ItemRow,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemRow, $$ItemsTableReferences),
          ItemRow,
          PrefetchHooks Function({
            bool pricePhasesRefs,
            bool occurrencesRefs,
            bool priceHistoryRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<ItemType> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> presetId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<Currency> currency = const Value.absent(),
                Value<CycleUnit> cycleUnit = const Value.absent(),
                Value<int> cycleEvery = const Value.absent(),
                Value<LocalDate> anchorOn = const Value.absent(),
                Value<LocalDate?> paidUntil = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<LocalDate?> statusSince = const Value.absent(),
                Value<String> reminderRules = const Value.absent(),
                Value<String> typeFields = const Value.absent(),
                Value<String?> sharing = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                name: name,
                presetId: presetId,
                categoryId: categoryId,
                accountId: accountId,
                currency: currency,
                cycleUnit: cycleUnit,
                cycleEvery: cycleEvery,
                anchorOn: anchorOn,
                paidUntil: paidUntil,
                status: status,
                statusSince: statusSince,
                reminderRules: reminderRules,
                typeFields: typeFields,
                sharing: sharing,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int createdAt,
                required int updatedAt,
                required String id,
                required ItemType type,
                required String name,
                Value<String?> presetId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                required Currency currency,
                required CycleUnit cycleUnit,
                required int cycleEvery,
                required LocalDate anchorOn,
                Value<LocalDate?> paidUntil = const Value.absent(),
                required ItemStatus status,
                Value<LocalDate?> statusSince = const Value.absent(),
                Value<String> reminderRules = const Value.absent(),
                Value<String> typeFields = const Value.absent(),
                Value<String?> sharing = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                name: name,
                presetId: presetId,
                categoryId: categoryId,
                accountId: accountId,
                currency: currency,
                cycleUnit: cycleUnit,
                cycleEvery: cycleEvery,
                anchorOn: anchorOn,
                paidUntil: paidUntil,
                status: status,
                statusSince: statusSince,
                reminderRules: reminderRules,
                typeFields: typeFields,
                sharing: sharing,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, ItemRow>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pricePhasesRefs = false,
                occurrencesRefs = false,
                priceHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pricePhasesRefs) db.pricePhases,
                    if (occurrencesRefs) db.occurrences,
                    if (priceHistoryRefs) db.priceHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pricePhasesRefs)
                        await $_getPrefetchedDataByColumns<
                          ItemRow,
                          $ItemsTable,
                          PricePhaseRow,
                          $PricePhasesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._pricePhasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).pricePhasesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (occurrencesRefs)
                        await $_getPrefetchedDataByColumns<
                          ItemRow,
                          $ItemsTable,
                          OccurrenceRow,
                          $OccurrencesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._occurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).occurrencesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (priceHistoryRefs)
                        await $_getPrefetchedDataByColumns<
                          ItemRow,
                          $ItemsTable,
                          PriceHistoryRow,
                          $PriceHistoryTable
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._priceHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceHistoryRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      ItemRow,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemRow, $$ItemsTableReferences),
      ItemRow,
      PrefetchHooks Function({
        bool pricePhasesRefs,
        bool occurrencesRefs,
        bool priceHistoryRefs,
      })
    >;
typedef $$PricePhasesTableCreateCompanionBuilder =
    PricePhasesCompanion Function({
      required String id,
      required String itemId,
      required int seq,
      required int amountMinor,
      required String lengthKind,
      Value<int?> periods,
      Value<LocalDate?> untilOn,
      Value<int> rowid,
    });
typedef $$PricePhasesTableUpdateCompanionBuilder =
    PricePhasesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<int> seq,
      Value<int> amountMinor,
      Value<String> lengthKind,
      Value<int?> periods,
      Value<LocalDate?> untilOn,
      Value<int> rowid,
    });

final class $$PricePhasesTableReferences
    extends BaseReferences<_$AppDatabase, $PricePhasesTable, PricePhaseRow> {
  $$PricePhasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('price_phases__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PricePhasesTableFilterComposer
    extends Composer<_$AppDatabase, $PricePhasesTable> {
  $$PricePhasesTableFilterComposer({
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

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lengthKind => $composableBuilder(
    column: $table.lengthKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periods => $composableBuilder(
    column: $table.periods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate?, LocalDate, String> get untilOn =>
      $composableBuilder(
        column: $table.untilOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePhasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PricePhasesTable> {
  $$PricePhasesTableOrderingComposer({
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

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lengthKind => $composableBuilder(
    column: $table.lengthKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periods => $composableBuilder(
    column: $table.periods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get untilOn => $composableBuilder(
    column: $table.untilOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePhasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PricePhasesTable> {
  $$PricePhasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lengthKind => $composableBuilder(
    column: $table.lengthKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periods =>
      $composableBuilder(column: $table.periods, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate?, String> get untilOn =>
      $composableBuilder(column: $table.untilOn, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePhasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PricePhasesTable,
          PricePhaseRow,
          $$PricePhasesTableFilterComposer,
          $$PricePhasesTableOrderingComposer,
          $$PricePhasesTableAnnotationComposer,
          $$PricePhasesTableCreateCompanionBuilder,
          $$PricePhasesTableUpdateCompanionBuilder,
          (PricePhaseRow, $$PricePhasesTableReferences),
          PricePhaseRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$PricePhasesTableTableManager(_$AppDatabase db, $PricePhasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PricePhasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PricePhasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PricePhasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> lengthKind = const Value.absent(),
                Value<int?> periods = const Value.absent(),
                Value<LocalDate?> untilOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PricePhasesCompanion(
                id: id,
                itemId: itemId,
                seq: seq,
                amountMinor: amountMinor,
                lengthKind: lengthKind,
                periods: periods,
                untilOn: untilOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required int seq,
                required int amountMinor,
                required String lengthKind,
                Value<int?> periods = const Value.absent(),
                Value<LocalDate?> untilOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PricePhasesCompanion.insert(
                id: id,
                itemId: itemId,
                seq: seq,
                amountMinor: amountMinor,
                lengthKind: lengthKind,
                periods: periods,
                untilOn: untilOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PricePhasesTable, PricePhaseRow>(table),
                  $$PricePhasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$PricePhasesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$PricePhasesTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PricePhasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PricePhasesTable,
      PricePhaseRow,
      $$PricePhasesTableFilterComposer,
      $$PricePhasesTableOrderingComposer,
      $$PricePhasesTableAnnotationComposer,
      $$PricePhasesTableCreateCompanionBuilder,
      $$PricePhasesTableUpdateCompanionBuilder,
      (PricePhaseRow, $$PricePhasesTableReferences),
      PricePhaseRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$OccurrencesTableCreateCompanionBuilder =
    OccurrencesCompanion Function({
      required String id,
      required String itemId,
      required int cycleIndex,
      required LocalDate dueOn,
      required int expectedMinor,
      required Currency currency,
      required OccurrenceState state,
      Value<String?> transactionId,
      Value<int> rowid,
    });
typedef $$OccurrencesTableUpdateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<int> cycleIndex,
      Value<LocalDate> dueOn,
      Value<int> expectedMinor,
      Value<Currency> currency,
      Value<OccurrenceState> state,
      Value<String?> transactionId,
      Value<int> rowid,
    });

final class $$OccurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $OccurrencesTable, OccurrenceRow> {
  $$OccurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('occurrences__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
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

  ColumnFilters<int> get cycleIndex => $composableBuilder(
    column: $table.cycleIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get dueOn =>
      $composableBuilder(
        column: $table.dueOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<OccurrenceState, OccurrenceState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
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

  ColumnOrderings<int> get cycleIndex => $composableBuilder(
    column: $table.cycleIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cycleIndex => $composableBuilder(
    column: $table.cycleIndex,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OccurrenceState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          OccurrenceRow,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (OccurrenceRow, $$OccurrencesTableReferences),
          OccurrenceRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> cycleIndex = const Value.absent(),
                Value<LocalDate> dueOn = const Value.absent(),
                Value<int> expectedMinor = const Value.absent(),
                Value<Currency> currency = const Value.absent(),
                Value<OccurrenceState> state = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                itemId: itemId,
                cycleIndex: cycleIndex,
                dueOn: dueOn,
                expectedMinor: expectedMinor,
                currency: currency,
                state: state,
                transactionId: transactionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required int cycleIndex,
                required LocalDate dueOn,
                required int expectedMinor,
                required Currency currency,
                required OccurrenceState state,
                Value<String?> transactionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                itemId: itemId,
                cycleIndex: cycleIndex,
                dueOn: dueOn,
                expectedMinor: expectedMinor,
                currency: currency,
                state: state,
                transactionId: transactionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrencesTable, OccurrenceRow>(table),
                  $$OccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$OccurrencesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$OccurrencesTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      OccurrenceRow,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (OccurrenceRow, $$OccurrencesTableReferences),
      OccurrenceRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$PriceHistoryTableCreateCompanionBuilder =
    PriceHistoryCompanion Function({
      required String id,
      required String itemId,
      required int fromCycleIndex,
      required LocalDate effectiveOn,
      required int oldMinor,
      required int newMinor,
      required Currency currency,
      required int recordedAt,
      Value<int> rowid,
    });
typedef $$PriceHistoryTableUpdateCompanionBuilder =
    PriceHistoryCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<int> fromCycleIndex,
      Value<LocalDate> effectiveOn,
      Value<int> oldMinor,
      Value<int> newMinor,
      Value<Currency> currency,
      Value<int> recordedAt,
      Value<int> rowid,
    });

final class $$PriceHistoryTableReferences
    extends BaseReferences<_$AppDatabase, $PriceHistoryTable, PriceHistoryRow> {
  $$PriceHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('price_history__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableFilterComposer({
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

  ColumnFilters<int> get fromCycleIndex => $composableBuilder(
    column: $table.fromCycleIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String>
  get effectiveOn => $composableBuilder(
    column: $table.effectiveOn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get oldMinor => $composableBuilder(
    column: $table.oldMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newMinor => $composableBuilder(
    column: $table.newMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get fromCycleIndex => $composableBuilder(
    column: $table.fromCycleIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveOn => $composableBuilder(
    column: $table.effectiveOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oldMinor => $composableBuilder(
    column: $table.oldMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newMinor => $composableBuilder(
    column: $table.newMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromCycleIndex => $composableBuilder(
    column: $table.fromCycleIndex,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get effectiveOn =>
      $composableBuilder(
        column: $table.effectiveOn,
        builder: (column) => column,
      );

  GeneratedColumn<int> get oldMinor =>
      $composableBuilder(column: $table.oldMinor, builder: (column) => column);

  GeneratedColumn<int> get newMinor =>
      $composableBuilder(column: $table.newMinor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceHistoryTable,
          PriceHistoryRow,
          $$PriceHistoryTableFilterComposer,
          $$PriceHistoryTableOrderingComposer,
          $$PriceHistoryTableAnnotationComposer,
          $$PriceHistoryTableCreateCompanionBuilder,
          $$PriceHistoryTableUpdateCompanionBuilder,
          (PriceHistoryRow, $$PriceHistoryTableReferences),
          PriceHistoryRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$PriceHistoryTableTableManager(_$AppDatabase db, $PriceHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> fromCycleIndex = const Value.absent(),
                Value<LocalDate> effectiveOn = const Value.absent(),
                Value<int> oldMinor = const Value.absent(),
                Value<int> newMinor = const Value.absent(),
                Value<Currency> currency = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryCompanion(
                id: id,
                itemId: itemId,
                fromCycleIndex: fromCycleIndex,
                effectiveOn: effectiveOn,
                oldMinor: oldMinor,
                newMinor: newMinor,
                currency: currency,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required int fromCycleIndex,
                required LocalDate effectiveOn,
                required int oldMinor,
                required int newMinor,
                required Currency currency,
                required int recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryCompanion.insert(
                id: id,
                itemId: itemId,
                fromCycleIndex: fromCycleIndex,
                effectiveOn: effectiveOn,
                oldMinor: oldMinor,
                newMinor: newMinor,
                currency: currency,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceHistoryTable, PriceHistoryRow>(table),
                  $$PriceHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$PriceHistoryTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$PriceHistoryTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PriceHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceHistoryTable,
      PriceHistoryRow,
      $$PriceHistoryTableFilterComposer,
      $$PriceHistoryTableOrderingComposer,
      $$PriceHistoryTableAnnotationComposer,
      $$PriceHistoryTableCreateCompanionBuilder,
      $$PriceHistoryTableUpdateCompanionBuilder,
      (PriceHistoryRow, $$PriceHistoryTableReferences),
      PriceHistoryRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required int createdAt,
  required int updatedAt,
  required String id,
  required AccountType type,
  required String name,
  required Currency currency,
  Value<int> openingBalanceMinor,
  Value<int?> creditLimitMinor,
  Value<int?> statementDay,
  Value<int?> paymentDueDay,
  Value<int?> fxFeeBasisPoints,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> id,
  Value<AccountType> type,
  Value<String> name,
  Value<Currency> currency,
  Value<int> openingBalanceMinor,
  Value<int?> creditLimitMinor,
  Value<int?> statementDay,
  Value<int?> paymentDueDay,
  Value<int?> fxFeeBasisPoints,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _outgoingTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$TransactionsTableProcessedTableManager get outgoingTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _outgoingTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _incomingTransfersTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__to_account_id',
  );

  $$TransactionsTableProcessedTableManager get incomingTransfers {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.toAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingTransfersTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fxFeeBasisPoints => $composableBuilder(
    column: $table.fxFeeBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> outgoingTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingTransfers(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.toAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fxFeeBasisPoints => $composableBuilder(
    column: $table.fxFeeBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fxFeeBasisPoints => $composableBuilder(
    column: $table.fxFeeBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> outgoingTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingTransfers<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.toAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool outgoingTransactions,
            bool incomingTransfers,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Currency> currency = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<int?> creditLimitMinor = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> paymentDueDay = const Value.absent(),
                Value<int?> fxFeeBasisPoints = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                name: name,
                currency: currency,
                openingBalanceMinor: openingBalanceMinor,
                creditLimitMinor: creditLimitMinor,
                statementDay: statementDay,
                paymentDueDay: paymentDueDay,
                fxFeeBasisPoints: fxFeeBasisPoints,
                archived: archived,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int createdAt,
                required int updatedAt,
                required String id,
                required AccountType type,
                required String name,
                required Currency currency,
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<int?> creditLimitMinor = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> paymentDueDay = const Value.absent(),
                Value<int?> fxFeeBasisPoints = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                name: name,
                currency: currency,
                openingBalanceMinor: openingBalanceMinor,
                creditLimitMinor: creditLimitMinor,
                statementDay: statementDay,
                paymentDueDay: paymentDueDay,
                fxFeeBasisPoints: fxFeeBasisPoints,
                archived: archived,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({outgoingTransactions = false, incomingTransfers = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (outgoingTransactions) db.transactions,
                    if (incomingTransfers) db.transactions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (outgoingTransactions)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._outgoingTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingTransactions,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (incomingTransfers)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._incomingTransfersTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingTransfers,
                          currentColumn: 'id',
                          referencedColumn: 'to_account_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool outgoingTransactions,
        bool incomingTransfers,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  Value<String?> parentId,
  required CategoryKind kind,
  Value<String> name,
  Value<String?> builtinKey,
  Value<String?> icon,
  Value<int> sortOrder,
  Value<bool> excludeFromWorkIncome,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<CategoryKind> kind,
  Value<String> name,
  Value<String?> builtinKey,
  Value<String?> icon,
  Value<int> sortOrder,
  Value<bool> excludeFromWorkIncome,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get builtinKey => $composableBuilder(
    column: $table.builtinKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromWorkIncome => $composableBuilder(
    column: $table.excludeFromWorkIncome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get builtinKey => $composableBuilder(
    column: $table.builtinKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromWorkIncome => $composableBuilder(
    column: $table.excludeFromWorkIncome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get builtinKey => $composableBuilder(
    column: $table.builtinKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get excludeFromWorkIncome => $composableBuilder(
    column: $table.excludeFromWorkIncome,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> builtinKey = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> excludeFromWorkIncome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                parentId: parentId,
                kind: kind,
                name: name,
                builtinKey: builtinKey,
                icon: icon,
                sortOrder: sortOrder,
                excludeFromWorkIncome: excludeFromWorkIncome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required CategoryKind kind,
                Value<String> name = const Value.absent(),
                Value<String?> builtinKey = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> excludeFromWorkIncome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                parentId: parentId,
                kind: kind,
                name: name,
                builtinKey: builtinKey,
                icon: icon,
                sortOrder: sortOrder,
                excludeFromWorkIncome: excludeFromWorkIncome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required int createdAt,
      required int updatedAt,
      required String id,
      required TransactionType type,
      required TransactionStatus status,
      required int amountMinor,
      required Currency currency,
      Value<String?> fxRate,
      Value<Currency?> fxMainCurrency,
      required String accountId,
      Value<String?> toAccountId,
      Value<int?> toAmountMinor,
      Value<String?> categoryId,
      required int occurredAt,
      Value<String> note,
      Value<String?> occurrenceId,
      Value<bool> isAdjustment,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> id,
      Value<TransactionType> type,
      Value<TransactionStatus> status,
      Value<int> amountMinor,
      Value<Currency> currency,
      Value<String?> fxRate,
      Value<Currency?> fxMainCurrency,
      Value<String> accountId,
      Value<String?> toAccountId,
      Value<int?> toAmountMinor,
      Value<String?> categoryId,
      Value<int> occurredAt,
      Value<String> note,
      Value<String?> occurrenceId,
      Value<bool> isAdjustment,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__to_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get toAccountId {
    final $_column = $_itemColumn<String>('to_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionTagsTable, List<TransactionTagRow>>
  _transactionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionTags,
    aliasName: 'transactions__id__transaction_tags__transaction_id',
  );

  $$TransactionTagsTableProcessedTableManager get transactionTagsRefs {
    final manager = $$TransactionTagsTableTableManager(
      $_db,
      $_db.transactionTags,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionTagsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<AttachmentRow>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'transactions__id__attachments__transaction_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionStatus, TransactionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency, Currency, String> get currency =>
      $composableBuilder(
        column: $table.currency,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get fxRate => $composableBuilder(
    column: $table.fxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Currency?, Currency, String>
  get fxMainCurrency => $composableBuilder(
    column: $table.fxMainCurrency,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get toAmountMinor => $composableBuilder(
    column: $table.toAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionTagsRefs(
    Expression<bool> Function($$TransactionTagsTableFilterComposer f) f,
  ) {
    final $$TransactionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionTags,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionTagsTableFilterComposer(
            $db: $db,
            $table: $db.transactionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxRate => $composableBuilder(
    column: $table.fxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fxMainCurrency => $composableBuilder(
    column: $table.fxMainCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAmountMinor => $composableBuilder(
    column: $table.toAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Currency, String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Currency?, String> get fxMainCurrency =>
      $composableBuilder(
        column: $table.fxMainCurrency,
        builder: (column) => column,
      );

  GeneratedColumn<int> get toAmountMinor => $composableBuilder(
    column: $table.toAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdjustment => $composableBuilder(
    column: $table.isAdjustment,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionTagsRefs<T extends Object>(
    Expression<T> Function($$TransactionTagsTableAnnotationComposer a) f,
  ) {
    final $$TransactionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionTags,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({
            bool accountId,
            bool toAccountId,
            bool transactionTagsRefs,
            bool attachmentsRefs,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<TransactionStatus> status = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<Currency> currency = const Value.absent(),
                Value<String?> fxRate = const Value.absent(),
                Value<Currency?> fxMainCurrency = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<int?> toAmountMinor = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                Value<bool> isAdjustment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                status: status,
                amountMinor: amountMinor,
                currency: currency,
                fxRate: fxRate,
                fxMainCurrency: fxMainCurrency,
                accountId: accountId,
                toAccountId: toAccountId,
                toAmountMinor: toAmountMinor,
                categoryId: categoryId,
                occurredAt: occurredAt,
                note: note,
                occurrenceId: occurrenceId,
                isAdjustment: isAdjustment,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int createdAt,
                required int updatedAt,
                required String id,
                required TransactionType type,
                required TransactionStatus status,
                required int amountMinor,
                required Currency currency,
                Value<String?> fxRate = const Value.absent(),
                Value<Currency?> fxMainCurrency = const Value.absent(),
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<int?> toAmountMinor = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required int occurredAt,
                Value<String> note = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                Value<bool> isAdjustment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                id: id,
                type: type,
                status: status,
                amountMinor: amountMinor,
                currency: currency,
                fxRate: fxRate,
                fxMainCurrency: fxMainCurrency,
                accountId: accountId,
                toAccountId: toAccountId,
                toAmountMinor: toAmountMinor,
                categoryId: categoryId,
                occurredAt: occurredAt,
                note: note,
                occurrenceId: occurrenceId,
                isAdjustment: isAdjustment,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                toAccountId = false,
                transactionTagsRefs = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionTagsRefs) db.transactionTags,
                    if (attachmentsRefs) db.attachments,
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
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TransactionsTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (toAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._toAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._toAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          TransactionRow,
                          $TransactionsTable,
                          TransactionTagRow,
                          $TransactionTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._transactionTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'transaction_id',
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedDataByColumns<
                          TransactionRow,
                          $TransactionsTable,
                          AttachmentRow,
                          $AttachmentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'transaction_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({
        bool accountId,
        bool toAccountId,
        bool transactionTagsRefs,
        bool attachmentsRefs,
      })
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionTagsTable, List<TransactionTagRow>>
  _transactionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionTags,
    aliasName: 'tags__id__transaction_tags__tag_id',
  );

  $$TransactionTagsTableProcessedTableManager get transactionTagsRefs {
    final manager = $$TransactionTagsTableTableManager(
      $_db,
      $_db.transactionTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionTagsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  Expression<bool> transactionTagsRefs(
    Expression<bool> Function($$TransactionTagsTableFilterComposer f) f,
  ) {
    final $$TransactionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionTagsTableFilterComposer(
            $db: $db,
            $table: $db.transactionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
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

  Expression<T> transactionTagsRefs<T extends Object>(
    Expression<T> Function($$TransactionTagsTableAnnotationComposer a) f,
  ) {
    final $$TransactionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool transactionTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagRow>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionTagsRefs) db.transactionTags,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionTagsRefs)
                    await $_getPrefetchedDataByColumns<
                      TagRow,
                      $TagsTable,
                      TransactionTagRow,
                      $TransactionTagsTable
                    >(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._transactionTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TagsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionTagsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tag_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool transactionTagsRefs})
    >;
typedef $$TransactionTagsTableCreateCompanionBuilder =
    TransactionTagsCompanion Function({
      required String transactionId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$TransactionTagsTableUpdateCompanionBuilder =
    TransactionTagsCompanion Function({
      Value<String> transactionId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$TransactionTagsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionTagsTable,
          TransactionTagRow
        > {
  $$TransactionTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('transaction_tags__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('transaction_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionTagsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionTagsTable,
          TransactionTagRow,
          $$TransactionTagsTableFilterComposer,
          $$TransactionTagsTableOrderingComposer,
          $$TransactionTagsTableAnnotationComposer,
          $$TransactionTagsTableCreateCompanionBuilder,
          $$TransactionTagsTableUpdateCompanionBuilder,
          (TransactionTagRow, $$TransactionTagsTableReferences),
          TransactionTagRow,
          PrefetchHooks Function({bool transactionId, bool tagId})
        > {
  $$TransactionTagsTableTableManager(
    _$AppDatabase db,
    $TransactionTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> transactionId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionTagsCompanion(
                transactionId: transactionId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String transactionId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => TransactionTagsCompanion.insert(
                transactionId: transactionId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionTagsTable, TransactionTagRow>(table),
                  $$TransactionTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false, tagId = false}) {
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
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$TransactionTagsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$TransactionTagsTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$TransactionTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$TransactionTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TransactionTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionTagsTable,
      TransactionTagRow,
      $$TransactionTagsTableFilterComposer,
      $$TransactionTagsTableOrderingComposer,
      $$TransactionTagsTableAnnotationComposer,
      $$TransactionTagsTableCreateCompanionBuilder,
      $$TransactionTagsTableUpdateCompanionBuilder,
      (TransactionTagRow, $$TransactionTagsTableReferences),
      TransactionTagRow,
      PrefetchHooks Function({bool transactionId, bool tagId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String transactionId,
      required String fileName,
      required String mimeType,
      required int sizeBytes,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> fileName,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentRow> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('attachments__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentRow,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (AttachmentRow, $$AttachmentsTableReferences),
          AttachmentRow,
          PrefetchHooks Function({bool transactionId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                transactionId: transactionId,
                fileName: fileName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String fileName,
                required String mimeType,
                required int sizeBytes,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                transactionId: transactionId,
                fileName: fileName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, AttachmentRow>(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
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
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$AttachmentsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$AttachmentsTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
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

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentRow,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (AttachmentRow, $$AttachmentsTableReferences),
      AttachmentRow,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$AliasesTableCreateCompanionBuilder = AliasesCompanion Function({
  required String id,
  required String presetId,
  required String alias,
  required int createdAt,
  Value<int> rowid,
});
typedef $$AliasesTableUpdateCompanionBuilder = AliasesCompanion Function({
  Value<String> id,
  Value<String> presetId,
  Value<String> alias,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$AliasesTableFilterComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableFilterComposer({
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

  ColumnFilters<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableOrderingComposer({
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

  ColumnOrderings<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AliasesTable> {
  $$AliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AliasesTable,
          AliasRow,
          $$AliasesTableFilterComposer,
          $$AliasesTableOrderingComposer,
          $$AliasesTableAnnotationComposer,
          $$AliasesTableCreateCompanionBuilder,
          $$AliasesTableUpdateCompanionBuilder,
          (AliasRow, BaseReferences<_$AppDatabase, $AliasesTable, AliasRow>),
          AliasRow,
          PrefetchHooks Function()
        > {
  $$AliasesTableTableManager(_$AppDatabase db, $AliasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> presetId = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AliasesCompanion(
                id: id,
                presetId: presetId,
                alias: alias,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String presetId,
                required String alias,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AliasesCompanion.insert(
                id: id,
                presetId: presetId,
                alias: alias,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AliasesTable, AliasRow>(table),
                  BaseReferences<_$AppDatabase, $AliasesTable, AliasRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AliasesTable,
      AliasRow,
      $$AliasesTableFilterComposer,
      $$AliasesTableOrderingComposer,
      $$AliasesTableAnnotationComposer,
      $$AliasesTableCreateCompanionBuilder,
      $$AliasesTableUpdateCompanionBuilder,
      (AliasRow, BaseReferences<_$AppDatabase, $AliasesTable, AliasRow>),
      AliasRow,
      PrefetchHooks Function()
    >;
typedef $$ReminderLogTableCreateCompanionBuilder =
    ReminderLogCompanion Function({
      required String id,
      Value<String?> itemId,
      Value<String?> occurrenceId,
      required String kind,
      required int scheduledAt,
      Value<int?> deliveredAt,
      Value<String?> action,
      Value<int> rowid,
    });
typedef $$ReminderLogTableUpdateCompanionBuilder =
    ReminderLogCompanion Function({
      Value<String> id,
      Value<String?> itemId,
      Value<String?> occurrenceId,
      Value<String> kind,
      Value<int> scheduledAt,
      Value<int?> deliveredAt,
      Value<String?> action,
      Value<int> rowid,
    });

class $$ReminderLogTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderLogTable> {
  $$ReminderLogTableFilterComposer({
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

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderLogTable> {
  $$ReminderLogTableOrderingComposer({
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

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderLogTable> {
  $$ReminderLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);
}

class $$ReminderLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderLogTable,
          ReminderLogRow,
          $$ReminderLogTableFilterComposer,
          $$ReminderLogTableOrderingComposer,
          $$ReminderLogTableAnnotationComposer,
          $$ReminderLogTableCreateCompanionBuilder,
          $$ReminderLogTableUpdateCompanionBuilder,
          (
            ReminderLogRow,
            BaseReferences<_$AppDatabase, $ReminderLogTable, ReminderLogRow>,
          ),
          ReminderLogRow,
          PrefetchHooks Function()
        > {
  $$ReminderLogTableTableManager(_$AppDatabase db, $ReminderLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> scheduledAt = const Value.absent(),
                Value<int?> deliveredAt = const Value.absent(),
                Value<String?> action = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderLogCompanion(
                id: id,
                itemId: itemId,
                occurrenceId: occurrenceId,
                kind: kind,
                scheduledAt: scheduledAt,
                deliveredAt: deliveredAt,
                action: action,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> itemId = const Value.absent(),
                Value<String?> occurrenceId = const Value.absent(),
                required String kind,
                required int scheduledAt,
                Value<int?> deliveredAt = const Value.absent(),
                Value<String?> action = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderLogCompanion.insert(
                id: id,
                itemId: itemId,
                occurrenceId: occurrenceId,
                kind: kind,
                scheduledAt: scheduledAt,
                deliveredAt: deliveredAt,
                action: action,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderLogTable, ReminderLogRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReminderLogTable,
                    ReminderLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderLogTable,
      ReminderLogRow,
      $$ReminderLogTableFilterComposer,
      $$ReminderLogTableOrderingComposer,
      $$ReminderLogTableAnnotationComposer,
      $$ReminderLogTableCreateCompanionBuilder,
      $$ReminderLogTableUpdateCompanionBuilder,
      (
        ReminderLogRow,
        BaseReferences<_$AppDatabase, $ReminderLogTable, ReminderLogRow>,
      ),
      ReminderLogRow,
      PrefetchHooks Function()
    >;
typedef $$ChangeLogTableCreateCompanionBuilder = ChangeLogCompanion Function({
  Value<int> seq,
  required String entity,
  required String rowId,
  required String field,
  required String value,
  required String hlc,
  Value<bool> uploaded,
});
typedef $$ChangeLogTableUpdateCompanionBuilder = ChangeLogCompanion Function({
  Value<int> seq,
  Value<String> entity,
  Value<String> rowId,
  Value<String> field,
  Value<String> value,
  Value<String> hlc,
  Value<bool> uploaded,
});

class $$ChangeLogTableFilterComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChangeLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChangeLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);
}

class $$ChangeLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChangeLogTable,
          ChangeLogRow,
          $$ChangeLogTableFilterComposer,
          $$ChangeLogTableOrderingComposer,
          $$ChangeLogTableAnnotationComposer,
          $$ChangeLogTableCreateCompanionBuilder,
          $$ChangeLogTableUpdateCompanionBuilder,
          (
            ChangeLogRow,
            BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogRow>,
          ),
          ChangeLogRow,
          PrefetchHooks Function()
        > {
  $$ChangeLogTableTableManager(_$AppDatabase db, $ChangeLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
              }) => ChangeLogCompanion(
                seq: seq,
                entity: entity,
                rowId: rowId,
                field: field,
                value: value,
                hlc: hlc,
                uploaded: uploaded,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String entity,
                required String rowId,
                required String field,
                required String value,
                required String hlc,
                Value<bool> uploaded = const Value.absent(),
              }) => ChangeLogCompanion.insert(
                seq: seq,
                entity: entity,
                rowId: rowId,
                field: field,
                value: value,
                hlc: hlc,
                uploaded: uploaded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChangeLogTable, ChangeLogRow>(table),
                  BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChangeLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChangeLogTable,
      ChangeLogRow,
      $$ChangeLogTableFilterComposer,
      $$ChangeLogTableOrderingComposer,
      $$ChangeLogTableAnnotationComposer,
      $$ChangeLogTableCreateCompanionBuilder,
      $$ChangeLogTableUpdateCompanionBuilder,
      (
        ChangeLogRow,
        BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogRow>,
      ),
      ChangeLogRow,
      PrefetchHooks Function()
    >;
typedef $$MetaTableCreateCompanionBuilder = MetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaTableUpdateCompanionBuilder = MetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaTableFilterComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableOrderingComposer extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaTable,
          MetaRow,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AppDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetaTable, MetaRow>(table),
                  BaseReferences<_$AppDatabase, $MetaTable, MetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaTable,
      MetaRow,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $MetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$PricePhasesTableTableManager get pricePhases =>
      $$PricePhasesTableTableManager(_db, _db.pricePhases);
  $$OccurrencesTableTableManager get occurrences =>
      $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$PriceHistoryTableTableManager get priceHistory =>
      $$PriceHistoryTableTableManager(_db, _db.priceHistory);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TransactionTagsTableTableManager get transactionTags =>
      $$TransactionTagsTableTableManager(_db, _db.transactionTags);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AliasesTableTableManager get aliases =>
      $$AliasesTableTableManager(_db, _db.aliases);
  $$ReminderLogTableTableManager get reminderLog =>
      $$ReminderLogTableTableManager(_db, _db.reminderLog);
  $$ChangeLogTableTableManager get changeLog =>
      $$ChangeLogTableTableManager(_db, _db.changeLog);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
