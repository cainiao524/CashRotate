import 'dart:math' as math;

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../../features.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../home/fixed_summary.dart';
import '../items/labels.dart';
import '../payments/payments_page.dart' show exportPaymentsCsv;
import 'report_data.dart';

/// Charts (CLAUDE.md item 11): this month, the last 12 months, the category
/// ranking and price changes; a month calendar and a year calendar of
/// payment days; and the CSV export of payment records.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  late final LocalDate _today = todayFrom(ref.read(clockProvider));
  late LocalDate _month = LocalDate(_today.year, _today.month, 1);
  late int _year = _today.year;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            key: const Key('reports-export'),
            tooltip: l10n.reportsExportCsv,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => exportPaymentsCsv(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              key: const Key('reports-tab-overview'),
              text: l10n.reportsOverview,
            ),
            Tab(key: const Key('reports-tab-month'), text: l10n.reportsMonth),
            Tab(key: const Key('reports-tab-year'), text: l10n.reportsYear),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _Overview(),
          _MonthCalendar(
            month: _month,
            today: _today,
            onMonth: (m) => setState(() => _month = m),
          ),
          _YearCalendar(
            year: _year,
            today: _today,
            onYear: (y) => setState(() => _year = y),
            onMonth: (m) => setState(() {
              _month = m;
              _tabs.animateTo(1);
            }),
          ),
        ],
      ),
    );
  }
}

// --- overview -----------------------------------------------------------------

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sections = [
          const _ThisMonth(),
          _Section(title: l10n.reportsLast12, child: const MonthBars()),
          _Section(
            title: l10n.reportsByCategory,
            child: Features.costConversion
                ? const _CategoryPeriods()
                : const CategoryBars(),
          ),
          _Section(
            title: l10n.reportsPriceChanges,
            child: const _PriceChanges(),
          ),
        ];
        // Two columns of cards on wide windows.
        if (constraints.maxWidth >= 840) {
          return ListView(
            key: const PageStorageKey('reports-overview'),
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < sections.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: sections[i]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: i + 1 < sections.length
                            ? sections[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }
        return ListView.separated(
          key: const PageStorageKey('reports-overview'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, i) => sections[i],
        );
      },
    );
  }
}

