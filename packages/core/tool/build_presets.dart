// Builds the preset library the app ships with.
//
//   dart run tool/build_presets.dart          # from packages/core: write
//   dart run tool/build_presets.dart --check  # fail if the output is stale
//
// Reads presets/**/*.json (each file a JSON array), validates every entry,
// rejects duplicate ids and aliases, adds pinyin / zhuyin search keys for
// Chinese names, and writes app/assets/presets/presets.json sorted by id.

import 'dart:convert';
import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';

const _minPresets = 200;
const _maxPresets = 300;

void main(List<String> args) {
  final check = args.contains('--check');
  final root = _repoRoot();
  final presetsDir = Directory('${root.path}/presets');
  final readings = HanReadings.parse(
    File('${presetsDir.path}/tool/han_readings.tsv').readAsStringSync(),
    File('${presetsDir.path}/tool/phrase_readings.tsv').readAsStringSync(),
  );

  final errors = <String>[];
  final presets = <Preset>[];
  final files =
      presetsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) => f.path.endsWith('.json') && !f.path.endsWith('schema.json'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final rel = file.path
        .substring(presetsDir.path.length + 1)
        .replaceAll(r'\', '/');
    final Object? json;
    try {
      json = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      errors.add('$rel: invalid JSON (${e.message})');
      continue;
    }
    if (json is! List<Object?>) {
      errors.add('$rel: top level must be an array');
      continue;
    }
    for (final entry in json) {
      try {
        presets.add(_withSearchKeys(Preset.fromJson(entry), readings));
      } on FormatException catch (e) {
        errors.add('$rel: ${e.message}');
      } on StateError catch (e) {
        errors.add(
          '$rel: ${e.message} (add it to presets/tool/han_readings.tsv)',
        );
      }
    }
  }

  final ids = <String, int>{};
  final aliasOwners = <String, String>{};
  for (final p in presets) {
    ids[p.id] = (ids[p.id] ?? 0) + 1;
    for (final text in [...p.aliases, ...p.name.all]) {
      final key = normalizeForSearch(text);
      final owner = aliasOwners[key];
      if (owner != null && owner != p.id) {
        // A shared plain name is fine; an alias pointing at two presets is not.
        if (p.aliases.contains(text)) {
          errors.add('alias "$text" of ${p.id} already names $owner');
        }
      } else {
        aliasOwners[key] = p.id;
      }
    }
  }
  for (final MapEntry(:key, :value) in ids.entries) {
    if (value > 1) errors.add('duplicate id "$key"');
  }
  if (presets.length < _minPresets || presets.length > _maxPresets) {
    errors.add(
      'expected $_minPresets–$_maxPresets presets, found ${presets.length}',
    );
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Preset library has ${errors.length} problem(s):');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  presets.sort((a, b) => a.id.compareTo(b.id));
  final output =
      '[\n${presets.map((p) => jsonEncode(p.toJson())).join(',\n')}\n]\n';
  final out = File('${root.path}/app/assets/presets/presets.json');

  if (check) {
    if (!out.existsSync() || out.readAsStringSync() != output) {
      stderr.writeln(
        '${out.path} is out of date. Run `dart run tool/build_presets.dart` '
        'in packages/core and commit the result.',
      );
      exit(1);
    }
    stdout.writeln('Preset library OK: ${presets.length} presets.');
    return;
  }
  out
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(output);
  final byRegion = <String, int>{};
  for (final p in presets) {
    for (final r in p.regions) {
      byRegion[r] = (byRegion[r] ?? 0) + 1;
    }
  }
  stdout.writeln(
    'Wrote ${presets.length} presets '
    '(${presets.where((p) => p.isTemplate).length} templates; by region $byRegion).',
  );
}

Preset _withSearchKeys(Preset p, HanReadings readings) {
  final chinese = {
    for (final t in [?p.name.zhHant, ?p.name.zhHans, ...p.aliases])
      if (HanReadings.containsHan(t)) t,
  };
  if (chinese.isEmpty) return p;
  final keys = [for (final t in chinese) readings.keys(t)];
  return Preset(
    id: p.id,
    name: p.name,
    aliases: p.aliases,
    category: p.category,
    type: p.type,
    defaultCycle: p.defaultCycle,
    regions: p.regions,
    currency: p.currency,
    plans: p.plans,
    remindDays: p.remindDays,
    cancelUrl: p.cancelUrl,
    color: p.color,
    fields: p.fields,
    search: PresetSearchKeys(
      pinyin: {for (final k in keys) k.pinyin}.toList(),
      initials: {for (final k in keys) k.initials}.toList(),
      zhuyin: {for (final k in keys) k.zhuyin}.toList(),
    ),
  );
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/presets/schema.json').existsSync()) {
    if (dir.parent.path == dir.path) {
      stderr.writeln('Run this from inside the CashRotate repository.');
      exit(2);
    }
    dir = dir.parent;
  }
  return dir;
}
