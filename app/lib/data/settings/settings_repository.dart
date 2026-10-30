import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';

import '../db/app_database.dart';
import '../journal.dart';

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
      wideTiles: wide is List ? {...wide.whereType<String>()} : const {},
      tileIcons: icons is Map
          ? {
              for (final e in icons.entries)
                if (e.value is String) '${e.key}': e.value as String,
            }
          : const {},
    );
  }
}