/// A flat card with a title.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// This month's fixed spending, paid and to pay, and what is due this week.
class _ThisMonth extends ConsumerWidget {
  const _ThisMonth();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(fixedSummaryProvider).value;
    final month = ref.watch(monthChargesProvider);
    Widget figure(String label, Money? value, Key key) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(color: palette.secondaryText),
          ),
          if (value == null)
            Text('—', style: text.titleMedium)
          else
            MoneyText(value, key: key, style: text.titleMedium),
        ],
      ),
    );
    return _Section(
      title: l10n.homeMonthlyFixedTotal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary == null)
            Text('—', style: text.headlineMedium)
          else
            MoneyText(
              summary.monthlyTotal,
              key: const Key('reports-monthly-total'),
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              figure(l10n.homePaid, month?.paid, const Key('reports-paid')),
              const SizedBox(width: 12),
              figure(
                l10n.homePending,
                month?.pending,
                const Key('reports-pending'),
              ),
            ],
          ),
          if (month != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: month.paidShare,
                minHeight: 6,
                color: palette.primary,
                backgroundColor: palette.selected,
                semanticsLabel: l10n.homePaid,
              ),
            ),
          ],
          if (Features.costConversion && summary != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                for (final p in [CostPeriod.year, CostPeriod.day])
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        p.label(l10n),
                        style: text.bodySmall?.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                      MoneyText(
                        p.of(summary.monthlyTotal),
                        key: ValueKey('reports-total-${p.name}'),
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.obSummaryDueSoon(summary?.dueSoon ?? 0),
            key: const Key('reports-due-soon'),
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Fixed spending of the last 12 months as bars; tap a bar to read its
/// month. Used on the reports page and the tablet home.
class MonthBars extends ConsumerStatefulWidget {
  const MonthBars({super.key, this.height = 140});

  final double height;

  @override
  ConsumerState<MonthBars> createState() => _MonthBarsState();
}

class _MonthBarsState extends ConsumerState<MonthBars> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final months = ref.watch(lastTwelveMonthsProvider);
    if (months == null) return SizedBox(height: widget.height);
    final max = months.fold(0, (m, e) => math.max(m, e.total.minor));
    if (max == 0) {
      return Text(
        l10n.reportsNoData,
        style: text.bodyMedium?.copyWith(color: palette.secondaryText),
      );
    }
    final last = months.length - 1;
    final selected = _selected ?? last;
    final pick = months[selected];
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    String monthName(int year, int month, String pattern) =>
        DateFormat(pattern, locale).format(DateTime(year, month));
    String describe(int i) {
      final m = months[i];
      final amount = hidden
          ? hiddenAmount
          : formatMoney(m.total, locale: locale);
      return '${monthName(m.year, m.month, 'yMMMM')}, $amount';
    }

    void select(int i) {
      if (i != selected) setState(() => _selected = i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              monthName(pick.year, pick.month, 'yMMM'),
              style: text.bodyMedium?.copyWith(color: palette.secondaryText),
            ),
            MoneyText(
              pick.total,
              key: const Key('month-bars-value'),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // One control for the whole chart rather than twelve narrow bars
        // (each under 48dp): tap or drag to pick a month; TalkBack swipes
        // up / down and the arrow keys step through the months.
        Semantics(
          label: l10n.reportsLast12,
          value: describe(selected),
          increasedValue: selected < last ? describe(selected + 1) : null,
          decreasedValue: selected > 0 ? describe(selected - 1) : null,
          onIncrease: selected < last ? () => select(selected + 1) : null,
          onDecrease: selected > 0 ? () => select(selected - 1) : null,
          excludeSemantics: true,
          child: Focus(
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final step = switch (event.logicalKey) {
                LogicalKeyboardKey.arrowRight => 1,
                LogicalKeyboardKey.arrowLeft => -1,
                _ => 0,
              };
              if (step == 0) return KeyEventResult.ignored;
              select((selected + step).clamp(0, last));
              return KeyEventResult.handled;
            },
            child: SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void pickAt(double x) => select(
                    (x / constraints.maxWidth * months.length).floor().clamp(
                      0,
                      last,
                    ),
                  );
                  return GestureDetector(
                    key: const Key('month-bars'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => pickAt(d.localPosition.dx),
                    onHorizontalDragUpdate: (d) => pickAt(d.localPosition.dx),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, m) in months.indexed)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: math.max(
                                          m.total.minor / max,
                                          0.02,
                                        ),
                                        child: Container(
                                          key: ValueKey('month-bar-$i'),
                                          decoration: BoxDecoration(
                                            color: i == selected
                                                ? palette.primary
                                                : palette.outline.withValues(
                                                    alpha: 0.45,
                                                  ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(3),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      monthName(m.year, m.month, 'LLLLL'),
                                      style: text.labelSmall?.copyWith(
                                        color: i == selected
                                            ? palette.text
                                            : palette.secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cost per month, year or day (CLAUDE.md item 18).
enum CostPeriod {
  month,
  year,
  day;

  Money of(Money monthly) => switch (this) {
    CostPeriod.month => monthly,
    CostPeriod.year => yearlyCost(monthly),
    CostPeriod.day => dailyCost(monthly),
  };

  String label(AppLocalizations l10n) => switch (this) {
    CostPeriod.month => l10n.costPerMonth,
    CostPeriod.year => l10n.costPerYear,
    CostPeriod.day => l10n.costPerDay,
  };
}

/// The category ranking with a month / year / day switch.
class _CategoryPeriods extends StatefulWidget {
  const _CategoryPeriods();

  @override
  State<_CategoryPeriods> createState() => _CategoryPeriodsState();
}

class _CategoryPeriodsState extends State<_CategoryPeriods> {
  var _period = CostPeriod.month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips rather than a segmented button: they wrap at large text.
        Wrap(
          key: const Key('category-period'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in CostPeriod.values)
              ChoiceChip(
                key: ValueKey('period-${p.name}'),
                label: Text(p.label(l10n)),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CategoryBars(period: _period),
      ],
    );
  }
}

/// Grey shades for ranked categories, darkest first (CLAUDE.md: charts tell
/// the top five apart by shade and label them directly).
Color rankShade(Palette palette, int rank) {
  const alphas = [1.0, 0.72, 0.52, 0.38, 0.27, 0.18];
  return palette.primary.withValues(alpha: alphas[math.min(rank, 5)]);
}

/// Monthly cost by category: top five and "other", labelled bars.
class CategoryBars extends ConsumerWidget {
  const CategoryBars({super.key, this.limit, this.period = CostPeriod.month});

  /// Show at most this many rows (the tablet card has room for fewer).
  final int? limit;

  /// Amounts per month, year or day.
  final CostPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final ranking = ref.watch(categoryRankingProvider);
    if (ranking == null) return const SizedBox(height: 48);
    if (ranking.isEmpty) {
      return Text(
        l10n.reportsNoData,
        style: text.bodyMedium?.copyWith(color: palette.secondaryText),
      );
    }
    final total = ranking.fold(0, (s, e) => s + e.monthly.minor);
    final rows = limit == null ? ranking : ranking.take(limit!).toList();
    final percent = NumberFormat.percentPattern(intlLocaleOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in rows.indexed)
          Padding(
            key: ValueKey('category-${e.category ?? 'other'}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name and figures share a line when they fit; otherwise
                // the figures move under the name.
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      e.category == null
                          ? l10n.categoryOther
                          : l10n.category(
                              PresetCategory.values.asNameMap()[e.category] ??
                                  PresetCategory.other,
                            ),
                      style: text.bodyMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        MoneyText(period.of(e.monthly), style: text.bodyMedium),
                        Text(
                          percent.format(e.monthly.minor / total),
                          style: tabularFigures(
                            text.bodySmall!.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: e.monthly.minor / ranking.first.monthly.minor,
                    minHeight: 8,
                    color: rankShade(palette, e.category == null ? 5 : i),
                    backgroundColor: palette.selected,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Recorded price changes, newest first: "NT$350 → NT$390, +NT$40 (+11%)".
class _PriceChanges extends ConsumerWidget {
  const _PriceChanges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final history = ref.watch(priceHistoryProvider).value ?? const [];
    final items = ref.watch(itemsProvider).value ?? const [];
    final lines = priceChanges(history, items);
    if (lines.isEmpty) {
      return Text(
        l10n.reportsNoPriceChanges,
        style: text.bodyMedium?.copyWith(color: palette.secondaryText),
      );
    }
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, l) in lines.take(20).indexed)
          Padding(
            key: ValueKey('price-change-$i'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  l.difference.minor >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 20,
                  color: palette.secondaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeText(l.itemName, style: text.bodyMedium),
                      Text(
                        hidden
                            ? hiddenAmount
                            : '${formatMoney(l.from, locale: locale)} → '
                                  '${formatMoney(l.to, locale: locale)}',
                        style: tabularFigures(text.bodyMedium!),
                      ),
                      Text(
                        priceDiffLabel(l10n, l, locale, hidden: hidden),
                        style: tabularFigures(
                          text.bodySmall!.copyWith(
                            color: l.difference.minor > 0
                                ? palette.warning
                                : palette.secondaryText,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd(locale).format(
                          DateTime(
                            l.effectiveOn.year,
                            l.effectiveOn.month,
                            l.effectiveOn.day,
                          ),
                        ),
                        style: text.bodySmall?.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --- calendars ------------------------------------------------------------------

/// Header with previous / next buttons around [title].
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          key: const Key('calendar-previous'),
          tooltip: l10n.reportsPrevious,
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('calendar-next'),
          tooltip: l10n.reportsNext,
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// The first letter of an item name, for calendar badges.
String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? '?'
      : String.fromCharCode(trimmed.runes.first).toUpperCase();
}

class _MonthCalendar extends ConsumerStatefulWidget {
  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.onMonth,
  });

  final LocalDate month;
  final LocalDate today;
  final ValueChanged<LocalDate> onMonth;

  @override
  ConsumerState<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<_MonthCalendar> {
  int? _day;

  @override
  void didUpdateWidget(_MonthCalendar old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _day = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final material = MaterialLocalizations.of(context);
    final month = widget.month;
    final charges = ref.watch(reportChargesProvider).value ?? const [];
    final items = ref.watch(itemsProvider).value ?? const [];
    final fx = ref.watch(fxConverterProvider).value;
    final main = ref.watch(userSettingsProvider).value?.mainCurrency;
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    final byId = {for (final v in items) v.row.id: v};
    final days = chargesByDay(charges, month.year, month.month);
    final first = LocalDate(widget.today.year - 1, 1, 1);
    final last = LocalDate(widget.today.year + 1, 12, 1);
    final compact = NumberFormat.compact(locale: locale);
    final settings = ref.watch(userSettingsProvider).value;
    // Short day totals ("1.2K"), rounded like other amounts of the currency.
    String compactAmount(Money m) {
      final major = m.minor / m.currency.minorPerMajor;
      final decimals =
          settings?.decimalsFor(m.currency) ?? m.currency.minorUnits;
      return compact.format(decimals == 0 ? major.round() : major);
    }

    Money? dayTotal(List<OccurrenceRow> list) {
      if (fx == null || main == null) return null;
      var sum = 0;
      for (final o in list) {
        final v = byId[o.itemId];
        if (v == null || !countsAsSpending(v)) continue;
        sum += myChargeCost(v, o, fx, main)?.minor ?? 0;
      }
      return Money(sum, main);
    }

    final monthTotal = dayTotal([for (final l in days.values) ...l]);
    final cells = monthCells(
      month.year,
      month.month,
      material.firstDayOfWeekIndex,
    );
    final weekdays = [
      for (var i = 0; i < 7; i++)
        material.narrowWeekdays[(material.firstDayOfWeekIndex + i) % 7],
    ];
    final selected = _day == null ? null : days[_day!] ?? const [];

    Widget cell(int? day) {
      if (day == null) return const SizedBox.shrink();
      final list = days[day] ?? const <OccurrenceRow>[];
      final isToday =
          month.year == widget.today.year &&
          month.month == widget.today.month &&
          day == widget.today.day;
      final total = dayTotal(list);
      final label = [
        DateFormat.MMMMd(locale).format(DateTime(month.year, month.month, day)),
        l10n.reportsDayCharges(list.length),
        if (total != null && list.isNotEmpty && !hidden)
          formatMoney(total, locale: locale),
      ].join(', ');
      return Semantics(
        button: true,
        selected: _day == day,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('calendar-day-$day'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _day = day),
          child: Container(
            decoration: BoxDecoration(
              color: _day == day ? palette.selected : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: palette.primary) : null,
            ),
            padding: const EdgeInsets.all(2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$day',
                    style: tabularFigures(
                      text.bodyMedium!.copyWith(
                        fontWeight: list.isEmpty ? null : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (list.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final o in list.take(2))
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(1),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: o.state == OccurrenceState.paid
                                  ? palette.selected
                                  : palette.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initial(byId[o.itemId]?.row.name ?? ''),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: o.state == OccurrenceState.paid
                                    ? palette.text
                                    : palette.onPrimary,
                              ),
                            ),
                          ),
                        if (list.length > 2)
                          Text('+${list.length - 2}', style: text.labelSmall),
                      ],
                    ),
                    if (total != null && total.minor != 0)
                      Text(
                        hidden ? '••' : compactAmount(total),
                        style: tabularFigures(
                          text.labelSmall!.copyWith(
                            color: palette.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      key: const PageStorageKey('reports-month'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
      children: [
        _Stepper(
          title: DateFormat.yMMMM(locale)
              .format(DateTime(month.year, month.month)),
          onPrevious: month <= first
              ? null
              : () => widget.onMonth(month.addMonths(-1)),
          onNext: month >= last
              ? null
              : () => widget.onMonth(month.addMonths(1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                l10n.reportsMonthTotal,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
              if (monthTotal != null)
                MoneyText(
                  monthTotal,
                  key: const Key('calendar-month-total'),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < cells.length; r += 7)
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in cells.sublist(r, r + 7))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: cell(d),
                    ),
                  ),
              ],
            ),
          ),
        if (selected != null) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              DateFormat.MMMMEEEEd(locale)
                  .format(DateTime(month.year, month.month, _day!)),
              style: text.titleSmall,
            ),
          ),
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.reportsDayCharges(0),
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ),
          for (final o in selected)
            if (byId[o.itemId] case final v?) _ChargeRow(view: v, charge: o),
        ],
      ],
    );
  }
}

/// One charge in the month calendar's day list.
class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.view, required this.charge});

  final ItemView view;
  final OccurrenceRow charge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final paid = charge.state == OccurrenceState.paid;
    return ListTile(
      key: ValueKey('calendar-charge-${charge.id}'),
      leading: Icon(
        paid ? Icons.check_circle : Icons.radio_button_unchecked,
        color: paid ? palette.primary : palette.secondaryText,
      ),
      title: MarqueeText(view.row.name),
      subtitle: Text(paid ? l10n.homePaid : l10n.homePending),
      trailing: MoneyText(Money(charge.expectedMinor, charge.currency)),
      onTap: () => context.go(Routes.item(view.row.id)),
    );
  }
}

class _YearCalendar extends ConsumerWidget {
  const _YearCalendar({
    required this.year,
    required this.today,
    required this.onYear,
    required this.onMonth,
  });

  final int year;
  final LocalDate today;
  final ValueChanged<int> onYear;
  final ValueChanged<LocalDate> onMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final material = MaterialLocalizations.of(context);
    final charges = ref.watch(reportChargesProvider).value ?? const [];
    final items = ref.watch(itemsProvider).value ?? const [];
    final fx = ref.watch(fxConverterProvider).value;
    final main = ref.watch(userSettingsProvider).value?.mainCurrency;
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    final totals = fx == null || main == null
        ? null
        : monthsOfYear(items, charges, fx, main, year);
    final max = totals?.fold(0, (m, t) => math.max(m, t.minor)) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        final cards = [
          for (var m = 1; m <= 12; m++)
            _MiniMonth(
              year: year,
              month: m,
              total: totals?[m - 1],
              // Grey depth by month total; text stays the body colour so
              // contrast holds on the darkest shade.
              shade: max == 0
                  ? palette.card
                  : Color.lerp(
                      palette.card,
                      palette.primary,
                      0.04 + 0.2 * totals![m - 1].minor / max,
                    )!,
              chargeDays: chargesByDay(charges, year, m).keys.toSet(),
              firstDayOfWeek: material.firstDayOfWeekIndex,
              isCurrent: year == today.year && m == today.month,
              hidden: hidden,
              onTap: () => onMonth(LocalDate(year, m, 1)),
            ),
        ];
        return ListView(
          key: const PageStorageKey('reports-year'),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          children: [
            _Stepper(
              title: DateFormat.y(locale).format(DateTime(year)),
              onPrevious: year <= today.year - 1
                  ? null
                  : () => onYear(year - 1),
              onNext: year >= today.year + 1 ? null : () => onYear(year + 1),
            ),
            if (totals != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      l10n.reportsYear,
                      style: text.bodyMedium?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                    MoneyText(
                      Money(totals.fold(0, (s, t) => s + t.minor), main!),
                      key: const Key('calendar-year-total'),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            for (var r = 0; r < 12; r += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = r; c < r + columns; c++) ...[
                        if (c > r) const SizedBox(width: 8),
                        Expanded(
                          child: c < 12 ? cards[c] : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One month of the year calendar: name, total and a dot grid of payment
/// days on a grey shade that deepens with the month's total.
class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.total,
    required this.shade,
    required this.chargeDays,
    required this.firstDayOfWeek,
    required this.isCurrent,
    required this.hidden,
    required this.onTap,
  });

  final int year;
  final int month;
  final Money? total;
  final Color shade;
  final Set<int> chargeDays;
  final int firstDayOfWeek;
  final bool isCurrent;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final name = DateFormat.MMMM(locale).format(DateTime(year, month));
    final cells = monthCells(year, month, firstDayOfWeek);
    return Semantics(
      button: true,
      label: [
        DateFormat.yMMMM(locale).format(DateTime(year, month)),
        if (total != null && !hidden) formatMoney(total!, locale: locale),
        l10n.reportsDayCharges(chargeDays.length),
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: shade,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrent ? palette.primary : palette.divider,
          ),
        ),
        child: InkWell(
          key: ValueKey('year-month-$month'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (total != null) MoneyText(total!, style: text.bodySmall),
                const SizedBox(height: 6),
                for (var r = 0; r < cells.length; r += 7)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        for (final d in cells.sublist(r, r + 7))
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: d == null
                                      ? null
                                      : chargeDays.contains(d)
                                      ? palette.text
                                      : palette.text.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
