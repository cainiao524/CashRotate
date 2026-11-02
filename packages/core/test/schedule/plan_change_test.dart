import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  Money twd(int d) => Money(d * 100, Currency.twd);

  // PS Plus Essential, yearly NT$2,000, paid through 2027-01-01.
  final yearly = ItemSchedule(
    anchor: LocalDate(2026, 1, 1),
    cycle: Cycle.yearly,
    prices: PriceSchedule.fixed(twd(2000)),
    paidUntil: LocalDate(2027, 1, 1),
  );

  test('upgrade now, paying the prorated difference', () {
    // Extra costs NT$3,000: half the year left (2026-07-02 → 2027-01-01 is
    // 183 of 365 days) costs 1,000 × 183/365 ≈ NT$501.37.
    final r = changePlan(
      yearly,
      newPrice: twd(3000),
      on: LocalDate(2026, 7, 2),
      mode: PlanChangeMode.payDifference,
    );
    expect(r.oneOff, const Money(50137, Currency.twd));
    expect(r.paidUntil, LocalDate(2027, 1, 1));
    expect(r.fromIndex, 1);
    expect(r.prices.priceAt(Cycle.yearly, yearly.anchor, 0), twd(2000));
    expect(r.prices.priceAt(Cycle.yearly, yearly.anchor, 1), twd(3000));
  });

  test('a downgrade has nothing to pay now', () {
    final r = changePlan(
      yearly,
      newPrice: twd(1000),
      on: LocalDate(2026, 7, 2),
      mode: PlanChangeMode.payDifference,
    );
    expect(r.oneOff, isNull);
  });

  test('downgrade at renewal keeps the paid period, cheaper from then', () {
    final r = changePlan(
      yearly,
      newPrice: twd(1000),
      on: LocalDate(2026, 7, 2),
      mode: PlanChangeMode.atRenewal,
    );
    expect(r.paidUntil, LocalDate(2027, 1, 1));
    expect(r.prices.priceAt(Cycle.yearly, yearly.anchor, 1), twd(1000));
    expect(r.oneOff, isNull);
  });

  test('convert the time left at the price ratio (Game Pass style)', () {
    // Monthly NT$300, paid through 2026-12-01; on 2026-11-11 there are 20
    // days left, worth 20 × 300/450 ≈ 13 days of a NT$450 plan.
    final monthly = ItemSchedule(
      anchor: LocalDate(2026, 1, 1),
      cycle: Cycle.monthly,
      prices: PriceSchedule.fixed(twd(300)),
      paidUntil: LocalDate(2026, 12, 1),
    );
    final r = changePlan(
      monthly,
      newPrice: twd(450),
      on: LocalDate(2026, 11, 11),
      mode: PlanChangeMode.convertTime,
    );
    expect(r.paidUntil, LocalDate(2026, 11, 24));
    expect(r.anchor, LocalDate(2026, 11, 24));
    expect(r.prices, PriceSchedule.fixed(twd(450)));
    // Downgrading converts the other way: more days.
    final down = changePlan(
      monthly,
      newPrice: twd(150),
      on: LocalDate(2026, 11, 11),
      mode: PlanChangeMode.convertTime,
    );
    expect(down.paidUntil, LocalDate(2026, 12, 21));
  });

  test('month-end anchors and the last day of the period', () {
    final endOfMonth = ItemSchedule(
      anchor: LocalDate(2026, 1, 31),
      cycle: Cycle.monthly,
      prices: PriceSchedule.fixed(twd(310)),
      paidUntil: LocalDate(2026, 3, 31),
    );
    // On the day it renews nothing is left to prorate.
    final r = changePlan(
      endOfMonth,
      newPrice: twd(620),
      on: LocalDate(2026, 3, 31),
      mode: PlanChangeMode.payDifference,
    );
    expect(r.oneOff, const Money(0, Currency.twd));
    // Mid-February (28 days): 14 days left of 28.
    final feb = changePlan(
      endOfMonth.copyWith(paidUntil: LocalDate(2026, 2, 28)),
      newPrice: twd(620),
      on: LocalDate(2026, 2, 14),
      mode: PlanChangeMode.payDifference,
    );
    expect(feb.oneOff, twd(155));
  });
}
