import 'package:cashrotate/features/home/countdown_ring.dart';
import 'package:cashrotate/features/home/home_tiles.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fixed_summary_test.dart' show today, view;

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
  const twd = Money(39000, Currency.twd);

  HomeTile tileOf(
    LocalDate due, {
    Money price = twd,
    bool needsDetails = false,
  }) => HomeTile.of(
    view(name: 'x', price: price, due: due, needsDetails: needsDetails),
    today: today,
    fx: fx,
    main: Currency.twd,
  );

  group('countdown', () {
    test('ring length is the share of the period gone', () {
      // Due 25 March; the period started 25 February (28 days).
      final t = tileOf(LocalDate(2026, 3, 25));
      expect(t.daysLeft, 10);
      expect(t.periodDays, 28);
      expect(t.elapsed, closeTo(1 - 10 / 28, 1e-9));
      expect(t.overdue, isFalse);
    });

    test('a new period starts nearly empty, never invisible', () {
      expect(tileOf(LocalDate(2026, 4, 14)).elapsed, 0.05);
    });

    test('overdue: full ring plus a lap that grows with the days', () {
      final t = tileOf(LocalDate(2026, 3, 12)); // period of 28 days
      expect(t.overdue, isTrue);
      expect(t.daysLeft, -3);
      expect(t.elapsed, 1);
      expect(t.overdueLap, closeTo(3 / 28, 1e-9));
      expect(tileOf(LocalDate(2025, 12, 1)).overdueLap, 0.5);
    });

    test('due within two days is inverted; items to fill in are not', () {
      expect(tileOf(today).dueSoon, isTrue);
      expect(tileOf(today.addDays(2)).dueSoon, isTrue);
      expect(tileOf(today.addDays(3)).dueSoon, isFalse);
      expect(tileOf(today, needsDetails: true).dueSoon, isFalse);
    });

    test('colour: grey beyond 14 days, yellow to red within, red overdue', () {
      expect(
        CountdownRing.colorFor(15, onDark: false),
        const Color(0xFF8E8E93),
      );
      expect(
        CountdownRing.colorFor(null, onDark: false),
        const Color(0xFF8E8E93),
      );
      expect(
        HSLColor.fromColor(CountdownRing.colorFor(14, onDark: false)).hue,
        closeTo(48, 1),
      );
      expect(
        HSLColor.fromColor(CountdownRing.colorFor(7, onDark: false)).hue,
        closeTo(25.5, 1),
      );
      expect(
        HSLColor.fromColor(CountdownRing.colorFor(0, onDark: false)).hue,
        closeTo(3, 1),
      );
      expect(
        CountdownRing.colorFor(-1, onDark: false),
        const Color(0xFFFF3B30),
      );
      expect(CountdownRing.colorFor(-1, onDark: true), const Color(0xFFFF453A));
    });
  });

  test('foreign prices are converted; local ones are not', () {
    final usd = tileOf(
      today.addDays(5),
      price: const Money(2000, Currency.usd),
    );
    expect(usd.converted, const Money(64000, Currency.twd));
    expect(usd.monthlyMinor, 64000);
    expect(tileOf(today.addDays(5)).converted, isNull);
  });

  test('flags the first charge at a new price', () {
    final intro = PriceSchedule.intro(
      intro: const Money(100, Currency.usd),
      periods: 1,
      renewal: const Money(1500, Currency.usd),
    );
    HomeTile at(int index) => HomeTile.of(
      view(
        name: 'domain',
        price: const Money(1500, Currency.usd),
        cycle: Cycle.yearly,
        prices: intro,
        cycleIndex: index,
        due: LocalDate(2026, 6, 1),
      ),
      today: today,
      fx: fx,
      main: Currency.twd,
    );
    expect(at(0).newPrice, isFalse);
    expect(at(1).newPrice, isTrue);
    expect(at(2).newPrice, isFalse);
  });

  group('homeTiles', () {
    final items = [
      view(name: 'Later', price: twd, due: today.addDays(20)),
      view(name: 'Overdue', price: twd, due: today.addDays(-1)),
      view(
        name: 'Paused',
        price: twd,
        status: ItemStatus.paused,
        pending: false,
      ),
      view(
        name: 'Gone',
        price: twd,
        status: ItemStatus.cancelled,
        pending: false,
        paidUntil: today,
      ),
      view(
        name: 'Ending',
        price: twd,
        status: ItemStatus.cancelled,
        pending: false,
        paidUntil: today.addDays(9),
      ),
      view(
        name: 'Big bill',
        price: const Money(900000, Currency.twd),
        type: ItemType.bill,
        due: today.addDays(5),
      ),
    ];
    List<String> names({
      TileSort sort = TileSort.dueDate,
      ItemType? type,
      String query = '',
    }) => [
      for (final t in homeTiles(
        items,
        today: today,
        fx: fx,
        main: Currency.twd,
        sort: sort,
        type: type,
        query: query,
      ))
        t.view.row.name,
    ];

    test('soonest first, overdue on top, paused and cancelled last; '
        'cancelled items drop out once no longer paid for', () {
      expect(names(), ['Overdue', 'Big bill', 'Later', 'Paused', 'Ending']);
    });

    test('by amount and by name', () {
      expect(names(sort: TileSort.amount).first, 'Big bill');
      expect(names(sort: TileSort.name), [
        'Big bill',
        'Ending',
        'Later',
        'Overdue',
        'Paused',
      ]);
    });

    test('type filter and search', () {
      expect(names(type: ItemType.bill), ['Big bill']);
      expect(names(query: ' LAT '), ['Later']);
    });
  });
}
