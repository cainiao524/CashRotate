import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

import '../reminders/reminder_planner_test.dart' show ids, source, today;

/// Repayments with a known number of instalments (CLAUDE.md item 1).
void main() {
  final anchor = LocalDate(2026, 1, 31);
  ItemSchedule loan({LocalDate? paidUntil}) => ItemSchedule(
    anchor: anchor,
    cycle: Cycle.monthly,
    prices: PriceSchedule.fixed(const Money(500000, Currency.twd)),
    paidUntil: paidUntil,
    endsOn: LocalDate(2026, 6, 30), // 6 instalments, month ends
  );

  test('nothing is planned after the last instalment', () {
    final planned = expectedOccurrences(loan(), today: today);
    expect(
      [for (final o in planned) o.dueOn],
      [
        LocalDate(2026, 1, 31),
        LocalDate(2026, 2, 28),
        LocalDate(2026, 3, 31),
        LocalDate(2026, 4, 30),
        LocalDate(2026, 5, 31),
        LocalDate(2026, 6, 30),
      ],
    );
  });

  test('instalments left count the next one; paid off after the last', () {
    final s = loan(paidUntil: LocalDate(2026, 3, 31));
    expect(s.instalmentsLeft(LocalDate(2026, 3, 31)), 4);
    expect(s.instalmentsLeft(LocalDate(2026, 6, 30)), 1);
    expect(s.instalmentsLeft(null), 0);
    expect(s.paidOff, false);
    final done = loan(paidUntil: Cycle.monthly.dateAt(anchor, 6));
    expect(done.paidOff, true);
    expect(expectedOccurrences(done, today: today), isEmpty);
  });

  test('no end: open-ended as before', () {
    final s = ItemSchedule(
      anchor: anchor,
      cycle: Cycle.monthly,
      prices: PriceSchedule.fixed(const Money(100, Currency.twd)),
    );
    expect(s.instalmentsLeft(anchor), isNull);
    expect(s.paidOff, false);
  });

  group('card statement reminders', () {
    test('on the statement day, about the next payment due', () {
      final rs = planReminders([
        source(
          type: ItemType.repayment,
          anchor: LocalDate(2026, 4, 5),
          remindDays: const [],
          typeFields: const {'statementDay': '20'},
        ),
      ], today: today);
      final statements = [
        for (final r in rs)
          if (r.kind == ReminderKind.statement) r,
      ];
      expect(ids(statements), [
        'statement:a:2026-03-20',
        'statement:a:2026-04-20',
      ]);
      expect(statements.first.charge!.dueOn, LocalDate(2026, 4, 5));
      expect(statements.first.daysBefore, 16);
    });

    test('day 31 falls on the month end; not for other types', () {
      final rs = planReminders([
        source(
          type: ItemType.repayment,
          anchor: LocalDate(2026, 4, 10),
          remindDays: const [],
          typeFields: const {'statementDay': 31},
        ),
        source(
          id: 'b',
          remindDays: const [],
          typeFields: const {'statementDay': 20},
        ),
      ], today: today);
      expect(ids(rs), ['statement:a:2026-03-31', 'statement:a:2026-04-30']);
    });
  });
}
