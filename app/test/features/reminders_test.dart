import 'package:cashrotate/data/reminders/reminder_platform.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_reminder_platform.dart';
import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

void main() {
  testApp('on start, reminders are planned and permission is asked once', (
    tester,
  ) async {
    final platform = FakeReminderPlatform()..enabled = false;
    late Map<String, String> ids;
    await pumpApp(
      tester,
      reminders: platform,
      seed: (d) async => ids = await d.seedItems(),
    );
    expect(platform.setCalls, greaterThan(0));
    // Netflix, 18 March, reminds 3 days before: today at 9:00.
    final netflix = platform.reminders.firstWhere(
      (r) => r.itemId == ids['netflix'],
    );
    expect(netflix.at, DateTime(2026, 3, 15, 9));
    expect(netflix.body, startsWith('Charged in 3 days'));
    // Spotify still needs details: no reminder.
    expect(
      platform.reminders.where((r) => r.itemId == ids['spotify']),
      isEmpty,
    );
    expect(platform.permissionRequests, 1);
  });

  testApp('"Paid" on a notification while the app is open settles it', (
    tester,
  ) async {
    final platform = FakeReminderPlatform();
    late Map<String, String> ids;
    await pumpApp(
      tester,
      reminders: platform,
      seed: (d) async => ids = await d.seedItems(),
    );
    final id = ids['netflix']!;
    expect(find.text('3/18 · Shared by 4'), findsOneWidget);
    final at = DateTime(2026, 3, 15, 9).millisecondsSinceEpoch;
    platform.emit(
      ReminderEvent(
        type: 'paid',
        reminderId: 'charge:$id:2026-03-15',
        itemId: id,
        occurrenceId: '$id:2026-03-18',
        kind: 'charge',
        scheduledAt: at,
        at: at + 1000,
      ),
    );
    await settle(tester, frames: 10);
    expect(find.text('4/18 · Shared by 4'), findsOneWidget);
  });

  testApp('tapping a notification opens its item', (tester) async {
    final platform = FakeReminderPlatform();
    late Map<String, String> ids;
    await pumpApp(
      tester,
      reminders: platform,
      seed: (d) async => ids = await d.seedItems(),
    );
    platform.tap(ids['rent']!);
    await settle(tester);
    expect(find.byKey(const Key('detail-edit')), findsOneWidget);
    expect(find.text('Rent'), findsWidgets);
  });

  testApp('settings: test notification, battery guide, turning off', (
    tester,
  ) async {
    final platform = FakeReminderPlatform()..maker = 'xiaomi';
    await pumpApp(tester, reminders: platform, seed: (d) => d.seedItems());
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-test-notification')));
    await tester.tap(find.byKey(const Key('settings-test-notification')));
    await settle(tester);
    expect(platform.tests.single.$1, 'Test notification');

    await scrollTo(tester, find.byKey(const Key('settings-battery-guide')));
    expect(find.textContaining('Autostart'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-open-battery')));
    expect(platform.batteryOpened, 1);

    await scrollTo(tester, find.byKey(const Key('settings-reminders-on')));
    await tester.tap(find.byKey(const Key('settings-reminders-on')));
    await settle(tester);
    expect(platform.reminders, isEmpty);
    expect(find.byKey(const Key('settings-test-notification')), findsNothing);
  });

  testApp('settings warn when notifications are off', (tester) async {
    final platform = FakeReminderPlatform()
      ..enabled = false
      ..grant = false;
    await pumpApp(tester, reminders: platform);
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-notifications-off')));
    expect(find.text('Allow notifications'), findsOneWidget);
  });

  testApp('the editor sets several reminder days per item', (tester) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
    );
    await tester.tap(find.byKey(ValueKey('tile-${ids['rent']}')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('detail-edit')));
    await settle(tester);
    final chip = find.byKey(const ValueKey('remind-7'));
    await tester.scrollUntilVisible(
      chip,
      200,
      // The editor list itself, not the fields scrolling inside it.
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('item-editor')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(chip);
    await settle(tester);
    await tester.tap(chip);
    await settle(tester);
    await tester.tap(find.byKey(const Key('editor-save')));
    await settle(tester);
    final rent = await tester.runAsync(() => data.items.view(ids['rent']!));
    expect(rent!.remindDays, [3, 7]);
    expect(rent.schedule.cycle, Cycle.monthly);
  });
}
