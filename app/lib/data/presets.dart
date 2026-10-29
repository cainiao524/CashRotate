import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The read-only preset library shipped in the app.
///
/// Built from presets/ by packages/core/tool/build_presets.dart. Online
/// updates (a Pro feature) will replace this source later.
class PresetLibrary {
  PresetLibrary(List<Preset> presets)
    : presets = List.unmodifiable(presets),
      byId = {for (final p in presets) p.id: p},
      search = PresetSearch(presets);

  static Future<PresetLibrary> load(AssetBundle bundle) async {
    final text = await bundle.loadString('assets/presets/presets.json');
    final json = jsonDecode(text) as List<Object?>;
    return PresetLibrary([for (final p in json) Preset.fromJson(p)]);
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

final presetLibraryProvider = FutureProvider<PresetLibrary>(
  (ref) => PresetLibrary.load(rootBundle),
);
