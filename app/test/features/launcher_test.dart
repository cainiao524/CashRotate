import 'dart:convert';

import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate/features/home/fixed_summary.dart';
import 'package:cashrotate/features/widgets/widget_bridge.dart';
import 'package:cashrotate/l10n/gen/app_localizations.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'fixed_summary_test.dart' show today, view;

/// M7: home-screen widgets and launcher shortcuts.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final zh = lookupAppLocalizations(
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  );
  const settings = UserSettings(mainCurrency: Currency.twd, region: 'TW');
  final items = [
    view(
      name: 'Rent',
      price: const Money(1800000, Currency.twd),
      due: today.addDays(20),
    ),
    view(
      name: 'netflix',
      price: const Money(39000, Currency.twd),
      due: today.addDays(3),
    ),
    view(
      name: 'Spotify',
      price: const Money(0, Currency.twd),
      needsDetails: true,
    ),
    view(
      name: 'Gym',
      price: const Money(99900, Currency.twd),
      status: ItemStatus.paused,
    ),
  ];
  const summary = FixedSummary(
    monthlyTotal: Money(1839000, Currency.twd),
    missingRates: 0,
    dueSoon: 1,
    needsDetails: 1,
  );
  const month = MonthCharges(
    paid: Money(39000, Currency.twd),
    pending: Money(1800000, Currency.twd),
  );

  test('widget snapshot: active charges soonest first, worded', () {
    final s = buildWidgetSnapshot(
      items: items,
      summary: summary,
      month: month,
      settings: settings,
      l10n: en,
      locale: 'en_US',
    );
    expect(s['total'], r'NT$18,390');
    expect(s['summary'], r'Paid NT$390 · To pay NT$18,000');
    final rows = (s['items']! as List).cast<Map<String, Object?>>();
    expect([for (final r in rows) r['name']], ['netflix', 'Rent']);
    expect(rows.first['letter'], 'N');
    expect(rows.first['dueOn'], '2026-03-18');
    final labels = s['labels']! as Map<String, Object?>;
    expect(labels['inDays'], 'In {n} days');
    expect(labels['overdue'], '{n} days overdue');
    expect(labels['tomorrow'], 'Due tomorrow');
  });

  test('widget snapshot: hidden amounts are masked; Chinese wording', () {
    final s = buildWidgetSnapshot(
      items: items,
      summary: summary,
      month: null,
      settings: const UserSettings(
        mainCurrency: Currency.twd,
        region: 'TW',
        hideAmounts: true,
      ),
      l10n: zh,
      locale: 'zh_TW',
    );
    expect(s['total'], '••••');
    expect(jsonEncode(s), isNot(contains('390')));
    expect((s['labels']! as Map)['inDays'], contains('{n}'));
  });

  testApp('the app hands the widgets their content', (tester) async {
    final widgets = FakeHomeWidgets();
    await pumpApp(tester, homeWidgets: widgets, seed: (d) => d.seedItems());
    await tester.pump(const Duration(seconds: 1));
    final last = jsonDecode(widgets.updates.last) as Map<String, Object?>;
    expect(last['total'], r'NT$18,752');
    expect((last['items']! as List).first, containsPair('name', 'Netflix'));
  });

  testApp('shortcuts: set in the app language; record a payment', (
    tester,
  ) async {
    final shortcuts = FakeShortcuts();
    late Map<String, String> ids;
    await pumpApp(
      tester,
      shortcuts: shortcuts,
      seed: (d) async => ids = await d.seedItems(),
    );
    expect(shortcuts.current, {'add': 'Add item', 'pay': 'Record payment'});

    shortcuts.open('pay');
    await settle(tester);
    expect(find.text('Which item did you pay?'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('pay-pick-${ids['netflix']}')));
    await settle(tester);
    expect(find.byKey(const Key('payment-amount')), findsOneWidget);
  });

  testApp('shortcut: add an item', (tester) async {
    final shortcuts = FakeShortcuts();
    await pumpApp(tester, shortcuts: shortcuts, seed: (d) => d.seedItems());
    shortcuts.open('add');
    await settle(tester);
    expect(find.byKey(const Key('add-search')), findsOneWidget);
  });
}
