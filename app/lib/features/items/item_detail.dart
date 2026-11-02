import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/payments/payment_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../features.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../../widgets/preset_badge.dart';
import '../../widgets/state_views.dart';
import '../home/fixed_summary.dart';
import '../payments/payment_sheet.dart';
import '../reports/report_data.dart';
import 'item_editor_page.dart';
import 'labels.dart';
import 'plan_change_sheet.dart';

final _itemProvider = StreamProvider.family<ItemView?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).watchOne(id),
);

final _paymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, id) => ref.watch(paymentRepositoryProvider).watchForItem(id),
);

final _upcomingProvider = StreamProvider.family<List<OccurrenceRow>, String>((
  ref,
  id,
) {
  final today = todayFrom(ref.watch(clockProvider));
  return ref
      .watch(itemRepositoryProvider)
      .watchDue(today.addDays(-366), today.addMonths(12))
      .map(
        (all) => all
            .where((o) => o.itemId == id && o.state == OccurrenceState.pending)
            .take(4)
            .toList(),
      );
});

String formatDate(BuildContext context, LocalDate d) =>
    DateFormat.yMMMd(intlLocaleOf(context))
        .format(DateTime(d.year, d.month, d.day));

/// Everything about one fixed expense, with its actions. Used as a page on
/// compact windows and as the detail pane on wide ones.
class ItemDetail extends ConsumerWidget {
  const ItemDetail({super.key, required this.id, this.onDeleted});

