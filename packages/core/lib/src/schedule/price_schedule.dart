import 'package:meta/meta.dart';

import '../money/money.dart';
import '../time/local_date.dart';
import 'cycle.dart';

/// How long a [PricePhase] lasts.
sealed class PhaseLength {
  const PhaseLength();
}

/// A fixed number of charges, e.g. "first 3 months at 5".
final class ForPeriods extends PhaseLength {
  const ForPeriods(this.periods);
  final int periods;

  @override
  bool operator ==(Object other) =>
      other is ForPeriods && other.periods == periods;
  @override
  int get hashCode => periods.hashCode;
  @override
  String toString() => 'ForPeriods($periods)';
}

/// Charges due strictly before [date], e.g. a promo ending on a contract date.
final class UntilDate extends PhaseLength {
  const UntilDate(this.date);
  final LocalDate date;

  @override
  bool operator ==(Object other) => other is UntilDate && other.date == date;
  @override
  int get hashCode => date.hashCode;
  @override
  String toString() => 'UntilDate($date)';
}

/// The long-term price. Only the last phase is open-ended.
final class OpenEnded extends PhaseLength {
  const OpenEnded();

  @override
  bool operator ==(Object other) => other is OpenEnded;
  @override
  int get hashCode => 0;
  @override
  String toString() => 'OpenEnded()';
}

@immutable
final class PricePhase {
  const PricePhase(this.amount, this.length);

  /// Price per charge in the item's own currency. Zero for free trials.
  final Money amount;
  final PhaseLength length;

  @override
  bool operator ==(Object other) =>
      other is PricePhase && other.amount == amount && other.length == length;
  @override
  int get hashCode => Object.hash(amount, length);
  @override
  String toString() => 'PricePhase($amount, $length)';
}

/// A price change between two consecutive charges.
typedef PriceChange = ({Money from, Money to});

/// An item's price over time: consecutive phases, the last one open-ended.
///
/// Covers first-year domain prices, introductory VPS discounts, zero-price
/// trial periods, contract promos and announced price rises with one model.
@immutable
final class PriceSchedule {
  PriceSchedule(List<PricePhase> phases) : phases = List.unmodifiable(phases) {
    if (phases.isEmpty) throw ArgumentError('A schedule needs a phase');
    final currency = phases.first.amount.currency;
    for (final (i, phase) in phases.indexed) {
      final isLast = i == phases.length - 1;
      if ((phase.length is OpenEnded) != isLast) {
        throw ArgumentError('Exactly the last phase must be open-ended');
      }
      if (phase.length case ForPeriods(:final periods) when periods < 1) {
        throw ArgumentError('A phase must last at least one period');
      }
      if (phase.amount.currency != currency) {
        throw ArgumentError('All phases must use the same currency');
      }
      if (phase.amount.isNegative) {
        throw ArgumentError('Prices cannot be negative');
      }
    }
  }

  /// One price, forever.
  factory PriceSchedule.fixed(Money amount) =>
      PriceSchedule([PricePhase(amount, const OpenEnded())]);

  /// An introductory price for [periods] charges, then [renewal].
  /// The renewal price is required, so nobody is surprised later.
  factory PriceSchedule.intro({
    required Money intro,
    required int periods,
    required Money renewal,
  }) => PriceSchedule([
    PricePhase(intro, ForPeriods(periods)),
    PricePhase(renewal, const OpenEnded()),
  ]);

  final List<PricePhase> phases;

  /// The long-term price once every promotion has ended.
  Money get stablePrice => phases.last.amount;

  /// Index of the phase that prices charge [index].
  int phaseIndexAt(Cycle cycle, LocalDate anchor, int index) {
    var start = 0;
    for (final (i, phase) in phases.indexed) {
      final end = switch (phase.length) {
        ForPeriods(:final periods) => start + periods,
        UntilDate(:final date) => cycle.firstIndexOnOrAfter(anchor, date),
        OpenEnded() => null,
      };
      if (end == null || index < end) return i;
      if (end > start) start = end;
    }
    return phases.length - 1; // unreachable: the last phase is open-ended
  }

  /// Expected price of the [index]-th charge.
  Money priceAt(Cycle cycle, LocalDate anchor, int index) =>
      phases[phaseIndexAt(cycle, anchor, index)].amount;

  /// Total for paying [count] charges at once starting at [index], e.g.
  /// renewing a domain for three years.
  Money totalFor(Cycle cycle, LocalDate anchor, int index, int count) {
    var total = Money.zero(stablePrice.currency);
    for (var k = index; k < index + count; k++) {
      total += priceAt(cycle, anchor, k);
    }
    return total;
  }

  /// The price change right after charge [index], if any. The reminder for
  /// that charge says "next time this goes from X to Y".
  PriceChange? changeAfter(Cycle cycle, LocalDate anchor, int index) {
    final from = priceAt(cycle, anchor, index);
    final to = priceAt(cycle, anchor, index + 1);
    return from == to ? null : (from: from, to: to);
  }

  /// A new schedule where every charge from [fromIndex] on costs [amount].
  /// Charges before it keep their phases, so history is never rewritten.
  PriceSchedule changedFrom(
    Cycle cycle,
    LocalDate anchor,
    int fromIndex,
    Money amount,
  ) {
    final kept = <PricePhase>[];
    var start = 0;
    for (final phase in phases) {
      if (start >= fromIndex) break;
      final end = switch (phase.length) {
        ForPeriods(:final periods) => start + periods,
        UntilDate(:final date) => cycle.firstIndexOnOrAfter(anchor, date),
        OpenEnded() => null,
      };
      if (end != null && end <= start) continue; // empty phase
      if (end == null || end > fromIndex) {
        kept.add(PricePhase(phase.amount, ForPeriods(fromIndex - start)));
        start = fromIndex;
        break;
      }
      kept.add(phase);
      start = end;
    }
    return PriceSchedule([...kept, PricePhase(amount, const OpenEnded())]);
  }

  @override
  bool operator ==(Object other) =>
      other is PriceSchedule &&
      other.phases.length == phases.length &&
      Iterable<int>.generate(phases.length)
          .every((i) => other.phases[i] == phases[i]);

  @override
  int get hashCode => Object.hashAll(phases);

  @override
  String toString() => 'PriceSchedule($phases)';
}
