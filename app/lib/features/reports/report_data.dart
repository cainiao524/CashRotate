import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../home/fixed_summary.dart';

/// Items that count as fixed spending in reports: not transfers, not game
/// servers on the user's own server, not still to fill in.
bool countsAsSpending(ItemView v) =>
    v.row.type != ItemType.transferOut &&
    v.typeFields['runsOnItemId'] == null &&
    !v.row.needsDetails;

/// Fixed spending per month for the 12 months up to [today]'s, oldest
/// first: every charge due in the month (paid or not, skipped ones left
/// out), at my share, in the main currency.
List<({int year, int month, Money total})> lastTwelveMonths(
  List<ItemView> items,
  List<OccurrenceRow> charges,
  FxConverter fx,
  Currency main,
  LocalDate today,
) {
  final byId = {
    for (final v in items)
      if (countsAsSpending(v)) v.row.id: v,
  };
  final first = LocalDate(today.year, today.month, 1).addMonths(-11);
  final totals = List.filled(12, 0);
  for (final o in charges) {
    if (o.state == OccurrenceState.skipped) continue;
    final v = byId[o.itemId];
    if (v == null) continue;
    final i = (o.dueOn.year - first.year) * 12 + o.dueOn.month - first.month;
    if (i < 0 || i >= 12) continue;
    totals[i] += myChargeCost(v, o, fx, main)?.minor ?? 0;
  }
  return [
    for (var i = 0; i < 12; i++)
      (
        year: first.addMonths(i).year,
        month: first.addMonths(i).month,
        total: Money(totals[i], main),
      ),
  ];
}

/// Monthly cost by category, largest first; categories past the top
/// [top] are merged into one entry with a null key ("other").
List<({String? category, Money monthly})> byCategory(
  List<ItemView> items,
  Map<String, Money> monthlyCost,
  Currency main, {
  int top = 5,
}) {
  final sums = <String, int>{};
  for (final v in items) {
    if (!countsAsSpending(v) || v.row.status != ItemStatus.active) continue;
    final cost = monthlyCost[v.row.id];
    if (cost == null || cost.minor == 0) continue;
    final key = v.row.categoryId ?? PresetCategory.other.name;
    sums[key] = (sums[key] ?? 0) + cost.minor;
  }
  final sorted = sums.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final rest = sorted.skip(top).fold(0, (s, e) => s + e.value);
  return [
    for (final e in sorted.take(top))
      (category: e.key, monthly: Money(e.value, main)),
    if (rest > 0) (category: null, monthly: Money(rest, main)),
  ];
}

/// Charges per day of a month (pending and paid), for the month calendar.
Map<int, List<OccurrenceRow>> chargesByDay(
  List<OccurrenceRow> charges,
  int year,
  int month,
) {
  final days = <int, List<OccurrenceRow>>{};
  for (final o in charges) {
    if (o.state == OccurrenceState.skipped) continue;
    if (o.dueOn.year == year && o.dueOn.month == month) {
      days.putIfAbsent(o.dueOn.day, () => []).add(o);
    }
  }
  return days;
}

