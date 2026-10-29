import 'dart:convert';

import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);
Money twd(int dollars) => Money(dollars * 100, Currency.twd);
Money usd(int cents) => Money(cents, Currency.usd);

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  var today = d('2026-03-15');
  var clock = 1700000000000;

  setUp(() {
    today = d('2026-03-15');
    clock = 1700000000000;
    db = AppDatabase(NativeDatabase.memory());
    final journal = Journal(db, nowMillis: () => clock++);
    repo = ItemRepository(
      db,
      journal,
      today: () => today,
      nowMillis: () => clock,
    );
  });
  tearDown(() => db.close());

  Future<List<OccurrenceRow>> occurrences(String itemId) =>
      (db.select(db.occurrences)
            ..where((o) => o.itemId.equals(itemId))
            ..orderBy([(o) => OrderingTerm.asc(o.cycleIndex)]))
          .get();

  Future<List<ChangeLogRow>> journal() => (db.select(
    db.changeLog,
  )..orderBy([(c) => OrderingTerm.asc(c.seq)])).get();

  Future<String> netflix({String anchor = '2026-01-31'}) => repo.create(
    NewItem(
      type: ItemType.subscription,
      name: 'Netflix',
      cycle: Cycle.monthly,
      anchor: d(anchor),
      prices: PriceSchedule.fixed(twd(390)),
    ),
  );

  test(
    'create stores the item, its phases and 12 months of occurrences',
    () async {
      final id = await netflix();
      final occ = await occurrences(id);
      expect(occ.first.dueOn, d('2026-01-31'));
      expect(occ[1].dueOn, d('2026-02-28'));
      expect(occ.last.dueOn, d('2027-02-28'));
      expect(occ.every((o) => o.state == OccurrenceState.pending), isTrue);
      expect(occ.first.id, '$id:2026-01-31');
      expect(
        await repo.scheduleOf(id).then((s) => s.prices),
        PriceSchedule.fixed(twd(390)),
      );
    },
  );

  test('daily refresh extends the window and is otherwise a no-op', () async {
    final id = await netflix();
    final journalBefore = (await journal()).length;
    await repo.refreshAll();
    expect((await journal()).length, journalBefore, reason: 'nothing changed');

    today = d('2026-05-15');
    await repo.refreshAll();
    final occ = await occurrences(id);
    expect(occ.last.dueOn, d('2027-04-30'));
  });

  test(
    'price rise: history kept, paid charges untouched, pending updated',
    () async {
      final id = await netflix();
      await repo.markPaid('$id:2026-01-31');
      await repo.changePrice(id, fromIndex: 3, amount: twd(420));

      final occ = await occurrences(id);
      final byIndex = {for (final o in occ) o.cycleIndex: o};
      expect(byIndex[0]!.state, OccurrenceState.paid);
      expect(byIndex[0]!.expectedMinor, 39000);
      expect(byIndex[2]!.expectedMinor, 39000);
      expect(byIndex[3]!.expectedMinor, 42000);
      expect(byIndex[6]!.expectedMinor, 42000);

      final history = await db.select(db.priceHistory).getSingle();
      expect(history.oldMinor, 39000);
      expect(history.newMinor, 42000);
      expect(history.effectiveOn, d('2026-04-30'));
    },
  );

  test('paying a domain three years at once moves paidUntil and drops covered years', () async {
    final id = await repo.create(
      NewItem(
        type: ItemType.subscription,
        name: 'example.com',
        cycle: Cycle.yearly,
        anchor: d('2026-06-01'),
        prices: PriceSchedule.intro(
          intro: usd(100),
          periods: 1,
          renewal: usd(1500),
        ),
      ),
    );
    expect((await occurrences(id)).map((o) => o.cycleIndex), [0]);
    await repo.markPaid('$id:2026-06-01', cycles: 3);

    final schedule = await repo.scheduleOf(id);
    expect(schedule.paidUntil, d('2029-06-01'));
    final occ = await occurrences(id);
    expect(occ.single.state, OccurrenceState.paid);

    today = d('2028-07-01');
    await repo.refreshAll();
    final later = await occurrences(id);
    expect(later.last.cycleIndex, 3);
    expect(later.last.dueOn, d('2029-06-01'));
    expect(later.last.expectedMinor, 1500);
  });

  test(
    'pausing removes future pending charges; resuming skips the paused span',
    () async {
      final id = await netflix();
      await repo.setStatus(id, ItemStatus.paused, d('2026-03-01'));
      var occ = await occurrences(id);
      expect(occ.map((o) => '${o.dueOn}'), ['2026-01-31', '2026-02-28']);

      today = d('2026-06-10');
      await repo.setStatus(id, ItemStatus.active, d('2026-06-10'));
      occ = await occurrences(id);
      expect(
        occ.where((o) => o.dueOn > d('2026-02-28')).first.dueOn,
        d('2026-06-30'),
      );
    },
  );

  test(
    'cancelled items stay usable until paidUntil and plan nothing after',
    () async {
      final id = await netflix();
      await repo.markPaid('$id:2026-01-31');
      await repo.markPaid('$id:2026-02-28');
      await repo.setStatus(id, ItemStatus.cancelled, d('2026-03-10'));
      final schedule = await repo.scheduleOf(id);
      expect(schedule.isUsableOn(d('2026-03-30')), isTrue);
      expect(schedule.isUsableOn(d('2026-03-31')), isFalse);
      expect(
        (await occurrences(id))
            .where((o) => o.state == OccurrenceState.pending),
        isEmpty,
      );
    },
  );

  test('delete cascades and leaves tombstones for sync', () async {
    final id = await netflix();
    final count = (await occurrences(id)).length;
    await repo.delete(id);
    expect(await occurrences(id), isEmpty);
    expect(await db.select(db.pricePhases).get(), isEmpty);
    final tombstones = (await journal())
        .where((c) => c.field == Journal.tombstone)
        .toList();
    expect(tombstones.where((c) => c.entity == 'items').single.rowId, id);
    expect(
      tombstones.where((c) => c.entity == 'occurrences'),
      hasLength(count),
    );
  });

  group('journal', () {
    test(
      'logs every column on insert and only changed columns on update',
      () async {
        final id = await netflix();
        final itemFields = (await journal())
            .where((c) => c.entity == 'items' && c.rowId == id)
            .map((c) => c.field)
            .toSet();
        expect(
          itemFields,
          containsAll(['name', 'anchor_on', 'cycle_unit', 'currency']),
        );

        final before = (await journal()).length;
        await repo.setStatus(id, ItemStatus.paused, d('2026-04-01'));
        final itemChanges = (await journal())
            .skip(before)
            .where((c) => c.entity == 'items')
            .map((c) => c.field)
            .toSet();
        expect(itemChanges, {'status', 'status_since', 'updated_at'});
      },
    );

    test('values are stored as JSON of the SQL value', () async {
      final id = await netflix();
      final anchor = (await journal()).firstWhere(
        (c) => c.entity == 'items' && c.rowId == id && c.field == 'anchor_on',
      );
      expect(jsonDecode(anchor.value), '2026-01-31');
    });

    test('HLCs strictly increase and carry this device id', () async {
      await netflix();
      await netflix(anchor: '2026-02-01');
      final rows = await journal();
      final clocks = rows.map((r) => Hlc.parse(r.hlc)).toList();
      final device = clocks.first.node;
      expect(clocks.every((c) => c.node == device), isTrue);
      final distinct = clocks.toSet().toList()..sort();
      for (var i = 1; i < distinct.length; i++) {
        expect(distinct[i] > distinct[i - 1], isTrue);
      }
      final meta = await (db.select(
        db.meta,
      )..where((m) => m.key.equals('device_id'))).getSingle();
      expect(meta.value, device);
    });
  });

  group('editing (M2)', () {
    test('update replaces details, keeps status and paid history', () async {
      final id = await netflix();
      await repo.markPaid('$id:2026-01-31');
      final before = (await repo.view(id)).toNewItem();
      await repo.update(
        id,
        NewItem(
          type: before.type,
          name: 'Netflix Premium',
          cycle: before.cycle,
          anchor: before.anchor,
          prices: PriceSchedule.fixed(twd(490)),
          typeFields: {'plan': 'premium'},
          sharing: {'people': 4, 'myShare': 12250},
        ),
      );
      final view = await repo.view(id);
      expect(view.row.name, 'Netflix Premium');
      expect(view.typeFields, {'plan': 'premium'});
      expect(view.sharing!['people'], 4);
      final occ = await occurrences(id);
      expect(occ.first.state, OccurrenceState.paid);
      expect(
        occ.first.expectedMinor,
        39000,
        reason: 'history is not rewritten',
      );
      expect(occ[1].expectedMinor, 49000);
    });

    test(
      'moving the billing day after payments keeps the next charge',
      () async {
        final id = await netflix();
        await repo.markPaid('$id:2026-01-31');
        await repo.markPaid('$id:2026-02-28');
        final before = (await repo.view(id)).toNewItem();
        await repo.update(
          id,
          NewItem(
            type: before.type,
            name: before.name,
            cycle: before.cycle,
            anchor: d('2026-03-10'),
            prices: before.prices,
            paidUntil: d('2026-03-10'), // what the editor sends
          ),
        );
        final occ = await occurrences(id);
        final paid = occ
            .where((o) => o.state == OccurrenceState.paid)
            .map((o) => '${o.dueOn}');
        expect(paid, ['2026-01-31', '2026-02-28']);
        final pending =
            occ.where((o) => o.state == OccurrenceState.pending).toList()
              ..sort((a, b) => a.dueOn.compareTo(b.dueOn));
        expect(pending.first.dueOn, d('2026-03-10'));
        expect(pending.first.id, '$id:2026-03-10');
      },
    );

    test('duplicate creates an independent active copy', () async {
      final id = await netflix();
      await repo.setStatus(id, ItemStatus.paused, d('2026-03-01'));
      final copy = await repo.duplicate(id, name: 'Netflix (copy)');
      final view = await repo.view(copy);
      expect(view.row.name, 'Netflix (copy)');
      expect(view.row.status, ItemStatus.active);
      expect(view.schedule.prices, PriceSchedule.fixed(twd(390)));
      expect(await occurrences(copy), isNotEmpty);
    });

    test('createAll writes items with blanks marked to fill in', () async {
      final ids = await repo.createAll([
        NewItem(
          type: ItemType.subscription,
          name: 'Spotify',
          cycle: Cycle.monthly,
          anchor: today,
          prices: PriceSchedule.fixed(twd(0)),
          needsDetails: true,
        ),
        NewItem(
          type: ItemType.bill,
          name: 'Rent',
          cycle: Cycle.monthly,
          anchor: d('2026-04-05'),
          prices: PriceSchedule.fixed(twd(20000)),
        ),
      ]);
      expect(ids, hasLength(2));
      final all = await repo.watchAll().first;
      expect(all.where((v) => v.row.needsDetails).map((v) => v.row.name), [
        'Spotify',
      ]);
    });

    test('watchAll orders by next charge and updates on change', () async {
      await netflix(anchor: '2026-04-20');
      await netflix(anchor: '2026-03-20');
      final first = await repo.watchAll().first;
      expect(first.map((v) => '${v.nextDue!.dueOn}'), [
        '2026-03-20',
        '2026-04-20',
      ]);
      expect(first.first.stableMonthly, twd(390));
    });
  });
}
