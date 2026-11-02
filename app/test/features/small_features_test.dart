import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/features/home/fixed_summary.dart';
import 'package:cashrotate/features/items/idle_prompt.dart';
import 'package:cashrotate/features/items/items_filter.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'fixed_summary_test.dart' show today, view;

/// CLAUDE.md item 18: the small add-ons behind `Features` switches.
void main() {
  group('cost conversion', () {
    test('a year is 12 months; a day is a year over 365 days', () {
      const monthly = Money(39000, Currency.twd);
      expect(yearlyCost(monthly).minor, 468000);
      expect(dailyCost(monthly).minor, 1282); // 4,680 / 365 = 12.82
    });
  });

  group('filters', () {
    ItemView item(
      String name, {
      String? category,
      String? account,
      String sharing = '',
    }) {
      final v = view(
        name: name,
        price: const Money(10000, Currency.twd),
        sharing: sharing,
      );
      return ItemView(
        v.row.copyWith(categoryId: Value(category), accountId: Value(account)),
        v.schedule,
        v.nextDue,
      );
    }

    final netflix = item(
      'Netflix',
      category: 'streaming',
      account: 'visa',
      sharing: '{"role":"organizer","split":"equal","members":[{"name":"A"}]}',
    );
    final rent = item('Rent', category: 'housing');
    final nas = item('NAS power');

    test('search matches the name, ignoring case', () {
      const f = ItemsFilter(query: 'netf');
      expect([netflix, rent, nas].where(f.matches), [netflix]);
    });

    test('category: items without one count as other', () {
      const f = ItemsFilter(categories: {'other', 'housing'});
      expect([netflix, rent, nas].where(f.matches), [rent, nas]);
    });

    test('payment method: none, and the unassigned account, match blank', () {
      final unassigned = item('Phone', account: 'unassigned');
      const f = ItemsFilter(accounts: {ItemsFilter.noAccount});
      expect([netflix, rent, unassigned].where(f.matches), [rent, unassigned]);
    });

    test('sharing role', () {
      const f = ItemsFilter(roles: {RoleFilter.organizer});
      expect([netflix, rent].where(f.matches), [netflix]);
      expect(const ItemsFilter(roles: {RoleFilter.none}).matches(rent), true);
    });

    test('groups combine; clearing keeps the search', () {
      const f = ItemsFilter(
        query: 'n',
        categories: {'streaming'},
        roles: {RoleFilter.none},
      );
      expect(f.count, 2);
      expect(f.matches(netflix), false);
      expect(f.cleared().query, 'n');
      expect(f.cleared().count, 0);
    });
  });

  group('rarely used', () {
    ItemView marked(String askedOn, {ItemStatus status = ItemStatus.active}) =>
        view(
          name: 'Gym',
          price: const Money(99900, Currency.twd),
          status: status,
          typeFields: '{"rarelyUsed":true,"idleAskedOn":"$askedOn"}',
        );

    test('asked again a quarter after the last time', () {
      expect(idleItemsDue([marked('2025-12-14')], today), hasLength(1));
      expect(idleItemsDue([marked('2025-12-15')], today), isEmpty);
    });

    test('paused items and unmarked items are not asked', () {
      expect(
        idleItemsDue([
          marked('2025-01-01', status: ItemStatus.paused),
          view(name: 'Other', price: const Money(100, Currency.twd)),
        ], today),
        isEmpty,
      );
    });
  });

  testApp('detail: yearly and daily cost, go cancel, rarely used', (
    tester,
  ) async {
    final links = FakeLinkOpener();
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      links: links,
      seed: (d) async => ids = await d.seedItems(),
    );
    await tester.tap(find.byKey(ValueKey('tile-${ids['rent']}')));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('detail-yearly')),
        matching: find.text(r'NT$216,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('detail-daily')),
        matching: find.text(r'NT$592'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('tile-${ids['netflix']}')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('detail-go-cancel')));
    // Clear of the bottom navigation bar.
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await settle(tester);
    await tester.tap(find.byKey(const Key('detail-go-cancel')));
    await settle(tester);
    expect(links.opened, ['https://www.netflix.com/cancelplan']);

    await tester.ensureVisible(find.byKey(const Key('detail-rarely-used')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('detail-rarely-used')));
    await settle(tester, frames: 6);
    final v = await tester.runAsync(() => data.items.view(ids['netflix']!));
    expect(v!.typeFields['rarelyUsed'], true);
    expect(v.typeFields['idleAskedOn'], '2026-03-15');
  });

  testApp('home asks about a rarely used item each quarter', (tester) async {
    late String id;
    final data = await pumpApp(
      tester,
      seed: (d) async {
        id = (await d.seedItems())['netflix']!;
        await d.items.setTypeFields(id, {
          'rarelyUsed': true,
          'idleAskedOn': '2025-11-01',
        });
      },
    );
    expect(find.text('Still want Netflix?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('idle-keep')));
    await settle(tester, frames: 6);
    expect(find.text('Still want Netflix?'), findsNothing);
    final v = await tester.runAsync(() => data.items.view(id));
    expect(v!.typeFields['idleAskedOn'], '2026-03-15');
  });

  testApp('fixed list: search, filter, then batch edit', (tester) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
    );
    await tester.tap(find.byIcon(Icons.event_repeat_outlined));
    await settle(tester);

    await tester.tap(find.byKey(const Key('items-search')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('items-search-field')), 'ne');
    await settle(tester);
    expect(find.byKey(ValueKey('item-${ids['netflix']}')), findsOneWidget);
    expect(find.byKey(ValueKey('item-${ids['rent']}')), findsNothing);
    await tester.tap(find.byKey(const Key('items-search')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('items-filter')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('filter-category-housing')));
    await settle(tester);
    await tester.tapAt(const Offset(200, 40)); // close the sheet
    await settle(tester);
    expect(find.byKey(ValueKey('item-${ids['rent']}')), findsOneWidget);
    expect(find.byKey(ValueKey('item-${ids['netflix']}')), findsNothing);
    await tester.tap(find.byKey(const Key('items-filter')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('filter-clear')));
    await settle(tester);
    await tester.tapAt(const Offset(200, 40));
    await settle(tester);

    await tester.longPress(find.byKey(ValueKey('item-${ids['netflix']}')));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('item-${ids['chatgpt']}')));
    await settle(tester);
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-category')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('batch-option-software')),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('batch-option-software')));
    await settle(tester, frames: 6);
    expect(find.text('2 items updated'), findsOneWidget);
    expect(find.text('2 selected'), findsNothing);
    for (final key in ['netflix', 'chatgpt']) {
      final v = await tester.runAsync(() => data.items.view(ids[key]!));
      expect(v!.row.categoryId, 'software');
    }
  });

  testApp('empty home: add a popular service with one tap', (tester) async {
    final data = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('popular-netflix')));
    await settle(tester, frames: 8);
    expect(find.text('Added Netflix'), findsOneWidget);
    final items = await tester.runAsync(
      () => data.db.select(data.db.items).get(),
    );
    expect(items!.single.name, 'Netflix');
    expect(items.single.needsDetails, true);
  });
}
