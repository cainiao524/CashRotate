import 'package:meta/meta.dart';

import '../model/kinds.dart';
import '../money/money.dart';
import '../schedule/occurrence_planner.dart';
import '../schedule/price_schedule.dart';
import '../time/local_date.dart';

/// What a reminder is about.
enum ReminderKind {
  /// A charge is coming up (subscriptions, bills, repayments, fees,
  /// domains and servers alike).
  charge,

  /// A free trial turns into a paid subscription.
  trialEnd,

  /// A bill's contract ends.
  contractEnd,

  /// An insurance policy or annual fee expires.
  policyExpiry,

  /// An unpaid domain's grace period is about to run out.
  graceEnd,

  /// A bill with a varying amount is due: confirm what it came to.
  confirmAmount,

  /// People sharing the cost have not paid their part yet.
  sharedUnpaid,

  /// A card's statement is out (repayments with a statement day): how much
  /// and when it is due.
  statement,
}

/// One pending charge of an item, as stored.
@immutable
class ReminderCharge {
  const ReminderCharge({
    required this.occurrenceId,
    required this.index,
    required this.dueOn,
    required this.expected,
  });

  final String occurrenceId;
  final int index;
  final LocalDate dueOn;
  final Money expected;
}

/// Everything about an item the planner needs.
@immutable
class ReminderSource {
  const ReminderSource({
    required this.itemId,
    required this.type,
    required this.schedule,
    required this.charges,
    this.remindDays = const [3],
    this.typeFields = const {},
    this.sharing,
  });

  final String itemId;
  final ItemType type;
  final ItemSchedule schedule;

  /// Pending charges, soonest first.
  final List<ReminderCharge> charges;

  /// Days before each charge to remind (0 = on the day).
  final List<int> remindDays;
  final Map<String, Object?> typeFields;
  final Map<String, Object?>? sharing;
}

/// A reminder to show on [date] (the time of day is the user's setting).
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.kind,
    required this.itemId,
    required this.date,
    this.charge,
    this.daysBefore = 0,
    this.priceChange,
    this.unpaidPeople = 0,
  });

  final ReminderKind kind;
  final String itemId;
  final LocalDate date;

  /// The charge this is about, for "Paid" on the notification.
  final ReminderCharge? charge;

  /// Days from [date] to the event.
  final int daysBefore;

  /// For the charge right before a price phase ends: "next time X → Y".
  final PriceChange? priceChange;

  /// For [ReminderKind.sharedUnpaid].
  final int unpaidPeople;

  /// Stable across re-planning, so the platform can replace or cancel it.
  String get id => '${kind.name}:$itemId:$date';

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.charge?.occurrenceId == charge?.occurrenceId &&
      other.daysBefore == daysBefore &&
      other.priceChange == priceChange &&
      other.unpaidPeople == unpaidPeople;

  @override
  int get hashCode => Object.hash(id, daysBefore, unpaidPeople);

  @override
  String toString() => 'PlannedReminder($id, $daysBefore days before)';
}

/// How far ahead reminders are handed to the platform. Re-planned every time
/// the app opens and whenever data changes.
const reminderHorizonDays = 60;

/// Days before a contract or policy ends to remind.
const endingRemindDays = [30, 7];

/// Days before a grace period ends to remind.
const graceRemindDays = [3, 1];

/// Days after a charge to remind people who share it and have not paid.
const sharedUnpaidAfterDays = 3;

