import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_reminder_platform.dart';
import '../helpers/pump_app.dart';

Finder tile(String id) => find.byKey(ValueKey('tile-$id'));

/// A phone bill three days overdue (15 March is the test date).
Future<String> seedOverdue(TestData d) => d.items.create(
  NewItem(
    type: ItemType.bill,
    name: 'Phone',
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 3, 12),
    prices: PriceSchedule.fixed(const Money(59900, Currency.twd)),
  ),
);

void main() {
  testApp('every item is a tile with amount, date and countdown', (
    tester,
  ) async {
    late Map<String, String> ids;
    await pumpApp(tester, seed: (d) async => ids = await d.seedItems());
    for (final id in ids.values) {
      expect(tile(id), findsOneWidget);
    }
    // Netflix, 18 March, shared by four.
    expect(find.text('3/18 · Shared by 4'), findsOneWidget);
    // ChatGPT is billed in USD: the main currency large, the original small.
    expect(find.text('≈ NT\$652'), findsOneWidget);
    expect(find.text('US\$20.00 · 3/20'), findsOneWidget);
    // Spotify still needs its amount.
    expect(find.text('To fill in'), findsWidgets);
    expect(find.text('5 items'), findsOneWidget);
    // Nothing paid yet this month: Netflix and ChatGPT are still to pay.
    expect(find.text('To pay NT\$1,042'), findsOneWidget);

    // Soonest first.
    final netflix = tester.getTopLeft(tile(ids['netflix']!));
    final rent = tester.getTopLeft(tile(ids['rent']!));
    expect(netflix.dy, lessThan(rent.dy));

    await tester.tap(tile(ids['netflix']!));
    await settle(tester);
    expect(find.text('Netflix'), findsWidgets);
    expect(tile(ids['rent']!), findsNothing);
  });

  testApp('an overdue charge is a wide tile that can be marked paid', (
    tester,
  ) async {
    late String phone;
    late String rent;
    await pumpApp(
      tester,
      seed: (d) async {
        rent = (await d.seedItems())['rent']!;
        phone = await seedOverdue(d);
      },
    );
    expect(find.text('3 days overdue'), findsOneWidget);
    final wide = tester.getSize(tile(phone)).width;
    expect(wide, greaterThan(tester.getSize(tile(rent)).width * 1.5));
    // Overdue comes first.
    expect(
      tester.getTopLeft(tile(phone)).dy,
      lessThan(tester.getTopLeft(tile(rent)).dy),
    );

    await tester.tap(find.byKey(ValueKey('tile-paid-$phone')));
    await settle(tester);
    expect(find.text('3 days overdue'), findsNothing);
    // Paid on time for March: the next charge is 12 April.
    expect(find.text('4/12'), findsOneWidget);
  });

  testApp('long press: make a tile wide and give it an icon', (tester) async {
    late Map<String, String> ids;
    await pumpApp(tester, seed: (d) async => ids = await d.seedItems());
    final rent = ids['rent']!;
    final single = tester.getSize(tile(rent)).width;
    await tester.longPress(tile(rent));
    await settle(tester);
    await tester.tap(find.byKey(const Key('tile-wide')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tile-icon-home')));
    await settle(tester);
    await tester.tapAt(const Offset(200, 40)); // close the sheet
    await settle(tester);
    expect(tester.getSize(tile(rent)).width, greaterThan(single * 1.5));
    expect(
      find.descendant(
        of: tile(rent),
        matching: find.byIcon(Icons.home_outlined),
      ),
      findsOneWidget,
    );
  });

  testApp('sort, type filter and search', (tester) async {
    late Map<String, String> ids;
    await pumpApp(tester, seed: (d) async => ids = await d.seedItems());

    await tester.tap(find.byKey(const Key('home-type')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('menu-Bill')));
    await settle(tester);
    expect(tile(ids['rent']!), findsOneWidget);
    expect(tile(ids['netflix']!), findsNothing);
    expect(find.text('1 item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-type')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('menu-All types')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('home-sort')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('menu-By amount')));
    await settle(tester);
    // Rent (NT$18,000 a month) comes first: top-left.
    final rent = tester.getTopLeft(tile(ids['rent']!));
    final netflix = tester.getTopLeft(tile(ids['netflix']!));
    expect(rent.dy, lessThanOrEqualTo(netflix.dy));
    expect(rent.dx, lessThan(netflix.dx));

    await tester.tap(find.byKey(const Key('home-search')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('home-search-field')), 'net');
    await settle(tester);
    expect(tile(ids['netflix']!), findsOneWidget);
    expect(tile(ids['rent']!), findsNothing);
    await tester.enterText(find.byKey(const Key('home-search-field')), 'zzz');
    await settle(tester);
    expect(find.text('No items match'), findsOneWidget);
  });

  testApp('service colours setting colours the tiles', (tester) async {
    late Map<String, String> ids;
    await pumpApp(tester, seed: (d) async => ids = await d.seedItems());
    Color colour() => tester
        .widget<Material>(
          find
              .ancestor(
                of: tile(ids['netflix']!),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(colour(), const Color(0xFFFFFFFF));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('settings-tile-colors')));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);
    expect(colour(), isNot(const Color(0xFFFFFFFF)));
  });

  testApp('tablet: total, ledger cards and an add tile share one grid', (
    tester,
  ) async {
    await pumpApp(tester, width: 1280, seed: (d) => d.seedItems());
    expect(find.byKey(const Key('home-total')), findsOneWidget);
    expect(find.byKey(const Key('home-paid')), findsOneWidget);
    expect(find.byKey(const Key('tile-add')), findsOneWidget);
    expect(find.byKey(const Key('rail-add')), findsOneWidget);
    expect(find.byKey(const Key('home-add')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-settings')));
    await settle(tester);
    expect(find.byKey(const Key('settings-reminders-on')), findsOneWidget);
  });

  for (final width in [360.0, 600.0, 1280.0]) {
    testApp('tiles fit at 200% text, ${width.toInt()}dp', (tester) async {
      await pumpApp(
        tester,
        width: width,
        textScale: 2,
        seed: (d) async {
          await d.seedItems();
          await seedOverdue(d);
        },
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('motion', () {
    Future<void> addRent(TestData d) => d.items.create(
      NewItem(
        type: ItemType.bill,
        name: 'Parking',
        cycle: Cycle.monthly,
        anchor: LocalDate(2026, 4, 1),
        prices: PriceSchedule.fixed(const Money(300000, Currency.twd)),
      ),
    );

    testApp('the total glides to a new amount; tiles glide to new places', (
      tester,
    ) async {
      late Map<String, String> ids;
      final data = await pumpApp(
        tester,
        seed: (d) async => ids = await d.seedItems(),
      );
      expect(find.text(r'NT$19,044'), findsOneWidget);
      await tester.runAsync(() => addRent(data));
      await settle(tester, frames: 2);
      // On its way from NT$19,044 to NT$22,044.
      expect(find.text(r'NT$19,044'), findsNothing);
      expect(find.text(r'NT$22,044'), findsNothing);
      await settle(tester, frames: 10);
      expect(find.text(r'NT$22,044'), findsOneWidget);

      final netflix = tile(ids['netflix']!);
      final before = tester.getTopLeft(netflix);
      await tester.tap(find.byKey(const Key('home-sort')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('menu-By name')));
      // The menu closes first; then the tile starts to move.
      var during = before;
      for (var i = 0; i < 20 && during == before; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        during = tester.getTopLeft(netflix);
      }
      await settle(tester);
      final after = tester.getTopLeft(netflix);
      expect(after, isNot(before));
      expect(during, isNot(before));
      expect(during, isNot(after), reason: 'glides, does not jump');
    });

    testApp('with animations off, long text wraps without overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        width: 360,
        textScale: 2,
        disableAnimations: true,
        seed: (d) async {
          await d.seedItems();
          await seedOverdue(d);
        },
      );
      expect(tester.takeException(), isNull);
    });

    testApp('with animations off, changes land at once', (tester) async {
      final data = await pumpApp(
        tester,
        disableAnimations: true,
        seed: (d) => d.seedItems(),
      );
      await tester.runAsync(() => addRent(data));
      await settle(tester, frames: 2);
      expect(find.text(r'NT$22,044'), findsOneWidget);
    });
  });

  testApp('hide amounts: dots on screen, none in notifications', (
    tester,
  ) async {
    final platform = FakeReminderPlatform();
    await pumpApp(tester, reminders: platform, seed: (d) => d.seedItems());
    expect(find.text(r'NT$19,044'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-hide-amounts')));
    await settle(tester, frames: 10);
    expect(find.text(r'NT$19,044'), findsNothing);
    expect(find.text('••••'), findsWidgets);
    expect(find.textContaining('≈ NT\$'), findsNothing);
    expect(platform.reminders, isNotEmpty);
    expect(
      platform.reminders.every((r) => !r.body.contains(r'NT$')),
      isTrue,
      reason: 'amounts stay off the lock screen',
    );
    await tester.tap(find.byKey(const Key('home-hide-amounts')));
    await settle(tester, frames: 10);
    expect(find.text(r'NT$19,044'), findsOneWidget);
  });
}
