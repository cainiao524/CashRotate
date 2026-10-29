import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

/// Settings is a lazy list: build and show [finder] before tapping it.
Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('settings')),
        matching: find.byType(Scrollable),
      ),
    );

void main() {
  testApp('shows language, region, main currency and stored rates', (
    tester,
  ) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openSettings(tester);
    expect(find.byKey(const Key('settings-language')), findsOneWidget);
    expect(find.text('Taiwan (TW)'), findsOneWidget);
    expect(find.textContaining(r'NT$ · New Taiwan dollar'), findsOneWidget);
    expect(find.text('1 USD = 32.59 TWD'), findsOneWidget);
  });

  testApp('showing TWD decimals changes amounts everywhere', (tester) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    expect(find.text(r'NT$19,044'), findsOneWidget);
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('settings-decimals-TWD')));
    await settle(tester);
    await tester.tap(find.text('Home'));
    await settle(tester);
    expect(find.text(r'NT$19,044.41'), findsOneWidget);
  });

  testApp('add an exchange rate for another currency', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.textContaining('No exchange rates yet'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('settings-add-rate')));
    await tester.tap(find.byKey(const Key('settings-add-rate')));
    await pumpUntil(
      tester,
      find.byKey(const ValueKey('currency-JPY')).hitTestable(),
    );
    await tester.tap(
      find.byKey(const ValueKey('currency-JPY')).hitTestable().first,
    );
    await pumpUntil(tester, find.byKey(const Key('fx-rate-field')));
    await tester.enterText(find.byKey(const Key('fx-rate-field')), '0.21');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(find.text('1 JPY = 0.21 TWD'), findsOneWidget);
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
}
