import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/features/home/fixed_summary.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';

final today = LocalDate(2026, 3, 15);

ItemView view({
  required String name,
  required Money price,
  Cycle cycle = Cycle.monthly,
  ItemType type = ItemType.subscription,
  ItemStatus status = ItemStatus.active,
  LocalDate? due,
  bool needsDetails = false,
  String typeFields = '{}',
  PriceSchedule? prices,
  int cycleIndex = 0,
  LocalDate? paidUntil,
  String sharing = '',
  bool pending = true,
}) {
  final nextDue = due ?? today.addDays(10);
  final schedule = ItemSchedule(
    anchor: cycle.dateAt(nextDue, -cycleIndex),
    cycle: cycle,
    prices: prices ?? PriceSchedule.fixed(price),
    status: status,
    paidUntil: paidUntil,
  );
  final row = ItemRow(
    id: name,
    type: type,
    name: name,
    currency: price.currency,
    cycleUnit: cycle.unit,
    cycleEvery: cycle.every,
    anchorOn: schedule.anchor,
    status: status,
    reminderRules: '[]',
    typeFields: typeFields,
    sharing: sharing.isEmpty ? null : sharing,
    paidUntil: paidUntil,
    note: '',
    needsDetails: needsDetails,
    createdAt: 0,
    updatedAt: 0,
  );
  final next = OccurrenceRow(
    id: '$name:$nextDue',
    itemId: name,
    cycleIndex: cycleIndex,
    dueOn: nextDue,
    expectedMinor: price.minor,
    currency: price.currency,
    state: OccurrenceState.pending,
  );
  return ItemView(row, schedule, pending ? next : null);
}

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

  FixedSummary summary(List<ItemView> items) =>
      computeFixedSummary(items, fx: fx, main: Currency.twd, today: today);

  test('sums monthly equivalents in the main currency', () {
    final s = summary([
      view(name: 'netflix', price: const Money(39000, Currency.twd)),
      view(name: 'chatgpt', price: const Money(2000, Currency.usd)), // NT$640
      view(
        name: 'domain',
        price: const Money(1200, Currency.usd),
        cycle: Cycle.yearly,
      ), // US$1/mo = NT$32
    ]);
    expect(s.monthlyTotal, const Money(39000 + 64000 + 3200, Currency.twd));
    expect(s.missingRates, 0);
  });

  test('leaves out transfers, paused and cancelled items, items to fill in, and VPS-hosted game servers', () {
    final s = summary([
      view(name: 'rent', price: const Money(1800000, Currency.twd)),
      view(
        name: 'parents',
        price: const Money(500000, Currency.twd),
        type: ItemType.transferOut,
      ),
      view(
        name: 'paused',
        price: const Money(10000, Currency.twd),
        status: ItemStatus.paused,
      ),
      view(
        name: 'cancelled',
        price: const Money(10000, Currency.twd),
        status: ItemStatus.cancelled,
      ),
      view(
        name: 'todo',
        price: const Money(0, Currency.twd),
        needsDetails: true,
      ),
      view(
        name: 'mc',
        price: const Money(30000, Currency.twd),
        typeFields: '{"runsOnItemId":"vps"}',
      ),
    ]);
    expect(s.monthlyTotal, const Money(1800000, Currency.twd));
    expect(s.needsDetails, 1);
  });

  test('foreign items without a rate are counted as missing, not guessed', () {
    final s = summary([
      view(name: 'eur', price: const Money(999, Currency.eur)),
    ]);
    expect(s.monthlyTotal, const Money.zero(Currency.twd));
    expect(s.missingRates, 1);
  });

  test('due soon counts charges within 7 days, overdue included', () {
    final s = summary([
      view(
        name: 'overdue',
        price: const Money(100, Currency.twd),
        due: today.addDays(-2),
      ),
      view(name: 'today', price: const Money(100, Currency.twd), due: today),
      view(
        name: 'day7',
        price: const Money(100, Currency.twd),
        due: today.addDays(7),
      ),
      view(
        name: 'day8',
        price: const Money(100, Currency.twd),
        due: today.addDays(8),
      ),
    ]);
    expect(s.dueSoon, 3);
  });

  group("this month's charges", () {
    OccurrenceRow occ(
      String item,
      LocalDate due,
      Money amount, {
      OccurrenceState state = OccurrenceState.pending,
    }) => OccurrenceRow(
      id: '$item:$due',
      itemId: item,
      cycleIndex: 0,
      dueOn: due,
      expectedMinor: amount.minor,
      currency: amount.currency,
      state: state,
    );
    const twd100 = Money(10000, Currency.twd);
    final items = [
      view(name: 'a', price: twd100),
      view(name: 'usd', price: const Money(1000, Currency.usd)),
      view(name: 'parents', price: twd100, type: ItemType.transferOut),
      view(name: 'todo', price: twd100, needsDetails: true),
    ];

    test('paid this month, still to pay through month end (overdue too)', () {
      final m = computeMonthCharges(
        items,
        [
          occ('a', LocalDate(2026, 2, 20), twd100), // overdue: to pay
          occ('a', LocalDate(2026, 2, 1), twd100, state: OccurrenceState.paid),
          occ('a', LocalDate(2026, 3, 1), twd100, state: OccurrenceState.paid),
          occ('a', LocalDate(2026, 3, 31), twd100),
          occ('a', LocalDate(2026, 4, 1), twd100), // next month
          occ('usd', LocalDate(2026, 3, 20), const Money(1000, Currency.usd)),
          occ('parents', LocalDate(2026, 3, 20), twd100),
          occ('todo', LocalDate(2026, 3, 20), twd100),
          occ(
            'a',
            LocalDate(2026, 3, 2),
            twd100,
            state: OccurrenceState.skipped,
          ),
        ],
        fx: fx,
        main: Currency.twd,
        today: today,
      );
      expect(m.paid, twd100);
      // 100 + 100 + US$10 (= NT$320).
      expect(m.pending, const Money(10000 * 2 + 32000, Currency.twd));
      expect(m.paidShare, closeTo(100 / 620, 1e-9));
    });

    test('nothing due: share is zero', () {
      final m = computeMonthCharges(
        items,
        const [],
        fx: fx,
        main: Currency.twd,
        today: today,
      );
      expect(m.paidShare, 0);
    });
  });
}
