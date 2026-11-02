import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

Money twd(int d) => Money(d * 100, Currency.twd);

Future<String> seedOrganizer(TestData d) => d.items.create(
  NewItem(
    type: ItemType.subscription,
    name: 'YouTube Family',
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 1, 10),
    paidUntil: LocalDate(2026, 3, 10),
    prices: PriceSchedule.fixed(twd(300)),
    sharing: SharingPlan(
      members: [
        // Paid through February only: owes March.
        SharingMemberPlan(name: 'Amy', paidUntil: LocalDate(2026, 3, 1)),
        // Paid a year ahead.
        SharingMemberPlan(name: 'Ben', paidUntil: LocalDate(2027, 1, 10)),
      ],
    ).toJson(),
  ),
);

Future<String> seedMember(TestData d) => d.items.create(
  NewItem(
    type: ItemType.subscription,
    name: 'Spotify Duo',
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 3, 17),
    prices: PriceSchedule.fixed(twd(120)),
    sharing: const SharingPlan(
      role: SharingRole.member,
      payee: 'Cat',
      payeeMethod: 'LINE Pay',
    ).toJson(),
  ),
);

Future<void> openOwed(WidgetTester tester) async {
  await openSettings(tester);
  await scrollTo(tester, find.byKey(const Key('settings-owed')));
  await tester.tap(find.byKey(const Key('settings-owed')));
  await settle(tester);
}

void main() {
  testApp('shared plans: my share in the total, who owes whom', (tester) async {
    late String family;
    late String duo;
    final data = await pumpApp(
      tester,
      seed: (d) async {
        family = await seedOrganizer(d);
        duo = await seedMember(d);
      },
    );
    // NT$300 ÷ 3 = 100, plus the NT$120 I pay Cat.
    expect(find.text(r'NT$220'), findsOneWidget);
    expect(find.textContaining('Organizer · split 3 ways'), findsOneWidget);
    expect(find.textContaining('Member · pays Cat'), findsOneWidget);

    await openOwed(tester);
    expect(find.text('Amy'), findsOneWidget);
    expect(find.text('Ben'), findsNothing, reason: 'paid a year ahead');
    expect(find.text(r'NT$100'), findsOneWidget);
    expect(find.text('Spotify Duo'), findsOneWidget, reason: 'I owe Cat');

    await tester.tap(find.byKey(ValueKey('owed-received-$family-0')));
    await settle(tester, frames: 10);
    expect(find.text('Amy'), findsNothing);
    final view = await tester.runAsync(() => data.items.view(family));
    expect(view!.sharingPlan!.members.first.paidUntil, LocalDate(2026, 4, 10));
    expect(duo, isNotEmpty);
  });
}
