import 'package:meta/meta.dart';

import '../model/kinds.dart';
import '../money/currency.dart';
import '../schedule/cycle.dart';

/// Preset categories. Names are localised in the app (`category_<name>`).
enum PresetCategory {
  streaming,
  music,
  cloud,
  software,
  ai,
  gaming,
  reading,
  creator,
  vpn,
  education,
  fitness,
  shopping,
  communication,
  domain,
  hosting,
  devtools,
  gameServer,
  telecom,
  broadband,
  utilities,
  housing,
  insurance,
  loan,
  tax,
  transport,
  family,
  investing,
  other,
}

/// Default billing cycles a preset can suggest.
enum PresetCycle {
  daily(Cycle.daily),
  weekly(Cycle.weekly),
  monthly(Cycle.monthly),
  bimonthly(Cycle.bimonthly),
  quarterly(Cycle.quarterly),
  halfYearly(Cycle.halfYearly),
  yearly(Cycle.yearly);

  const PresetCycle(this.cycle);
  final Cycle cycle;
}

/// Extra field groups the item editor shows for a preset.
enum PresetField { trial, contract, domain, vps, gameServer, repayment, policy }

/// Text in the app's three languages. English is required; Chinese falls
/// back to the other script, then to English.
@immutable
final class LocalizedText {
  const LocalizedText({required this.en, this.zhHant, this.zhHans});

  final String en;
  final String? zhHant;
  final String? zhHans;

  /// Best text for a language tag such as `zh-Hant`, `zh-Hans` or `en`.
  String resolve(String languageTag) => switch (languageTag) {
    'zh-Hant' => zhHant ?? zhHans ?? en,
    'zh-Hans' => zhHans ?? zhHant ?? en,
    _ => en,
  };

  Iterable<String> get all => {en, ?zhHant, ?zhHans};

  static LocalizedText fromJson(Object? json, String where) {
    final map = _object(json, where);
    _onlyKeys(map, const {'en', 'zh-Hant', 'zh-Hans'}, where);
    return LocalizedText(
      en: _string(map['en'], '$where.en'),
      zhHant: _optString(map['zh-Hant'], '$where.zh-Hant'),
      zhHans: _optString(map['zh-Hans'], '$where.zh-Hans'),
    );
  }

  Map<String, Object?> toJson() => {
    'en': en,
    'zh-Hant': ?zhHant,
    'zh-Hans': ?zhHans,
  };
}

@immutable
final class PresetPlan {
  const PresetPlan({required this.id, required this.name});

  final String id;
  final LocalizedText name;

  Map<String, Object?> toJson() => {'id': id, 'name': name.toJson()};
}

/// Search keys computed at build time from the Chinese names, so the app
/// needs no pronunciation data: full pinyin, pinyin initials, zhuyin
/// initials. Each list has one entry per Chinese name.
@immutable
final class PresetSearchKeys {
  const PresetSearchKeys({
    this.pinyin = const [],
    this.initials = const [],
    this.zhuyin = const [],
  });

  final List<String> pinyin;
  final List<String> initials;
  final List<String> zhuyin;

  bool get isEmpty => pinyin.isEmpty && initials.isEmpty && zhuyin.isEmpty;

  Map<String, Object?> toJson() => {
    if (pinyin.isNotEmpty) 'pinyin': pinyin,
    if (initials.isNotEmpty) 'initials': initials,
    if (zhuyin.isNotEmpty) 'zhuyin': zhuyin,
  };
}

/// One entry of the read-only preset library: a known service or a generic
/// template. It never carries prices; users enter what they actually pay.
@immutable
final class Preset {
  const Preset({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.defaultCycle,
    required this.regions,
    required this.color,
    this.aliases = const [],
    this.currency,
    this.plans = const [],
    this.remindDays = 3,
    this.cancelUrl,
    this.fields = const [],
    this.search = const PresetSearchKeys(),
  });

  /// Lowercase id, stable forever: items and user aliases refer to it.
  final String id;
  final LocalizedText name;
  final PresetCategory category;
  final ItemType type;
  final PresetCycle defaultCycle;

  /// `global` or ISO 3166 region codes (`TW`, `HK`, `CN` …).
  final List<String> regions;

  /// Brand colour for the initial badge, `#RRGGBB`.
  final String color;

  /// Other names: nicknames, both Chinese scripts, abbreviations, domains,
  /// merchant names printed on bank statements.
  final List<String> aliases;

  /// Currency the service bills in, when it is the same everywhere (AI
  /// services in USD, pixivFANBOX in JPY). Null means the local currency.
  final Currency? currency;
  final List<PresetPlan> plans;
  final int remindDays;

  /// Where to cancel or manage the subscription.
  final String? cancelUrl;
  final List<PresetField> fields;
  final PresetSearchKeys search;

  bool get isTemplate => id.startsWith('template-');

  bool availableIn(String region) =>
      regions.contains('global') || regions.contains(region);

  static final _id = RegExp(r'^[a-z0-9][a-z0-9-]*$');
  static final _color = RegExp(r'^#[0-9A-F]{6}$');
  static final _region = RegExp(r'^(global|[A-Z]{2})$');

