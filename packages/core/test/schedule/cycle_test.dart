import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  group('dateAt', () {
    test('monthly anchored on the 31st keeps returning to the 31st', () {
      final anchor = d('2026-01-31');
      final dates = [
        for (var k = 0; k < 6; k++) Cycle.monthly.dateAt(anchor, k),
      ];
      expect(dates, [
        d('2026-01-31'),
        d('2026-02-28'),
        d('2026-03-31'),
        d('2026-04-30'),
        d('2026-05-31'),
        d('2026-06-30'),
      ]);
    });

    test('monthly anchored on the 30th in a leap year', () {
      final anchor = d('2028-01-30');
      expect(Cycle.monthly.dateAt(anchor, 1), d('2028-02-29'));
      expect(Cycle.monthly.dateAt(anchor, 2), d('2028-03-30'));
    });

    test('bimonthly, quarterly, half-yearly', () {
      final anchor = d('2026-08-31');
      expect(Cycle.bimonthly.dateAt(anchor, 1), d('2026-10-31'));
      expect(Cycle.bimonthly.dateAt(anchor, 3), d('2027-02-28'));
      expect(Cycle.quarterly.dateAt(anchor, 1), d('2026-11-30'));
      expect(Cycle.halfYearly.dateAt(anchor, 1), d('2027-02-28'));
      expect(Cycle.halfYearly.dateAt(anchor, 2), d('2027-08-31'));
    });

    test('yearly from Feb 29', () {
      final anchor = d('2024-02-29');
      expect(Cycle.yearly.dateAt(anchor, 1), d('2025-02-28'));
      expect(Cycle.yearly.dateAt(anchor, 4), d('2028-02-29'));
    });

    test('daily, weekly and custom intervals', () {
      final anchor = d('2026-12-30');
      expect(Cycle.daily.dateAt(anchor, 3), d('2027-01-02'));
      expect(Cycle.weekly.dateAt(anchor, 1), d('2027-01-06'));
      expect(Cycle(CycleUnit.day, 10).dateAt(anchor, 2), d('2027-01-19'));
      expect(Cycle(CycleUnit.week, 2).dateAt(anchor, 2), d('2027-01-27'));
      expect(Cycle(CycleUnit.month, 4).dateAt(anchor, 1), d('2027-04-30'));
      expect(Cycle(CycleUnit.year, 2).dateAt(anchor, 1), d('2028-12-30'));
    });

    test('custom interval must be at least 1', () {
      expect(() => Cycle(CycleUnit.month, 0), throwsArgumentError);
    });
  });

  group('firstIndexOnOrAfter', () {
    final cycles = [
      Cycle.daily,
      Cycle.weekly,
      Cycle.monthly,
      Cycle.bimonthly,
      Cycle.quarterly,
      Cycle.yearly,
      Cycle(CycleUnit.day, 9),
      Cycle(CycleUnit.week, 3),
      Cycle(CycleUnit.month, 5),
    ];
    final anchors = [d('2024-01-31'), d('2024-02-29'), d('2026-03-15')];

    test('agrees with a brute-force scan', () {
      for (final cycle in cycles) {
        for (final anchor in anchors) {
          for (var offset = -3; offset < 800; offset += 7) {
            final target = anchor.addDays(offset);
            var expected = 0;
            while (cycle.dateAt(anchor, expected) < target) {
              expected++;
            }
            expect(
              cycle.firstIndexOnOrAfter(anchor, target),
              expected,
              reason: '$cycle from $anchor to $target',
            );
          }
        }
      }
    });

    test('exact due date maps to that charge', () {
      expect(
        Cycle.monthly.firstIndexOnOrAfter(d('2026-01-31'), d('2026-02-28')),
        1,
      );
      expect(
        Cycle.monthly.firstIndexOnOrAfter(d('2026-01-31'), d('2026-03-01')),
        2,
      );
    });
  });

  group('monthlyEquivalent', () {
    test('per unit', () {
      expect(
        Cycle.monthly.monthlyEquivalent(const Money(390, Currency.twd)).minor,
        390,
      );
      expect(
        Cycle.yearly.monthlyEquivalent(const Money(1200, Currency.usd)).minor,
        100,
      );
      expect(
        Cycle.quarterly.monthlyEquivalent(const Money(900, Currency.usd)).minor,
        300,
      );
      // 100/week × 365.2425/7/12 = 434.8
      expect(
        Cycle.weekly.monthlyEquivalent(const Money(100, Currency.usd)).minor,
        435,
      );
      // 10/day × 30.436875
      expect(
        Cycle.daily.monthlyEquivalent(const Money(10, Currency.usd)).minor,
        304,
      );
    });

    test('rounds ties to even', () {
      // 18/12 = 1.5 → 2, 30/12 = 2.5 → 2
      expect(
        Cycle.yearly.monthlyEquivalent(const Money(18, Currency.jpy)).minor,
        2,
      );
      expect(
        Cycle.yearly.monthlyEquivalent(const Money(30, Currency.jpy)).minor,
        2,
      );
    });

    test('large amounts do not overflow', () {
      const big = Money(1000000000000, Currency.idr); // 10 billion rupiah
      expect(Cycle.daily.monthlyEquivalent(big).minor, 30436875000000);
    });
  });
}
