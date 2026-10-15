// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_db.dart';

// ignore_for_file: type=lint
class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altNamesMeta = const VerificationMeta(
    'altNames',
  );
  @override
  late final GeneratedColumn<String> altNames = GeneratedColumn<String>(
    'alt_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _networkMeta = const VerificationMeta(
    'network',
  );
  @override
  late final GeneratedColumn<String> network = GeneratedColumn<String>(
    'network',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featuredMeta = const VerificationMeta(
    'featured',
  );
  @override
  late final GeneratedColumn<bool> featured = GeneratedColumn<bool>(
    'featured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("featured" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _epgIdMeta = const VerificationMeta('epgId');
  @override
  late final GeneratedColumn<String> epgId = GeneratedColumn<String>(
    'epg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgOffsetMeta = const VerificationMeta(
    'epgOffset',
  );
  @override
  late final GeneratedColumn<int> epgOffset = GeneratedColumn<int>(
    'epg_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _familyMeta = const VerificationMeta('family');
  @override
  late final GeneratedColumn<String> family = GeneratedColumn<String>(
    'family',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentalMeta = const VerificationMeta(
    'parental',
  );
  @override
  late final GeneratedColumn<bool> parental = GeneratedColumn<bool>(
    'parental',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("parental" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    number,
    nameAr,
    nameEn,
    altNames,
    network,
    logoUrl,
    country,
    category,
    categories,
    language,
    quality,
    featured,
    sort,
    epgId,
    epgOffset,
    family,
    parental,
    publishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('alt_names')) {
      context.handle(
        _altNamesMeta,
        altNames.isAcceptableOrUnknown(data['alt_names']!, _altNamesMeta),
      );
    }
    if (data.containsKey('network')) {
      context.handle(
        _networkMeta,
        network.isAcceptableOrUnknown(data['network']!, _networkMeta),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('featured')) {
      context.handle(
        _featuredMeta,
        featured.isAcceptableOrUnknown(data['featured']!, _featuredMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('epg_id')) {
      context.handle(
        _epgIdMeta,
        epgId.isAcceptableOrUnknown(data['epg_id']!, _epgIdMeta),
      );
    }
    if (data.containsKey('epg_offset')) {
      context.handle(
        _epgOffsetMeta,
        epgOffset.isAcceptableOrUnknown(data['epg_offset']!, _epgOffsetMeta),
      );
    }
    if (data.containsKey('family')) {
      context.handle(
        _familyMeta,
        family.isAcceptableOrUnknown(data['family']!, _familyMeta),
      );
    }
    if (data.containsKey('parental')) {
      context.handle(
        _parentalMeta,
        parental.isAcceptableOrUnknown(data['parental']!, _parentalMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      altNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alt_names'],
      )!,
      network: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      ),
      featured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}featured'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      epgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_id'],
      ),
      epgOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epg_offset'],
      )!,
      family: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family'],
      ),
      parental: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}parental'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelRow extends DataClass implements Insertable<ChannelRow> {
  final String id;
  final String uid;
  final int? number;
  final String? nameAr;
  final String? nameEn;
  final String altNames;
  final String? network;
  final String? logoUrl;
  final String? country;
  final String? category;
  final String categories;
  final String? language;
  final String? quality;
  final bool featured;
  final int sort;
  final String? epgId;
  final int epgOffset;
  final String? family;
  final bool parental;
  final DateTime? publishedAt;
  const ChannelRow({
    required this.id,
    required this.uid,
    this.number,
    this.nameAr,
    this.nameEn,
    required this.altNames,
    this.network,
    this.logoUrl,
    this.country,
    this.category,
    required this.categories,
    this.language,
    this.quality,
    required this.featured,
    required this.sort,
    this.epgId,
    required this.epgOffset,
    this.family,
    required this.parental,
    this.publishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['uid'] = Variable<String>(uid);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    map['alt_names'] = Variable<String>(altNames);
    if (!nullToAbsent || network != null) {
      map['network'] = Variable<String>(network);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['categories'] = Variable<String>(categories);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    map['featured'] = Variable<bool>(featured);
    map['sort'] = Variable<int>(sort);
    if (!nullToAbsent || epgId != null) {
      map['epg_id'] = Variable<String>(epgId);
    }
    map['epg_offset'] = Variable<int>(epgOffset);
    if (!nullToAbsent || family != null) {
      map['family'] = Variable<String>(family);
    }
    map['parental'] = Variable<bool>(parental);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      uid: Value(uid),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      nameEn: nameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameEn),
      altNames: Value(altNames),
      network: network == null && nullToAbsent
          ? const Value.absent()
          : Value(network),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      categories: Value(categories),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      featured: Value(featured),
      sort: Value(sort),
      epgId: epgId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgId),
      epgOffset: Value(epgOffset),
      family: family == null && nullToAbsent
          ? const Value.absent()
          : Value(family),
      parental: Value(parental),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory ChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelRow(
      id: serializer.fromJson<String>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      number: serializer.fromJson<int?>(json['number']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      altNames: serializer.fromJson<String>(json['altNames']),
      network: serializer.fromJson<String?>(json['network']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      country: serializer.fromJson<String?>(json['country']),
      category: serializer.fromJson<String?>(json['category']),
      categories: serializer.fromJson<String>(json['categories']),
      language: serializer.fromJson<String?>(json['language']),
      quality: serializer.fromJson<String?>(json['quality']),
      featured: serializer.fromJson<bool>(json['featured']),
      sort: serializer.fromJson<int>(json['sort']),
      epgId: serializer.fromJson<String?>(json['epgId']),
      epgOffset: serializer.fromJson<int>(json['epgOffset']),
      family: serializer.fromJson<String?>(json['family']),
      parental: serializer.fromJson<bool>(json['parental']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'uid': serializer.toJson<String>(uid),
      'number': serializer.toJson<int?>(number),
      'nameAr': serializer.toJson<String?>(nameAr),
      'nameEn': serializer.toJson<String?>(nameEn),
      'altNames': serializer.toJson<String>(altNames),
      'network': serializer.toJson<String?>(network),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'country': serializer.toJson<String?>(country),
      'category': serializer.toJson<String?>(category),
      'categories': serializer.toJson<String>(categories),
      'language': serializer.toJson<String?>(language),
      'quality': serializer.toJson<String?>(quality),
      'featured': serializer.toJson<bool>(featured),
      'sort': serializer.toJson<int>(sort),
      'epgId': serializer.toJson<String?>(epgId),
      'epgOffset': serializer.toJson<int>(epgOffset),
      'family': serializer.toJson<String?>(family),
      'parental': serializer.toJson<bool>(parental),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
    };
  }

  ChannelRow copyWith({
    String? id,
    String? uid,
    Value<int?> number = const Value.absent(),
    Value<String?> nameAr = const Value.absent(),
    Value<String?> nameEn = const Value.absent(),
    String? altNames,
    Value<String?> network = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? categories,
    Value<String?> language = const Value.absent(),
    Value<String?> quality = const Value.absent(),
    bool? featured,
    int? sort,
    Value<String?> epgId = const Value.absent(),
    int? epgOffset,
    Value<String?> family = const Value.absent(),
    bool? parental,
    Value<DateTime?> publishedAt = const Value.absent(),
  }) => ChannelRow(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    number: number.present ? number.value : this.number,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    nameEn: nameEn.present ? nameEn.value : this.nameEn,
    altNames: altNames ?? this.altNames,
    network: network.present ? network.value : this.network,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    country: country.present ? country.value : this.country,
    category: category.present ? category.value : this.category,
    categories: categories ?? this.categories,
    language: language.present ? language.value : this.language,
    quality: quality.present ? quality.value : this.quality,
    featured: featured ?? this.featured,
    sort: sort ?? this.sort,
    epgId: epgId.present ? epgId.value : this.epgId,
    epgOffset: epgOffset ?? this.epgOffset,
    family: family.present ? family.value : this.family,
    parental: parental ?? this.parental,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
  );
  ChannelRow copyWithCompanion(ChannelsCompanion data) {
    return ChannelRow(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      number: data.number.present ? data.number.value : this.number,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      altNames: data.altNames.present ? data.altNames.value : this.altNames,
      network: data.network.present ? data.network.value : this.network,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      country: data.country.present ? data.country.value : this.country,
      category: data.category.present ? data.category.value : this.category,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      language: data.language.present ? data.language.value : this.language,
      quality: data.quality.present ? data.quality.value : this.quality,
      featured: data.featured.present ? data.featured.value : this.featured,
      sort: data.sort.present ? data.sort.value : this.sort,
      epgId: data.epgId.present ? data.epgId.value : this.epgId,
      epgOffset: data.epgOffset.present ? data.epgOffset.value : this.epgOffset,
      family: data.family.present ? data.family.value : this.family,
      parental: data.parental.present ? data.parental.value : this.parental,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelRow(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('number: $number, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('altNames: $altNames, ')
          ..write('network: $network, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('country: $country, ')
          ..write('category: $category, ')
          ..write('categories: $categories, ')
          ..write('language: $language, ')
          ..write('quality: $quality, ')
          ..write('featured: $featured, ')
          ..write('sort: $sort, ')
          ..write('epgId: $epgId, ')
          ..write('epgOffset: $epgOffset, ')
          ..write('family: $family, ')
          ..write('parental: $parental, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    number,
    nameAr,
    nameEn,
    altNames,
    network,
    logoUrl,
    country,
    category,
    categories,
    language,
    quality,
    featured,
    sort,
    epgId,
    epgOffset,
    family,
    parental,
    publishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelRow &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.number == this.number &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.altNames == this.altNames &&
          other.network == this.network &&
          other.logoUrl == this.logoUrl &&
          other.country == this.country &&
          other.category == this.category &&
          other.categories == this.categories &&
          other.language == this.language &&
          other.quality == this.quality &&
          other.featured == this.featured &&
          other.sort == this.sort &&
          other.epgId == this.epgId &&
          other.epgOffset == this.epgOffset &&
          other.family == this.family &&
          other.parental == this.parental &&
          other.publishedAt == this.publishedAt);
}

class ChannelsCompanion extends UpdateCompanion<ChannelRow> {
  final Value<String> id;
  final Value<String> uid;
  final Value<int?> number;
  final Value<String?> nameAr;
  final Value<String?> nameEn;
  final Value<String> altNames;
  final Value<String?> network;
  final Value<String?> logoUrl;
  final Value<String?> country;
  final Value<String?> category;
  final Value<String> categories;
  final Value<String?> language;
  final Value<String?> quality;
  final Value<bool> featured;
  final Value<int> sort;
  final Value<String?> epgId;
  final Value<int> epgOffset;
  final Value<String?> family;
  final Value<bool> parental;
  final Value<DateTime?> publishedAt;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.number = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.altNames = const Value.absent(),
    this.network = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.country = const Value.absent(),
    this.category = const Value.absent(),
    this.categories = const Value.absent(),
    this.language = const Value.absent(),
    this.quality = const Value.absent(),
    this.featured = const Value.absent(),
    this.sort = const Value.absent(),
    this.epgId = const Value.absent(),
    this.epgOffset = const Value.absent(),
    this.family = const Value.absent(),
    this.parental = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String id,
    required String uid,
    this.number = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.altNames = const Value.absent(),
    this.network = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.country = const Value.absent(),
    this.category = const Value.absent(),
    this.categories = const Value.absent(),
    this.language = const Value.absent(),
    this.quality = const Value.absent(),
    this.featured = const Value.absent(),
    this.sort = const Value.absent(),
    this.epgId = const Value.absent(),
    this.epgOffset = const Value.absent(),
    this.family = const Value.absent(),
    this.parental = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       uid = Value(uid);
  static Insertable<ChannelRow> custom({
    Expression<String>? id,
    Expression<String>? uid,
    Expression<int>? number,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? altNames,
    Expression<String>? network,
    Expression<String>? logoUrl,
    Expression<String>? country,
    Expression<String>? category,
    Expression<String>? categories,
    Expression<String>? language,
    Expression<String>? quality,
    Expression<bool>? featured,
    Expression<int>? sort,
    Expression<String>? epgId,
    Expression<int>? epgOffset,
    Expression<String>? family,
    Expression<bool>? parental,
    Expression<DateTime>? publishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (number != null) 'number': number,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (altNames != null) 'alt_names': altNames,
      if (network != null) 'network': network,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (country != null) 'country': country,
      if (category != null) 'category': category,
      if (categories != null) 'categories': categories,
      if (language != null) 'language': language,
      if (quality != null) 'quality': quality,
      if (featured != null) 'featured': featured,
      if (sort != null) 'sort': sort,
      if (epgId != null) 'epg_id': epgId,
      if (epgOffset != null) 'epg_offset': epgOffset,
      if (family != null) 'family': family,
      if (parental != null) 'parental': parental,
      if (publishedAt != null) 'published_at': publishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? uid,
    Value<int?>? number,
    Value<String?>? nameAr,
    Value<String?>? nameEn,
    Value<String>? altNames,
    Value<String?>? network,
    Value<String?>? logoUrl,
    Value<String?>? country,
    Value<String?>? category,
    Value<String>? categories,
    Value<String?>? language,
    Value<String?>? quality,
    Value<bool>? featured,
    Value<int>? sort,
    Value<String?>? epgId,
    Value<int>? epgOffset,
    Value<String?>? family,
    Value<bool>? parental,
    Value<DateTime?>? publishedAt,
    Value<int>? rowid,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      number: number ?? this.number,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      altNames: altNames ?? this.altNames,
      network: network ?? this.network,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      quality: quality ?? this.quality,
      featured: featured ?? this.featured,
      sort: sort ?? this.sort,
      epgId: epgId ?? this.epgId,
      epgOffset: epgOffset ?? this.epgOffset,
      family: family ?? this.family,
      parental: parental ?? this.parental,
      publishedAt: publishedAt ?? this.publishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (altNames.present) {
      map['alt_names'] = Variable<String>(altNames.value);
    }
    if (network.present) {
      map['network'] = Variable<String>(network.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (featured.present) {
      map['featured'] = Variable<bool>(featured.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (epgId.present) {
      map['epg_id'] = Variable<String>(epgId.value);
    }
    if (epgOffset.present) {
      map['epg_offset'] = Variable<int>(epgOffset.value);
    }
    if (family.present) {
      map['family'] = Variable<String>(family.value);
    }
    if (parental.present) {
      map['parental'] = Variable<bool>(parental.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('number: $number, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('altNames: $altNames, ')
          ..write('network: $network, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('country: $country, ')
          ..write('category: $category, ')
          ..write('categories: $categories, ')
          ..write('language: $language, ')
          ..write('quality: $quality, ')
          ..write('featured: $featured, ')
          ..write('sort: $sort, ')
          ..write('epgId: $epgId, ')
          ..write('epgOffset: $epgOffset, ')
          ..write('family: $family, ')
          ..write('parental: $parental, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreamsTable extends Streams with TableInfo<$StreamsTable, StreamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userAgentMeta = const VerificationMeta(
    'userAgent',
  );
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
    'user_agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referrerMeta = const VerificationMeta(
    'referrer',
  );
  @override
  late final GeneratedColumn<String> referrer = GeneratedColumn<String>(
    'referrer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headersMeta = const VerificationMeta(
    'headers',
  );
  @override
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
    'headers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta(
    'protocol',
  );
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<String> health = GeneratedColumn<String>(
    'health',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inconclusive'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    url,
    label,
    quality,
    priority,
    userAgent,
    referrer,
    headers,
    protocol,
    health,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streams';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('user_agent')) {
      context.handle(
        _userAgentMeta,
        userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta),
      );
    }
    if (data.containsKey('referrer')) {
      context.handle(
        _referrerMeta,
        referrer.isAcceptableOrUnknown(data['referrer']!, _referrerMeta),
      );
    }
    if (data.containsKey('headers')) {
      context.handle(
        _headersMeta,
        headers.isAcceptableOrUnknown(data['headers']!, _headersMeta),
      );
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    }
    if (data.containsKey('health')) {
      context.handle(
        _healthMeta,
        health.isAcceptableOrUnknown(data['health']!, _healthMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      userAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent'],
      ),
      referrer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referrer'],
      ),
      headers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers'],
      )!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      ),
      health: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
    );
  }

  @override
  $StreamsTable createAlias(String alias) {
    return $StreamsTable(attachedDatabase, alias);
  }
}

class StreamRow extends DataClass implements Insertable<StreamRow> {
  final String id;
  final String channelId;
  final String url;
  final String? label;
  final String? quality;
  final int priority;
  final String? userAgent;
  final String? referrer;
  final String headers;
  final String? protocol;
  final String health;
  final int? score;
  const StreamRow({
    required this.id,
    required this.channelId,
    required this.url,
    this.label,
    this.quality,
    required this.priority,
    this.userAgent,
    this.referrer,
    required this.headers,
    this.protocol,
    required this.health,
    this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    if (!nullToAbsent || referrer != null) {
      map['referrer'] = Variable<String>(referrer);
    }
    map['headers'] = Variable<String>(headers);
    if (!nullToAbsent || protocol != null) {
      map['protocol'] = Variable<String>(protocol);
    }
    map['health'] = Variable<String>(health);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    return map;
  }

  StreamsCompanion toCompanion(bool nullToAbsent) {
    return StreamsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      url: Value(url),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      priority: Value(priority),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
      referrer: referrer == null && nullToAbsent
          ? const Value.absent()
          : Value(referrer),
      headers: Value(headers),
      protocol: protocol == null && nullToAbsent
          ? const Value.absent()
          : Value(protocol),
      health: Value(health),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
    );
  }

  factory StreamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreamRow(
      id: serializer.fromJson<String>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      url: serializer.fromJson<String>(json['url']),
      label: serializer.fromJson<String?>(json['label']),
      quality: serializer.fromJson<String?>(json['quality']),
      priority: serializer.fromJson<int>(json['priority']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
      referrer: serializer.fromJson<String?>(json['referrer']),
      headers: serializer.fromJson<String>(json['headers']),
      protocol: serializer.fromJson<String?>(json['protocol']),
      health: serializer.fromJson<String>(json['health']),
      score: serializer.fromJson<int?>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channelId': serializer.toJson<String>(channelId),
      'url': serializer.toJson<String>(url),
      'label': serializer.toJson<String?>(label),
      'quality': serializer.toJson<String?>(quality),
      'priority': serializer.toJson<int>(priority),
      'userAgent': serializer.toJson<String?>(userAgent),
      'referrer': serializer.toJson<String?>(referrer),
      'headers': serializer.toJson<String>(headers),
      'protocol': serializer.toJson<String?>(protocol),
      'health': serializer.toJson<String>(health),
      'score': serializer.toJson<int?>(score),
    };
  }

  StreamRow copyWith({
    String? id,
    String? channelId,
    String? url,
    Value<String?> label = const Value.absent(),
    Value<String?> quality = const Value.absent(),
    int? priority,
    Value<String?> userAgent = const Value.absent(),
    Value<String?> referrer = const Value.absent(),
    String? headers,
    Value<String?> protocol = const Value.absent(),
    String? health,
    Value<int?> score = const Value.absent(),
  }) => StreamRow(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    url: url ?? this.url,
    label: label.present ? label.value : this.label,
    quality: quality.present ? quality.value : this.quality,
    priority: priority ?? this.priority,
    userAgent: userAgent.present ? userAgent.value : this.userAgent,
    referrer: referrer.present ? referrer.value : this.referrer,
    headers: headers ?? this.headers,
    protocol: protocol.present ? protocol.value : this.protocol,
    health: health ?? this.health,
    score: score.present ? score.value : this.score,
  );
  StreamRow copyWithCompanion(StreamsCompanion data) {
    return StreamRow(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      url: data.url.present ? data.url.value : this.url,
      label: data.label.present ? data.label.value : this.label,
      quality: data.quality.present ? data.quality.value : this.quality,
      priority: data.priority.present ? data.priority.value : this.priority,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      referrer: data.referrer.present ? data.referrer.value : this.referrer,
      headers: data.headers.present ? data.headers.value : this.headers,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      health: data.health.present ? data.health.value : this.health,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreamRow(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('url: $url, ')
          ..write('label: $label, ')
          ..write('quality: $quality, ')
          ..write('priority: $priority, ')
          ..write('userAgent: $userAgent, ')
          ..write('referrer: $referrer, ')
          ..write('headers: $headers, ')
          ..write('protocol: $protocol, ')
          ..write('health: $health, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    url,
    label,
    quality,
    priority,
    userAgent,
    referrer,
    headers,
    protocol,
    health,
    score,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreamRow &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.url == this.url &&
          other.label == this.label &&
          other.quality == this.quality &&
          other.priority == this.priority &&
          other.userAgent == this.userAgent &&
          other.referrer == this.referrer &&
          other.headers == this.headers &&
          other.protocol == this.protocol &&
          other.health == this.health &&
          other.score == this.score);
}

class StreamsCompanion extends UpdateCompanion<StreamRow> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> url;
  final Value<String?> label;
  final Value<String?> quality;
  final Value<int> priority;
  final Value<String?> userAgent;
  final Value<String?> referrer;
  final Value<String> headers;
  final Value<String?> protocol;
  final Value<String> health;
  final Value<int?> score;
  final Value<int> rowid;
  const StreamsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.url = const Value.absent(),
    this.label = const Value.absent(),
    this.quality = const Value.absent(),
    this.priority = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.referrer = const Value.absent(),
    this.headers = const Value.absent(),
    this.protocol = const Value.absent(),
    this.health = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreamsCompanion.insert({
    required String id,
    required String channelId,
    required String url,
    this.label = const Value.absent(),
    this.quality = const Value.absent(),
    this.priority = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.referrer = const Value.absent(),
    this.headers = const Value.absent(),
    this.protocol = const Value.absent(),
    this.health = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channelId = Value(channelId),
       url = Value(url);
  static Insertable<StreamRow> custom({
    Expression<String>? id,
    Expression<String>? channelId,
    Expression<String>? url,
    Expression<String>? label,
    Expression<String>? quality,
    Expression<int>? priority,
    Expression<String>? userAgent,
    Expression<String>? referrer,
    Expression<String>? headers,
    Expression<String>? protocol,
    Expression<String>? health,
    Expression<int>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (url != null) 'url': url,
      if (label != null) 'label': label,
      if (quality != null) 'quality': quality,
      if (priority != null) 'priority': priority,
      if (userAgent != null) 'user_agent': userAgent,
      if (referrer != null) 'referrer': referrer,
      if (headers != null) 'headers': headers,
      if (protocol != null) 'protocol': protocol,
      if (health != null) 'health': health,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreamsCompanion copyWith({
    Value<String>? id,
    Value<String>? channelId,
    Value<String>? url,
    Value<String?>? label,
    Value<String?>? quality,
    Value<int>? priority,
    Value<String?>? userAgent,
    Value<String?>? referrer,
    Value<String>? headers,
    Value<String?>? protocol,
    Value<String>? health,
    Value<int?>? score,
    Value<int>? rowid,
  }) {
    return StreamsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      url: url ?? this.url,
      label: label ?? this.label,
      quality: quality ?? this.quality,
      priority: priority ?? this.priority,
      userAgent: userAgent ?? this.userAgent,
      referrer: referrer ?? this.referrer,
      headers: headers ?? this.headers,
      protocol: protocol ?? this.protocol,
      health: health ?? this.health,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (referrer.present) {
      map['referrer'] = Variable<String>(referrer.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (health.present) {
      map['health'] = Variable<String>(health.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('url: $url, ')
          ..write('label: $label, ')
          ..write('quality: $quality, ')
          ..write('priority: $priority, ')
          ..write('userAgent: $userAgent, ')
          ..write('referrer: $referrer, ')
          ..write('headers: $headers, ')
          ..write('protocol: $protocol, ')
          ..write('health: $health, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
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
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
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
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
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

  SyncStateData copyWith({String? key, String? value}) =>
      SyncStateData(key: key ?? this.key, value: value ?? this.value);
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
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
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateData> custom({
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

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
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
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CatalogDb extends GeneratedDatabase {
  _$CatalogDb(QueryExecutor e) : super(e);
  $CatalogDbManager get managers => $CatalogDbManager(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $StreamsTable streams = $StreamsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    channels,
    streams,
    syncState,
  ];
}

typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  required String id,
  required String uid,
  Value<int?> number,
  Value<String?> nameAr,
  Value<String?> nameEn,
  Value<String> altNames,
  Value<String?> network,
  Value<String?> logoUrl,
  Value<String?> country,
  Value<String?> category,
  Value<String> categories,
  Value<String?> language,
  Value<String?> quality,
  Value<bool> featured,
  Value<int> sort,
  Value<String?> epgId,
  Value<int> epgOffset,
  Value<String?> family,
  Value<bool> parental,
  Value<DateTime?> publishedAt,
  Value<int> rowid,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<String> id,
  Value<String> uid,
  Value<int?> number,
  Value<String?> nameAr,
  Value<String?> nameEn,
  Value<String> altNames,
  Value<String?> network,
  Value<String?> logoUrl,
  Value<String?> country,
  Value<String?> category,
  Value<String> categories,
  Value<String?> language,
  Value<String?> quality,
  Value<bool> featured,
  Value<int> sort,
  Value<String?> epgId,
  Value<int> epgOffset,
  Value<String?> family,
  Value<bool> parental,
  Value<DateTime?> publishedAt,
  Value<int> rowid,
});

class $$ChannelsTableFilterComposer
    extends Composer<_$CatalogDb, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get altNames => $composableBuilder(
    column: $table.altNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get featured => $composableBuilder(
    column: $table.featured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epgOffset => $composableBuilder(
    column: $table.epgOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get parental => $composableBuilder(
    column: $table.parental,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$CatalogDb, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get altNames => $composableBuilder(
    column: $table.altNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get featured => $composableBuilder(
    column: $table.featured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epgOffset => $composableBuilder(
    column: $table.epgOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get parental => $composableBuilder(
    column: $table.parental,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$CatalogDb, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get altNames =>
      $composableBuilder(column: $table.altNames, builder: (column) => column);

  GeneratedColumn<String> get network =>
      $composableBuilder(column: $table.network, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<bool> get featured =>
      $composableBuilder(column: $table.featured, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get epgId =>
      $composableBuilder(column: $table.epgId, builder: (column) => column);

  GeneratedColumn<int> get epgOffset =>
      $composableBuilder(column: $table.epgOffset, builder: (column) => column);

  GeneratedColumn<String> get family =>
      $composableBuilder(column: $table.family, builder: (column) => column);

  GeneratedColumn<bool> get parental =>
      $composableBuilder(column: $table.parental, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$CatalogDb,
          $ChannelsTable,
          ChannelRow,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (ChannelRow, BaseReferences<_$CatalogDb, $ChannelsTable, ChannelRow>),
          ChannelRow,
          PrefetchHooks Function()
        > {
  $$ChannelsTableTableManager(_$CatalogDb db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<String> altNames = const Value.absent(),
                Value<String?> network = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<bool> featured = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<int> epgOffset = const Value.absent(),
                Value<String?> family = const Value.absent(),
                Value<bool> parental = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                uid: uid,
                number: number,
                nameAr: nameAr,
                nameEn: nameEn,
                altNames: altNames,
                network: network,
                logoUrl: logoUrl,
                country: country,
                category: category,
                categories: categories,
                language: language,
                quality: quality,
                featured: featured,
                sort: sort,
                epgId: epgId,
                epgOffset: epgOffset,
                family: family,
                parental: parental,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String uid,
                Value<int?> number = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<String> altNames = const Value.absent(),
                Value<String?> network = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<bool> featured = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<int> epgOffset = const Value.absent(),
                Value<String?> family = const Value.absent(),
                Value<bool> parental = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                uid: uid,
                number: number,
                nameAr: nameAr,
                nameEn: nameEn,
                altNames: altNames,
                network: network,
                logoUrl: logoUrl,
                country: country,
                category: category,
                categories: categories,
                language: language,
                quality: quality,
                featured: featured,
                sort: sort,
                epgId: epgId,
                epgOffset: epgOffset,
                family: family,
                parental: parental,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChannelsTable, ChannelRow>(table),
                  BaseReferences<_$CatalogDb, $ChannelsTable, ChannelRow>(
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

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDb,
      $ChannelsTable,
      ChannelRow,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (ChannelRow, BaseReferences<_$CatalogDb, $ChannelsTable, ChannelRow>),
      ChannelRow,
      PrefetchHooks Function()
    >;
typedef $$StreamsTableCreateCompanionBuilder = StreamsCompanion Function({
  required String id,
  required String channelId,
  required String url,
  Value<String?> label,
  Value<String?> quality,
  Value<int> priority,
  Value<String?> userAgent,
  Value<String?> referrer,
  Value<String> headers,
  Value<String?> protocol,
  Value<String> health,
  Value<int?> score,
  Value<int> rowid,
});
typedef $$StreamsTableUpdateCompanionBuilder = StreamsCompanion Function({
  Value<String> id,
  Value<String> channelId,
  Value<String> url,
  Value<String?> label,
  Value<String?> quality,
  Value<int> priority,
  Value<String?> userAgent,
  Value<String?> referrer,
  Value<String> headers,
  Value<String?> protocol,
  Value<String> health,
  Value<int?> score,
  Value<int> rowid,
});

class $$StreamsTableFilterComposer
    extends Composer<_$CatalogDb, $StreamsTable> {
  $$StreamsTableFilterComposer({
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

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referrer => $composableBuilder(
    column: $table.referrer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreamsTableOrderingComposer
    extends Composer<_$CatalogDb, $StreamsTable> {
  $$StreamsTableOrderingComposer({
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

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referrer => $composableBuilder(
    column: $table.referrer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreamsTableAnnotationComposer
    extends Composer<_$CatalogDb, $StreamsTable> {
  $$StreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<String> get referrer =>
      $composableBuilder(column: $table.referrer, builder: (column) => column);

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get health =>
      $composableBuilder(column: $table.health, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$StreamsTableTableManager
    extends
        RootTableManager<
          _$CatalogDb,
          $StreamsTable,
          StreamRow,
          $$StreamsTableFilterComposer,
          $$StreamsTableOrderingComposer,
          $$StreamsTableAnnotationComposer,
          $$StreamsTableCreateCompanionBuilder,
          $$StreamsTableUpdateCompanionBuilder,
          (StreamRow, BaseReferences<_$CatalogDb, $StreamsTable, StreamRow>),
          StreamRow,
          PrefetchHooks Function()
        > {
  $$StreamsTableTableManager(_$CatalogDb db, $StreamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
                Value<String?> referrer = const Value.absent(),
                Value<String> headers = const Value.absent(),
                Value<String?> protocol = const Value.absent(),
                Value<String> health = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamsCompanion(
                id: id,
                channelId: channelId,
                url: url,
                label: label,
                quality: quality,
                priority: priority,
                userAgent: userAgent,
                referrer: referrer,
                headers: headers,
                protocol: protocol,
                health: health,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channelId,
                required String url,
                Value<String?> label = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
                Value<String?> referrer = const Value.absent(),
                Value<String> headers = const Value.absent(),
                Value<String?> protocol = const Value.absent(),
                Value<String> health = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamsCompanion.insert(
                id: id,
                channelId: channelId,
                url: url,
                label: label,
                quality: quality,
                priority: priority,
                userAgent: userAgent,
                referrer: referrer,
                headers: headers,
                protocol: protocol,
                health: health,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StreamsTable, StreamRow>(table),
                  BaseReferences<_$CatalogDb, $StreamsTable, StreamRow>(
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

typedef $$StreamsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDb,
      $StreamsTable,
      StreamRow,
      $$StreamsTableFilterComposer,
      $$StreamsTableOrderingComposer,
      $$StreamsTableAnnotationComposer,
      $$StreamsTableCreateCompanionBuilder,
      $$StreamsTableUpdateCompanionBuilder,
      (StreamRow, BaseReferences<_$CatalogDb, $StreamsTable, StreamRow>),
      StreamRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$CatalogDb, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

class $$SyncStateTableOrderingComposer
    extends Composer<_$CatalogDb, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

class $$SyncStateTableAnnotationComposer
    extends Composer<_$CatalogDb, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
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

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$CatalogDb,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$CatalogDb, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$CatalogDb db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$CatalogDb, $SyncStateTable, SyncStateData>(
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

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDb,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$CatalogDb, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;

class $CatalogDbManager {
  final _$CatalogDb _db;
  $CatalogDbManager(this._db);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$StreamsTableTableManager get streams =>
      $$StreamsTableTableManager(_db, _db.streams);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
