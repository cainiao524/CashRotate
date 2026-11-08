import 'dart:convert';
import 'dart:typed_data';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../db/app_database.dart';
import '../journal.dart';
import 'income.dart';

export 'income.dart';

/// Settings that follow the user across devices.
class UserSettings {
  const UserSettings({
    required this.mainCurrency,
    required this.region,
    this.onboardingDone = false,
    this.decimalsOverride = const {},
    this.language,
    this.autoRateCurrencies,
    this.tileColors = false,
    this.wideTiles = const {},
    this.tileIcons = const {},
    this.tileBadges = const {},
    this.incomes = const [],
    this.tileImages = const {},
    this.remindersOn = true,
    this.reminderMinutes = 9 * 60,
    this.hideAmounts = false,
  });

  /// Defaults for a fresh install, from the system locale's region.
  factory UserSettings.defaultsFor(String? region) => UserSettings(
    mainCurrency: CurrencyInfo.forRegion(region),
    region: (region ?? 'US').toUpperCase(),
  );

  final Currency mainCurrency;

  /// ISO 3166 region; decides which presets and symbols apply.
  final String region;
  final bool onboardingDone;

  /// `en`, `zh-Hant`, `zh-Hans`, or null to follow the system.
  final String? language;

  /// Free tier: currencies chosen for daily automatic rates (null = the
  /// defaults). Ignored while every currency is automatic (Pro, preview).
  final List<Currency>? autoRateCurrencies;

  /// Display decimals chosen by the user per currency code.
  final Map<String, int> decimalsOverride;

  /// Home tiles in each service's colour instead of monochrome.
  final bool tileColors;

  /// Items whose home tile spans two columns.
  final Set<String> wideTiles;

  /// Built-in icon name per item id; items without one show their initial.
  final Map<String, String> tileIcons;

  /// The user's own badge per item id: a short text in place of the
  /// initial, and / or a background colour.
  final Map<String, TileBadge> tileBadges;

  /// Expected income, to compare fixed expenses with (CLAUDE.md item 19).
  final List<IncomeSource> incomes;

  /// The user's own pictures as tile icons (square PNG), per item id.
  final Map<String, Uint8List> tileImages;

  /// Notifications before charges, trial ends and the like.
  final bool remindersOn;

  /// Time of day reminders show, in minutes after midnight (local time).
  final int reminderMinutes;

  /// Amounts shown as dots on screen and left out of notifications, for
  /// using the app in public.
  final bool hideAmounts;

  int decimalsFor(Currency c) =>
      decimalsOverride[c.code] ?? c.defaultDisplayDecimals;
}

/// Reads and writes [UserSettings], journaling each key for sync.
class SettingsRepository {
  SettingsRepository(this._db, this._journal, {int Function()? nowMillis})
    : _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final Journal _journal;
  final int Function() _nowMillis;

  static const mainCurrencyKey = 'main_currency';
  static const regionKey = 'region';
  static const onboardingDoneKey = 'onboarding_done';
  static const decimalsKey = 'display_decimals';
  static const languageKey = 'language';
  static const onboardingDraftKey = 'onboarding_draft';
  static const autoRateCurrenciesKey = 'auto_rate_currencies';
  static const tileColorsKey = 'home_tile_colors';
  static const wideTilesKey = 'home_wide_tiles';
  static const tileIconsKey = 'home_tile_icons';
  static const tileBadgesKey = 'home_tile_badges';
  static const incomesKey = 'income_sources';

  /// One setting per picture (`tile_image:<item id>`, base64 PNG), so a
  /// change syncs that picture alone.
  static const tileImagePrefix = 'tile_image:';
  static const remindersOnKey = 'reminders_on';
  static const reminderMinutesKey = 'reminder_minutes';
  static const hideAmountsKey = 'hide_amounts';

  /// Current settings, falling back to [defaults] for keys never written.
  Stream<UserSettings> watch(UserSettings defaults) =>
      _db.select(_db.appSettings).watch().map((rows) => _parse(rows, defaults));

  Future<UserSettings> read(UserSettings defaults) async =>
      _parse(await _db.select(_db.appSettings).get(), defaults);

  Future<void> setMainCurrency(Currency c) => _set(mainCurrencyKey, c.code);
  Future<void> setRegion(String region) =>
      _set(regionKey, region.toUpperCase());
  Future<void> setOnboardingDone({bool done = true}) =>
      _set(onboardingDoneKey, done);
  Future<void> setLanguage(String? language) => _set(languageKey, language);
  Future<void> setAutoRateCurrencies(List<Currency> currencies) =>
      _set(autoRateCurrenciesKey, [for (final c in currencies) c.code]);
  Future<void> setTileColors(bool on) => _set(tileColorsKey, on);
  Future<void> setRemindersOn(bool on) => _set(remindersOnKey, on);
  Future<void> setHideAmounts(bool hide) => _set(hideAmountsKey, hide);
  Future<void> setReminderMinutes(int minutes) =>
      _set(reminderMinutesKey, minutes.clamp(0, 24 * 60 - 1));
  Future<void> setWideTile(String itemId, {required bool wide}) async {
    final current = await read(UserSettings.defaultsFor(null));
    final ids = {...current.wideTiles};
    wide ? ids.add(itemId) : ids.remove(itemId);
    await _set(wideTilesKey, ids.toList()..sort());
  }