/// Reminders from [today] through [today] + [horizonDays], soonest first.
///
/// Only active items remind. Dates before [today] are dropped, so an
/// overdue charge does not remind again (the home tile shows it instead),
/// except for its grace period.
List<PlannedReminder> planReminders(
  List<ReminderSource> sources, {
  required LocalDate today,
  int horizonDays = reminderHorizonDays,
}) {
  final last = today.addDays(horizonDays);
  final byId = <String, PlannedReminder>{};
  void add(PlannedReminder r) {
    if (r.date < today || r.date > last) return;
    // One reminder per kind, item and day: the closest event wins.
    final existing = byId[r.id];
    if (existing == null || r.daysBefore < existing.daysBefore) byId[r.id] = r;
  }

  for (final s in sources) {
    if (s.schedule.status != ItemStatus.active) continue;
    final days = {...s.remindDays.where((d) => d >= 0)}.toList()..sort();
    final variable =
        s.type == ItemType.bill && s.typeFields['variableAmount'] == true;

    for (final c in s.charges) {
      final change = s.schedule.prices.changeAfter(
        s.schedule.cycle,
        s.schedule.anchor,
        c.index,
      );
      for (final d in days) {
        add(
          PlannedReminder(
            kind: ReminderKind.charge,
            itemId: s.itemId,
            date: c.dueOn.addDays(-d),
            charge: c,
            daysBefore: d,
            priceChange: change,
          ),
        );
      }
      if (variable) {
        add(
          PlannedReminder(
            kind: ReminderKind.confirmAmount,
            itemId: s.itemId,
            date: c.dueOn,
            charge: c,
          ),
        );
      }
      final people = _unpaidPeople(s.sharing);
      if (people > 0) {
        add(
          PlannedReminder(
            kind: ReminderKind.sharedUnpaid,
            itemId: s.itemId,
            date: c.dueOn.addDays(sharedUnpaidAfterDays),
            charge: c,
            unpaidPeople: people,
          ),
        );
      }
      final grace = _int(s.typeFields['graceDays']);
      if (grace != null && grace > 0) {
        final end = c.dueOn.addDays(grace);
        for (final d in graceRemindDays) {
          add(
            PlannedReminder(
              kind: ReminderKind.graceEnd,
              itemId: s.itemId,
              date: end.addDays(-d),
              charge: c,
              daysBefore: d,
            ),
          );
        }
      }
    }

    void ending(ReminderKind kind, String field, List<int> before) {
      final on = _date(s.typeFields[field]);
      if (on == null) return;
      for (final d in before) {
        add(
          PlannedReminder(
            kind: kind,
            itemId: s.itemId,
            date: on.addDays(-d),
            daysBefore: d,
          ),
        );
      }
    }

    // Card statements: on the statement day each month, about the first
    // charge due after it (the payment due date).
    final statementDay = _int(s.typeFields['statementDay']);
    if (s.type == ItemType.repayment &&
        statementDay != null &&
        statementDay >= 1 &&
        statementDay <= 31) {
      for (
        var month = LocalDate(today.year, today.month, 1);
        month <= last;
        month = month.addMonths(1)
      ) {
        final lastDay = month.addMonths(1).addDays(-1).day;
        final on = LocalDate(
          month.year,
          month.month,
          statementDay > lastDay ? lastDay : statementDay,
        );
        final due = s.charges.where((c) => c.dueOn >= on).firstOrNull;
        if (due == null) continue; // nothing left to pay (or paid off)
        add(
          PlannedReminder(
            kind: ReminderKind.statement,
            itemId: s.itemId,
            date: on,
            charge: due,
            daysBefore: on.daysUntil(due.dueOn),
          ),
        );
      }
    }

    ending(ReminderKind.trialEnd, 'trialEndsOn', days.isEmpty ? [1] : days);
    ending(ReminderKind.contractEnd, 'contractEndsOn', endingRemindDays);
    ending(ReminderKind.policyExpiry, 'expiresOn', endingRemindDays);
  }

  return byId.values.toList()..sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
}

int _unpaidPeople(Map<String, Object?>? sharing) {
  final members = sharing?['members'];
  if (members is! List) return 0;
  return members.where((m) => m is Map && m['paid'] != true).length;
}

int? _int(Object? v) => switch (v) {
  final int i => i,
  final String s => int.tryParse(s.trim()),
  _ => null,
};

LocalDate? _date(Object? v) {
  if (v is! String) return null;
  try {
    return LocalDate.parse(v);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null; // e.g. 2026-02-30
  }
}
