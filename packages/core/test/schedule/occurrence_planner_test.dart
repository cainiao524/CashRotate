import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);
Money twd(int dollars) => Money(dollars * 100, Currency.twd);

ItemSchedule monthly({
  String anchor = '2026-01-31',
  PriceSchedule? prices,
  String? paidUntil,
  ItemStatus status = ItemStatus.active,
  String? statusSince,
}) => ItemSchedule(
  anchor: d(anchor),
  cycle: Cycle.monthly,
  prices: prices ?? PriceSchedule.fixed(twd(390)),
  paidUntil: paidUntil == null ? null : d(paidUntil),
  status: status,
  statusSince: statusSince == null ? null : d(statusSince),
);

List<String> dates(List<PlannedOccurrence> list) => [
  for (final o in list) '${o.dueOn}',
];

StoredOccurrence stored(
  PlannedOccurrence o, {
  OccurrenceState state = OccurrenceState.pending,
  String? id,
}) => StoredOccurrence(
  id: id ?? 'occ-${o.index}',
  index: o.index,
  dueOn: o.dueOn,
  expected: o.expected,
  state: state,
);

void main() {
  final today = d('2026-03-15');

  group('expectedOccurrences', () {
    test('runs from the anchor through 12 months ahead, overdue included', () {
      final list = expectedOccurrences(monthly(), today: today);
      expect(list.first.dueOn, d('2026-01-31'));
      expect(list.last.dueOn, d('2027-02-28'));
      expect(list.last.dueOn <= today.addMonths(12), isTrue);
      expect(list.map((o) => o.index), List.generate(list.length, (i) => i));
    });

    test('month-end anchor never drifts', () {
      final list = expectedOccurrences(monthly(), today: today);
      expect(dates(list).take(5), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
      ]);
    });

    test('starts at paidUntil when it is later than the anchor', () {
      final list = expectedOccurrences(
        monthly(paidUntil: '2026-04-30'),
        today: today,
      );
      expect(list.first.dueOn, d('2026-04-30'));
      expect(list.first.index, 3);
    });

    test('future anchor (trial ends later) starts there', () {
      final list = expectedOccurrences(
        monthly(anchor: '2026-03-22'),
        today: today,
      );
      expect(list.first.dueOn, d('2026-03-22'));
    });

    test('carries phase prices', () {
      final list = expectedOccurrences(
        monthly(
          prices: PriceSchedule.intro(
            intro: twd(0),
            periods: 1,
            renewal: twd(390),
          ),
        ),
        today: today,
      );
      expect(list[0].expected, twd(0));
      expect(list[1].expected, twd(390));
    });

    test('paused: charges due before the pause stay, later ones stop', () {
      final list = expectedOccurrences(
        monthly(status: ItemStatus.paused, statusSince: '2026-03-01'),
        today: today,
      );
      expect(dates(list), ['2026-01-31', '2026-02-28']);
    });

    test('resumed: the paused span is never planned', () {
      final list = expectedOccurrences(
        monthly(statusSince: '2026-05-10'), // active again since May 10
        today: today,
      );
      expect(list.first.dueOn, d('2026-05-31'));
    });

    test('cancelled: nothing at or after the cancellation date', () {
      final list = expectedOccurrences(
        monthly(
          status: ItemStatus.cancelled,
          statusSince: '2026-02-28',
          paidUntil: '2026-02-28',
        ),
        today: today,
      );
      expect(list, isEmpty);
    });

    test('yearly domain, paid three years ahead', () {
      final item = ItemSchedule(
        anchor: d('2025-06-01'),
        cycle: Cycle.yearly,
        prices: PriceSchedule.intro(
          intro: const Money(100, Currency.usd),
          periods: 1,
          renewal: const Money(1500, Currency.usd),
        ),
      );
      final paidUntil = item.paidUntilAfterPaying(0, count: 3);
      expect(paidUntil, d('2028-06-01'));
      expect(
        expectedOccurrences(item.copyWith(paidUntil: paidUntil), today: today),
        isEmpty,
        reason: 'next charge is beyond the 12-month horizon',
      );
      final later = expectedOccurrences(
        item.copyWith(paidUntil: paidUntil),
        today: d('2027-07-01'),
      );
      expect(
        later.single,
        PlannedOccurrence(3, d('2028-06-01'), const Money(1500, Currency.usd)),
      );
    });
  });

  group('isUsableOn: cancelled items stay usable until paidUntil', () {
    final cancelled = monthly(
      status: ItemStatus.cancelled,
      statusSince: '2026-03-10',
      paidUntil: '2026-03-31',
    );

    test(
      'before paidUntil',
      () => expect(cancelled.isUsableOn(d('2026-03-30')), isTrue),
    );
    test(
      'on paidUntil',
      () => expect(cancelled.isUsableOn(d('2026-03-31')), isFalse),
    );
    test('active and paused are usable', () {
      expect(monthly().isUsableOn(today), isTrue);
      expect(monthly(status: ItemStatus.paused).isUsableOn(today), isTrue);
    });
  });

  group('planOccurrences', () {
    test('first run inserts everything', () {
      final plan = planOccurrences(monthly(), const [], today: today);
      expect(plan.toInsert, expectedOccurrences(monthly(), today: today));
      expect(plan.toUpdate, isEmpty);
      expect(plan.toDelete, isEmpty);
    });

    test('second run with nothing changed is empty', () {
      final existing = expectedOccurrences(
        monthly(),
        today: today,
      ).map(stored).toList();
      expect(
        planOccurrences(monthly(), existing, today: today).isEmpty,
        isTrue,
      );
    });

    test('a later "today" only appends', () {
      final existing = expectedOccurrences(
        monthly(),
        today: today,
      ).map(stored).toList();
      final plan = planOccurrences(monthly(), existing, today: d('2026-05-15'));
      expect(dates(plan.toInsert), ['2027-03-31', '2027-04-30']);
      expect(plan.toUpdate, isEmpty);
      expect(plan.toDelete, isEmpty);
    });

    test('price rise updates pending occurrences but never paid ones', () {
      final before = monthly();
      final planned = expectedOccurrences(before, today: today);
      final existing = [
        stored(planned[0], state: OccurrenceState.paid),
        stored(planned[1], state: OccurrenceState.skipped),
        ...planned.skip(2).map(stored),
      ];
      final raised = before.copyWith(
        prices: before.prices.changedFrom(
          before.cycle,
          before.anchor,
          2,
          twd(420),
        ),
      );
      final plan = planOccurrences(raised, existing, today: today);
      expect(plan.toInsert, isEmpty);
      expect(plan.toDelete, isEmpty);
      expect(plan.toUpdate.keys, containsAll(['occ-2', 'occ-3']));
      expect(plan.toUpdate.keys, isNot(contains('occ-0')));
      expect(plan.toUpdate.keys, isNot(contains('occ-1')));
      expect(plan.toUpdate.values.every((o) => o.expected == twd(420)), isTrue);
    });

    test(
      'pausing deletes future pending occurrences, keeps overdue and paid',
      () {
        final planned = expectedOccurrences(monthly(), today: today);
        final existing = [
          stored(planned[0], state: OccurrenceState.paid),
          ...planned.skip(1).map(stored),
        ];
        final plan = planOccurrences(
          monthly(status: ItemStatus.paused, statusSince: '2026-03-15'),
          existing,
          today: today,
        );
        // Feb 28 is overdue and stays; Mar 31 onward goes.
        expect(plan.toDelete, isNot(contains('occ-1')));
        expect(plan.toDelete.first, 'occ-2');
        expect(plan.toDelete, hasLength(planned.length - 2));
        expect(plan.toInsert, isEmpty);
      },
    );

    test('paying ahead removes the covered pending occurrences', () {
      final item = monthly();
      final planned = expectedOccurrences(item, today: today);
      final existing = planned.map(stored).toList();
      // Pay charge #2 for 3 months at once: #3 and #4 are no longer due.
      final paid = [
        for (final s in existing)
          s.index == 2
              ? StoredOccurrence(
                  id: s.id,
                  index: s.index,
                  dueOn: s.dueOn,
                  expected: s.expected,
                  state: OccurrenceState.paid,
                )
              : s,
      ];
      final plan = planOccurrences(
        item.copyWith(paidUntil: item.paidUntilAfterPaying(2, count: 3)),
        paid,
        today: today,
      );
      expect(plan.toDelete, containsAll(['occ-0', 'occ-1', 'occ-3', 'occ-4']));
      expect(plan.toDelete, isNot(contains('occ-2')));
      expect(plan.toDelete, isNot(contains('occ-5')));
    });

    test('changing the anchor day moves pending dates', () {
      final existing = expectedOccurrences(
        monthly(),
        today: today,
      ).map(stored).toList();
      final plan = planOccurrences(
        monthly(anchor: '2026-01-15'),
        existing,
        today: today,
      );
      expect(plan.toUpdate['occ-1']!.dueOn, d('2026-02-15'));
    });

    test('inserts are sorted by index', () {
      final plan = planOccurrences(monthly(), const [], today: today);
      final indexes = plan.toInsert.map((o) => o.index).toList();
      expect(indexes, [...indexes]..sort());
    });
  });
}
