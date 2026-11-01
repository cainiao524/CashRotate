import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Future<void> openDetail(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('tile-$id')));
  await settle(tester);
  await tester.ensureVisible(find.byKey(const Key('detail-pay')));
  await tester.tap(find.byKey(const Key('detail-pay')));
  await settle(tester);
}

void main() {
  testApp('a foreign charge recorded in the card currency shows its rate', (
    tester,
  ) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
    );
    await openDetail(tester, ids['chatgpt']!);
    expect(find.text('Due: US\$20.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('payment-in-main')));
    await settle(tester);
    // Prefilled with the estimate at the stored rate (32.59).
    expect(find.text('651.80'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('payment-amount')), '661');
    await settle(tester);
    await tester.tap(find.byKey(const Key('payment-save')));
    await settle(tester, frames: 10);

    final payments = await tester.runAsync(
      () => data.db.select(data.db.transactions).get(),
    );
    final p = payments!.single;
    expect(p.amountMinor, 66100);
    expect(p.currency, Currency.twd);
    expect(p.originalAmountMinor, 2000);
    expect(p.fxRate, '33.05');
    expect(p.marketFxRate, '32.59');
    await tester.scrollUntilVisible(find.textContaining('rate 33.05'), 200);
    expect(find.textContaining('1.4% over the published rate'), findsOneWidget);
  });

  testApp('a different amount asks: just this once or update the price', (
    tester,
  ) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
    );
    await openDetail(tester, ids['netflix']!);
    await tester.enterText(find.byKey(const Key('payment-amount')), '420');
    await settle(tester);
    await tester.tap(find.byKey(const Key('payment-save')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('payment-update-price')));
    await settle(tester, frames: 10);
    final view = await tester.runAsync(() => data.items.view(ids['netflix']!));
    expect(view!.nextDue!.dueOn, LocalDate(2026, 4, 18));
    expect(view.nextDue!.expectedMinor, 42000);
  });
}
