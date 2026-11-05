import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/db/app_database.dart';
import '../../data/detection/detection_service.dart';
import '../../data/items/item_repository.dart';
import '../../data/payments/payment_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../../widgets/preset_badge.dart';
import '../../widgets/state_views.dart';
import '../home/fixed_summary.dart';
import '../home/tile_icons.dart';
import '../reports/report_data.dart';

/// Saves every payment record as CSV through the system file picker.
Future<void> exportPaymentsCsv(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final payments = ref.read(allPaymentsProvider).value ?? const [];
  if (payments.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportsNoPayments)));
    return;
  }
  final items = ref.read(itemsProvider).value ?? const [];
  final methods = ref.read(paymentMethodListProvider).value ?? const [];
  final today = todayFrom(ref.read(clockProvider));
  final csv = paymentsCsv(
    [for (final p in payments.reversed) p.row],
    {for (final v in items) v.row.id: v.row.name},
    {for (final m in methods) m.id: m.name},
  );
  // The BOM lets spreadsheet apps read the file as UTF-8.
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
  final saved = await ref
      .read(filePickerProvider)
      .save('${Brand.appName}-payments-$today.csv', bytes);
  if (saved) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportsExported)));
  }
}

/// Every payment record, newest first, by month (CLAUDE.md item 10: payment
/// records replace full bookkeeping). Charges detected from notifications
/// that still need confirming are flagged at the top.
class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  /// Show one item's payments only; null for all.
  String? _itemId;

  Future<void> _delete(Payment p) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.paymentDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            key: const Key('payment-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(paymentRepositoryProvider).deleteAndReopen(p.row.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.paymentDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = intlLocaleOf(context);
    final all = ref.watch(allPaymentsProvider);
    final items = ref.watch(itemsProvider).value ?? const <ItemView>[];
    final byId = {for (final v in items) v.row.id: v};
    final methods = {
      for (final m
          in ref.watch(paymentMethodListProvider).value ?? const <AccountRow>[])
        m.id: m.name,
    };
    final fx = ref.watch(fxConverterProvider).value;
    final settings = ref.watch(userSettingsProvider).value;
    final presets = ref.watch(presetLibraryProvider).value?.byId ?? const {};
    final pending = (ref.watch(detectionsProvider).value ?? const [])
        .where((d) => d.status == DetectionStatus.pending)
        .length;

    final payments = [
      for (final p in all.value ?? const <Payment>[])
        if (_itemId == null || p.row.itemId == _itemId) p,
    ];
    // Month headers and rows, flattened for a lazy list.
    final rows = <Object>[];
    String? month;
    for (final p in payments) {
      final key = '${p.paidOn.year}-${p.paidOn.month}';
      if (key != month) {
        month = key;
        rows.add((year: p.paidOn.year, month: p.paidOn.month));
      }
      rows.add(p);
    }
    Money? monthTotal(int year, int month) {
      final main = settings?.mainCurrency;
      if (fx == null || main == null) return null;
      var sum = 0;
      for (final p in payments) {
        if (p.paidOn.year != year || p.paidOn.month != month) continue;
        sum += fx.convert(p.paid, main)?.amount.minor ?? 0;
      }
      return Money(sum, main);
    }

    final paidItems = {
      for (final p in all.value ?? const <Payment>[]) ?p.row.itemId,
    };
    final filterable = [
      for (final v in items)
        if (paidItems.contains(v.row.id)) v,
    ]..sort((a, b) => a.row.name.compareTo(b.row.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentsTitle),
        actions: [
          if (filterable.length > 1)
            PopupMenuButton<String?>(
              key: const Key('payments-filter'),
              tooltip: l10n.filterTitle,
              icon: Badge(
                isLabelVisible: _itemId != null,
                smallSize: 8,
                child: const Icon(Icons.filter_list),
              ),
              initialValue: _itemId,
              onSelected: (id) => setState(() => _itemId = id),
              itemBuilder: (_) => [
                PopupMenuItem(value: null, child: Text(l10n.paymentsFilterAll)),
                for (final v in filterable)
                  PopupMenuItem(
                    key: ValueKey('payments-filter-${v.row.id}'),
                    value: v.row.id,
                    child: Text(v.row.name),
                  ),
              ],
            ),
          IconButton(
            key: const Key('payments-export'),
            tooltip: l10n.reportsExportCsv,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => exportPaymentsCsv(context, ref),
          ),
        ],
      ),
      body: switch (all) {
        AsyncError(:final error) => ErrorState(message: '$error'),
        AsyncData() || AsyncValue(hasValue: true) => ListView.builder(
          key: const PageStorageKey('payments-list'),
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: rows.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pending > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Material(
                        color: palette.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: palette.warning),
                        ),
                        child: ListTile(
                          key: const Key('payments-to-confirm'),
                          leading: Icon(
                            Icons.notifications_active_outlined,
                            color: palette.warning,
                          ),
                          title: Text(l10n.paymentsToConfirm(pending)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(Routes.settingsDetection),
                        ),
                      ),
                    ),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: palette.secondaryText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.paymentsEmpty,
                            style: text.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.paymentsEmptyHint,
                            style: text.bodyMedium?.copyWith(
                              color: palette.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
            final row = rows[i - 1];
            if (row case (year: final int y, month: final int m)) {
              final total = monthTotal(y, m);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Semantics(
                  header: true,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      Text(
                        DateFormat.yMMMM(locale).format(DateTime(y, m)),
                        style: text.titleSmall,
                      ),
                      if (total != null)
                        Text(
                          l10n.paymentsMonthTotal(
                            settings?.hideAmounts ?? false
                                ? hiddenAmount
                                : formatMoney(
                                    total,
                                    locale: locale,
                                    decimals: settings?.decimalsFor(
                                      total.currency,
                                    ),
                                  ),
                          ),
                          style: text.bodyMedium?.copyWith(
                            color: palette.secondaryText,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
            final p = row as Payment;
            final view = byId[p.row.itemId];
            final name = view?.row.name ?? '—';
            final badge = badgeOf(p.row.itemId ?? '', name, settings);
            final details = [
              DateFormat.MMMd(
                locale,
              ).format(DateTime(p.paidOn.year, p.paidOn.month, p.paidOn.day)),
              if (methods[p.row.accountId] case final m? when m.isNotEmpty) m,
              if (p.original case final o?)
                settings?.hideAmounts ?? false
                    ? hiddenAmount
                    : formatMoney(o, locale: locale),
              if (p.row.note.isNotEmpty) p.row.note,
            ].join(' · ');
            return ListTile(
              key: ValueKey('payment-row-${p.row.id}'),
              leading: InitialBadge(
                name: name,
                text: badge.text,
                color:
                    badge.color ??
                    presets[view?.row.presetId]?.color ??
                    '#6B7280',
              ),
              title: MarqueeText(name),
              subtitle: Text(details),
              trailing: MoneyText(p.paid, style: text.bodyLarge),
              onTap: view == null
                  ? null
                  : () => context.go(Routes.item(view.row.id)),
              onLongPress: () => _delete(p),
            );
          },
        ),
        _ => const LoadingState(),
      },
    );
  }
}
