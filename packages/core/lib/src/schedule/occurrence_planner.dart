import 'package:meta/meta.dart';

import '../money/money.dart';
import '../time/local_date.dart';
import 'cycle.dart';
import 'price_schedule.dart';

enum ItemStatus { active, paused, cancelled }

enum OccurrenceState { pending, paid, skipped }

/// Everything about an item that decides when it is due and for how much.
@immutable
final class ItemSchedule {
  const ItemSchedule({
    required this.anchor,
    required this.cycle,
    required this.prices,
    this.paidUntil,
    this.status = ItemStatus.active,
    this.statusSince,
    this.irregular = false,
  });

  /// Due date of the first charge; every later date derives from it.
  final LocalDate anchor;
  final Cycle cycle;
  final PriceSchedule prices;

  /// Service is paid up to (not including) this date; the next charge is due
  /// on it. Paying several cycles at once pushes it forward several cycles.
  /// Pending charges before it count as settled and are no longer planned.
  final LocalDate? paidUntil;

  final ItemStatus status;

  /// When the current [status] took effect: the pause or cancellation date,
  /// or the resume date for an item that was paused before. Charges in a
  /// pause are never planned, even after resuming.
  final LocalDate? statusSince;

  /// A bill with no fixed date or amount (API top-ups, auto-reload): no
  /// charges are planned; payments are recorded as they happen.
  final bool irregular;

  /// Still usable on [today]: active, paused, or cancelled but already paid
  /// through a later date.
  bool isUsableOn(LocalDate today) => switch (status) {
    ItemStatus.active || ItemStatus.paused => true,
    ItemStatus.cancelled => paidUntil != null && today < paidUntil!,
  };

  /// [paidUntil] after paying [count] charges starting at charge [index].
  LocalDate paidUntilAfterPaying(int index, {int count = 1}) =>
      cycle.dateAt(anchor, index + count);

  ItemSchedule copyWith({
    LocalDate? anchor,
    Cycle? cycle,
    PriceSchedule? prices,
    LocalDate? paidUntil,
    ItemStatus? status,
    LocalDate? statusSince,
    bool? irregular,
  }) => ItemSchedule(
    anchor: anchor ?? this.anchor,
    cycle: cycle ?? this.cycle,
    prices: prices ?? this.prices,
    paidUntil: paidUntil ?? this.paidUntil,
    status: status ?? this.status,
    statusSince: statusSince ?? this.statusSince,
    irregular: irregular ?? this.irregular,
  );
}

/// One expected charge.
@immutable
final class PlannedOccurrence {
  const PlannedOccurrence(this.index, this.dueOn, this.expected);

  /// Charge number counted from the anchor; stable across re-planning.
  final int index;
  final LocalDate dueOn;
  final Money expected;

  @override
  bool operator ==(Object other) =>
      other is PlannedOccurrence &&
      other.index == index &&
      other.dueOn == dueOn &&
      other.expected == expected;

  @override
  int get hashCode => Object.hash(index, dueOn, expected);

  @override
  String toString() => 'PlannedOccurrence(#$index $dueOn $expected)';
}

/// An occurrence already stored for the item.
@immutable
final class StoredOccurrence {
  const StoredOccurrence({
    required this.id,
    required this.index,
    required this.dueOn,
    required this.expected,
    required this.state,
  });

  final String id;
  final int index;
  final LocalDate dueOn;
  final Money expected;
  final OccurrenceState state;
}

/// Changes that bring the stored occurrences in line with the schedule.
@immutable
final class OccurrencePlan {
  const OccurrencePlan({
    required this.toInsert,
    required this.toUpdate,
    required this.toDelete,
  });

  final List<PlannedOccurrence> toInsert;

  /// Stored id → corrected values.
  final Map<String, PlannedOccurrence> toUpdate;
  final List<String> toDelete;

  bool get isEmpty => toInsert.isEmpty && toUpdate.isEmpty && toDelete.isEmpty;
}

/// How far ahead occurrences are expanded.
const occurrenceHorizonMonths = 12;

/// Expected charges from the first unpaid one through [today] +
/// [horizonMonths]. Overdue charges are included: they stay due until paid
/// or skipped.
List<PlannedOccurrence> expectedOccurrences(
  ItemSchedule item, {
  required LocalDate today,
  int horizonMonths = occurrenceHorizonMonths,
}) {
  if (item.irregular) return const [];
  var from = item.anchor;
  if (item.paidUntil case final paid?) from = LocalDate.max(from, paid);
  final horizon = today.addMonths(horizonMonths);
  LocalDate? stopBefore;
  switch (item.status) {
    case ItemStatus.active:
      if (item.statusSince case final resumed?) {
        from = LocalDate.max(from, resumed);
      }
    case ItemStatus.paused || ItemStatus.cancelled:
      // Charges already due before the pause or cancellation still count.
      stopBefore = item.statusSince ?? today;
  }

  final result = <PlannedOccurrence>[];
  for (var k = item.cycle.firstIndexOnOrAfter(item.anchor, from); ; k++) {
    final due = item.cycle.dateAt(item.anchor, k);
    if (due > horizon) break;
    if (stopBefore != null && due >= stopBefore) break;
    result.add(
      PlannedOccurrence(
        k,
        due,
        item.prices.priceAt(item.cycle, item.anchor, k),
      ),
    );
  }
  return result;
}

/// Reconciles [stored] occurrences with [item]'s schedule.
///
/// Occurrences are identified by due date: an item has at most one charge
/// per day, and dates stay meaningful when the user moves the billing day
/// (charge numbers restart from the new anchor, dates never collide with
/// history). Paid and skipped occurrences are history and are never touched;
/// a date already paid or skipped is not planned again. Pending ones are
/// updated (amount, charge number), removed when no longer expected (paused,
/// cancelled, paid ahead, moved), and missing dates are added.
OccurrencePlan planOccurrences(
  ItemSchedule item,
  List<StoredOccurrence> stored, {
  required LocalDate today,
  int horizonMonths = occurrenceHorizonMonths,
}) {
  final expected = {
    for (final o in expectedOccurrences(
      item,
      today: today,
      horizonMonths: horizonMonths,
    ))
      o.dueOn: o,
  };
  final toUpdate = <String, PlannedOccurrence>{};
  final toDelete = <String>[];

  for (final s in stored) {
    final want = expected.remove(s.dueOn);
    if (s.state != OccurrenceState.pending) continue;
    if (want == null) {
      toDelete.add(s.id);
    } else if (want.index != s.index || want.expected != s.expected) {
      toUpdate[s.id] = want;
    }
  }

  return OccurrencePlan(
    toInsert: expected.values.toList()..sort((a, b) => a.index - b.index),
    toUpdate: toUpdate,
    toDelete: toDelete,
  );
}

/// Average monthly cost of an irregular bill from its [payments] (amounts in
/// the bill's currency): the last 12 months' total divided by the months
/// since the first of them, at least 3 so one top-up is not taken as a
/// monthly cost. Null before any payment, which shows as "to fill in".
Money? irregularMonthly(
  Iterable<(LocalDate, Money)> payments, {
  required LocalDate today,
}) {
  final since = today.addMonths(-12);
  final recent = [
    for (final p in payments)
      if (p.$1 > since && p.$1 <= today) p,
  ];
  if (recent.isEmpty) return null;
  final first = recent.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
  final months =
      ((today.year - first.year) * 12 + today.month - first.month + 1).clamp(
        3,
        12,
      );
  final total = recent.fold(0, (sum, p) => sum + p.$2.minor);
  return Money((total / months).round(), recent.first.$2.currency);
}
