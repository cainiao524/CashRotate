import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/payments/payment_repository.dart';
import '../../data/providers.dart';

/// "How much a month, what's due soon, what's still to fill in."
class FixedSummary {
  const FixedSummary({
    required this.monthlyTotal,
    required this.missingRates,
    required this.dueSoon,
    required this.needsDetails,
  });

  /// Average monthly cost of active fixed expenses in the main currency.
  final Money monthlyTotal;

  /// Foreign items left out of [monthlyTotal] for lack of an exchange rate.
  final int missingRates;

  /// Pending charges due within 7 days, overdue ones included.
  final int dueSoon;
  final int needsDetails;
}

/// Pure computation, unit-tested. Leaves out regular transfers (not
/// spending), paused or cancelled items, items still to fill in, and game
/// servers running on one of the user's own servers (already counted).
FixedSummary computeFixedSummary(
  List<ItemView> items, {
  required FxConverter fx,
  required Currency main,
  required LocalDate today,
  Map<String, Money?> irregularAverages = const {},
}) {
  var total = Money.zero(main);
  var unknownIrregular = 0;
  var missing = 0;
  var dueSoon = 0;
  final soon = today.addDays(7);
  for (final v in items) {
    final next = v.nextDue;
    if (next != null && next.dueOn <= soon) dueSoon++;
    if (v.row.needsDetails ||
        v.row.status != ItemStatus.active ||
        v.row.type == ItemType.transferOut ||
        v.typeFields['runsOnItemId'] != null) {
      continue;
    }
    final Money monthly;
    if (v.irregular) {
      final average = irregularAverages[v.row.id];
      if (average == null) {
        unknownIrregular++; // no payments yet: "to fill in"
        continue;
      }
      monthly = average;
    } else {
      final perCharge = next == null
          ? v.schedule.prices.stablePrice
          : Money(next.expectedMinor, next.currency);
      // Shared plans count my share only (CLAUDE.md item 4).
      monthly = switch (v.sharingPlan) {
        final plan? => plan.myMonthly(
          perCharge,
          v.schedule.cycle,
          on: next?.dueOn ?? today,
        ),
        null => v.schedule.cycle.monthlyEquivalent(perCharge),
      };
    }
    final converted = fx.convert(monthly, main);
    if (converted == null) {
      missing++;
    } else {
      total += converted.amount;
    }
  }
  return FixedSummary(
    monthlyTotal: total,
    missingRates: missing,
    dueSoon: dueSoon,
    needsDetails:
        items.where((v) => v.row.needsDetails).length + unknownIrregular,
  );
}

/// This month's actual charges: what is paid and what is still to pay
/// (overdue charges from earlier months included).
class MonthCharges {
  const MonthCharges({required this.paid, required this.pending});

  final Money paid;
  final Money pending;

  /// Paid share of the month's charges, 0–1 (0 when nothing is due).
  double get paidShare {
    final all = paid.minor + pending.minor;
    return all == 0 ? 0 : paid.minor / all;
  }
}

/// Pure computation, unit-tested. Counts the same items as
/// [computeFixedSummary]; charges without an exchange rate are left out.
MonthCharges computeMonthCharges(
  List<ItemView> items,
  List<OccurrenceRow> occurrences, {
  required FxConverter fx,
  required Currency main,
  required LocalDate today,
}) {
  final monthStart = LocalDate(today.year, today.month, 1);
  final monthEnd = monthStart.addMonths(1).addDays(-1);
  final counted = {
    for (final v in items)
      if (!v.row.needsDetails &&
          v.row.type != ItemType.transferOut &&
          v.typeFields['runsOnItemId'] == null)
        v.row.id,
  };
  var paid = Money.zero(main);
  var pending = Money.zero(main);
  for (final o in occurrences) {
    if (!counted.contains(o.itemId) || o.dueOn > monthEnd) continue;
    final amount = fx.convert(Money(o.expectedMinor, o.currency), main)?.amount;
    if (amount == null) continue;
    switch (o.state) {
      case OccurrenceState.paid when o.dueOn >= monthStart:
        paid += amount;
      case OccurrenceState.pending:
        pending += amount;
      default:
    }
  }
  return MonthCharges(paid: paid, pending: pending);
}

/// Every payment record, newest first.
final allPaymentsProvider = StreamProvider<List<Payment>>(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);

/// Irregular bills: monthly average of their payments (null before any),
/// and each item's latest payment date.
final irregularStatsProvider =
    Provider<({Map<String, Money?> averages, Map<String, LocalDate> lastPaid})>(
      (ref) {
        final items = ref.watch(itemsProvider).value ?? const [];
        final payments = ref.watch(allPaymentsProvider).value ?? const [];
        final today = todayFrom(ref.watch(clockProvider));
        final byItem = <String, List<Payment>>{};
        for (final p in payments) {
          if (p.row.itemId case final id?) {
            byItem.putIfAbsent(id, () => []).add(p);
          }
        }
        final averages = <String, Money?>{};
        for (final v in items.where((v) => v.irregular)) {
          final currency = v.schedule.prices.stablePrice.currency;
          averages[v.row.id] = irregularMonthly([
            for (final p in byItem[v.row.id] ?? const <Payment>[])
              if ((p.original ?? p.paid).currency == currency)
                (p.paidOn, p.original ?? p.paid),
          ], today: today);
        }
        return (
          averages: averages,
          lastPaid: {
            for (final MapEntry(:key, :value) in byItem.entries)
              key: value.first.paidOn,
          },
        );
      },
    );

final itemsProvider = StreamProvider<List<ItemView>>(
  (ref) => ref.watch(itemRepositoryProvider).watchAll(),
);

final fixedSummaryProvider = Provider<AsyncValue<FixedSummary>>((ref) {
  final items = ref.watch(itemsProvider);
  final fx = ref.watch(fxConverterProvider);
  final settings = ref.watch(userSettingsProvider);
  if (items case AsyncData(:final value)) {
    if (fx case AsyncData(value: final converter)) {
      if (settings case AsyncData(value: final s)) {
        return AsyncData(
          computeFixedSummary(
            value,
            fx: converter,
            main: s.mainCurrency,
            today: todayFrom(ref.watch(clockProvider)),
            irregularAverages: ref.watch(irregularStatsProvider).averages,
          ),
        );
      }
    }
  }
  final error = [
    items,
    fx,
    settings,
  ].whereType<AsyncError<Object?>>().firstOrNull;
  return error == null
      ? const AsyncLoading()
      : AsyncError(error.error, error.stackTrace);
});

/// Charges up to the end of this month, from a year back so overdue ones
/// are included.
final _monthOccurrencesProvider = StreamProvider<List<OccurrenceRow>>((ref) {
  final today = todayFrom(ref.watch(clockProvider));
  final monthEnd = LocalDate(
    today.year,
    today.month,
    1,
  ).addMonths(1).addDays(-1);
  return ref
      .watch(itemRepositoryProvider)
      .watchDue(today.addDays(-366), monthEnd);
});

final monthChargesProvider = Provider<MonthCharges?>((ref) {
  final items = ref.watch(itemsProvider).value;
  final occurrences = ref.watch(_monthOccurrencesProvider).value;
  final fx = ref.watch(fxConverterProvider).value;
  final settings = ref.watch(userSettingsProvider).value;
  if (items == null || occurrences == null || fx == null || settings == null) {
    return null;
  }
  return computeMonthCharges(
    items,
    occurrences,
    fx: fx,
    main: settings.mainCurrency,
    today: todayFrom(ref.watch(clockProvider)),
  );
});
