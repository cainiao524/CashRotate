import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate/data/sync/conflict_resolver.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import 'drift_sync_store_test.dart' show Phone;

/// [v] as the editor would save it, with a new name or price schedule.
NewItem edited(ItemView v, {String? name, PriceSchedule? prices}) {
  final n = v.toNewItem();
  return NewItem(
    type: n.type,
    name: name ?? n.name,
    cycle: n.cycle,
    anchor: n.anchor,
    prices: prices ?? n.prices,
    paidUntil: n.paidUntil,
    remindDays: n.remindDays,
  );
}

/// "Edited after delete" conflicts: keep the item deleted, or bring it back
/// with the other phone's edits.
void main() {
  var now = DateTime.utc(2026, 3, 15, 10);
  DateTime clock() => now;
  late MemoryFolder remote;
  late Phone a;
  late Phone b;
  late Phone c;

  ConflictResolver resolver(Phone p) =>
      ConflictResolver(p.db, p.journal, p.items);
  PaymentRepository payments(Phone p) => PaymentRepository(
    p.db,
    p.journal,
    p.items,
    PaymentMethods(p.db, p.journal),
  );
  void later([int seconds = 60]) => now = now.add(Duration(seconds: seconds));

  setUp(() {
    now = DateTime.utc(2026, 3, 15, 10);
    remote = MemoryFolder();
    a = Phone(remote, clock);
    b = Phone(remote, clock);
    c = Phone(remote, clock);
  });
  tearDown(() async {
    for (final p in [a, b, c]) {
      await p.db.close();
    }
  });

  /// Netflix on both phones, with an intro price; A paid the first charge.
  /// Then A deletes it while B, offline, renames it and pays the next one.
  Future<String> deletedOnAEditedOnB() async {
    final id = await a.items.create(
      NewItem(
        type: ItemType.subscription,
        name: 'Netflix',
        cycle: Cycle.monthly,
        anchor: LocalDate(2026, 2, 18),
        prices: PriceSchedule.intro(
          intro: const Money(0, Currency.twd),
          periods: 1,
          renewal: const Money(39000, Currency.twd),
        ),
      ),
    );
    final first = (await a.items.view(id)).nextDue!;
    await payments(a).record(
      itemId: id,
      occurrenceId: first.id,
      expected: const Money(0, Currency.twd),
      paid: const Money(0, Currency.twd),
      paidOn: LocalDate(2026, 2, 18),
      main: Currency.twd,
    );
    await a.sync();
    await b.sync();
    expect(await b.names(), ['Netflix']);

    later();
    await a.items.delete(id);
    later();
    final onB = await b.items.view(id);
    await b.items.update(id, edited(onB, name: 'Netflix 4K'));
    await payments(b).record(
      itemId: id,
      occurrenceId: (await b.items.view(id)).nextDue!.id,
      expected: const Money(39000, Currency.twd),
      paid: const Money(39000, Currency.twd),
      paidOn: LocalDate(2026, 3, 18),
      main: Currency.twd,
    );
    later();
    await a.sync(); // uploads the deletion
    await b.sync(); // B loses the item, uploads its edits
    await a.sync(); // A sees edits made after its deletion
    expect(await a.names(), isEmpty);
    expect(await b.names(), isEmpty);
    return id;
  }

  test('the deleting phone lists the item with its last known name', () async {
    final id = await deletedOnAEditedOnB();
    final conflicts = await resolver(a).deletedItems();
    expect(conflicts, hasLength(1));
    expect(conflicts.single.itemId, id);
    expect(conflicts.single.name, 'Netflix');
    expect(conflicts.single.changes, greaterThan(0));
  });

  test('keep deleted: the conflicts go, nothing comes back', () async {
    final id = await deletedOnAEditedOnB();
    await resolver(a).keepDeleted(id);
    expect(await resolver(a).deletedItems(), isEmpty);
    expect(await a.store.conflictsJson(), isEmpty);
    expect(await a.names(), isEmpty);
  });

  test('restore: back with the edits, prices, paid charges and payments; '
      'the other phones get it too', () async {
    final id = await deletedOnAEditedOnB();
    final newId = await resolver(a).restore(id);
    expect(newId, ConflictResolver.restoredId(id));
    expect(await resolver(a).deletedItems(), isEmpty);

    final view = await a.items.view(newId!);
    expect(view.row.name, 'Netflix 4K', reason: "B's rename is applied");
    expect(view.schedule.prices.phases, hasLength(2));
    expect(view.schedule.prices.stablePrice, const Money(39000, Currency.twd));
    // Both charges are paid (A's and B's); the next one is April's.
    expect(view.nextDue!.dueOn, LocalDate(2026, 4, 18));
    final charges = await (a.db.select(
      a.db.occurrences,
    )..where((o) => o.itemId.equals(newId))).get();
    expect(
      [
        for (final o in charges)
          if (o.state == OccurrenceState.paid) o.dueOn,
      ],
      [LocalDate(2026, 2, 18), LocalDate(2026, 3, 18)],
    );
    final paid = await payments(a).watchForItem(newId).first;
    expect(paid, hasLength(2), reason: 'payment records follow the item');
    expect(
      paid.map((p) => p.row.occurrenceId),
      everyElement(startsWith('$newId:')),
    );

    later();
    await a.sync();
    await b.sync();
    await c.sync();
    expect(await b.names(), ['Netflix 4K']);
    expect(await c.names(), ['Netflix 4K']);
    expect((await b.items.view(newId)).nextDue!.dueOn, LocalDate(2026, 4, 18));
  });

  test('restoring on two phones gives one item, not two', () async {
    final id = await deletedOnAEditedOnB();
    await c.sync(); // C merges the deletion and B's edits: conflict too
    expect(await resolver(c).deletedItems(), hasLength(1));
    final onA = await resolver(a).restore(id);
    final onC = await resolver(c).restore(id);
    expect(onA, onC);
    later();
    for (final p in [a, c, b, a, c]) {
      await p.sync();
    }
    for (final p in [a, b, c]) {
      expect(await p.names(), ['Netflix 4K']);
    }
  });

  test('a price phase removed before the deletion stays removed', () async {
    final id = await a.items.create(
      NewItem(
        type: ItemType.subscription,
        name: 'VPS',
        cycle: Cycle.monthly,
        anchor: LocalDate(2026, 3, 20),
        prices: PriceSchedule.intro(
          intro: const Money(100, Currency.usd),
          periods: 1,
          renewal: const Money(500, Currency.usd),
        ),
      ),
    );
    later();
    final v = await a.items.view(id);
    await a.items.update(
      id,
      edited(v, prices: PriceSchedule.fixed(const Money(500, Currency.usd))),
    );
    await a.sync();
    await b.sync();
    later();
    await a.items.delete(id);
    later();
    final onB = await b.items.view(id);
    await b.items.update(id, edited(onB, name: 'VPS Tokyo'));
    later();
    await a.sync();
    await b.sync();
    await a.sync();
    final newId = await resolver(a).restore(id);
    final restored = await a.items.view(newId!);
    expect(restored.row.name, 'VPS Tokyo');
    expect(restored.schedule.prices.phases, hasLength(1));
  });
}
