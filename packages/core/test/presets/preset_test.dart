import 'dart:convert';
import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

Map<String, Object?> valid([Map<String, Object?> overrides = const {}]) => {
  'id': 'netflix',
  'name': {'en': 'Netflix', 'zh-Hans': '奈飞'},
  'category': 'streaming',
  'type': 'subscription',
  'defaultCycle': 'monthly',
  'regions': ['global'],
  'color': '#E50914',
  ...overrides,
};

Matcher throwsFormat(String fragment) => throwsA(
  isA<FormatException>().having(
    (e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('Preset.fromJson', () {
    test('parses a minimal preset with defaults', () {
      final p = Preset.fromJson(valid());
      expect(p.id, 'netflix');
      expect(p.remindDays, 3);
      expect(p.currency, isNull);
      expect(p.defaultCycle.cycle, Cycle.monthly);
      expect(p.availableIn('TW'), isTrue);
      expect(p.isTemplate, isFalse);
    });

    test('round-trips through toJson', () {
      final p = Preset.fromJson(
        valid({
          'currency': 'USD',
          'plans': [
            {
              'id': 'pro',
              'name': {'en': 'Pro'},
            },
          ],
          'remindDays': 30,
          'cancelUrl': 'https://example.com/cancel',
          'fields': ['domain'],
          'aliases': ['NF'],
        }),
      );
      expect(
        Preset.fromJson(jsonDecode(jsonEncode(p.toJson()))).toJson(),
        p.toJson(),
      );
    });

    test('rejects prices and other unknown fields', () {
      expect(
        () => Preset.fromJson(valid({'price': 390})),
        throwsFormat('unknown field'),
      );
    });

    test('names the offending field', () {
      expect(
        () => Preset.fromJson(valid({'id': 'Bad Id'})),
        throwsFormat('kebab-case'),
      );
      expect(
        () => Preset.fromJson(valid({'category': 'tv'})),
        throwsFormat('category'),
      );
      expect(
        () => Preset.fromJson(valid({'type': 'sub'})),
        throwsFormat('type'),
      );
      expect(
        () => Preset.fromJson(valid({'defaultCycle': 'monthy'})),
        throwsFormat('defaultCycle'),
      );
      expect(
        () => Preset.fromJson(valid({'regions': <String>[]})),
        throwsFormat('regions'),
      );
      expect(
        () => Preset.fromJson(
          valid({
            'regions': ['tw'],
          }),
        ),
        throwsFormat('regions'),
      );
      expect(
        () => Preset.fromJson(valid({'color': '#e50914'})),
        throwsFormat('color'),
      );
      expect(
        () => Preset.fromJson(valid({'currency': 'KPW'})),
        throwsFormat('currency'),
      );
      expect(
        () => Preset.fromJson(valid({'remindDays': 120})),
        throwsFormat('remindDays'),
      );
      expect(
        () => Preset.fromJson(valid({'cancelUrl': 'http://x'})),
        throwsFormat('https'),
      );
      expect(
        () => Preset.fromJson(
          valid({
            'name': {'zh-Hant': '網飛'},
          }),
        ),
        throwsFormat('name.en'),
      );
      expect(
        () => Preset.fromJson(
          valid({
            'fields': ['logo'],
          }),
        ),
        throwsFormat('fields'),
      );
    });
  });

  group('LocalizedText.resolve', () {
    const t = LocalizedText(en: 'Rent', zhHant: '房租');
    test('falls back across scripts, then to English', () {
      expect(t.resolve('zh-Hant'), '房租');
      expect(t.resolve('zh-Hans'), '房租');
      expect(t.resolve('en'), 'Rent');
      expect(const LocalizedText(en: 'X').resolve('zh-Hant'), 'X');
    });
  });

  group('schema.json stays in sync with the Dart model', () {
    final schema = jsonDecode(
      File('../../presets/schema.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final props =
        ((schema[r'$defs'] as Map)['preset'] as Map)['properties']
            as Map<String, Object?>;
    List<String> enumOf(String key) =>
        ((props[key] as Map)['enum'] as List).cast<String>();

    test('enumerations', () {
      expect(enumOf('category'), PresetCategory.values.map((e) => e.name));
      expect(enumOf('type'), ItemType.values.map((e) => e.name));
      expect(enumOf('defaultCycle'), PresetCycle.values.map((e) => e.name));
      expect(enumOf('currency'), Currency.all.map((c) => c.code));
      final fields =
          (((props['fields'] as Map)['items'] as Map)['enum'] as List)
              .cast<String>();
      expect(fields, PresetField.values.map((e) => e.name));
    });
  });
}
