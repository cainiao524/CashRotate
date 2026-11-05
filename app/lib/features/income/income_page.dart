import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers.dart';
import '../../data/settings/settings_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../home/fixed_summary.dart';
import '../items/labels.dart';

extension IncomeLabels on AppLocalizations {
  String incomeTypeName(IncomeType t) => switch (t) {
    IncomeType.salary => incomeTypeSalary,
    IncomeType.bonus => incomeTypeBonus,
    IncomeType.freelance => incomeTypeFreelance,
    IncomeType.business => incomeTypeBusiness,
    IncomeType.rental => incomeTypeRental,
    IncomeType.investment => incomeTypeInvestment,
    IncomeType.pension => incomeTypePension,
    IncomeType.benefits => incomeTypeBenefits,
    IncomeType.allowance => incomeTypeAllowance,
    IncomeType.sales => incomeTypeSales,
    IncomeType.other => incomeTypeOther,
  };
}

/// Cycles offered for income: weekly and fortnightly pay, monthly salary,
/// quarterly dividends, half-yearly and yearly bonuses.
final incomeCycles = [
  Cycle.weekly,
  Cycle(CycleUnit.week, 2),
  Cycle.monthly,
  Cycle.quarterly,
  Cycle.halfYearly,
  Cycle.yearly,
];

/// Monthly income against monthly fixed expenses; null without counted
/// income or while loading.
final incomeComparisonProvider = Provider<IncomeComparison?>((ref) {
  final settings = ref.watch(userSettingsProvider).value;
  final summary = ref.watch(fixedSummaryProvider).value;
  final fx = ref.watch(fxConverterProvider).value;
  if (settings == null || summary == null || fx == null) return null;
  return compareIncome(
    settings.incomes,
    fixedMonthly: summary.monthlyTotal,
    fx: fx,
  );
});

/// "38% of income · NT$31,000 left" (or "over income"), for home and
/// reports.
String incomeShareLine(
  AppLocalizations l10n,
  IncomeComparison c,
  String locale, {
  required bool hidden,
}) {
  final percent = NumberFormat.percentPattern(locale).format(c.share ?? 0);
  final left = c.remaining;
  String money(Money m) =>
      hidden ? hiddenAmount : formatMoney(m, locale: locale);
  return [
    l10n.incomeShare(percent),
    if (left.minor >= 0)
      l10n.incomeRemaining(money(left))
    else
      l10n.incomeOver(money(Money(-left.minor, left.currency))),
  ].join(' · ');
}

/// The settings row that opens [IncomePage].
class IncomeTile extends ConsumerWidget {
  const IncomeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final comparison = ref.watch(incomeComparisonProvider);
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    return ListTile(
      key: const Key('settings-income'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.savings_outlined),
      title: Text(l10n.incomeTitle),
      subtitle: comparison == null
          ? null
          : Text(
              l10n.incomePerMonth(
                hidden
                    ? hiddenAmount
                    : formatMoney(
                        comparison.income,
                        locale: intlLocaleOf(context),
                      ),
              ),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.settingsIncome),
    );
  }
}

/// Every kind of income (salary, bonus, freelance, rent, investments,
/// pension, benefits …), each with its own cycle (CLAUDE.md item 19).
class IncomePage extends ConsumerWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final incomes =
        ref.watch(userSettingsProvider).value?.incomes ??
        const <IncomeSource>[];
    final comparison = ref.watch(incomeComparisonProvider);
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    final locale = intlLocaleOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('income-add'),
        heroTag: null,
        icon: const Icon(Icons.add),
        label: Text(l10n.incomeAdd),
        onPressed: () => showIncomeForm(context),
      ),
      body: ListView(
        key: const PageStorageKey('settings-income'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            l10n.incomeHint,
            style: text.bodyMedium?.copyWith(color: palette.secondaryText),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 16),
            Text(l10n.incomeMonthlyTotal, style: text.labelLarge),
            MoneyText(
              comparison.income,
              key: const Key('income-total'),
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              incomeShareLine(l10n, comparison, locale, hidden: hidden),
              key: const Key('income-share'),
              style: text.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          if (incomes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.incomeEmpty,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ),
          for (final i in incomes)
            ListTile(
              key: ValueKey('income-${i.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                i.countsInShare ? Icons.savings_outlined : Icons.money_off,
                color: i.countsInShare ? null : palette.secondaryText,
              ),
              title: MarqueeText(
                i.name.isEmpty
                    ? l10n.incomeTypeName(i.type)
                    : '${i.name} · ${l10n.incomeTypeName(i.type)}',
              ),
              subtitle: Text(
                [
                  l10n.cycle(i.cycle),
                  if (i.cycle != Cycle.monthly)
                    l10n.incomePerMonth(
                      hidden
                          ? hiddenAmount
                          : formatMoney(i.monthly, locale: locale),
                    ),
                ].join(' · '),
              ),
              trailing: MoneyText(i.amount),
              onTap: () => showIncomeForm(context, income: i),
            ),
        ],
      ),
    );
  }
}

