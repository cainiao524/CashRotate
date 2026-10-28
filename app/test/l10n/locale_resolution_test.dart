import 'package:cashrotate/l10n/gen/app_localizations.dart';
import 'package:cashrotate/l10n/locale_resolution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;
  Locale resolve(List<Locale>? preferred) =>
      resolveAppLocale(preferred, supported);

  group('Chinese script', () {
    for (final region in ['TW', 'HK', 'MO']) {
      test('zh_$region without script resolves to Traditional', () {
        expect(
          resolve([Locale('zh', region)]),
          Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: region,
          ),
        );
      });
    }

    for (final region in ['CN', 'SG', 'MY']) {
      test('zh_$region without script resolves to Simplified', () {
        expect(resolve([Locale('zh', region)]).scriptCode, 'Hans');
      });
    }

    test('explicit script wins over region', () {
      const hansInHk = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'HK',
      );
      expect(resolve([hansInHk]), hansInHk);
    });

    test('Traditional locale loads Traditional strings', () async {
      final l10n = await AppLocalizations.delegate.load(
        resolve([const Locale('zh', 'TW')]),
      );
      expect(l10n.navSettings, '設定');
      final hans = await AppLocalizations.delegate.load(
        resolve([const Locale('zh', 'CN')]),
      );
      expect(hans.navSettings, '设置');
    });
  });

  test('keeps the system region for formatting', () {
    expect(resolve([const Locale('en', 'GB')]), const Locale('en', 'GB'));
  });

  test('skips unsupported languages and falls back to English', () {
    expect(
      resolve([const Locale('ja', 'JP'), const Locale('zh', 'HK')]).scriptCode,
      'Hant',
    );
    expect(resolve([const Locale('ja', 'JP')]).languageCode, 'en');
    expect(resolve(null).languageCode, 'en');
  });

  test('plural messages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.itemsPendingCount(0), 'Nothing left to fill in');
    expect(en.itemsPendingCount(1), '1 item still needs details');
    expect(en.itemsPendingCount(3), '3 items still need details');
    final hant = await AppLocalizations.delegate.load(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(hant.itemsPendingCount(3), '還有 3 項待補');
  });
}