/// Days of [month] laid out in weeks starting on the locale's first day:
/// null for blanks before the 1st and after the last day.
List<int?> monthCells(int year, int month, int firstDayOfWeek) {
  final first = DateTime.utc(year, month);
  // DateTime.weekday: Monday 1 … Sunday 7; firstDayOfWeek: Sunday 0 … 6.
  final lead = (first.weekday % 7 - firstDayOfWeek) % 7;
  final days = LocalDate(year, month, 1).addMonths(1).addDays(-1).day;
  final cells = <int?>[
    ...List.filled(lead, null),
    for (var d = 1; d <= days; d++) d,
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

/// Total charged per month of [year] at my share, for the year calendar.
List<Money> monthsOfYear(
  List<ItemView> items,
  List<OccurrenceRow> charges,
  FxConverter fx,
  Currency main,
  int year,
) {
  final byId = {
    for (final v in items)
      if (countsAsSpending(v)) v.row.id: v,
  };
  final totals = List.filled(12, 0);
  for (final o in charges) {
    if (o.state == OccurrenceState.skipped || o.dueOn.year != year) continue;
    final v = byId[o.itemId];
    if (v == null) continue;
    totals[o.dueOn.month - 1] += myChargeCost(v, o, fx, main)?.minor ?? 0;
  }
  return [for (final t in totals) Money(t, main)];
}

/// A price change for the history list, with the difference ("+NT$40,
/// +10%").
typedef PriceChangeLine = ({
  String itemName,
  LocalDate effectiveOn,
  Money from,
  Money to,
  Money difference,
  double percent,
});

List<PriceChangeLine> priceChanges(
  List<PriceHistoryRow> history,
  List<ItemView> items,
) {
  final names = {for (final v in items) v.row.id: v.row.name};
  return [
    for (final h in history)
      if (names[h.itemId] case final name?)
        (
          itemName: name,
          effectiveOn: h.effectiveOn,
          from: Money(h.oldMinor, h.currency),
          to: Money(h.newMinor, h.currency),
          difference: Money(h.newMinor - h.oldMinor, h.currency),
          percent: h.oldMinor == 0
              ? 0
              : (h.newMinor - h.oldMinor) * 100 / h.oldMinor,
        ),
  ]..sort((a, b) => b.effectiveOn.compareTo(a.effectiveOn));
}

/// Payment records as CSV (UTF-8; Excel opens it with the BOM the caller
/// adds). Columns: date, item, amount, currency, original amount, original
/// currency, rate, payment method, note.
String paymentsCsv(
  List<TransactionRow> payments,
  Map<String, String> itemNames,
  Map<String, String> methodNames,
) {
  String cell(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  String amount(int minor, Currency c) {
    final unit = Money(minor, c);
    return formatAmount(
      unit,
      locale: 'en',
      decimals: c.minorUnits,
    ).replaceAll(',', '');
  }

  final rows = [
    'date,item,amount,currency,original_amount,original_currency,rate,payment_method,note',
    for (final t in payments)
      [
        LocalDate.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(t.occurredAt, isUtc: true),
        ),
        itemNames[t.itemId] ?? '',
        amount(t.amountMinor, t.currency),
        t.currency.code,
        if (t.originalCurrency case final c?)
          amount(t.originalAmountMinor!, c)
        else
          '',
        t.originalCurrency?.code ?? '',
        t.fxRate ?? '',
        methodNames[t.accountId] ?? '',
        t.note,
      ].map(cell).join(','),
  ];
  return '${rows.join('\n')}\n';
}

/// Charges from the start of last year to the end of next year: enough for
/// the 12-month chart and both calendars.
final reportChargesProvider = StreamProvider<List<OccurrenceRow>>((ref) {
  final today = todayFrom(ref.watch(clockProvider));
  return ref
      .watch(itemRepositoryProvider)
      .watchDue(
        LocalDate(today.year - 1, 1, 1),
        LocalDate(today.year + 1, 12, 31),
      );
});

final priceHistoryProvider = StreamProvider<List<PriceHistoryRow>>(
  (ref) => ref.watch(itemRepositoryProvider).watchPriceHistory(),
);

/// Each counted item's monthly cost in the main currency (my share);
/// items without a rate or an irregular average are left out.
final monthlyCostsProvider = Provider<Map<String, Money>>((ref) {
  final items = ref.watch(itemsProvider).value ?? const [];
  final fx = ref.watch(fxConverterProvider).value;
  final main = ref.watch(userSettingsProvider).value?.mainCurrency;
  if (fx == null || main == null) return const {};
  final today = todayFrom(ref.watch(clockProvider));
  final averages = ref.watch(irregularStatsProvider).averages;
  return {
    for (final v in items)
      if (countsAsSpending(v) && v.row.status == ItemStatus.active)
        if (monthlyCostOf(v, today: today, irregularAverage: averages[v.row.id])
            case final cost?)
          if (fx.convert(cost, main) case final converted?)
            v.row.id: converted.amount,
  };
});

/// The 12-month chart's data, or null while loading.
final lastTwelveMonthsProvider =
    Provider<List<({int year, int month, Money total})>?>((ref) {
      final items = ref.watch(itemsProvider).value;
      final charges = ref.watch(reportChargesProvider).value;
      final fx = ref.watch(fxConverterProvider).value;
      final main = ref.watch(userSettingsProvider).value?.mainCurrency;
      if (items == null || charges == null || fx == null || main == null) {
        return null;
      }
      return lastTwelveMonths(
        items,
        charges,
        fx,
        main,
        todayFrom(ref.watch(clockProvider)),
      );
    });

/// The category ranking's data, or null while loading.
final categoryRankingProvider =
    Provider<List<({String? category, Money monthly})>?>((ref) {
      final items = ref.watch(itemsProvider).value;
      final main = ref.watch(userSettingsProvider).value?.mainCurrency;
      if (items == null || main == null) return null;
      return byCategory(items, ref.watch(monthlyCostsProvider), main);
    });
