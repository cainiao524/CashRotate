import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = LocalDate(2026, 3, 15);
  late AppDatabase db;
  late ItemRepository items;
  late PaymentMethods methods;
  late PaymentRepository payments;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final journal = Journal(db);
    items = ItemRepository(db, journal, today: () => today);
    methods = PaymentMethods(db, journal);
    payments = PaymentRepository(db, journal, items, methods);
  });
  tearDown(() => db.close());

  Future<String> netflix() => items.create(
    NewItem(
      type: ItemType.subscription,
      name: 'Netflix',
      cycle: Cycle.monthly,
      anchor: LocalDate(2026, 3, 18),
      prices: PriceSchedule.fixed(const Money(39000, Currency.twd)),
    ),
  );

  test('a payment settles its charge and is linked to it', () async {
    final id = await netflix();
    final due = (await items.view(id)).nextDue!;
    final tx = await payments.record(
      itemId: id,
      occurrenceId: due.id,
      expected: const Money(39000, Currency.twd),
      paid: const Money(39000, Currency.twd),
      paidOn: LocalDate(2026, 3, 18),
      main: Currency.twd,
    );
    final occ = await (db.select(
      db.occurrences,
    )..where((o) => o.id.equals(due.id))).getSingle();
    expect(occ.state, OccurrenceState.paid);
    expect(occ.transactionId, tx);
    expect((await items.view(id)).nextDue!.dueOn, LocalDate(2026, 4, 18));
    final list = await payments.watchForItem(id).first;
    expect(list.single.paid, const Money(39000, Currency.twd));
    expect(list.single.paidOn, LocalDate(2026, 3, 18));
    // No method chosen: the shared "unassigned" one, created once.
    expect(list.single.row.accountId, PaymentMethods.unassignedId);
    expect(await methods.watchAll().first, isEmpty, reason: 'hidden');
  });

  test('"update the price" changes the following charges; "just this once" '
      'does not', () async {
    final id = await netflix();
    var due = (await items.view(id)).nextDue!;
    await payments.record(
      itemId: id,
      occurrenceId: due.id,
      expected: const Money(39000, Currency.twd),
      paid: const Money(41000, Currency.twd),
      paidOn: LocalDate(2026, 3, 18),
      main: Currency.twd,
    );
    due = (await items.view(id)).nextDue!;
    expect(due.expectedMinor, 39000, reason: 'just this once');

    await payments.record(
      itemId: id,
      occurrenceId: due.id,
      expected: const Money(39000, Currency.twd),
      paid: const Money(41000, Currency.twd),
      paidOn: LocalDate(2026, 4, 18),
      main: Currency.twd,
      updateFuturePrice: true,
    );
    expect((await items.view(id)).nextDue!.expectedMinor, 41000);
  });

  test('a foreign charge in the card\'s currency: actual rate and the card\'s '
      'learned markup', () async {
    final id = await items.create(
      NewItem(
        type: ItemType.subscription,
        name: 'ChatGPT',
        cycle: Cycle.monthly,
        anchor: LocalDate(2026, 3, 20),
        prices: PriceSchedule.fixed(const Money(2000, Currency.usd)),
      ),
    );
    final card = await methods.create(
      name: 'Cathay Visa',
      type: AccountType.creditCard,
      currency: Currency.twd,
      cardLast4: '4000 1234 5678 9010',
    );
    final due = (await items.view(id)).nextDue!;
    await payments.record(
      itemId: id,
      occurrenceId: due.id,
      expected: const Money(2000, Currency.usd),
      paid: const Money(66100, Currency.twd),
      paidOn: LocalDate(2026, 3, 20),
      main: Currency.twd,
      accountId: card,
      marketRate: Ratio.tryParse('32.5'),
    );
    final p = (await payments.watchForItem(id).first).single;
    expect(p.original, const Money(2000, Currency.usd));
    expect(p.actualRate!.toDecimalString(), '33.05');
    // 33.05 / 32.5 = 1.0169…: about 1.69% over the published rate.
    expect(p.markupBasisPoints, 169);
    expect(await payments.learnedMarkup(card), 169);
    expect((await methods.watchAll().first).single.cardLast4, '9010');
  });

  test('a payment can be deleted', () async {
    final id = await netflix();
    final tx = await payments.record(
      itemId: id,
      expected: const Money(39000, Currency.twd),
      paid: const Money(39000, Currency.twd),
      paidOn: today,
      main: Currency.twd,
    );
    await payments.delete(tx);
    expect(await payments.watchForItem(id).first, isEmpty);
  });
}
