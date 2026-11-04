import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

/// Exhaustive checks over every anchor day of 2027–2028 (a common and a
/// leap year) and the common cycles: month ends clamp, nothing is skipped
/// or repeated, and "next charge on or after" agrees with the dates.
void main() {
  int lastDay(int year, int month) =>
      LocalDate(year, month, 1).addMonths(1).addDays(-1).day;

  final anchors = [
    for (
      var d = LocalDate(2027, 1, 1);
      d < LocalDate(2029, 1, 1);
      d = d.addDays(1)
    )
      d,
  ];

  for (final (name, cycle, months) in [
    ('monthly', Cycle.monthly, 1),
    ('bimonthly', Cycle.bimonthly, 2),
    ('quarterly', Cycle.quarterly, 3),
    ('half-yearly', Cycle.halfYearly, 6),
    ('yearly', Cycle.yearly, 12),
    ('every 5 months', Cycle(CycleUnit.month, 5), 5),
  ]) {
    test('$name: each charge is on the anchor day or the month end', () {
      for (final anchor in anchors) {
        for (var i = 0; i < 40; i++) {
          final due = cycle.dateAt(anchor, i);
          final target = LocalDate(
            anchor.year,
            anchor.month,
            1,
          ).addMonths(i * months);
          expect((due.year, due.month), (target.year, target.month));
          expect(
            due.day,
            anchor.day.clamp(1, lastDay(due.year, due.month)),
            reason: '$anchor #$i',
          );
        }
      }
    });
  }

  test('next charge on or after a date matches the charge dates', () {
    for (final cycle in [
      Cycle.monthly,
      Cycle.quarterly,
      Cycle.yearly,
      Cycle.weekly,
      Cycle(CycleUnit.day, 10),
    ]) {
      for (final anchor in anchors.where((d) => d.day >= 27 || d.day == 1)) {
        for (var offset = 0; offset < 800; offset += 13) {
          final date = anchor.addDays(offset);
          final i = cycle.firstIndexOnOrAfter(anchor, date);
          expect(cycle.dateAt(anchor, i) >= date, true);
          if (i > 0) expect(cycle.dateAt(anchor, i - 1) < date, true);
        }
      }
    }
  });

  test(
    'Feb 29 anchors: Feb 28 in common years, back to the 29th in leap years',
    () {
      final anchor = LocalDate(2028, 2, 29);
      expect(Cycle.yearly.dateAt(anchor, 1), LocalDate(2029, 2, 28));
      expect(Cycle.yearly.dateAt(anchor, 4), LocalDate(2032, 2, 29));
      expect(Cycle.monthly.dateAt(anchor, 1), LocalDate(2028, 3, 29));
    },
  );
}
