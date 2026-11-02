import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  testApp('upgrade PS Plus now: pay the difference, new tier from renewal', (
    tester,
  ) async {
    late String id;
    final data = await pumpApp(
      tester,
      seed: (d) async => id = await d.items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'PlayStation Plus',
          presetId: 'playstation-plus',
          cycle: Cycle.yearly,
          anchor: LocalDate(2026, 1, 1),
          paidUntil: LocalDate(2027, 1, 1),
          prices: PriceSchedule.fixed(const Money(200000, Currency.twd)),
          typeFields: const {'plan': 'essential'},
        ),
      ),
    );
    await tester.tap(find.byKey(ValueKey('tile-$id')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('detail-change-plan')));
    await tester.tap(find.byKey(const Key('detail-change-plan')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('plan-extra')));
    await tester.enterText(find.byKey(const Key('plan-price')), '3000');
    await settle(tester);
    // 15 March: 292 of 365 days left; NT$1,000 × 292/365 = NT$800.
    expect(find.textContaining('Pay NT\$800 now'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan-save')));
    await settle(tester, frames: 10);

    final view = await tester.runAsync(() => data.items.view(id));
    expect(view!.typeFields['plan'], 'extra');
    expect(view.nextDue!.dueOn, LocalDate(2027, 1, 1));
    expect(view.nextDue!.expectedMinor, 300000);
    final payments = await tester.runAsync(
      () => data.db.select(data.db.transactions).get(),
    );
    expect(payments!.single.amountMinor, 80000);
    final history = await tester.runAsync(
      () => data.db.select(data.db.priceHistory).get(),
    );
    expect(history!.single.newMinor, 300000);
  });
}
