import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate/features/home/fixed_summary.dart';
import 'package:cashrotate/features/reports/report_data.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// CLAUDE.md: with 10,000 transactions, home and charts open within 1 s.
/// 200 fixed expenses (with a year of charges each planned ahead) and
/// 10,000 payment records.
Future<void> seedTenThousand(TestData d) async {
  final ids = <String>[];
  for (var i = 0; i < 200; i++) {
    ids.add(
      await d.items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'Service $i',
          categoryId: PresetCategory.values[i % 20].name,
          cycle: Cycle.monthly,
          anchor: testToday.addDays(i % 28),
          prices: PriceSchedule.fixed(Money(10000 + i * 100, Currency.twd)),
        ),
      ),
    );
  }
  // One real payment creates the "not specified" payment method.
  await PaymentRepository(
    d.db,
    d.journal,
    d.items,
    PaymentMethods(d.db, d.journal),
  ).record(
    itemId: ids.first,
    expected: const Money(10000, Currency.twd),
    paid: const Money(10000, Currency.twd),
    paidOn: testToday,
    main: Currency.twd,
  );
  const account = PaymentMethods.unassignedId;
  await d.db.batch((b) {
    b.insertAll(d.db.transactions, [
      for (var i = 0; i < 10000; i++)
        TransactionsCompanion.insert(
          id: 'tx$i',
          type: TransactionType.expense,
          status: TransactionStatus.confirmed,
          amountMinor: 10000 + i,
          currency: Currency.twd,
          accountId: account,
          occurredAt: DateTime.utc(
            2025,
            3,
            15,
          ).add(Duration(hours: i * 3 % (365 * 24))).millisecondsSinceEpoch,
          itemId: Value(ids[i % 200]),
          createdAt: 0,
          updatedAt: 0,
        ),
    ]);
  });
}

void main() {
  test('data for home and charts loads within a second', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final d = TestData(db);
    await d.settings.setRegion('TW');
    await seedTenThousand(d);
    final payments = PaymentRepository(
      db,
      d.journal,
      d.items,
      PaymentMethods(db, d.journal),
    );
    final fx = await d.rates.watchConverter().first;

    final watch = Stopwatch()..start();
    final items = await d.items.watchAll().first;
    final charges = await d.items
        .watchDue(LocalDate(2025, 1, 1), LocalDate(2027, 12, 31))
        .first;
    final all = await payments.watchAll().first;
    computeFixedSummary(items, fx: fx, main: Currency.twd, today: testToday);
    lastTwelveMonths(items, charges, fx, Currency.twd, testToday);
    monthsOfYear(items, charges, fx, Currency.twd, 2026);
    await payments.watchForItem(items.first.row.id).first;
    watch.stop();

    expect(items, hasLength(200));
    expect(all, hasLength(10001));
    expect(watch.elapsedMilliseconds, lessThan(1000));
    // ignore: avoid_print
    print('10k: data for home and charts in ${watch.elapsedMilliseconds} ms');
  });

  testApp('home and reports render with 10,000 payments', (tester) async {
    await pumpApp(tester, seed: seedTenThousand);
    expect(find.text('Service 0'), findsWidgets);
    final watch = Stopwatch()..start();
    await tester.tap(find.byIcon(Icons.insert_chart_outlined));
    await settle(tester);
    watch.stop();
    expect(find.byKey(const Key('reports-monthly-total')), findsOneWidget);
    // ignore: avoid_print
    print('10k: reports page in ${watch.elapsedMilliseconds} ms');
  });
}
