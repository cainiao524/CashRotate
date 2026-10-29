import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../layout/list_detail_layout.dart';
import '../../layout/window_class.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../../widgets/preset_badge.dart';
import '../../widgets/state_views.dart';
import '../home/fixed_summary.dart';
import 'add_item_page.dart';
import 'item_detail.dart';
import 'labels.dart';

/// Fixed expenses: list alone on compact windows, list + detail otherwise.
class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = _ItemsList(selectedId: selectedId);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('items-add'),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAdd),
        onPressed: () => openAddItem(context),
      ),
      body: WindowClass.of(context).isTwoPane
          ? ListDetailLayout(
              list: list,
              detail: switch (selectedId) {
                final id? => ItemDetail(
                  key: ValueKey(id),
                  id: id,
                  onDeleted: () => context.go(Routes.items),
                ),
                null => EmptyState(
                  icon: Icons.touch_app_outlined,
                  title: l10n.detailPlaceholder,
                ),
              },
            )
          : list,
    );
  }
}

/// Full-page detail used on compact windows.
class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: ItemDetail(id: id, onDeleted: () => context.go(Routes.items)),
  );
}

class _ItemsList extends ConsumerWidget {
  const _ItemsList({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(itemsProvider)) {
      AsyncData(value: final items) when items.isEmpty => EmptyState(
        icon: Icons.event_repeat_outlined,
        title: l10n.emptyItems,
        body: l10n.emptyItemsHint,
      ),
      AsyncData(value: final items) => ListView.builder(
        key: const PageStorageKey('items-list'),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: items.length,
        itemBuilder: (context, i) =>
            ItemTile(view: items[i], selected: items[i].row.id == selectedId),
      ),
      AsyncError(:final error) => ErrorState(message: '$error'),
      _ => const LoadingState(),
    };
  }
}

class ItemTile extends ConsumerWidget {
  const ItemTile({super.key, required this.view, this.selected = false});

  final ItemView view;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final preset = ref
        .watch(presetLibraryProvider)
        .value
        ?.byId[view.row.presetId];
    final next = view.nextDue;
    final today = todayFrom(ref.watch(clockProvider));
    final subtitle = switch (view.row.status) {
      ItemStatus.paused => l10n.statusPaused,
      ItemStatus.cancelled => l10n.statusCancelled,
      ItemStatus.active when view.row.needsDetails => l10n.detailNeedsDetails,
      ItemStatus.active =>
        next == null
            ? l10n.cycle(view.schedule.cycle)
            : formatDate(context, next.dueOn),
    };
    final overdue = next != null && next.dueOn < today;
    final amount = next == null
        ? view.schedule.prices.stablePrice
        : Money(next.expectedMinor, next.currency);
    final text = Theme.of(context).textTheme;

    // Not a ListTile: its fixed-height trailing slot cannot hold the
    // two-line amount at large text sizes. This row grows with the text.
    return Material(
      color: selected ? palette.selected : Colors.transparent,
      child: InkWell(
        key: ValueKey('item-${view.row.id}'),
        onTap: () => context.go(Routes.item(view.row.id)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                InitialBadge(
                  name: view.row.name,
                  color: preset?.color ?? '#6B7280',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeText(view.row.name, style: text.bodyLarge),
                      Text(
                        subtitle,
                        style: text.bodyMedium?.copyWith(
                          color: view.row.needsDetails
                              ? palette.warning
                              : (overdue
                                    ? palette.error
                                    : palette.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!view.row.needsDetails) ...[
                  const SizedBox(width: 12),
                  DualMoneyText(amount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
