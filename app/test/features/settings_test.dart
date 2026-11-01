import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-settings')));
  await settle(tester);
}

/// Settings pages are lazy lists: build and show [finder] before tapping
/// it. [list] is the page's list key.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  Key list = const PageStorageKey('settings'),
}) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(of: find.byKey(list), matching: find.byType(Scrollable))
        .first,
  );
  // Built is not enough: bring it fully into the viewport, clear of the
  // bottom navigation bar.
  await tester.ensureVisible(finder);
  await settle(tester);
}

/// Settings › Amounts: the per-currency decimals page.
Future<void> openAmounts(WidgetTester tester) async {
  await openSettings(tester);
  await tester.tap(find.byKey(const Key('settings-amounts')));
  await settle(tester);
}

void main() {
  testApp('shows language, region, main currency and stored rates', (
    tester,
  ) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openSettings(tester);
    expect(find.byKey(const Key('settings-language')), findsOneWidget);
    expect(find.text('Taiwan (TW)'), findsOneWidget);
    expect(find.textContaining(r'NT$ · New Taiwan dollar'), findsOneWidget);
    await scrollTo(tester, find.text('1 USD = 32.59 TWD'));
    expect(find.text('1 USD = 32.59 TWD'), findsOneWidget);
  });

  testApp('showing TWD decimals changes amounts everywhere', (tester) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    expect(find.text(r'NT$19,044'), findsOneWidget);
    await openSettings(tester);
    // The settings row previews each currency in use.
    expect(find.text(r'NT$1,235 · US$1,234.56'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-amounts')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('settings-decimals-TWD')));
    await settle(tester);
    await tester.pageBack(); // amounts → settings
    await settle(tester);
    expect(find.text(r'NT$1,234.56 · US$1,234.56'), findsOneWidget);
    await tester.pageBack(); // settings → home
    await settle(tester);
    expect(find.text(r'NT$19,044.41'), findsOneWidget);
  });

  testApp('decimals list skips currencies that only have a rate', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (d) async {
        await d.seedItems();
        await d.rates.setManualRate(
          Currency.eur,
          Currency.twd,
          Ratio.tryParse('35')!,
        );
      },
    );
    await openAmounts(tester);
    expect(find.byKey(const Key('settings-decimals-TWD')), findsOneWidget);
    expect(find.byKey(const Key('settings-decimals-USD')), findsOneWidget);
    expect(find.byKey(const Key('settings-decimals-EUR')), findsNothing);
  });

  testApp('a currency appears once an item uses it', (tester) async {
    await pumpApp(tester);
    await openAmounts(tester);
    expect(find.byKey(const Key('settings-decimals-TWD')), findsOneWidget);
    expect(find.byKey(const Key('settings-decimals-USD')), findsNothing);
    expect(find.textContaining('A currency appears here'), findsOneWidget);
  });

  testApp('free tier: add a manual rate for a non-automatic currency', (
    tester,
  ) async {
    await pumpApp(tester, entitlements: Entitlements.free);
    await openSettings(tester);
    await scrollTo(tester, find.textContaining('No exchange rates yet'));
    expect(find.textContaining('No exchange rates yet'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('settings-add-rate')));
    await tester.tap(find.byKey(const Key('settings-add-rate')));
    await pumpUntil(
      tester,
      find.byKey(const ValueKey('currency-JPY')).hitTestable(),
    );
    // JPY is one of the free automatic currencies; MYR is not.
    await tester.enterText(find.byType(TextField).last, 'MYR');
    await pumpUntil(
      tester,
      find.byKey(const ValueKey('currency-MYR')).hitTestable(),
    );
    await tester.tap(
      find.byKey(const ValueKey('currency-MYR')).hitTestable().first,
    );
    await pumpUntil(tester, find.byKey(const Key('fx-rate-field')));
    await tester.enterText(find.byKey(const Key('fx-rate-field')), '7.2');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(find.text('1 MYR = 7.2 TWD'), findsOneWidget);
  });

  testApp('quick setup can be run again', (tester) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-run-setup')));
    await tester.tap(find.byKey(const Key('settings-run-setup')));
    await settle(tester);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testApp('update now downloads automatic rates', (tester) async {
    testRateResponses = (uri) async =>
        '{"result":"success","base_code":"TWD","time_last_update_unix":1761696000,'
        '"rates":{"USD":0.03068,"JPY":4.6812}}';
    addTearDown(() => testRateResponses = (uri) => throw Exception('offline'));
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openSettings(tester);
    await scrollTo(
      tester,
      find.text('Every currency updates automatically each day'),
    );
    expect(
      find.text('Every currency updates automatically each day'),
      findsOneWidget,
    );
    await scrollTo(tester, find.byKey(const Key('settings-update-rates')));
    await tester.tap(find.byKey(const Key('settings-update-rates')));
    await settle(tester, frames: 10);
    // ChatGPT is billed in USD, so its now-automatic rate is listed.
    expect(find.text('1 TWD = 0.03068 USD'), findsOneWidget);
    expect(find.textContaining('Automatic'), findsWidgets);
    expect(find.byKey(const Key('settings-add-rate')), findsNothing);
  });
}
