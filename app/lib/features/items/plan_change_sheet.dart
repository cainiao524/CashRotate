import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';

/// Upgrade or downgrade: new plan and price, from when, and how the change
/// is settled (pay the difference now, convert the time left, or at
/// renewal). Shows what it will do before saving.
Future<void> showPlanChangeSheet(BuildContext context, ItemView view) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlanChangeSheet(view: view),
    );

class _PlanChangeSheet extends ConsumerStatefulWidget {
  const _PlanChangeSheet({required this.view});

  final ItemView view;

  @override
  ConsumerState<_PlanChangeSheet> createState() => _PlanChangeSheetState();
}

class _PlanChangeSheetState extends ConsumerState<_PlanChangeSheet> {
  final _price = TextEditingController();
  String? _planId;
  PlanChangeMode? _mode;
  late LocalDate _on = todayFrom(ref.read(clockProvider));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _planId = widget.view.typeFields['plan'] as String?;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Currency get _currency => widget.view.schedule.prices.stablePrice.currency;
  Money get _current => widget.view.schedule.prices.stablePrice;
  Money? get _newPrice => parseMoney(_price.text, _currency);

  /// Upgrades default to paying the difference; downgrades to renewal.
  PlanChangeMode get _effectiveMode =>
      _mode ??
      ((_newPrice?.minor ?? 0) > _current.minor
          ? PlanChangeMode.payDifference
          : PlanChangeMode.atRenewal);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final language = contentLanguageOf(context);
    final preset = ref
        .watch(presetLibraryProvider)
        .value
        ?.byId[widget.view.row.presetId];
    final plans = preset?.plans ?? const <PresetPlan>[];
    String date(LocalDate d) =>
        DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));
    String money(Money m) => formatMoney(m, locale: locale);

    final price = _newPrice;
    final mode = _effectiveMode;
    final preview = price == null
        ? null
        : changePlan(
            widget.view.schedule,
            newPrice: price,
            on: _on,
            mode: mode,
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
            Text(l10n.planChangeTitle, style: text.titleMedium),
            Text(
              l10n.planChangeCurrent(money(_current)),
              style: text.bodyMedium?.copyWith(color: palette.secondaryText),
            ),
            if (plans.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in plans)
                    ChoiceChip(
                      key: ValueKey('plan-${p.id}'),
                      label: Text(p.name.resolve(language)),
                      selected: _planId == p.id,
                      onSelected: (_) => setState(() => _planId = p.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('plan-price'),
              controller: _price,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.planChangeNewPrice,
                suffixText: _currency.code,
              ),
              onChanged: (_) => setState(() {}),
            ),
            ListTile(
              key: const Key('plan-date'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.planChangeFrom),
              trailing: Text(date(_on)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(_on.year, _on.month, _on.day),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _on = LocalDate.fromDateTime(picked));
                }
              },
            ),
            RadioGroup<PlanChangeMode>(
              groupValue: mode,
              onChanged: (m) => setState(() => _mode = m),
              child: Column(
                children: [
                  for (final m in PlanChangeMode.values)
                    RadioListTile<PlanChangeMode>(
                      key: ValueKey('plan-mode-${m.name}'),
                      contentPadding: EdgeInsets.zero,
                      value: m,
                      title: Text(switch (m) {
                        PlanChangeMode.payDifference => l10n.planModePay,
                        PlanChangeMode.convertTime => l10n.planModeConvert,
                        PlanChangeMode.atRenewal => l10n.planModeRenewal,
                      }),
                    ),
                ],
              ),
            ),
            if (preview != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(key: const Key('plan-preview'), switch (mode) {
                  PlanChangeMode.payDifference => l10n.planPreviewPay(
                    money(preview.oneOff ?? Money.zero(_currency)),
                  ),
                  PlanChangeMode.convertTime => l10n.planPreviewConvert(
                    date(preview.paidUntil!),
                  ),
                  PlanChangeMode.atRenewal => l10n.planPreviewRenewal(
                    date(
                      widget.view.schedule.cycle.dateAt(
                        preview.anchor,
                        preview.fromIndex!,
                      ),
                    ),
                    money(price!),
                  ),
                }),
              ),
            FilledButton(
              key: const Key('plan-save'),
              onPressed: price == null || _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final result = await ref
                          .read(itemRepositoryProvider)
                          .switchPlan(
                            widget.view.row.id,
                            newPrice: price,
                            on: _on,
                            mode: mode,
                            planId: _planId,
                          );
                      final oneOff = result.oneOff;
                      if (oneOff != null && oneOff.minor > 0) {
                        await ref
                            .read(paymentRepositoryProvider)
                            .record(
                              itemId: widget.view.row.id,
                              expected: oneOff,
                              paid: oneOff,
                              paidOn: _on,
                              main:
                                  ref
                                      .read(userSettingsProvider)
                                      .value
                                      ?.mainCurrency ??
                                  _currency,
                              accountId: widget.view.row.accountId,
                              note: 'plan change',
                            );
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
