@Tags(['golden'])
library;

import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// A screen in the golden matrix: how to seed data and how to get there.
typedef GoldenScreen = ({
  bool onboarded,
  Future<void> Function(TestData data)? seed,
  Future<void> Function(WidgetTester tester)? open,
});

Map<String, Object?> _row(
  String key,
  String name, {
  String? amount,
  String? date,
}) => {
  'key': key,
  'name': name,
  'presetId': key,
  'type': 'subscription',
  'cycleUnit': 'month',
  'cycleEvery': 1,
  'currency': 'TWD',
  'remindDays': [3],
  'amount': ?amount,
  'date': ?date,
};

Future<void> _draft(TestData d, int step) =>
    d.settings.setJson(SettingsRepository.onboardingDraftKey, {
      'step': step,
      'rows': [
        _row('netflix', 'Netflix', amount: '390', date: '2026-03-18'),
        _row('spotify', 'Spotify'),
        _row('icloud-plus', 'iCloud+', amount: '90', date: '2026-03-25'),
      ],
    });

Future<void> _openFixed(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.event_repeat_outlined));
  await settle(tester);
}

/// Every width × text scale × brightness from CLAUDE.md, for each screen.
/// Layout overflow throws during pumping, so these also prove nothing breaks
/// at 200% text on any width (checked on every platform; pixels are compared
/// on Linux only).
///
/// Regenerate baselines with the "Update goldens" GitHub workflow.
void main() {
  final screens = <String, GoldenScreen>{
    'home': (onboarded: true, seed: (d) => d.seedItems(), open: null),
    'items': (onboarded: true, seed: (d) => d.seedItems(), open: _openFixed),
    'item_detail': (
      onboarded: true,
      seed: (d) => d.seedItems(),
      open: (tester) async {
        await _openFixed(tester);
        // At 200% text a narrow list pane may need scrolling to reach it.
        await tester.scrollUntilVisible(
          find.text('example.com'),
          120,
          scrollable: find.descendant(
            of: find.byKey(const PageStorageKey('items-list')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.text('example.com'));
        await settle(tester);
      },
    ),
    'editor': (
      onboarded: true,
      seed: (d) => d.seedItems(),
      open: (tester) async {
        await _openFixed(tester);
        await tester.tap(find.byKey(const Key('items-add')));
        await pumpUntil(tester, find.byKey(const Key('add-search')));
        await tester.enterText(find.byKey(const Key('add-search')), 'chatgpt');
        await pumpUntil(
          tester,
          find.byKey(const ValueKey('add-preset-chatgpt')),
        );
        await tester.tap(find.byKey(const ValueKey('add-preset-chatgpt')));
        await pumpUntil(tester, find.byKey(const Key('field-amount')));
        await tester.enterText(find.byKey(const Key('field-amount')), '20');
        await settle(tester);
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
      },
    ),
    'add_item': (
      onboarded: true,
      seed: null,
      open: (tester) async {
        await _openFixed(tester);
        await tester.tap(find.byKey(const Key('items-add')));
        await pumpUntil(tester, find.byKey(const Key('add-search')));
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
      },
    ),
    'batch_add': (
      onboarded: true,
      seed: null,
      open: (tester) async {
        await _openFixed(tester);
        await tester.tap(find.byKey(const Key('items-add')));
        await pumpUntil(
          tester,
          find.byKey(const Key('add-several')).hitTestable(),
        );
        await tester.tap(find.byKey(const Key('add-several')));
        await pumpUntil(tester, find.byKey(const Key('picker-count')));
      },
    ),
    'fx_rate_dialog': (
      onboarded: true,
      seed: (d) => d.seedItems(),
      open: (tester) async {
        await _openFixed(tester);
        await tester.tap(find.byKey(const Key('items-add')));
        await pumpUntil(tester, find.byKey(const Key('add-search')));
        await tester.enterText(find.byKey(const Key('add-search')), 'chatgpt');
        await pumpUntil(
          tester,
          find.byKey(const ValueKey('add-preset-chatgpt')),
        );
        await tester.tap(find.byKey(const ValueKey('add-preset-chatgpt')));
        await pumpUntil(tester, find.text('Set rate'));
        await tester.tap(find.text('Set rate'));
        await pumpUntil(tester, find.byKey(const Key('fx-rate-field')));
      },
    ),
    'currency_picker': (
      onboarded: false,
      seed: null,
      open: (tester) async {
        await tester.tap(find.byKey(const Key('ob-currency')));
        await pumpUntil(tester, find.byKey(const ValueKey('currency-USD')));
      },
    ),
    'settings': (
      onboarded: true,
      seed: (d) => d.seedItems(),
      open: (tester) async {
        await tester.tap(find.byKey(const Key('nav-settings')));
        await settle(tester);
      },
    ),
    'onboarding_basics': (onboarded: false, seed: null, open: null),
    'onboarding_import': (
      onboarded: false,
      seed: (d) => _draft(d, 1),
      open: null,
    ),
    'onboarding_pick': (
      onboarded: false,
      seed: (d) => _draft(d, 2),
      open: (tester) =>
          pumpUntil(tester, find.byKey(const Key('picker-count'))),
    ),
    'onboarding_batch': (
      onboarded: false,
      seed: (d) => _draft(d, 3),
      open: null,
    ),
    'onboarding_summary': (
      onboarded: false,
      seed: (d) async {
        await d.seedItems();
        await d.settings.setJson(SettingsRepository.onboardingDraftKey, {
          'step': 4,
          'rows': <Object?>[],
        });
      },
      open: null,
    ),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    for (final width in goldenWidths) {
      for (final scale in goldenTextScales) {
        for (final brightness in goldenBrightnesses) {
          final file = '${name}_${width.toInt()}_x${scale}_${brightness.name}';
          testApp(file, (tester) async {
            await pumpApp(
              tester,
              width: width,
              textScale: scale,
              brightness: brightness,
              onboarded: screen.onboarded,
              seed: screen.seed,
            );
            await screen.open?.call(tester);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('$name/$file.png'),
            );
          });
        }
      }
    }
  }
}
