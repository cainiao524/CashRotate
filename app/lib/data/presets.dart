import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlements.dart';
import 'presets_update.dart';
import 'providers.dart';

export 'presets_update.dart';

/// The read-only preset library: built into the app, with a downloaded
/// update laid over it when there is one (CLAUDE.md item 6).
///
/// Built from presets/ by packages/core/tool/build_presets.dart.
class PresetLibrary {
  PresetLibrary(List<Preset> presets, {this.downloadedAt})
    : presets = List.unmodifiable(presets),
      byId = {for (final p in presets) p.id: p},
      search = PresetSearch(presets);

  /// When the downloaded update was last checked; null for the built-in
  /// library alone.
  final DateTime? downloadedAt;

  /// The downloaded library as fetched, to tell a new one from the same.
  String? downloadedJson;

  static Future<PresetLibrary> load(AssetBundle bundle) async {
    final text = await bundle.loadString('assets/presets/presets.json');
    final json = jsonDecode(text) as List<Object?>;
    return PresetLibrary([for (final p in json) Preset.fromJson(p)]);
  }

  /// [builtIn] with the downloaded update from [stored] laid over it.
  static PresetLibrary withUpdate(PresetLibrary builtIn, StoredPresets stored) {
    final json = stored.json;
    final downloaded = json == null ? null : PresetUpdater.parse(json);
    if (downloaded == null) return builtIn;
    return PresetLibrary(
      mergePresets(builtIn.presets, downloaded),
      downloadedAt: stored.checkedAt,
    )..downloadedJson = json;
  }

  final List<Preset> presets;
  final Map<String, Preset> byId;
  final PresetSearch search;

  /// Presets offered in [region], templates last, otherwise in file order.
  List<Preset> availableIn(String region) => [
    ...presets.where((p) => !p.isTemplate && p.availableIn(region)),
    ...presets.where((p) => p.isTemplate),
  ];
}

/// The library that came with the app.
final builtInPresetsProvider = FutureProvider<PresetLibrary>(
  (ref) => PresetLibrary.load(rootBundle),
);

final presetLibraryProvider = FutureProvider<PresetLibrary>((ref) async {
  final builtIn = await ref.watch(builtInPresetsProvider.future);
  final db = await ref.watch(appDatabaseProvider.future);
  return PresetLibrary.withUpdate(builtIn, await PresetUpdater(db).stored());
});

final presetUpdaterProvider = Provider<PresetUpdater>(
  (ref) => PresetUpdater(
    ref.watch(appDatabaseProvider).requireValue,
    now: ref.watch(clockProvider),
  ),
);

/// Checks for a newer library at most once a week (Pro; every feature is
/// open in the preview). Reloads the library when one arrived.
final presetAutoUpdateProvider = FutureProvider<PresetUpdateResult?>((
  ref,
) async {
  if (!ref.watch(entitlementsProvider).has(ProFeature.presetUpdates)) {
    return null;
  }
  final library = await ref.watch(presetLibraryProvider.future);
  final result = await ref
      .read(presetUpdaterProvider)
      .updateIfDue(current: library.downloadedJson);
  if (result?.status == PresetUpdateStatus.updated) {
    ref.invalidate(presetLibraryProvider);
  }
  return result;
});
