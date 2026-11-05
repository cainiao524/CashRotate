import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate/features/items/item_draft.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'home_tiles_test.dart' show tile;

/// Payments tab and instalments (filling the gaps found on 2026-11-05).
void main() {
  group('instalments in the editor', () {
    ItemDraft loan({String remaining = '', String total = ''}) => ItemDraft(
      type: ItemType.repayment,
      currency: Currency.twd,
      cycle: Cycle.monthly,
      name: 'Phone instalments',
      amountText: '1000',
      nextCharge: LocalDate(2026, 3, 31),
      fields: {'remainingPeriods': remaining, 'totalPeriods': total},
    );

    test('the last charge is worked out from what is left', () {
      final item = loan(remaining: '4', total: '12').toNewItem();
      expect(item.typeFields['lastChargeOn'], '2026-06-30');
    });

    test('nothing paid yet: the total counts; neither: open-ended', () {
      expect(
        loan(total: '3').toNewItem().typeFields['lastChargeOn'],
        '2026-05-31',
      );
      expect(loan().toNewItem().typeFields.containsKey('lastChargeOn'), false);
    });

    test('more left than in total is capped at the total', () {
      final item = loan(remaining: '20', total: '2').toNewItem();
      expect(item.typeFields['lastChargeOn'], '2026-04-30');
    });
  });

  testApp('a repayment shows its instalment; paid off leaves the home grid', (
    tester,
  ) async {
    late String id;
    final data = await pumpApp(
      tester,
      seed: (d) async {
        await d.seedItems();
        id = await d.items.create(
          NewItem(
            type: ItemType.repayment,
            name: 'Phone instalments',
            cycle: Cycle.monthly,
            anchor: LocalDate(2026, 1, 20),
            paidUntil: LocalDate(2026, 3, 20),
            prices: PriceSchedule.fixed(const Money(100000, Currency.twd)),
            typeFields: const {
              'totalPeriods': '4',
              'lastChargeOn': '2026-04-20',
            },
          ),
        );
      },
    );
    // Third of four (January and February paid).
    expect(
      find.descendant(of: tile(id), matching: find.textContaining('3 of 4')),
      findsOneWidget,
    );
    await tester.tap(tile(id));
    await settle(tester);
    expect(find.textContaining('last Apr 20, 2026'), findsOneWidget);

    // Pay the last two: the item is paid off and leaves the home grid.
    final payments = PaymentRepository(
      data.db,
      data.journal,
      data.items,
      PaymentMethods(data.db, data.journal),
    );
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(() async {
        final v = await data.items.view(id);
        await payments.record(
          itemId: id,
          occurrenceId: v.nextDue!.id,
          expected: const Money(100000, Currency.twd),
          paid: const Money(100000, Currency.twd),
          paidOn: v.nextDue!.dueOn,
          main: Currency.twd,
        );
      });
      // Let the app's own queries (in the test's fake time) finish before
      // the next real-time write.
      await settle(tester, frames: 8);
    }
    final v = await tester.runAsync(() => data.items.view(id));
    expect(v!.schedule.paidOff, true);
    expect(v.nextDue, isNull);
    await tester.tap(find.text('Home'));
    await settle(tester);
    expect(tile(id), findsNothing);
  });

  testApp('payments tab: by month; deleting one makes the charge due again', (
    tester,
  ) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async {
        ids = await d.seedItems();
        final payments = PaymentRepository(
          d.db,
          d.journal,
          d.items,
          PaymentMethods(d.db, d.journal),
        );
        final netflix = await d.items.view(ids['netflix']!);
        await payments.record(
          itemId: ids['netflix']!,
          occurrenceId: netflix.nextDue!.id,
          expected: const Money(39000, Currency.twd),
          paid: const Money(39000, Currency.twd),
          paidOn: LocalDate(2026, 3, 14),
          main: Currency.twd,
        );
        await payments.record(
          itemId: ids['rent']!,
          expected: const Money(1800000, Currency.twd),
          paid: const Money(1800000, Currency.twd),
          paidOn: LocalDate(2026, 2, 5),
          main: Currency.twd,
        );
      },
    );
    await tester.tap(find.text('Payments'));
    await settle(tester);
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.text(r'Total NT$390'), findsOneWidget);

    final netflixRow = find.ancestor(
      of: find.text('Netflix'),
      matching: find.byType(ListTile),
    );
    await tester.longPress(netflixRow);
    await settle(tester);
    await tester.tap(find.byKey(const Key('payment-delete-confirm')));
    await settle(tester, frames: 8);
    expect(find.text('March 2026'), findsNothing);
    final v = await tester.runAsync(() => data.items.view(ids['netflix']!));
    expect(v!.nextDue!.dueOn, LocalDate(2026, 3, 18));
  });
}