  /// [icon] null goes back to the initial.
  Future<void> setTileIcon(String itemId, String? icon) async {
    final current = await read(UserSettings.defaultsFor(null));
    final icons = {...current.tileIcons}..remove(itemId);
    if (icon != null) icons[itemId] = icon;
    await _set(tileIconsKey, icons);
  }

  /// [badge] null (or empty) goes back to the initial on the usual colour.
  Future<void> setTileBadge(String itemId, TileBadge? badge) async {
    final current = await read(UserSettings.defaultsFor(null));
    final badges = {...current.tileBadges}..remove(itemId);
    if (badge != null && !badge.isEmpty) badges[itemId] = badge;
    await _set(tileBadgesKey, {
      for (final MapEntry(:key, :value) in badges.entries) key: value.toJson(),
    });
  }

  /// [png] null removes the picture.
  Future<void> setTileImage(String itemId, Uint8List? png) =>
      _set('$tileImagePrefix$itemId', png == null ? null : base64Encode(png));

  /// Adds [income], or replaces the one with its id.
  Future<void> saveIncome(IncomeSource income) async {
    final current = await read(UserSettings.defaultsFor(null));
    final list = [...current.incomes];
    final at = list.indexWhere((i) => i.id == income.id);
    at < 0 ? list.add(income) : list[at] = income;
    await _set(incomesKey, [for (final i in list) i.toJson()]);
  }

  Future<void> removeIncome(String id) async {
    final current = await read(UserSettings.defaultsFor(null));
    await _set(incomesKey, [
      for (final i in current.incomes)
        if (i.id != id) i.toJson(),
    ]);
  }

  Future<void> setDecimals(Currency c, int decimals) async {
    final current = await read(UserSettings.defaultsFor(null));
    await _set(decimalsKey, {...current.decimalsOverride, c.code: decimals});
  }

  /// Raw JSON value under [key], for features that keep their own state
  /// (e.g. an unfinished onboarding batch).
  Future<Object?> getJson(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  Future<void> setJson(String key, Object? value) => _set(key, value);

  Future<void> _set(String key, Object? value) => _db.transaction(() async {
    final before = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    final after = SettingRow(
      key: key,
      value: jsonEncode(value),
      updatedAt: _nowMillis(),
    );
    if (before?.value == after.value) return;
    await _db.into(_db.appSettings).insertOnConflictUpdate(after);
    if (before == null) {
      await _journal.inserted('app_settings', key, after);
    } else {
      await _journal.updated('app_settings', key, before, after);
    }
  });

  static UserSettings _parse(List<SettingRow> rows, UserSettings defaults) {
    final map = {for (final r in rows) r.key: jsonDecode(r.value)};
    final code = map[mainCurrencyKey];
    final decimals = map[decimalsKey];
    final wide = map[wideTilesKey];
    final icons = map[tileIconsKey];
    final badges = map[tileBadgesKey];
    final incomes = map[incomesKey];
    return UserSettings(
      mainCurrency: code is String
          ? Currency.tryParse(code) ?? defaults.mainCurrency
          : defaults.mainCurrency,
      region: map[regionKey] is String
          ? map[regionKey] as String
          : defaults.region,
      onboardingDone: map[onboardingDoneKey] == true,
      language: map[languageKey] is String ? map[languageKey] as String : null,
      autoRateCurrencies: map[autoRateCurrenciesKey] is List
          ? [
              for (final c in map[autoRateCurrenciesKey] as List)
                if (c is String) ?Currency.tryParse(c),
            ]
          : null,
      decimalsOverride: decimals is Map
          ? {
              for (final e in decimals.entries)
                if (e.value is int) '${e.key}': e.value as int,
            }
          : const {},
      tileColors: map[tileColorsKey] == true,
      remindersOn: map[remindersOnKey] != false,
      hideAmounts: map[hideAmountsKey] == true,
      reminderMinutes: switch (map[reminderMinutesKey]) {
        final int m when m >= 0 && m < 24 * 60 => m,
        _ => 9 * 60,
      },
      wideTiles: wide is List ? {...wide.whereType<String>()} : const {},
      tileIcons: icons is Map
          ? {
              for (final e in icons.entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {},
      tileBadges: badges is Map
          ? {
              for (final e in badges.entries)
                '${e.key}': ?TileBadge.fromJson(e.value),
            }
          : const {},
      incomes: incomes is List
          ? [for (final i in incomes) ?IncomeSource.fromJson(i)]
          : const [],
      tileImages: {
        for (final MapEntry(:key, :value) in map.entries)
          if (key.startsWith(tileImagePrefix) && value is String)
            key.substring(tileImagePrefix.length): base64Decode(value),
      },
    );
  }
}

/// A home-tile badge the user made: up to three characters in place of the
/// initial, and / or its own background colour (`#RRGGBB`).
@immutable
class TileBadge {
  const TileBadge({this.text, this.color});

  static const maxLength = 3;

  final String? text;
  final String? color;

  bool get isEmpty => (text == null || text!.trim().isEmpty) && color == null;

  static final _hex = RegExp(r'^#[0-9A-F]{6}$');

  static TileBadge? fromJson(Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    final color = json['color'];
    final badge = TileBadge(
      text: text is String && text.trim().isNotEmpty ? text.trim() : null,
      color: color is String && _hex.hasMatch(color) ? color : null,
    );
    return badge.isEmpty ? null : badge;
  }

  Map<String, Object?> toJson() => {'text': ?text, 'color': ?color};

  @override
  bool operator ==(Object other) =>
      other is TileBadge && other.text == text && other.color == color;

  @override
  int get hashCode => Object.hash(text, color);
}
