import 'package:cashrotate/data/detection/notice_platform.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_notice_platform.dart';
import '../helpers/pump_app.dart';

Future<String> seedOpenRouter(TestData d) => d.items.create(
  NewItem(
    type: ItemType.bill,
    name: 'OpenRouter',
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 3, 15),
    prices: PriceSchedule.fixed(const Money(0, Currency.usd)),
    typeFields: const {'irregular': true},
  ),
);

void main() {
  testApp('an irregular bill: no countdown, payments set its monthly average', (
    tester,
  ) async {
    late String id;
    final data = await pumpApp(
      tester,
      seed: (d) async => id = await seedOpenRouter(d),
    );
    expect(find.text('Irregular · no payments yet'), findsOneWidget);
    expect(find.text('1 item still needs details'), findsOneWidget);
    final view = await tester.runAsync(() => data.items.view(id));
    expect(view!.nextDue, isNull, reason: 'no charges planned');

    await tester.tap(find.byKey(ValueKey('tile-$id')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('detail-pay')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('payment-amount')), '30');
    await settle(tester);
    await tester.tap(find.byKey(const Key('payment-save')));
    await settle(tester, frames: 10);
    // The tile opened the item on the Fixed tab; go back to Home.
    await tester.tap(find.text('Home'));
    await settle(tester, frames: 10);
    // US$30 over at least three months: US$10 a month (≈ NT$326 at 32.59
    // is not known here: no USD rate in this test, so it shows in USD).
    expect(find.text('US\$10.00/mo'), findsOneWidget);
    expect(find.textContaining('Irregular · last paid 3/15'), findsOneWidget);
  });

  testApp('a top-up notification is filed under the irregular bill by name', (
    tester,
  ) async {
    final notices = FakeNoticePlatform();
    late String id;
    final data = await pumpApp(
      tester,
      notices: notices,
      seed: (d) async => id = await seedOpenRouter(d),
    );
    notices.post(
      'Your card was charged US\$25.00 at OPENROUTER.AI',
      DateTime(2026, 3, 20, 9),
    );
    await settle(tester, frames: 10);
    final payments = await tester.runAsync(
      () => data.db.select(data.db.transactions).get(),
    );
    expect(payments!.single.itemId, id);
    expect(payments.single.amountMinor, 2500);
    expect(Notice.shared, 'shared');
  });
}