  /// Parses and validates one preset. Throws [FormatException] naming the
  /// offending field, so contributors get a precise error.
  static Preset fromJson(Object? json) {
    final map = _object(json, 'preset');
    final id = _string(map['id'], 'id');
    final where = 'preset "$id"';
    if (!_id.hasMatch(id)) {
      throw FormatException('$where: id must be kebab-case');
    }
    _onlyKeys(map, const {
      'id', 'name', 'aliases', 'category', 'type', 'defaultCycle', 'regions', //
      'currency',
      'plans',
      'remindDays',
      'cancelUrl',
      'color',
      'fields',
      'search',
    }, where);

    final regions = _stringList(map['regions'], '$where.regions');
    if (regions.isEmpty || !regions.every(_region.hasMatch)) {
      throw FormatException('$where.regions: use "global" or ISO region codes');
    }
    final color = _string(map['color'], '$where.color');
    if (!_color.hasMatch(color)) {
      throw FormatException('$where.color: use uppercase #RRGGBB');
    }
    final currencyCode = _optString(map['currency'], '$where.currency');
    final currency = currencyCode == null
        ? null
        : Currency.tryParse(currencyCode);
    if (currencyCode != null && currency == null) {
      throw FormatException('$where.currency: unsupported "$currencyCode"');
    }
    final remindDays = map['remindDays'] ?? 3;
    if (remindDays is! int || remindDays < 0 || remindDays > 90) {
      throw FormatException('$where.remindDays: 0–90 days');
    }
    final cancelUrl = _optString(map['cancelUrl'], '$where.cancelUrl');
    if (cancelUrl != null && !cancelUrl.startsWith('https://')) {
      throw FormatException('$where.cancelUrl: must be https');
    }
    final plans = [
      for (final (i, p) in _list(
        map['plans'] ?? const [],
        '$where.plans',
      ).indexed)
        () {
          final pm = _object(p, '$where.plans[$i]');
          _onlyKeys(pm, const {'id', 'name'}, '$where.plans[$i]');
          return PresetPlan(
            id: _string(pm['id'], '$where.plans[$i].id'),
            name: LocalizedText.fromJson(pm['name'], '$where.plans[$i].name'),
          );
        }(),
    ];
    final aliases = _stringList(map['aliases'] ?? const [], '$where.aliases');
    final searchMap = map['search'] == null
        ? null
        : _object(map['search'], '$where.search');

    return Preset(
      id: id,
      name: LocalizedText.fromJson(map['name'], '$where.name'),
      aliases: aliases,
      category: _enum(
        PresetCategory.values,
        map['category'],
        '$where.category',
      ),
      type: _enum(ItemType.values, map['type'], '$where.type'),
      defaultCycle: _enum(
        PresetCycle.values,
        map['defaultCycle'],
        '$where.defaultCycle',
      ),
      regions: regions,
      currency: currency,
      plans: plans,
      remindDays: remindDays,
      cancelUrl: cancelUrl,
      color: color,
      fields: [
        for (final f in _stringList(map['fields'] ?? const [], '$where.fields'))
          _enum(PresetField.values, f, '$where.fields'),
      ],
      search: searchMap == null
          ? const PresetSearchKeys()
          : PresetSearchKeys(
              pinyin: _stringList(
                searchMap['pinyin'] ?? const [],
                '$where.search.pinyin',
              ),
              initials: _stringList(
                searchMap['initials'] ?? const [],
                '$where.search.initials',
              ),
              zhuyin: _stringList(
                searchMap['zhuyin'] ?? const [],
                '$where.search.zhuyin',
              ),
            ),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name.toJson(),
    if (aliases.isNotEmpty) 'aliases': aliases,
    'category': category.name,
    'type': type.name,
    'defaultCycle': defaultCycle.name,
    'regions': regions,
    'currency': ?currency?.code,
    if (plans.isNotEmpty) 'plans': [for (final p in plans) p.toJson()],
    if (remindDays != 3) 'remindDays': remindDays,
    'cancelUrl': ?cancelUrl,
    'color': color,
    if (fields.isNotEmpty) 'fields': [for (final f in fields) f.name],
    if (!search.isEmpty) 'search': search.toJson(),
  };
}

Map<String, Object?> _object(Object? json, String where) =>
    json is Map<String, Object?>
    ? json
    : throw FormatException('$where: expected an object');

List<Object?> _list(Object? json, String where) => json is List<Object?>
    ? json
    : throw FormatException('$where: expected a list');

String _string(Object? json, String where) =>
    json is String && json.trim().isNotEmpty
    ? json
    : throw FormatException('$where: expected a non-empty string');

String? _optString(Object? json, String where) =>
    json == null ? null : _string(json, where);

List<String> _stringList(Object? json, String where) => [
  for (final (i, s) in _list(json, where).indexed) _string(s, '$where[$i]'),
];

T _enum<T extends Enum>(List<T> values, Object? json, String where) {
  final name = _string(json, where);
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('$where: unknown value "$name"');
}

void _onlyKeys(Map<String, Object?> map, Set<String> allowed, String where) {
  final unknown = map.keys.where((k) => !allowed.contains(k)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException('$where: unknown field(s) ${unknown.join(', ')}');
  }
}
