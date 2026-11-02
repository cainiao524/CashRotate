import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/reminders/reminder_platform.dart';
import 'package:cashrotate/data/reminders/reminder_service.dart';
import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate/l10n/gen/app_localizations.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_reminder_platform.dart';

void main() {
  final now = DateTime(2026, 3, 15, 10);
  final today = LocalDate(2026, 3, 15);
  final en = lookupAppLocalizations(const Locale('en'));
  late AppDatabase db;
  late ItemRepository items;
  late FakeReminderPlatform platform;
  late ReminderService service;
  const settings = UserSettings(mainCurrency: Currency.twd, region: 'TW');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    items = ItemRepository(db, Journal(db), today: () => today);
    platform = FakeReminderPlatform();
    service = ReminderService(db, items, platform, () => now);
  });
  tearDown(() => db.close());

  Future<String> netflix({List<int> remindDays = const [3, 0]}) => items.create(
    NewItem(
      type: ItemType.subscription,
      name: 'Netflix',
      cycle: Cycle.monthly,
      anchor: LocalDate(2026, 3, 18),
      prices: PriceSchedule.fixed(const Money(39000, Currency.twd)),
      remindDays: remindDays,
    ),
  );

  Future<List<NativeReminder>> sync([UserSettings s = settings]) async =>
      service.sync(
        items: await items.watchAll().first,
        occurrences: await items
            .watchDue(today.addDays(-366), today.addDays(60))
            .first,
        settings: s,
        l10n: en,
        locale: 'en_US',
      );

  test('plans worded reminders at the chosen time of day', () async {
    final id = await netflix();
    final rs = await sync();
    expect(platform.reminders, rs);
    expect(rs.first.id, 'charge:$id:2026-03-15');
    expect(rs.first.at, DateTime(2026, 3, 15, 9));
    expect(rs.first.title, 'Netflix');
    expect(rs.first.body, 'Charged in 3 days · Mar 18 · NT\$390');
    expect(rs.first.occurrenceId, '$id:2026-03-18');
    expect(rs[1].body, 'Charged today · Mar 18 · NT\$390');
    expect(platform.labels['paid'], 'Paid');
    expect(platform.labels['snooze'], 'Remind me tomorrow');

    final later = await sync(
      const UserSettings(
        mainCurrency: Currency.twd,
        region: 'TW',
        reminderMinutes: 20 * 60 + 30,
      ),
    );
    expect(later.first.at, DateTime(2026, 3, 15, 20, 30));
  });

  test('large icon and Go cancel on renewals, not on bills', () async {
    final id = await netflix();
    final rent = await items.create(
      NewItem(
        type: ItemType.bill,
        name: 'Rent',
        cycle: Cycle.monthly,
        anchor: LocalDate(2026, 3, 17),
        prices: PriceSchedule.fixed(const Money(1800000, Currency.twd)),
      ),
    );
    const badge = NotificationBadge(
      letter: 'N',
      background: 0xFF111111,
      foreground: 0xFFFFFFFF,
      iconCodePoint: 0xe40a,
    );
    final rs = await service.sync(
      items: await items.watchAll().first,
      occurrences: await items
          .watchDue(today.addDays(-366), today.addDays(60))
          .first,
      settings: settings,
      l10n: en,
      locale: 'en_US',
      badges: {id: badge},
      cancelUrls: {id: 'https://netflix.example/cancel', rent: 'https://x'},
    );
    final renewal = rs.firstWhere((r) => r.itemId == id);
    expect(renewal.badge, badge);
    expect(renewal.cancelUrl, 'https://netflix.example/cancel');
    expect(renewal.toJson()['badge'], {
      'letter': 'N',
      'background': 0xFF111111,
      'foreground': 0xFFFFFFFF,
      'icon': 0xe40a,
    });
    expect(rs.firstWhere((r) => r.itemId == rent).cancelUrl, isNull);
    expect(platform.labels['goCancel'], 'Go cancel');
  });

  test('the charge before an intro price ends says what it becomes', () async {
    await items.create(
      NewItem(
        type: ItemType.subscription,
        name: 'example.com',
        cycle: Cycle.yearly,
        anchor: LocalDate(2026, 3, 20),
        prices: PriceSchedule.intro(
          intro: const Money(100, Currency.usd),
          periods: 1,
          renewal: const Money(1500, Currency.usd),
        ),
      ),
    );
    final rs = await sync();
    expect(
      rs.single.body,
      'Charged in 3 days · Mar 20 · US\$1.00\n'
      'Next time it goes from US\$1.00 to US\$15.00',
    );
  });

  test(
    'items still to fill in, and reminders turned off, plan nothing',
    () async {
      await items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'Spotify',
          cycle: Cycle.monthly,
          anchor: LocalDate(2026, 3, 18),
          prices: PriceSchedule.fixed(const Money(0, Currency.twd)),
          needsDetails: true,
        ),
      );
      expect(await sync(), isEmpty);
      await netflix();
      expect(
        await sync(
          const UserSettings(
            mainCurrency: Currency.twd,
            region: 'TW',
            remindersOn: false,
          ),
        ),
        isEmpty,
      );
      expect(platform.reminders, isEmpty, reason: 'cleared on the platform');
    },
  );

  test('delivery and "Paid" go to the log; Paid settles the charge', () async {
    final id = await netflix();
    final occurrence = '$id:2026-03-18';
    final scheduled = DateTime(2026, 3, 15, 9).millisecondsSinceEpoch;
    ReminderEvent event(String type, int at) => ReminderEvent(
      type: type,
      reminderId: 'charge:$id:2026-03-15',
      itemId: id,
      occurrenceId: occurrence,
      kind: 'charge',
      scheduledAt: scheduled,
      at: at,
    );
    platform.queued.addAll([
      event('delivered', scheduled + 60000),
      event('paid', scheduled + 120000),
    ]);
    expect(await service.applyEvents(), 2);

    final log = await db.select(db.reminderLog).getSingle();
    expect(log.deliveredAt, scheduled + 60000);
    expect(log.action, 'paid');
    final row = await (db.select(
      db.occurrences,
    )..where((o) => o.id.equals(occurrence))).getSingle();
    expect(row.state, OccurrenceState.paid);

    // Paid again (e.g. from an older notification): no error, no change.
    platform.queued.add(event('paid', scheduled + 180000));
    expect(await service.applyEvents(), 1);
  });

  test('counts reminders that arrived over an hour late', () async {
    final scheduled = DateTime(2026, 3, 10, 9).millisecondsSinceEpoch;
    platform.queued.addAll([
      ReminderEvent(
        type: 'delivered',
        reminderId: 'charge:a:2026-03-10',
        itemId: 'a',
        kind: 'charge',
        scheduledAt: scheduled,
        at: scheduled + const Duration(hours: 3).inMilliseconds,
      ),
      ReminderEvent(
        type: 'delivered',
        reminderId: 'charge:b:2026-03-10',
        itemId: 'b',
        kind: 'charge',
        scheduledAt: scheduled,
        at: scheduled + const Duration(minutes: 10).inMilliseconds,
      ),
    ]);
    await service.applyEvents();
    expect(await service.lateCount(), 1);
  });

  test('asks for notification permission only once', () async {
    platform
      ..enabled = false
      ..grant = false;
    expect(await service.askPermissionOnce(), isFalse);
    expect(await service.askPermissionOnce(), isFalse);
    expect(platform.permissionRequests, 1);
  });

  test('every kind has wording', () {
    String money(Money m) => '${m.minor}';
    String date(LocalDate d) => '$d';
    final charge = ReminderCharge(
      occurrenceId: 'o',
      index: 0,
      dueOn: today,
      expected: const Money(100, Currency.twd),
    );
    for (final kind in ReminderKind.values) {
      final text = reminderBody(
        PlannedReminder(
          kind: kind,
          itemId: 'a',
          date: today,
          charge: charge,
          daysBefore: 2,
          unpaidPeople: 2,
        ),
        l10n: en,
        money: money,
        date: date,
      );
      expect(text, isNotEmpty, reason: kind.name);
    }
  });
}
