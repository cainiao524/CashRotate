import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);
Money usd(int cents) => Money(cents, Currency.usd);
Money twd(int dollars) => Money(dollars * 100, Currency.twd);

List<Money> prices(PriceSchedule s, Cycle c, LocalDate anchor, int n) => [
  for (var k = 0; k < n; k++) s.priceAt(c, anchor, k),
];

void main() {
  final anchor = d('2026-01-31');

  group('validation', () {
    test('needs at least one phase and exactly one open-ended last phase', () {
      expect(() => PriceSchedule([]), throwsArgumentError);
      expect(
        () => PriceSchedule([PricePhase(usd(100), const ForPeriods(1))]),
        throwsArgumentError,
      );
      expect(
        () => PriceSchedule([
          PricePhase(usd(100), const OpenEnded()),
          PricePhase(usd(200), const OpenEnded()),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects empty periods, mixed currencies and negative prices', () {
      expect(
        () => PriceSchedule.intro(intro: usd(1), periods: 0, renewal: usd(2)),
        throwsArgumentError,
      );
      expect(
        () => PriceSchedule.intro(intro: usd(1), periods: 1, renewal: twd(2)),
        throwsArgumentError,
      );
      expect(() => PriceSchedule.fixed(usd(-1)), throwsArgumentError);
    });

    test('zero is a valid price (free trial)', () {
      expect(PriceSchedule.fixed(usd(0)).stablePrice, usd(0));
    });
  });

  group('examples from the requirements', () {
    test('.com domain: first year 1, then 15 a year', () {
      final s = PriceSchedule.intro(
        intro: usd(100),
        periods: 1,
        renewal: usd(1500),
      );
      expect(prices(s, Cycle.yearly, anchor, 3), [
        usd(100),
        usd(1500),
        usd(1500),
      ]);
      expect(s.stablePrice, usd(1500));
    });

    test('VPS: 3 months at 5, then 8', () {
      final s = PriceSchedule.intro(
        intro: usd(500),
        periods: 3,
        renewal: usd(800),
      );
      expect(prices(s, Cycle.monthly, anchor, 5), [
        usd(500),
        usd(500),
        usd(500),
        usd(800),
        usd(800),
      ]);
    });

    test('streaming: first month free, then 390', () {
      final s = PriceSchedule.intro(
        intro: twd(0),
        periods: 1,
        renewal: twd(390),
      );
      expect(prices(s, Cycle.monthly, anchor, 2), [twd(0), twd(390)]);
    });

    test('telecom contract: 24 months at 499, then 599', () {
      final s = PriceSchedule.intro(
        intro: twd(499),
        periods: 24,
        renewal: twd(599),
      );
      expect(s.priceAt(Cycle.monthly, anchor, 23), twd(499));
      expect(s.priceAt(Cycle.monthly, anchor, 24), twd(599));
    });
  });

  group('UntilDate phases', () {
    test('cover charges strictly before the date', () {
      final s = PriceSchedule([
        PricePhase(twd(499), UntilDate(d('2026-04-30'))),
        PricePhase(twd(599), const OpenEnded()),
      ]);
      // Charges: Jan 31, Feb 28, Mar 31, Apr 30, May 31.
      expect(prices(s, Cycle.monthly, anchor, 5), [
        twd(499),
        twd(499),
        twd(499),
        twd(599),
        twd(599),
      ]);
    });

    test('a date before the anchor makes the phase empty', () {
      final s = PriceSchedule([
        PricePhase(twd(1), UntilDate(d('2025-01-01'))),
        PricePhase(twd(2), const OpenEnded()),
      ]);
      expect(s.priceAt(Cycle.monthly, anchor, 0), twd(2));
    });

    test('mixed with ForPeriods', () {
      final s = PriceSchedule([
        PricePhase(twd(0), const ForPeriods(1)),
        PricePhase(twd(100), UntilDate(d('2026-05-01'))),
        PricePhase(twd(200), const OpenEnded()),
      ]);
      expect(prices(s, Cycle.monthly, anchor, 6), [
        twd(0),
        twd(100),
        twd(100),
        twd(100),
        twd(200),
        twd(200),
      ]);
    });
  });

  group('changeAfter: reminder text "next time X → Y"', () {
    final s = PriceSchedule.intro(
      intro: usd(100),
      periods: 1,
      renewal: usd(1500),
    );

    test('flags the charge before the switch only', () {
      expect(s.changeAfter(Cycle.yearly, anchor, 0), (
        from: usd(100),
        to: usd(1500),
      ));
      expect(s.changeAfter(Cycle.yearly, anchor, 1), isNull);
    });
  });

  group('totalFor: paying several cycles at once', () {
    test('sums the actual phase prices', () {
      final s = PriceSchedule.intro(
        intro: usd(100),
        periods: 1,
        renewal: usd(1500),
      );
      expect(s.totalFor(Cycle.yearly, anchor, 0, 3), usd(3100));
      expect(s.totalFor(Cycle.yearly, anchor, 1, 3), usd(4500));
    });
  });

  group('changedFrom: price rise from a given charge', () {
    test('keeps earlier charges, changes this one and every later one', () {
      final s = PriceSchedule.fixed(twd(390));
      final raised = s.changedFrom(Cycle.monthly, anchor, 4, twd(420));
      expect(prices(raised, Cycle.monthly, anchor, 6), [
        twd(390),
        twd(390),
        twd(390),
        twd(390),
        twd(420),
        twd(420),
      ]);
      expect(raised.phases, [
        PricePhase(twd(390), const ForPeriods(4)),
        PricePhase(twd(420), const OpenEnded()),
      ]);
    });

    test('inside an intro phase replaces the planned renewal too', () {
      final s = PriceSchedule.intro(
        intro: usd(500),
        periods: 6,
        renewal: usd(800),
      );
      final raised = s.changedFrom(Cycle.monthly, anchor, 2, usd(600));
      expect(prices(raised, Cycle.monthly, anchor, 8), [
        usd(500),
        usd(500),
        usd(600),
        usd(600),
        usd(600),
        usd(600),
        usd(600),
        usd(600),
      ]);
    });

    test('exactly at a phase boundary keeps the earlier phase intact', () {
      final s = PriceSchedule.intro(
        intro: usd(100),
        periods: 1,
        renewal: usd(1500),
      );
      final raised = s.changedFrom(Cycle.yearly, anchor, 1, usd(1800));
      expect(raised.phases, [
        PricePhase(usd(100), const ForPeriods(1)),
        PricePhase(usd(1800), const OpenEnded()),
      ]);
    });

    test('from the first charge replaces everything', () {
      final s = PriceSchedule.intro(
        intro: usd(100),
        periods: 1,
        renewal: usd(1500),
      );
      expect(
        s.changedFrom(Cycle.yearly, anchor, 0, usd(900)),
        PriceSchedule.fixed(usd(900)),
      );
    });

    test('converts an UntilDate phase it cuts into a period count', () {
      final s = PriceSchedule([
        PricePhase(twd(499), UntilDate(d('2026-12-31'))),
        PricePhase(twd(599), const OpenEnded()),
      ]);
      final raised = s.changedFrom(Cycle.monthly, anchor, 3, twd(450));
      expect(raised.phases.first, PricePhase(twd(499), const ForPeriods(3)));
      expect(raised.priceAt(Cycle.monthly, anchor, 3), twd(450));
    });
  });
}
