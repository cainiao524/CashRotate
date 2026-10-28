import 'package:meta/meta.dart';

import '../money/money.dart';
import '../time/local_date.dart';

enum CycleUnit { day, week, month, year }

/// How often a fixed expense recurs: every [every] [unit]s.
///
/// Hourly-billed VPS plans are not a cycle of their own: providers invoice
/// them monthly, so they use [monthly] with an estimated amount and keep the
/// hourly rate in their type-specific fields.
@immutable
final class Cycle {
  const Cycle._(this.unit, this.every);

  factory Cycle(CycleUnit unit, int every) {
    if (every < 1) throw ArgumentError.value(every, 'every', 'must be ≥ 1');
    return Cycle._(unit, every);
  }

  static const daily = Cycle._(CycleUnit.day, 1);
  static const weekly = Cycle._(CycleUnit.week, 1);
  static const monthly = Cycle._(CycleUnit.month, 1);
  static const bimonthly = Cycle._(CycleUnit.month, 2);
  static const quarterly = Cycle._(CycleUnit.month, 3);
  static const halfYearly = Cycle._(CycleUnit.month, 6);
  static const yearly = Cycle._(CycleUnit.year, 1);

  final CycleUnit unit;
  final int every;

  /// Due date of the [index]-th charge (0 = [anchor]).
  ///
  /// Computed from the anchor each time so month-end anchors are kept:
  /// anchored on Jan 31, charges fall on Feb 28/29, Mar 31, Apr 30 …
  LocalDate dateAt(LocalDate anchor, int index) => switch (unit) {
    CycleUnit.day => anchor.addDays(index * every),
    CycleUnit.week => anchor.addDays(index * every * 7),
    CycleUnit.month => anchor.addMonths(index * every),
    CycleUnit.year => anchor.addYears(index * every),
  };

  /// Smallest index ≥ 0 whose due date is on or after [date].
  int firstIndexOnOrAfter(LocalDate anchor, LocalDate date) {
    if (date <= anchor) return 0;
    final days = anchor.daysUntil(date);
    // Estimate from the cycle length (never overshooting), then step forward.
    final approxDays = switch (unit) {
      CycleUnit.day => every,
      CycleUnit.week => every * 7,
      CycleUnit.month => every * 31,
      CycleUnit.year => every * 366,
    };
    var index = days ~/ approxDays;
    while (index > 0 && dateAt(anchor, index - 1) >= date) {
      index--;
    }
    while (dateAt(anchor, index) < date) {
      index++;
    }
    return index;
  }

  /// Average monthly cost of [amount] charged once per cycle.
  ///
  /// Uses the Gregorian average month (146097 days per 4800 months), so a
  /// weekly 100 becomes 435 a month and a yearly 1200 becomes 100.
  Money monthlyEquivalent(Money amount) {
    final (num, den) = switch (unit) {
      // amount per (every × days) → × (146097 / 4800) days per month
      CycleUnit.day => (146097, 4800 * every),
      CycleUnit.week => (146097, 4800 * 7 * every),
      CycleUnit.month => (1, every),
      CycleUnit.year => (1, 12 * every),
    };
    return Money(divideRoundHalfEven(amount.minor * num, den), amount.currency);
  }

  @override
  bool operator ==(Object other) =>
      other is Cycle && other.unit == unit && other.every == every;

  @override
  int get hashCode => Object.hash(unit, every);

  @override
  String toString() => 'Cycle(${unit.name} × $every)';
}