  final String id;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(_itemProvider(id))) {
      AsyncData(value: final view?) => _body(context, ref, view),
      AsyncData() => const SizedBox.shrink(), // deleted
      AsyncError(:final error) => ErrorState(message: '$error'),
      _ => const LoadingState(),
    };
  }

  Widget _body(BuildContext context, WidgetRef ref, ItemView v) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final preset = ref.watch(presetLibraryProvider).value?.byId[v.row.presetId];
    final s = v.schedule;
    final today = todayFrom(ref.watch(clockProvider));
    final next = v.nextDue;
    final current = next == null
        ? s.prices.stablePrice
        : Money(next.expectedMinor, next.currency);
    final change = next == null
        ? null
        : s.prices.changeAfter(s.cycle, s.anchor, next.cycleIndex);
    final upcoming = ref.watch(_upcomingProvider(id)).value ?? const [];
    final payments = ref.watch(_paymentsProvider(id)).value ?? const [];
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    String money(Money m) =>
        hidden ? hiddenAmount : formatMoney(m, locale: locale);
    // My monthly cost (my share; the payment average for irregular bills),
    // for the yearly and daily figures.
    final myMonthly = monthlyCostOf(
      v,
      today: today,
      irregularAverage: ref.watch(irregularStatsProvider).averages[id],
    );
    final priceLines = Features.priceComparison
        ? priceChanges(
            [
              for (final h
                  in ref.watch(priceHistoryProvider).value ??
                      const <PriceHistoryRow>[])
                if (h.itemId == id) h,
            ],
            [v],
          )
        : const <PriceChangeLine>[];
    final cancelUrl =
        (v.typeFields['cancelUrl'] as String?) ?? preset?.cancelUrl;
    final rarelyUsed = v.typeFields['rarelyUsed'] == true;

    final status = switch (v.row.status) {
      ItemStatus.active => null,
      ItemStatus.paused => l10n.statusPaused,
      ItemStatus.cancelled =>
        s.isUsableOn(today)
            ? l10n.statusCancelledUntil(formatDate(context, s.paidUntil!))
            : l10n.statusCancelled,
    };

    return ListView(
      key: PageStorageKey('item-detail-$id'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            InitialBadge(
              name: v.row.name,
              color: preset?.color ?? '#6B7280',
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarqueeText(v.row.name, style: text.titleLarge),
                  Text(
                    '${l10n.itemType(v.row.type)} · ${l10n.cycle(s.cycle)}',
                    style: text.bodyMedium?.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (v.row.needsDetails)
              Chip(
                avatar: Icon(Icons.edit_note, color: palette.warning),
                label: Text(l10n.detailNeedsDetails),
              ),
            if (status != null) Chip(label: Text(status)),
          ],
        ),
        const SizedBox(height: 8),
        DualMoneyText(
          current,
          largeStyle: text.headlineSmall,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        if (change != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.detailPriceChange(money(change.from), money(change.to)),
              style: text.bodyMedium?.copyWith(color: palette.warning),
            ),
          ),
        const Divider(height: 32),
        _Row(
          l10n.detailNextCharge,
          next == null ? '—' : formatDate(context, next.dueOn),
        ),
        _Row(l10n.detailMonthlyCost, money(s.cycle.monthlyEquivalent(current))),
        if (s.prices.phases.length > 1)
          _Row(l10n.detailStableMonthly, money(v.stableMonthly)),
        if (Features.costConversion && myMonthly != null) ...[
          _Row(
            l10n.costPerYear,
            money(yearlyCost(myMonthly)),
            key: const Key('detail-yearly'),
          ),
          _Row(
            l10n.costPerDay,
            money(dailyCost(myMonthly)),
            key: const Key('detail-daily'),
          ),
        ],
        if (v.sharing case final sharing? when sharing['myShare'] is int)
          _Row(
            l10n.sharingMyShare,
            money(
              Money(sharing['myShare']! as int, s.prices.stablePrice.currency),
            ),
          ),
        if (s.prices.phases.length > 1) ...[
          const SizedBox(height: 16),
          Text(l10n.detailPrices, style: text.titleSmall),
          for (final p in s.prices.phases)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(switch (p.length) {
                ForPeriods(:final periods) => l10n.detailPhaseFor(
                  money(p.amount),
                  periods,
                ),
                UntilDate(:final date) => l10n.detailPhaseUntil(
                  money(p.amount),
                  formatDate(context, date),
                ),
                OpenEnded() => l10n.detailPhaseThen(money(p.amount)),
              }),
            ),
        ],
        if (priceLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.reportsPriceChanges, style: text.titleSmall),
          for (final (i, l) in priceLines.indexed)
            ListTile(
              key: ValueKey('detail-price-change-$i'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                l.difference.minor >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
              title: Text('${money(l.from)} → ${money(l.to)}'),
              subtitle: Text(formatDate(context, l.effectiveOn)),
              trailing: Text(
                priceDiffLabel(l10n, l, locale, hidden: hidden),
                style: TextStyle(
                  color: l.difference.minor > 0 ? palette.warning : null,
                ),
              ),
            ),
        ],
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.detailUpcoming, style: text.titleSmall),
          for (final o in upcoming)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                o.dueOn < today ? Icons.error_outline : Icons.event_outlined,
                color: o.dueOn < today ? palette.error : null,
              ),
              title: Text(formatDate(context, o.dueOn)),
              trailing: MoneyText(Money(o.expectedMinor, o.currency)),
            ),
        ],
        if (payments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.paymentHistory, style: text.titleSmall),
          for (final p in payments.take(12))
            ListTile(
              key: ValueKey('payment-${p.row.id}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(formatDate(context, p.paidOn)),
              subtitle: p.original == null
                  ? null
                  : Text(
                      [
                        l10n.paymentForeign(
                          money(p.original!),
                          p.actualRate?.toDecimalString(maxDecimals: 4) ?? '—',
                        ),
                        if (p.markupBasisPoints case final m? when m > 0)
                          l10n.paymentMarkup((m / 100).toStringAsFixed(1)),
                      ].join(' · '),
                    ),
              trailing: MoneyText(p.paid),
            ),
        ],
        if (Features.idleReminder && v.row.status == ItemStatus.active)
          SwitchListTile(
            key: const Key('detail-rarely-used'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rarelyUsed),
            subtitle: Text(l10n.rarelyUsedHint),
            value: rarelyUsed,
            onChanged: (on) =>
                ref.read(itemRepositoryProvider).setTypeFields(id, {
                  'rarelyUsed': on ? true : null,
                  // First asked a quarter from now.
                  'idleAskedOn': on ? today.toString() : null,
                }),
          ),
        if (v.row.note.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(v.row.note),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (v.row.status == ItemStatus.active && !v.row.needsDetails)
              FilledButton.icon(
                key: const Key('detail-pay'),
                icon: const Icon(Icons.check),
                label: Text(l10n.paymentRecord),
                onPressed: () => showPaymentSheet(context, v),
              ),
            if (v.row.status == ItemStatus.active && !v.irregular)
              OutlinedButton.icon(
                key: const Key('detail-change-plan'),
                icon: const Icon(Icons.swap_vert),
                label: Text(l10n.planChangeTitle),
                onPressed: () => showPlanChangeSheet(context, v),
              ),
            FilledButton.icon(
              key: const Key('detail-edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.actionEdit),
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<String>(
                  builder: (_) => ItemEditorPage(itemId: id),
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('detail-duplicate'),
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.actionDuplicate),
              onPressed: () => ref
                  .read(itemRepositoryProvider)
                  .duplicate(id, name: l10n.copyOfName(v.row.name)),
            ),
            if (v.row.status == ItemStatus.active)
              OutlinedButton.icon(
                icon: const Icon(Icons.pause_outlined),
                label: Text(l10n.actionPause),
                onPressed: () => ref
                    .read(itemRepositoryProvider)
                    .setStatus(id, ItemStatus.paused, today),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(l10n.actionResume),
                onPressed: () => ref
                    .read(itemRepositoryProvider)
                    .setStatus(id, ItemStatus.active, today),
              ),
            if (Features.goCancel &&
                cancelUrl != null &&
                cancelUrl.isNotEmpty &&
                v.row.status != ItemStatus.cancelled)
              OutlinedButton.icon(
                key: const Key('detail-go-cancel'),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.actionGoCancel),
                onPressed: () => openCancelPage(context, ref, cancelUrl),
              ),
            if (v.row.status != ItemStatus.cancelled)
              OutlinedButton.icon(
                icon: const Icon(Icons.block_outlined),
                label: Text(l10n.actionMarkCancelled),
                onPressed: () => ref
                    .read(itemRepositoryProvider)
                    .setStatus(id, ItemStatus.cancelled, today),
              ),
            TextButton.icon(
              key: const Key('detail-delete'),
              icon: Icon(Icons.delete_outline, color: palette.error),
              label: Text(
                l10n.actionDelete,
                style: TextStyle(color: palette.error),
              ),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(l10n.deleteItemConfirm(v.row.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.actionCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                );
                if (ok ?? false) {
                  await ref.read(itemRepositoryProvider).delete(id);
                  onDeleted?.call();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      children: [
        Text(label, style: TextStyle(color: Palette.of(context).secondaryText)),
        Text(value),
      ],
    ),
  );
}

/// Opens a service's cancel page, or says it couldn't.
Future<void> openCancelPage(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = AppLocalizations.of(context).goCancelFailed;
  if (!await ref.read(linkOpenerProvider).open(url)) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
