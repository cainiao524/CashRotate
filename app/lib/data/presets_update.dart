import 'dart:convert';
import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';

import 'db/app_database.dart';

/// Where newer preset libraries are published: the built file in the public
/// repository, through jsDelivr first and raw GitHub as the fallback. Only a
/// plain GET; nothing about the user is sent.
const presetSources = [
  'https://cdn.jsdelivr.net/gh/cainiao524/CashRotate@main/app/assets/presets/presets.json',
  'https://raw.githubusercontent.com/cainiao524/CashRotate/main/app/assets/presets/presets.json',
];

/// A downloaded library smaller than this is treated as broken.
const minPresetCount = 100;

/// How often the library is checked by itself.
const presetCheckEvery = Duration(days: 7);

enum PresetUpdateStatus { updated, unchanged, failed }

typedef PresetUpdateResult = ({PresetUpdateStatus status, int count});

/// The downloaded library kept on this device (not synced: each device
/// fetches its own), and when it was last checked.
typedef StoredPresets = ({String? json, DateTime? checkedAt});

/// Downloads the latest preset library, checks every entry, and keeps it in
/// the local database (CLAUDE.md item 6).
class PresetUpdater {
  PresetUpdater(
    this._db, {
    Future<String> Function(Uri uri)? get,
    DateTime Function()? now,
  }) : _get = get ?? _httpGet,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Future<String> Function(Uri uri) _get;
  final DateTime Function() _now;

  static const _jsonKey = 'presets_download';
  static const _checkedKey = 'presets_checked_at';

  Future<StoredPresets> stored() async {
    final rows = await (_db.select(
      _db.meta,
    )..where((m) => m.key.isIn([_jsonKey, _checkedKey]))).get();
    String? value(String key) =>
        rows.where((r) => r.key == key).firstOrNull?.value;
    return (
      json: value(_jsonKey),
      checkedAt: DateTime.tryParse(value(_checkedKey) ?? ''),
    );
  }

  /// Parses a library; null when any entry is invalid, ids repeat, or it is
  /// suspiciously small.
  static List<Preset>? parse(String text) {
    try {
      final list = jsonDecode(text) as List<Object?>;
      final presets = [for (final p in list) Preset.fromJson(p)];
      final ids = {for (final p in presets) p.id};
      if (presets.length < minPresetCount || ids.length != presets.length) {
        return null;
      }
      return presets;
    } on Object {
      return null;
    }
  }

  /// Fetches the library now. [current] is what the app already shows, to
  /// tell an update from no change.
  Future<PresetUpdateResult> update({required String? current}) async {
    for (final source in presetSources) {
      final String text;
      try {
        text = await _get(Uri.parse(source));
      } on Object {
        continue;
      }
      final presets = parse(text);
      if (presets == null) continue;
      await _put(_checkedKey, _now().toUtc().toIso8601String());
      if (text == current) {
        return (status: PresetUpdateStatus.unchanged, count: presets.length);
      }
      await _put(_jsonKey, text);
      return (status: PresetUpdateStatus.updated, count: presets.length);
    }
    return (status: PresetUpdateStatus.failed, count: 0);
  }

  /// Checks once a week at most; returns null when it is not time yet.
  Future<PresetUpdateResult?> updateIfDue({required String? current}) async {
    final checked = (await stored()).checkedAt;
    if (checked != null &&
        _now().toUtc().difference(checked) < presetCheckEvery) {
      return null;
    }
    return update(current: current);
  }

  Future<void> _put(String key, String value) => _db
      .into(_db.meta)
      .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  static Future<String> _httpGet(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }
}

/// The built-in library with a downloaded one laid over it: downloaded
/// entries replace built-in ones with the same id, and new ones are added.
/// Built-in entries missing online stay (an app update may know newer ones).
List<Preset> mergePresets(List<Preset> builtIn, List<Preset>? downloaded) {
  if (downloaded == null) return builtIn;
  final online = {for (final p in downloaded) p.id: p};
  return [for (final p in builtIn) online.remove(p.id) ?? p, ...online.values];
}
