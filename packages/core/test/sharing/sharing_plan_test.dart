import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  final today = LocalDate(2026, 11, 2);
  Money twd(int d) => Money(d * 100, Currency.twd);
  Money usd(int c) => Money(c, Currency.usd);

  test('older items read as an organizer splitting equally', () {
    final plan = SharingPlan.fromJson({
      'people': 4,
      'myShare': 9750,
      'members': <Object?>[],
    }, Currency.twd);
    expect(plan.role, SharingRole.organizer);
    expect(plan.members, hasLength(3));
    expect(plan.myCost(twd(390), dueOn: today), const Money(9750, Currency.twd));
  });

  test('a member pays the organizer: the item price is my cost', () {
    const plan = SharingPlan(role: SharingRole.member, payee: 'Amy');
    expect(plan.myCost(twd(150), dueOn: today), twd(150));
  });

  test('equal split counts members only while they are in', () {
    final plan = SharingPlan(
      members: [
        const SharingMemberPlan(name: 'Amy'),
        SharingMemberPlan(name: 'Ben', joinedOn: LocalDate(2026, 12, 1)),
        SharingMemberPlan(name: 'Cat', leftOn: LocalDate(2026, 11, 1)),
      ],
    );
    // November: me and Amy. December: Ben joins.
    expect(plan.myCost(twd(400), dueOn: today), twd(200));
    expect(
      plan.myCost(twd(400), dueOn: LocalDate(2026, 12, 2)),
      const Money(13333, Currency.twd),
    );
  });

  test('custom shares, a free seat, and following a price rise', () {
    final plan = SharingPlan(
      split: SharingSplit.custom,
      myShare: twd(250),
      basePriceMinor: twd(390).minor,
      members: [
        SharingMemberPlan(name: 'Mum', share: twd(0)),
        SharingMemberPlan(name: 'Amy', share: twd(140)),
      ],
    );
    expect(plan.myCost(twd(390), dueOn: today), twd(250));
    // 390 → 468 (+20%): shares follow.
    expect(plan.myCost(twd(468), dueOn: today), twd(300));
    expect(plan.memberShare(plan.members[1], twd(468), today), twd(168));
    expect(
      plan.owedBy(plan.members[0], twd(390), [today], today),
      isNull,
      reason: 'a free seat owes nothing',
    );
    final fixed = SharingPlan(
      split: SharingSplit.custom,
      myShare: twd(250),
      basePriceMinor: twd(390).minor,
      followPrice: false,
    );
    expect(fixed.myCost(twd(468), dueOn: today), twd(250));
  });

  test('a member paying in another currency keeps their own amount', () {
    final plan = SharingPlan(
      split: SharingSplit.custom,
      myShare: usd(1000),
      basePriceMinor: 2000,
      members: [SharingMemberPlan(name: 'Amy', share: twd(330))],
    );
    expect(plan.memberShare(plan.members[0], usd(2400), today), twd(330));
  });

  test('a member paying a year ahead owes nothing until it runs out', () {
    final plan = SharingPlan(
      members: [
        SharingMemberPlan(name: 'Amy', paidUntil: LocalDate(2027, 9, 1)),
        SharingMemberPlan(name: 'Ben', paidUntil: LocalDate(2026, 9, 1)),
      ],
    );
    final due = [
      LocalDate(2026, 9, 1),
      LocalDate(2026, 10, 1),
      LocalDate(2026, 11, 1),
    ];
    expect(plan.owedBy(plan.members[0], twd(300), due, today), isNull);
    // Ben: September, October and November at NT$100 each.
    expect(plan.owedBy(plan.members[1], twd(300), due, today), twd(300));
  });

  test('rotating payer: whose turn, and my average cost', () {
    const plan = SharingPlan(
      split: SharingSplit.rotating,
      members: [
        SharingMemberPlan(name: 'Amy'),
        SharingMemberPlan(name: 'Ben'),
      ],
    );
    expect(plan.myTurn(0), isTrue);
    expect(plan.payerOf(1), 'Amy');
    expect(plan.payerOf(2), 'Ben');
    expect(plan.myTurn(3), isTrue);
    expect(plan.myCost(twd(300), dueOn: today, index: 1), twd(0));
    expect(plan.myMonthly(twd(300), Cycle.monthly, on: today), twd(100));
  });

  test('round trip through JSON', () {
    final plan = SharingPlan(
      role: SharingRole.organizer,
      split: SharingSplit.custom,
      myShare: twd(250),
      basePriceMinor: 39000,
      members: [
        SharingMemberPlan(
          name: 'Amy',
          share: twd(140),
          paidUntil: LocalDate(2026, 12, 1),
          joinedOn: LocalDate(2026, 1, 1),
        ),
      ],
    );
    final back = SharingPlan.fromJson(plan.toJson(), Currency.twd);
    expect(back.toJson(), plan.toJson());
  });
}
