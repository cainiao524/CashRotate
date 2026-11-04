import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/payments/payment_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../features.dart';
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
import '../home/tile_icons.dart';
import 'add_item_page.dart';
import 'item_detail.dart';
import 'items_filter.dart';
import 'labels.dart';

/// Fixed expenses: list alone on compact windows, list + detail otherwise.
/// Search, filters and multi-select for batch edits live in the app bar.
class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = _ItemsList(selectedId: selectedId);
    final selection = Features.batchEdit
        ? ref.watch(itemsSelectionProvider)
        : null;
    final filter = ref.watch(itemsFilterProvider);
    return PopScope(
      canPop: selection == null,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) ref.read(itemsSelectionProvider.notifier).end();
      },
      child: Scaffold(
        appBar: selection == null
            ? AppBar(
                title: Text(l10n.itemsTitle),
                actions: [
                  if (Features.searchFilter) ...[
                    IconButton(
                      key: const Key('items-search'),
                      tooltip: l10n.homeSearch,
                      icon: Icon(
                        filter.query == null ? Icons.search : Icons.search_off,
                      ),
                      onPressed: () => ref
                          .read(itemsFilterProvider.notifier)
                          .set(
                            filter.copyWith(
                              query: () => filter.query == null ? '' : null,
                            ),
                          ),
                    ),
                    IconButton(
                      key: const Key('items-filter'),
                      tooltip: filter.count == 0
                          ? l10n.filterTitle
                          : l10n.filterActive(filter.count),
                      icon: Badge(
                        isLabelVisible: filter.count > 0,
                        label: Text('${filter.count}'),
                        child: const Icon(Icons.filter_list),
                      ),
                      onPressed: () => _showFilters(context),
                    ),
                  ],
                ],
                bottom: filter.query == null
                    ? null
                    : const PreferredSize(
                        preferredSize: Size.fromHeight(64),
                        child: _SearchField(),
                      ),
              )
            : _SelectionBar(selection: selection),
        floatingActionButton: selection != null
            ? null
            : FloatingActionButton.extended(
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
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final _controller = TextEditingController(
    text: ref.read(itemsFilterProvider).query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: TextField(
      key: const Key('items-search-field'),
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).homeSearch,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
      ),
      onChanged: (q) {
        final filter = ref.read(itemsFilterProvider);
        ref
            .read(itemsFilterProvider.notifier)
            .set(filter.copyWith(query: () => q));
      },
    ),
  );
}