Future<void> showIncomeForm(BuildContext context, {IncomeSource? income}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _IncomeForm(income: income),
    );

class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm({this.income});

  final IncomeSource? income;

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  late IncomeType _type = widget.income?.type ?? IncomeType.salary;
  late Cycle _cycle = widget.income?.cycle ?? Cycle.monthly;
  late bool _counts = widget.income?.countsInShare ?? true;
  late Currency _currency =
      widget.income?.amount.currency ??
      ref.read(userSettingsProvider).value?.mainCurrency ??
      Currency.usd;
  late final _name = TextEditingController(text: widget.income?.name);
  late final _amount = TextEditingController(
    text: widget.income == null
        ? ''
        : formatAmount(
            widget.income!.amount,
            locale: 'en',
            decimals: widget.income!.amount.currency.minorUnits,
          ).replaceAll(',', ''),
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Money? get _money => parseMoney(_amount.text, _currency);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final repo = ref.read(settingsRepositoryProvider);
    final region = ref.read(userSettingsProvider).value?.region ?? 'US';
    final money = _money;

    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(s, style: text.titleSmall),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.income == null ? l10n.incomeAdd : l10n.incomeEdit,
              style: text.titleMedium,
            ),
            label(l10n.incomeType),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in IncomeType.values)
                  ChoiceChip(
                    key: ValueKey('income-type-${t.name}'),
                    label: Text(l10n.incomeTypeName(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      // Sensible defaults for a new source.
                      if (widget.income == null) {
                        _counts = t != IncomeType.sales;
                        if (t == IncomeType.bonus) _cycle = Cycle.yearly;
                        if (t == IncomeType.investment) {
                          _cycle = Cycle.quarterly;
                        }
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('income-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l10n.incomeName),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('income-amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l10n.incomeAmount),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    key: const Key('income-currency'),
                    onPressed: () async {
                      final c = await showCurrencyPicker(
                        context,
                        region: region,
                        selected: _currency,
                      );
                      if (c != null) setState(() => _currency = c);
                    },
                    child: Text(_currency.code),
                  ),
                ),
              ],
            ),
            label(l10n.incomeCycle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in incomeCycles)
                  ChoiceChip(
                    key: ValueKey('income-cycle-${c.unit.name}-${c.every}'),
                    label: Text(l10n.cycle(c)),
                    selected: _cycle == c,
                    onSelected: (_) => setState(() => _cycle = c),
                  ),
              ],
            ),
            if (money != null && _cycle != Cycle.monthly)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.incomePerMonth(
                    formatMoney(
                      _cycle.monthlyEquivalent(money),
                      locale: intlLocaleOf(context),
                    ),
                  ),
                  style: text.bodyMedium?.copyWith(
                    color: palette.secondaryText,
                  ),
                ),
              ),
            SwitchListTile(
              key: const Key('income-counts'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.incomeCountsInShare),
              subtitle: Text(l10n.incomeCountsInShareHint),
              value: _counts,
              onChanged: (v) => setState(() => _counts = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.income != null)
                  TextButton(
                    key: const Key('income-delete'),
                    onPressed: () async {
                      await repo.removeIncome(widget.income!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      l10n.incomeDelete,
                      style: TextStyle(color: palette.error),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('income-save'),
                  onPressed: money == null || money.minor <= 0
                      ? null
                      : () async {
                          await repo.saveIncome(
                            IncomeSource(
                              id: widget.income?.id ?? const Uuid().v4(),
                              type: _type,
                              name: _name.text.trim(),
                              amount: money,
                              cycle: _cycle,
                              countsInShare: _counts,
                            ),
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
