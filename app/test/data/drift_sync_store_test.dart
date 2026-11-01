import 'dart:math';

import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/fx/exchange_rate_repository.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate/data/sync/drift_sync_store.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// One phone: its own database, repositories and sync engine.
class Phone {
  Phone(this.remote, this.clock) : db = AppDatabase(NativeDatabase.memory()) {
    journal = Journal(db, nowMillis: () => clock().millisecondsSinceEpoch);
    items = ItemRepository(
      db,
      journal,
      today: () => LocalDate(2026, 3, 15),
      nowMillis: () => clock().millisecondsSinceEpoch,
    );
    settings = SettingsRepository(db, journal);
    rates = ExchangeRateRepository(db, journal);
    store = DriftSyncStore(db, journal);
  }

  final MemoryFolder remote;
  final DateTime Function() clock;
  final AppDatabase db;
  late final Journal journal;
  late final ItemRepository items;
  late final SettingsRepository settings;
  late final ExchangeRateRepository rates;
  late final DriftSyncStore store;

  Future<SyncReport> sync() => SyncEngine(
    store: store,
    remote: remote,
    cipher: const TestCipher(),
    nowMillis: () => clock().millisecondsSinceEpoch,
    random: Random(3),
  ).sync();

  Future<List<String>> names() async =>
      [for (final v in await items.watchAll().first) v.row.name]..sort();
}

void main() {
  var now = DateTime.utc(2026, 3, 15, 10);
  DateTime clock() => now;
  late MemoryFolder remote;
  late Phone a;
  late Phone b;

  setUp(() {
    remote = MemoryFolder();
    a = Phone(remote, clock);
    b = Phone(remote, clock);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  NewItem netflix() => NewItem(
    type: ItemType.subscription,
    name: 'Netflix',
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 3, 18),
    prices: PriceSchedule.intro(
      intro: const Money(0, Currency.twd),
      periods: 1,
      renewal: const Money(39000, Currency.twd),
    ),
  );

  test('an item made on one phone arrives on the other with its prices and '
      'charges', () async {
    final id = await a.items.create(netflix());
    await a.sync();
    now = now.add(const Duration(seconds: 5));
    await b.sync();
    final view = await b.items.view(id);
    expect(view.row.name, 'Netflix');
    expect(view.schedule.prices, netflix().prices);
    expect(view.nextDue?.dueOn, LocalDate(2026, 3, 18));
    // Nothing merged is sent back.
    expect(await b.store.pending(), isEmpty);
  });

  test('edits on both phones merge field by field; delete wins', () async {
    final id = await a.items.create(netflix());
    await a.sync();
    await b.sync();

    now = now.add(const Duration(minutes: 1));
    final onA = (await a.items.view(id)).toNewItem();
    await a.items.update(id, onA.copyWithName('Netflix Premium'));
    now = now.add(const Duration(minutes: 1));
    await b.settings.setMainCurrency(Currency.usd);
    await a.sync();
    await b.sync();
    await a.sync();
    expect(await b.names(), ['Netflix Premium']);
    expect(
      (await a.settings.read(UserSettings.defaultsFor('TW'))).mainCurrency,
      Currency.usd,
    );

    now = now.add(const Duration(minutes: 1));
    await b.items.delete(id);
    await b.sync();
    await a.sync();
    expect(await a.names(), isEmpty);
    // The cascade took its charges too.
    expect(await a.db.select(a.db.occurrences).get(), isEmpty);
  });

  test('exchange rates (two-part keys) sync', () async {
    await a.rates.setManualRate(
      Currency.usd,
      Currency.twd,
      Ratio.tryParse('32.5')!,
    );
    await a.sync();
    await b.sync();
    final fx = await b.rates.converter();
    expect(
      fx.convert(const Money(100, Currency.usd), Currency.twd)!.amount,
      const Money(3250, Currency.twd),
    );
  });

  test('changes naming unknown tables or columns are ignored', () async {
    await b.store.apply([
      FieldChange(
        entity: 'items; DROP TABLE items',
        rowId: 'x',
        field: 'name',
        value: '"evil"',
        hlc: Hlc(now.millisecondsSinceEpoch, 0, 'z'),
      ),
      FieldChange(
        entity: 'app_settings',
        rowId: 'k',
        field: 'value = 1; --',
        value: '"x"',
        hlc: Hlc(now.millisecondsSinceEpoch, 1, 'z'),
      ),
    ]);
    expect(await b.db.select(b.db.items).get(), isEmpty);
    expect(await b.db.select(b.db.appSettings).get(), isEmpty);
  });
}

extension on NewItem {
  NewItem copyWithName(String name) => NewItem(
    type: type,
    name: name,
    cycle: cycle,
    anchor: anchor,
    prices: prices,
    presetId: presetId,
    categoryId: categoryId,
    accountId: accountId,
    paidUntil: paidUntil,
    note: note,
    typeFields: typeFields,
    sharing: sharing,
    remindDays: remindDays,
    needsDetails: needsDetails,
  );
}