/// Filters: category, payment method and sharing role, each "any of".
Future<void> _showFilters(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _FilterSheet(),
);

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final filter = ref.watch(itemsFilterProvider);
    final notifier = ref.read(itemsFilterProvider.notifier);
    final items = ref.watch(itemsProvider).value ?? const [];
    final methods = ref.watch(paymentMethodListProvider).value ?? const [];
    String category(String id) => l10n.category(
      PresetCategory.values.asNameMap()[id] ?? PresetCategory.other,
    );
    final categories = {
      for (final v in items) ItemsFilter.categoryOf(v),
    }.toList()..sort((a, b) => category(a).compareTo(category(b)));
    Set<T> toggled<T>(Set<T> set, T value) =>
        set.contains(value) ? ({...set}..remove(value)) : {...set, value};

    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.filterTitle, style: text.titleMedium),
                TextButton(
                  key: const Key('filter-clear'),
                  onPressed: filter.count == 0
                      ? null
                      : () => notifier.set(filter.cleared()),
                  child: Text(l10n.filterClear),
                ),
              ],
            ),
            section(l10n.filterCategory, [
              for (final c in categories)
                FilterChip(
                  key: ValueKey('filter-category-$c'),
                  label: Text(category(c)),
                  selected: filter.categories.contains(c),
                  onSelected: (_) => notifier.set(
                    filter.copyWith(categories: toggled(filter.categories, c)),
                  ),
                ),
            ]),
            section(l10n.paymentMethod, [
              for (final (id, name) in [
                for (final m in methods) (m.id, m.name),
                (ItemsFilter.noAccount, l10n.paymentMethodNone),
              ])
                FilterChip(
                  key: ValueKey('filter-account-$id'),
                  label: Text(name),
                  selected: filter.accounts.contains(id),
                  onSelected: (_) => notifier.set(
                    filter.copyWith(accounts: toggled(filter.accounts, id)),
                  ),
                ),
            ]),
            section(l10n.filterRole, [
              for (final r in RoleFilter.values)
                FilterChip(
                  key: ValueKey('filter-role-${r.name}'),
                  label: Text(switch (r) {
                    RoleFilter.none => l10n.filterRoleNone,
                    RoleFilter.organizer => l10n.filterRoleOrganizer,
                    RoleFilter.member => l10n.filterRoleMember,
                  }),
                  selected: filter.roles.contains(r),
                  onSelected: (_) => notifier.set(
                    filter.copyWith(roles: toggled(filter.roles, r)),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// App bar while picking items: how many, and the batch actions.
class _SelectionBar extends ConsumerWidget implements PreferredSizeWidget {
  const _SelectionBar({required this.selection});

  final Set<String> selection;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(itemRepositoryProvider);
    final ids = selection.toList();

    Future<void> done(Future<void> Function() edit) async {
      final messenger = ScaffoldMessenger.of(context);
      await edit();
      ref.read(itemsSelectionProvider.notifier).end();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.batchDone(ids.length))),
      );
    }

    Future<T?> pick<T>(String title, List<(T, String)> options) =>
        showModalBottomSheet<T>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final (value, label) in options)
                  ListTile(
                    key: ValueKey('batch-option-$value'),
                    title: Text(label),
                    onTap: () => Navigator.pop(context, value),
                  ),
              ],
            ),
          ),
        );

    return AppBar(
      leading: IconButton(
        key: const Key('batch-exit'),
        tooltip: l10n.batchExit,
        icon: const Icon(Icons.close),
        onPressed: () => ref.read(itemsSelectionProvider.notifier).end(),
      ),
      title: Text(l10n.obSelectedCount(ids.length)),
      actions: [
        IconButton(
          key: const Key('batch-category'),
          tooltip: l10n.batchCategory,
          icon: const Icon(Icons.category_outlined),
          onPressed: () async {
            final c = await pick(l10n.batchCategory, [
              for (final c in PresetCategory.values) (c.name, l10n.category(c)),
            ]);
            if (c != null) await done(() => repo.editMany(ids, categoryId: c));
          },
        ),
        IconButton(
          key: const Key('batch-payment-method'),
          tooltip: l10n.batchPaymentMethod,
          icon: const Icon(Icons.credit_card_outlined),
          onPressed: () async {
            final methods =
                ref.read(paymentMethodListProvider).value ?? const [];
            final id = await pick(l10n.batchPaymentMethod, [
              for (final m in methods) (m.id, m.name),
              (PaymentMethods.unassignedId, l10n.paymentMethodNone),
            ]);
            if (id != null) await done(() => repo.editMany(ids, accountId: id));
          },
        ),
        IconButton(
          key: const Key('batch-pause'),
          tooltip: l10n.actionPause,
          icon: const Icon(Icons.pause_outlined),
          onPressed: () => done(() async {
            final today = todayFrom(ref.read(clockProvider));
            for (final id in ids) {
              await repo.setStatus(id, ItemStatus.paused, today);
            }
          }),
        ),
        IconButton(
          key: const Key('batch-resume'),
          tooltip: l10n.actionResume,
          icon: const Icon(Icons.play_arrow_outlined),
          onPressed: () => done(() async {
            final today = todayFrom(ref.read(clockProvider));
            for (final id in ids) {
              await repo.setStatus(id, ItemStatus.active, today);
            }
          }),
        ),
      ],
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
    final filter = ref.watch(itemsFilterProvider);
    final selection = ref.watch(itemsSelectionProvider);
    final selector = ref.read(itemsSelectionProvider.notifier);
    return switch (ref.watch(itemsProvider)) {
      AsyncData(value: final items) when items.isEmpty => EmptyState(
        icon: Icons.event_repeat_outlined,
        title: l10n.emptyItems,
        body: l10n.emptyItemsHint,
      ),
      AsyncData(value: final all) => switch ([
        for (final v in all)
          if (filter.matches(v)) v,
      ]) {
        final items when items.isEmpty => EmptyState(
          icon: Icons.filter_list_off,
          title: l10n.homeNoMatches,
        ),
        final items => ListView.builder(
          key: const PageStorageKey('items-list'),
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final id = items[i].row.id;
            return ItemTile(
              view: items[i],
              selected: selection == null && id == selectedId,
              checked: selection?.contains(id),
              onTap: selection == null ? null : () => selector.toggle(id),
              onLongPress: Features.batchEdit && selection == null
                  ? () => selector.start(id)
                  : null,
            );
          },
        ),
      },
      AsyncError(:final error) => ErrorState(message: '$error'),
      _ => const LoadingState(),
    };
  }
}

class ItemTile extends ConsumerWidget {
  const ItemTile({
    super.key,
    required this.view,
    this.selected = false,
    this.checked,
    this.onTap,
    this.onLongPress,
  });

  final ItemView view;
  final bool selected;

  /// Picked for a batch edit; null when not selecting.
  final bool? checked;

  /// Defaults to opening the item.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final preset = ref
        .watch(presetLibraryProvider)
        .value
        ?.byId[view.row.presetId];
    final next = view.nextDue;
    final badge = badgeOf(
      view.row.id,
      view.row.name,
      ref.watch(userSettingsProvider).value,
    );
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
      color: selected || (checked ?? false)
          ? palette.selected
          : Colors.transparent,
      child: InkWell(
        key: ValueKey('item-${view.row.id}'),
        onTap: onTap ?? () => context.go(Routes.item(view.row.id)),
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (checked case final on?)
                  Semantics(
                    checked: on,
                    child: Icon(
                      on ? Icons.check_circle : Icons.radio_button_unchecked,
                      key: ValueKey('item-check-${view.row.id}'),
                      size: 40,
                      color: on ? palette.primary : palette.outline,
                    ),
                  )
                else
                  InitialBadge(
                    name: view.row.name,
                    text: badge.text,
                    color: badge.color ?? preset?.color ?? '#6B7280',
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
