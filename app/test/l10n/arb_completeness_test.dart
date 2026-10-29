import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every string exists in English, Traditional and Simplified Chinese, with
/// the same placeholders, so no screen falls back to another language.
void main() {
  Map<String, Object?> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, Object?>;

  final en = load('app_en.arb');
  final translations = {
    'zh_Hant': load('app_zh_Hant.arb'),
    'zh': load('app_zh.arb'),
  };

  Set<String> messages(Map<String, Object?> arb) => {
    for (final k in arb.keys)
      if (!k.startsWith('@')) k,
  };

  // {name}, but not ICU keywords such as {count, plural, …} branches.
  Set<String> placeholders(String text) => {
    for (final m in RegExp(r'\{(\w+)[,}]').allMatches(text)) m[1]!,
  };

  test('English messages all have a description', () {
    for (final key in messages(en)) {
      final meta = en['@$key'];
      expect(meta, isA<Map<String, Object?>>(), reason: '@$key missing');
      expect(
        (meta! as Map)['description'],
        isA<String>(),
        reason: '@$key.description missing',
      );
    }
  });

  for (final MapEntry(key: locale, value: arb) in translations.entries) {
    group(locale, () {
      test('has exactly the English keys', () {
        expect(
          messages(arb).difference(messages(en)),
          isEmpty,
          reason: 'extra keys',
        );
        expect(
          messages(en).difference(messages(arb)),
          isEmpty,
          reason: 'untranslated keys',
        );
      });

      test('no empty values and the same placeholders', () {
        for (final key in messages(en)) {
          final value = arb[key];
          expect(value, isA<String>(), reason: key);
          expect((value! as String).trim(), isNotEmpty, reason: key);
          expect(
            placeholders(value as String),
            placeholders(en[key]! as String),
            reason: '$key placeholders differ',
          );
        }
      });
    });
  }

  test('gen-l10n reports no untranslated messages', () async {
    final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final result = await Process.run(flutter, [
      'gen-l10n',
      '--untranslated-messages-file',
      'build/untranslated.json',
    ], runInShell: true);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final file = File('build/untranslated.json');
    final untranslated = file.existsSync()
        ? jsonDecode(file.readAsStringSync())
        : <String, Object?>{};
    expect(untranslated, isEmpty);
  });
}
