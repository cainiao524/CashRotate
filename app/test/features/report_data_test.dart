import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/features/reports/report_data.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'fixed_summary_test.dart' show today, view;

ItemView inCategory(ItemView v, String category) => ItemView(
  v.row.copyWith(categoryId: Value(category)),
  v.schedule,
  v.nextDue,
);

OccurrenceRow charge(
  String itemId,
  LocalDate dueOn,
  int minor, {
  Currency currency = Currency.twd,
  OccurrenceState state = OccurrenceState.paid,
}) => OccurrenceRow(
  id: '$itemId:$dueOn',
  itemId: itemId,
  cycleIndex: 0,
  dueOn: dueOn,
  expectedMinor: minor,
  currency: currency,
  state: state,
);

void main() {
  final fx = FxConverter([
    ExchangeRate(
      base: Currency.usd,
      quote: Currency.twd,
      rate: Ratio.tryParse('32')!,
      asOf: today,
      source: 'manual',
    ),
  ]);

  group('monthCells', () {
    test('March 2026 starts on a Sunday', () {
      final cells = monthCells(2026, 3, 0);
      expect(cells.first, 1);
      expect(cells.length, 35);
      expect(cells.whereType<int>().length, 31);
    });

    test('Monday-first weeks shift the blanks', () {
      final cells = monthCells(2026, 3, 1);
      expect(cells.take(7), [null, null, null, null, null, null, 1]);
      expect(cells.length % 7, 0);
    });

    test('leap February', () {
      expect(monthCells(2028, 2, 0).whereType<int>().last, 29);
      expect(monthCells(2027, 2, 0).whereType<int>().last, 28);
    });
  });

  test('last 12 months: oldest first, skipped and transfers left out, '
      'foreign converted, shared at my share', () {
    final items = [
      view(name: 'rent', price: const Money(1800000, Currency.twd)),
      view(name: 'gpt', price: const Money(2000, Currency.usd)),
      view(
        name: 'transfer',
        price: const Money(500000, Currency.twd),
        type: ItemType.transferOut,
      ),
      view(
        name: 'netflix',
        price: const Money(40000, Currency.twd),
        sharing: '{"people":4}',
      ),
    ];
    final months = lastTwelveMonths(
      items,
      [
        charge('rent', LocalDate(2026, 3, 5), 1800000),
        charge('rent', LocalDate(2025, 4, 5), 1800000),
        charge('rent', LocalDate(2025, 3, 5), 1800000), // 13 months ago
        charge(
          'rent',
          LocalDate(2026, 2, 5),
          1800000,
          state: OccurrenceState.skipped,
        ),
        charge('gpt', LocalDate(2026, 3, 20), 2000, currency: Currency.usd),
        charge('transfer', LocalDate(2026, 3, 1), 500000),
        charge('netflix', LocalDate(2026, 3, 18), 40000),
      ],
      fx,
      Currency.twd,
      today,
    );
    expect(months.length, 12);
    expect((months.first.year, months.first.month), (2025, 4));
    expect((months.last.year, months.last.month), (2026, 3));
    expect(months.first.total.minor, 1800000);
    expect(months[10].total.minor, 0); // February: skipped
    expect(months.last.total.minor, 1800000 + 64000 + 10000);
  });

  test('categories: largest first, past the top five merged', () {
    final items = [
      for (final (i, c) in ['a', 'b', 'c', 'd', 'e', 'f', 'g'].indexed)
        inCategory(view(name: c, price: Money((i + 1) * 100, Currency.twd)), c),
    ];
    final ranking = byCategory(items, {
      for (final (i, v) in items.indexed)
        v.row.id: Money((i + 1) * 100, Currency.twd),
    }, Currency.twd);
    expect(
      [for (final e in ranking) e.category],
      ['g', 'f', 'e', 'd', 'c', null],
    );
    expect(ranking.last.monthly.minor, 300); // a + b
  });

  test('price changes: newest first with the difference and percent', () {
    final items = [
      view(name: 'netflix', price: const Money(39000, Currency.twd)),
    ];
    PriceHistoryRow row(
      String id,
      String item,
      LocalDate on,
      int from,
      int to,
    ) => PriceHistoryRow(
      id: id,
      itemId: item,
      fromCycleIndex: 1,
      effectiveOn: on,
      oldMinor: from,
      newMinor: to,
      currency: Currency.twd,
      recordedAt: 0,
    );
    final lines = priceChanges([
      row('1', 'netflix', LocalDate(2025, 1, 1), 33000, 39000),
      row('2', 'netflix', LocalDate(2026, 1, 1), 39000, 42900),
      row('3', 'gone', LocalDate(2026, 2, 1), 1, 2),
    ], items);
    expect(lines.length, 2);
    expect(lines.first.effectiveOn, LocalDate(2026, 1, 1));
    expect(lines.first.difference.minor, 3900);
    expect(lines.first.percent, closeTo(10, 1e-9));
  });

  test('10,000 charges: the chart data takes well under a second', () {
    final items = [
      for (var i = 0; i < 200; i++)
        view(name: 'item$i', price: const Money(10000, Currency.twd)),
    ];
    final charges = [
      for (var i = 0; i < 10000; i++)
        charge(
          'item${i % 200}',
          LocalDate(2025, 4, 1).addDays(i % 365),
          10000 + i,
        ),
    ];
    final watch = Stopwatch()..start();
    lastTwelveMonths(items, charges, fx, Currency.twd, today);
    monthsOfYear(items, charges, fx, Currency.twd, 2025);
    chargesByDay(charges, 2026, 3);
    expect(watch.elapsedMilliseconds, lessThan(500));
  });
}
