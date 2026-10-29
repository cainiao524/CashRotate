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
}) {
  final schedule = ItemSchedule(
    anchor: due ?? today.addDays(10),
    cycle: cycle,
    prices: PriceSchedule.fixed(price),
    status: status,
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
    note: '',
    needsDetails: needsDetails,
    createdAt: 0,
    updatedAt: 0,
  );
  final next = OccurrenceRow(
    id: '$name:${schedule.anchor}',
    itemId: name,
    cycleIndex: 0,
    dueOn: schedule.anchor,
    expectedMinor: price.minor,
    currency: price.currency,
    state: OccurrenceState.pending,
  );
  return ItemView(row, schedule, next);
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
}
