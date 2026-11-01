import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

final today = LocalDate(2026, 3, 15);
const twd = Money(39000, Currency.twd);

ReminderSource source({
  String id = 'a',
  ItemType type = ItemType.subscription,
  ItemStatus status = ItemStatus.active,
  LocalDate? anchor,
  Cycle cycle = Cycle.monthly,
  PriceSchedule? prices,
  List<int> remindDays = const [3],
  Map<String, Object?> typeFields = const {},
  Map<String, Object?>? sharing,
  int charges = 3,
}) {
  final a = anchor ?? LocalDate(2026, 3, 20);
  final p = prices ?? PriceSchedule.fixed(twd);
  return ReminderSource(
    itemId: id,
    type: type,
    schedule: ItemSchedule(anchor: a, cycle: cycle, prices: p, status: status),
    charges: [
      for (var k = 0; k < charges; k++)
        ReminderCharge(
          occurrenceId: '$id:${cycle.dateAt(a, k)}',
          index: k,
          dueOn: cycle.dateAt(a, k),
          expected: p.priceAt(cycle, a, k),
        ),
    ],
    remindDays: remindDays,
    typeFields: typeFields,
    sharing: sharing,
  );
}

List<String> ids(List<PlannedReminder> rs) => [for (final r in rs) r.id];

void main() {
  test('each charge reminds the chosen days before, soonest first', () {
    final rs = planReminders([
      source(remindDays: [3, 0]),
    ], today: today);
    expect(ids(rs), [
      'charge:a:2026-03-17',
      'charge:a:2026-03-20',
      'charge:a:2026-04-17',
      'charge:a:2026-04-20',
      // 17 May is past the 60-day horizon (14 May).
    ]);
    expect(rs.first.daysBefore, 3);
    expect(rs.first.charge!.occurrenceId, 'a:2026-03-20');
    expect(rs[1].daysBefore, 0);
  });

  test('dates already past are dropped; the horizon is 60 days', () {
    final rs = planReminders([
      source(anchor: LocalDate(2026, 3, 16), remindDays: [3]),
    ], today: today);
    // 13 March is past; 13 April and 13 May (inside 14 May) are kept.
    expect(ids(rs), ['charge:a:2026-04-13', 'charge:a:2026-05-13']);
  });

  test('paused and cancelled items stay quiet', () {
    expect(
      planReminders([
        source(status: ItemStatus.paused),
        source(id: 'b', status: ItemStatus.cancelled),
      ], today: today),
      isEmpty,
    );
  });

  test('the charge before a price change says "next time X → Y"', () {
    final rs = planReminders([
      source(
        prices: PriceSchedule.intro(
          intro: const Money(100, Currency.usd),
          periods: 1,
          renewal: const Money(1500, Currency.usd),
        ),
      ),
    ], today: today);
    expect(rs.first.priceChange, (
      from: const Money(100, Currency.usd),
      to: const Money(1500, Currency.usd),
    ));
    expect(rs[1].priceChange, isNull);
  });

  test('trial end uses the item\'s reminder days', () {
    final rs = planReminders([
      source(
        charges: 0,
        remindDays: [3, 1],
        typeFields: {'trialEndsOn': '2026-03-25'},
      ),
    ], today: today);
    expect(ids(rs), ['trialEnd:a:2026-03-22', 'trialEnd:a:2026-03-24']);
  });

  test('contract end and policy expiry: 30 and 7 days before', () {
    final rs = planReminders([
      source(
        type: ItemType.bill,
        charges: 0,
        typeFields: {'contractEndsOn': '2026-04-30'},
      ),
      source(
        id: 'p',
        type: ItemType.insuranceAndFees,
        charges: 0,
        typeFields: {'expiresOn': '2026-04-20'},
      ),
    ], today: today);
    expect(ids(rs), [
      'policyExpiry:p:2026-03-21',
      'contractEnd:a:2026-03-31',
      'policyExpiry:p:2026-04-13',
      'contractEnd:a:2026-04-23',
    ]);
  });

  test('a varying bill asks to confirm its amount on the due day', () {
    final rs = planReminders([
      source(
        type: ItemType.bill,
        charges: 1,
        remindDays: const [],
        typeFields: {'variableAmount': true},
      ),
    ], today: today);
    expect(ids(rs), ['confirmAmount:a:2026-03-20']);
  });

  test('an overdue domain reminds before its grace period ends', () {
    final rs = planReminders([
      source(
        anchor: LocalDate(2026, 3, 10),
        cycle: Cycle.yearly,
        charges: 1,
        typeFields: {'graceDays': '30'},
      ),
    ], today: today);
    // Due 10 March (overdue), grace until 9 April.
    expect(ids(rs), ['graceEnd:a:2026-04-06', 'graceEnd:a:2026-04-08']);
  });

  test('unpaid sharers are reminded three days after each charge', () {
    final rs = planReminders([
      source(
        charges: 1,
        remindDays: const [],
        sharing: {
          'people': 3,
          'members': [
            {'name': 'Amy', 'paid': true},
            {'name': 'Ben', 'paid': false},
            {'name': 'Cat'},
          ],
        },
      ),
    ], today: today);
    expect(ids(rs), ['sharedUnpaid:a:2026-03-23']);
    expect(rs.single.unpaidPeople, 2);
  });

  test('two charges on one day (weekly with several reminder days) '
      'keep the closer one', () {
    final rs = planReminders([
      source(
        cycle: Cycle(CycleUnit.week, 1),
        anchor: LocalDate(2026, 3, 17),
        remindDays: [0, 7],
        charges: 2,
      ),
    ], today: today);
    final on24 = rs.singleWhere((r) => r.date == LocalDate(2026, 3, 24));
    expect(on24.daysBefore, 0);
  });

  test('bad dates in fields are ignored, not fatal', () {
    expect(
      planReminders([
        source(
          charges: 0,
          typeFields: {'trialEndsOn': '2026-02-30', 'expiresOn': 'soon'},
        ),
      ], today: today),
      isEmpty,
    );
  });

  test('ids are stable across re-planning', () {
    final a = planReminders([source()], today: today);
    final b = planReminders([source()], today: today);
    expect(ids(a), ids(b));
    expect(a, b);
  });
}
