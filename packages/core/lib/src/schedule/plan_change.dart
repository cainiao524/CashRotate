import 'package:meta/meta.dart';

import '../money/money.dart';
import '../time/local_date.dart';
import 'occurrence_planner.dart';
import 'price_schedule.dart';

/// How a plan change (upgrade or downgrade) is settled (CLAUDE.md item 16).
enum PlanChangeMode {
  /// Switch now and pay the prorated difference for the rest of the paid
  /// period as a one-off charge (e.g. PS Plus upgrades). The new price
  /// applies from the next charge.
  payDifference,

  /// Switch now; the paid time left is converted at the price ratio, which
  /// moves the paid-until date (e.g. Game Pass conversions). The new price
  /// applies from then, and charges follow the new date.
  convertTime,

  /// Keep the current plan until the paid period ends; the new price
  /// applies from the next charge (usual for downgrades).
  atRenewal,
}

/// What a plan change does to the schedule.
@immutable
class PlanChangeResult {
  const PlanChangeResult({
    required this.prices,
    required this.anchor,
    required this.paidUntil,
    this.oneOff,
    this.fromIndex,
  });

  final PriceSchedule prices;
  final LocalDate anchor;
  final LocalDate? paidUntil;

  /// The prorated difference to pay now ([PlanChangeMode.payDifference]).
  final Money? oneOff;

  /// Charge number from which the new price applies (unchanged anchor).
  final int? fromIndex;
}

/// Works out a plan change to [newPrice] taking effect on [on].
///
/// The current paid period runs from the last charge date to paidUntil
/// (the next charge). Charges already made keep their price; history is
/// recorded by the caller.
PlanChangeResult changePlan(
  ItemSchedule s, {
  required Money newPrice,
  required LocalDate on,
  required PlanChangeMode mode,
}) {
  final cycle = s.cycle;
  // The next charge on or after the change (what paidUntil points at).
  final paidUntil = s.paidUntil ?? on;
  final nextIndex = cycle.firstIndexOnOrAfter(
    s.anchor,
    paidUntil > on ? paidUntil : on,
  );
  final nextDate = cycle.dateAt(s.anchor, nextIndex);
  final periodStart = cycle.dateAt(s.anchor, nextIndex - 1);
  final periodDays = periodStart.daysUntil(nextDate).clamp(1, 1 << 20);
  final remaining = on.daysUntil(nextDate).clamp(0, periodDays);
  final oldPrice = s.prices.priceAt(cycle, s.anchor, nextIndex - 1);

  switch (mode) {
    case PlanChangeMode.atRenewal:
      return PlanChangeResult(
        prices: s.prices.changedFrom(cycle, s.anchor, nextIndex, newPrice),
        anchor: s.anchor,
        paidUntil: s.paidUntil,
        fromIndex: nextIndex,
      );
    case PlanChangeMode.payDifference:
      final diff = newPrice.minor - oldPrice.minor;
      final oneOff = diff <= 0
          ? null
          : Money(
              divideRoundHalfEven(diff * remaining, periodDays),
              newPrice.currency,
            );
      return PlanChangeResult(
        prices: s.prices.changedFrom(cycle, s.anchor, nextIndex, newPrice),
        anchor: s.anchor,
        paidUntil: s.paidUntil,
        oneOff: oneOff,
        fromIndex: nextIndex,
      );
    case PlanChangeMode.convertTime:
      // Days left at the old price buy fewer (or more) days at the new one.
      final converted = newPrice.minor <= 0
          ? remaining
          : divideRoundHalfEven(remaining * oldPrice.minor, newPrice.minor);
      final until = on.addDays(converted);
      return PlanChangeResult(
        prices: PriceSchedule.fixed(newPrice),
        anchor: until,
        paidUntil: until,
      );
  }
}
