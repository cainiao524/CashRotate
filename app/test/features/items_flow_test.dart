import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Future<void> openFixed(WidgetTester tester) async {
  await tester.tap(find.text('Fixed'));
  await settle(tester);
}

Future<void> pickDateOk(WidgetTester tester, Finder field) async {
  await tester.tap(field);
  await settle(tester);
  await tester.tap(find.text('OK'));
  await settle(tester);
}

void main() {
  testApp('add from a preset with a manual exchange rate', (tester) async {
    await pumpApp(tester, width: 411);
    await openFixed(tester);
    await tester.tap(find.byKey(const Key('items-add')));
    await pumpUntil(tester, find.byKey(const Key('add-search')));

    await tester.enterText(find.byKey(const Key('add-search')), 'chatgpt');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('add-preset-chatgpt')));
    await pumpUntil(tester, find.byKey(const Key('field-amount')));

    // Pre-filled from the preset, billed in USD.
    expect(find.widgetWithText(TextField, 'ChatGPT'), findsOneWidget);
    expect(find.text('Currency: USD'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field-amount')), '20');
    await settle(tester);
    expect(find.text('No USD exchange rate yet'), findsOneWidget);

    await tester.tap(find.text('Set rate'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('fx-rate-field')), '32.59');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await settle(tester);
    expect(find.textContaining('≈ NT\$652 · rate 32.59'), findsOneWidget);

    await pickDateOk(tester, find.byKey(const Key('field-nextCharge')));
    await tester.tap(find.byKey(const Key('editor-save')));
    await settle(tester, frames: 10);

    // Lands on the new item's detail page.
    expect(find.text('ChatGPT'), findsWidgets);
    expect(find.textContaining('≈ NT\$652'), findsWidgets);
    expect(find.text(r'US$20.00'), findsWidgets);
  });

  testApp('intro price without a renewal price is refused', (tester) async {
    await pumpApp(tester);
    await openFixed(tester);
    await tester.tap(find.byKey(const Key('items-add')));
    await pumpUntil(tester, find.byKey(const Key('add-search')));
    await tester.tap(find.byKey(const Key('add-custom')));
    await pumpUntil(tester, find.byKey(const Key('field-name')));

    await tester.enterText(find.byKey(const Key('field-name')), 'VPS');
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('field-intro')));
    await tester.tap(find.byKey(const Key('field-intro')));
    await settle(tester);
    // The intro price field appears above, out of view: back to the top.
    await tester.drag(
      find.byKey(const PageStorageKey('item-editor')),
      const Offset(0, 800),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('field-introAmount')), '5');
    await tester.tap(find.byKey(const Key('editor-save')));
    await settle(tester);

    expect(
      find.text("Enter the renewal price so it doesn't surprise you later"),
      findsOneWidget,
    );
    expect(find.text('Required'), findsOneWidget, reason: 'next charge date');
    expect(find.text('Edit fixed expense'), findsNothing);
    expect(
      find.text('New fixed expense'),
      findsOneWidget,
      reason: 'still on the editor',
    );
  });

  testApp('list shows items soonest first; duplicate and delete from detail', (
    tester,
  ) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openFixed(tester);

    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('item-'),
    );
    expect(rows, findsNWidgets(5));
    // Soonest first: Netflix (18 Mar) before ChatGPT (20 Mar) before Rent (5 Apr).
    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(top('Netflix') < top('ChatGPT'), isTrue);
    expect(top('ChatGPT') < top('Rent'), isTrue);
    expect(find.text('To fill in'), findsOneWidget, reason: 'Spotify');

    await tester.tap(find.text('Netflix'));
    await settle(tester);
    expect(find.text('Next charge'), findsOneWidget);
    await tester.tap(find.byKey(const Key('detail-duplicate')));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Netflix (copy)'), findsOneWidget);

    await tester.tap(find.text('Netflix (copy)'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('detail-delete')));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await settle(tester);
    expect(find.text('Netflix (copy)'), findsNothing);
  });

  testApp('detail shows the upcoming price change of an intro price', (
    tester,
  ) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openFixed(tester);
    await tester.tap(find.text('example.com'));
    await settle(tester);
    expect(
      find.text(r'Next time it goes from US$1.00 to US$15.00'),
      findsOneWidget,
    );
    expect(find.text('Monthly cost after promotions'), findsOneWidget);
  });

  testApp('home shows the monthly total and items to fill in', (tester) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    // My share of Netflix (390 ÷ 4) + 20×32.59 + (1/12 US$ → 8¢ × 32.59)
    // + 18,000 = NT$18,751.91
    expect(find.text(r'NT$18,752'), findsOneWidget);
    expect(find.text('1 item still needs details'), findsOneWidget);
    // Netflix (18 Mar) and ChatGPT (20 Mar) are due within 7 days of 15 Mar.
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('ChatGPT'), findsOneWidget);
  });

  testApp('two-pane: selecting an item shows it beside the list', (
    tester,
  ) async {
    await pumpApp(tester, width: 1280, seed: (d) => d.seedItems());
    await openFixed(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);
    expect(
      find.text('Rent'),
      findsNWidgets(2),
      reason: 'in the list and the detail pane',
    );
    expect(find.text('Next charge'), findsOneWidget);
  });
}
