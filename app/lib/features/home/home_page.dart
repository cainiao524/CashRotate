import 'dart:math' as math;

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../layout/window_class.dart';
import '../../routing/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../theme/pearl_surface.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart' show hiddenAmount;
import '../../widgets/preset_badge.dart';
import '../items/add_item_page.dart';
import '../items/labels.dart';
import '../payments/payment_sheet.dart';
import '../reports/reports_page.dart';
import 'countdown_ring.dart';
import 'fixed_summary.dart';
import 'home_motion.dart';
import 'home_tiles.dart';
import 'tile_icons.dart';

/// Sort, type filter and search of the home grid; `query` null while the
/// search field is closed. Kept in a provider so it survives rotating and
/// folding.
typedef HomeView = ({TileSort sort, ItemType? type, String? query});

class HomeViewNotifier extends Notifier<HomeView> {
  @override
  HomeView build() => (sort: TileSort.dueDate, type: null, query: null);

  void setSort(TileSort sort) =>
      state = (sort: sort, type: state.type, query: state.query);
  void setType(ItemType? type) =>
      state = (sort: state.sort, type: type, query: state.query);
  void setQuery(String? query) =>
      state = (sort: state.sort, type: state.type, query: query);
}

final homeViewProvider = NotifierProvider<HomeViewNotifier, HomeView>(
  HomeViewNotifier.new,
);

/// Home: a compact pearl total card, the sort and filter bar, then every
/// fixed expense as a tile, soonest charge first. Tablets put the total in
/// a large tile of the same grid, beside the month's income and spending.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = WindowClass.of(context);
    final compact = window == WindowClass.compact;
    final expanded = window == WindowClass.expanded;
    final searching =
        ref.watch(homeViewProvider.select((v) => v.query)) != null;
    final side = expanded ? 32.0 : (compact ? 16.0 : 24.0);
    final hidden = ref.watch(userSettingsProvider).value?.hideAmounts ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Brand.appName,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('home-hide-amounts'),
            tooltip: hidden ? l10n.showAmounts : l10n.hideAmounts,
            isSelected: hidden,
            icon: const Icon(Icons.visibility_outlined),
            selectedIcon: const Icon(Icons.visibility_off_outlined),
            onPressed: () =>
                ref.read(settingsRepositoryProvider).setHideAmounts(!hidden),
          ),
          // Two-pane windows reach settings from the navigation rail.
          if (compact)
            IconButton(
              key: const Key('nav-settings'),
              tooltip: l10n.navSettings,
              icon: const Icon(Icons.tune),
              onPressed: () => context.go(Routes.settings),
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              key: const Key('home-add'),
              // The fixed expenses tab keeps its own add button alive in
              // the same indexed stack: no shared hero tag.
              heroTag: null,
              onPressed: () => openAddItem(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAdd),
            )
          : null,
      body: ListView(
        key: const PageStorageKey('home'),
        // Room under the last tiles for the floating add button.
        padding: EdgeInsets.fromLTRB(side, 8, side, compact ? 96 : 24),
        children: [
          if (!expanded) ...[const _TotalCard(), const SizedBox(height: 12)],
          const _Toolbar(),
          AnimatedSwitcher(
            duration: HomeMotion.of(context, HomeMotion.fade),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: HomeMotion.curve,
                ),
                child: child,
              ),
            ),
            child: searching
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _SearchField(),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 12),
          _TileGrid(window: window),
        ],
      ),
    );
  }
}

String _format(BuildContext context, WidgetRef ref, Money money) {
  final settings = ref.watch(userSettingsProvider).value;
  if (settings?.hideAmounts ?? false) return hiddenAmount;
  return formatMoney(
    money,
    locale: intlLocaleOf(context),
    decimals: settings?.decimalsFor(money.currency),
  );
}

String _shortDate(BuildContext context, LocalDate d) =>
    DateFormat.Md(intlLocaleOf(context))
        .format(DateTime(d.year, d.month, d.day));

// --- total card --------------------------------------------------------------

class _TotalCard extends ConsumerWidget {
  const _TotalCard({this.large = false});

  /// The 2 × 2 tablet tile: paid and still-to-pay side by side.
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(fixedSummaryProvider).value;
    final month = ref.watch(monthChargesProvider);
    final today = todayFrom(ref.watch(clockProvider));
    final locale = intlLocaleOf(context);
    final muted = TextStyle(color: palette.secondaryText);
    final monthLabel =
        (large ? DateFormat.yMMMM(locale) : DateFormat.MMM(locale)).format(
          DateTime(today.year, today.month),
        );

    final total = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: summary == null
          ? Text('—', style: tabularFigures(text.displaySmall!))
          : CountingMoneyText(
              summary.monthlyTotal,
              key: const Key('home-total'),
              style: TextStyle(
                fontSize: large ? 46 : 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: palette.text,
              ),
            ),
    );
    final notes = [
      if ((summary?.needsDetails ?? 0) > 0)
        Text(
          l10n.itemsPendingCount(summary!.needsDetails),
          key: const Key('home-pending'),
          style: text.bodySmall?.copyWith(color: palette.warning),
        ),
      if ((summary?.missingRates ?? 0) > 0)
        Text(l10n.obSummaryMissingRates, style: text.bodySmall?.merge(muted)),
    ];
    final header = Row(
      children: [
        Expanded(
          child: MarqueeText(
            l10n.homeMonthlyFixedTotal,
            style: text.labelLarge?.merge(muted).copyWith(letterSpacing: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          monthLabel,
          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );

    if (!large) {
      return Semantics(
        container: true,
        child: PearlSurface(
          sheen: true,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                runSpacing: 4,
                children: [
                  total,
                  if (month != null)
                    Text(
                      l10n.homeToPay(_format(context, ref, month.pending)),
                      key: const Key('home-to-pay'),
                      style: text.bodyMedium?.merge(muted),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _PaidBar(share: month?.paidShare ?? 0, height: 6),
              for (final n in notes) ...[const SizedBox(height: 6), n],
            ],
          ),
        ),
      );
    }

    final count = (ref.watch(itemsProvider).value ?? const [])
        .where((v) => v.schedule.isUsableOn(today))
        .length;
    Widget figure(String label, Money? amount, Key key) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.bodySmall?.merge(muted)),
        Text(
          amount == null ? '—' : _format(context, ref, amount),
          key: key,
          style: tabularFigures(
            text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      child: PearlSurface(
        sheen: true,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            header,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                total,
                const SizedBox(height: 6),
                MarqueeText(
                  l10n.homeFixedItemCount(count),
                  style: text.bodyMedium?.merge(muted),
                ),
                ...notes,
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PaidBar(share: month?.paidShare ?? 0, height: 8),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 32,
                  runSpacing: 8,
                  children: [
                    figure(l10n.homePaid, month?.paid, const Key('home-paid')),
                    figure(
                      l10n.homePending,
                      month?.pending,
                      const Key('home-to-pay'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidBar extends StatelessWidget {
  const _PaidBar({required this.share, required this.height});

  final double share;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Semantics(
      label: AppLocalizations.of(context).homePaidShare((share * 100).round()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: palette.selected),
              // Fills from empty when the card appears, then follows
              // each payment.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: share.clamp(0.0, 1.0)),
                duration: HomeMotion.of(context, HomeMotion.count),
                curve: HomeMotion.curve,
                builder: (context, factor, child) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: factor,
                  child: child,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- toolbar -----------------------------------------------------------------

class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final view = ref.watch(homeViewProvider);
    final notifier = ref.read(homeViewProvider.notifier);
    final count = ref.watch(_visibleTilesProvider)?.length;
    String sortLabel(TileSort s) => switch (s) {
      TileSort.dueDate => l10n.sortDueDate,
      TileSort.amount => l10n.sortAmount,
      TileSort.name => l10n.sortName,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton.outlined(
          key: const Key('home-search'),
          tooltip: l10n.homeSearch,
          isSelected: view.query != null,
          icon: const Icon(Icons.search),
          onPressed: () => notifier.setQuery(view.query == null ? '' : null),
        ),
        _MenuPill<TileSort>(
          key: const Key('home-sort'),
          label: sortLabel(view.sort),
          options: [for (final s in TileSort.values) (s, sortLabel(s))],
          selected: view.sort,
          onSelected: notifier.setSort,
        ),
        _MenuPill<ItemType?>(
          key: const Key('home-type'),
          label: view.type == null
              ? l10n.filterAllTypes
              : l10n.itemType(view.type!),
          options: [
            (null, l10n.filterAllTypes),
            for (final t in ItemType.values) (t, l10n.itemType(t)),
          ],
          selected: view.type,
          onSelected: notifier.setType,
        ),
        if (count != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.homeItemCount(count),
              key: const Key('home-count'),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.secondaryText),
            ),
          ),
      ],
    );
  }
}

/// An outlined pill showing the current choice; opens a menu of [options].
class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final (value, text) in options)
          MenuItemButton(
            key: ValueKey('menu-$text'),
            leadingIcon: Icon(value == selected ? Icons.check : null, size: 20),
            onPressed: () => onSelected(value),
            child: Text(text),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 8, 0),
          shape: const StadiumBorder(),
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
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
    text: ref.read(homeViewProvider).query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(homeViewProvider.notifier);
    return TextField(
      key: const Key('home-search-field'),
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.homeSearch,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: l10n.homeSearchClose,
          icon: const Icon(Icons.close),
          onPressed: () => notifier.setQuery(null),
        ),
      ),
      onChanged: notifier.setQuery,
    );
  }
}

// --- grid --------------------------------------------------------------------

final _visibleTilesProvider = Provider<List<HomeTile>?>((ref) {
  final items = ref.watch(itemsProvider).value;
  final settings = ref.watch(userSettingsProvider).value;
  if (items == null || settings == null) return null;
  final view = ref.watch(homeViewProvider);
  return homeTiles(
    items,
    today: todayFrom(ref.watch(clockProvider)),
    fx: ref.watch(fxConverterProvider).value,
    main: settings.mainCurrency,
    sort: view.sort,
    type: view.type,
    query: view.query ?? '',
    irregularAverages: ref.watch(irregularStatsProvider).averages,
    lastPaid: ref.watch(irregularStatsProvider).lastPaid,
  );
});

/// Footprint in grid cells.
typedef _Span = ({int columns, int rows});

/// Where an entry sits on the grid.
typedef _Placement = ({int column, int row, _Span span});

/// First-fit packing, left to right then top to bottom, so a single tile
/// fills the gap a wide one leaves at the end of a row.
List<_Placement> _pack(List<_Span> spans, int columns) {
  final taken = <(int, int)>{};
  bool fits(int c, int r, _Span s) {
    if (c + s.columns > columns) return false;
    for (var dc = 0; dc < s.columns; dc++) {
      for (var dr = 0; dr < s.rows; dr++) {
        if (taken.contains((c + dc, r + dr))) return false;
      }
    }
    return true;
  }

  final placed = <_Placement>[];
  for (final wanted in spans) {
    final s = (columns: math.min(wanted.columns, columns), rows: wanted.rows);
    var index = 0;
    while (!fits(index % columns, index ~/ columns, s)) {
      index++;
    }
    final (c, r) = (index % columns, index ~/ columns);
    for (var dc = 0; dc < s.columns; dc++) {
      for (var dr = 0; dr < s.rows; dr++) {
        taken.add((c + dc, r + dr));
      }
    }
    placed.add((column: c, row: r, span: s));
  }
  return placed;
}

/// Sizes of the tile parts; tablets are a little larger.
class _TileMetrics {
  const _TileMetrics({required this.large});

  final bool large;

  double get baseRow => large ? 140 : 120;
  double get gap => large ? 12 : 8;
  EdgeInsets get padding => large
      ? const EdgeInsets.fromLTRB(14, 12, 12, 12)
      : const EdgeInsets.fromLTRB(12, 10, 10, 10);
  double get icon => large ? 38 : 34;
  double get ring => large ? 36 : 32;
  double get radius => large ? 16 : 14;
  double get nameSize => large ? 13.5 : 12.5;
  double get amountSize => large ? 18 : 16;
  double get subSize => large ? 12 : 11.5;

  static const nameHeight = 1.3;
  static const amountHeight = 1.25;
  static const subHeight = 1.3;

  /// Row height that fits the icon row and three text lines at [scaler].
  double rowHeight(TextScaler scaler) => math.max(
    baseRow,
    padding.vertical +
        icon +
        8 +
        scaler.scale(nameSize) * nameHeight +
        scaler.scale(amountSize) * amountHeight +
        scaler.scale(subSize) * subHeight,
  );
}

class _TileGrid extends ConsumerStatefulWidget {
  const _TileGrid({required this.window});

  final WindowClass window;

  @override
  ConsumerState<_TileGrid> createState() => _TileGridState();
}

class _TileGridState extends ConsumerState<_TileGrid> {
  /// Whether the grid has shown its first tiles: only that first fill is
  /// staggered; tiles added later simply rise into place.
  bool _filled = false;

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final l10n = AppLocalizations.of(context);
    final tiles = ref.watch(_visibleTilesProvider);
    final settings = ref.watch(userSettingsProvider).value;
    if (tiles == null || settings == null) return const SizedBox.shrink();
    final expanded = window == WindowClass.expanded;
    final filtered = ref.watch(
      homeViewProvider.select((v) => v.type != null || (v.query ?? '') != ''),
    );
    final metrics = _TileMetrics(large: expanded);

    if (tiles.isEmpty && !expanded) {
      return _EmptyGrid(
        title: filtered ? l10n.homeNoMatches : l10n.emptyItems,
        body: filtered ? null : l10n.emptyItemsHint,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (window) {
          WindowClass.compact => 3,
          WindowClass.medium => 4,
          WindowClass.expanded => 6,
        };
        final gap = metrics.gap;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final scaler = MediaQuery.textScalerOf(context);
        final rowHeight = metrics.rowHeight(scaler);
        // The tablet total tile grows a row when large text needs it.
        final totalRows = (scaler.scale(1) > 1.5) ? 3 : 2;

        final entries = <(String, _Span, Widget)>[
          if (expanded)
            (
              'total',
              (columns: 2, rows: totalRows),
              const _TotalCard(large: true),
            ),
          for (final t in tiles)
            (
              t.id,
              (
                columns: settings.wideTiles.contains(t.id) || t.overdue ? 2 : 1,
                rows: 1,
              ),
              _ItemTile(tile: t, metrics: metrics),
            ),
          if (expanded) ...[
            ('last-12', (columns: 2, rows: 1), const _Last12Card()),
            ('categories', (columns: 2, rows: 1), const _CategoryCard()),
            ('add', (columns: 1, rows: 1), const _AddTile()),
          ],
        ];
        final placed = _pack([for (final (_, s, _) in entries) s], columns);
        final rows = placed.fold(0, (n, p) => math.max(n, p.row + p.span.rows));
        final stagger = !_filled;
        if (entries.isNotEmpty) _filled = true;
        final move = HomeMotion.of(context, HomeMotion.move);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: rows * rowHeight + (rows - 1) * gap,
              child: Stack(
                children: [
                  // Keyed by item: sorting, filtering, a tile turning wide
                  // or a charge being paid glides tiles to their new place.
                  for (final (i, (id, _, child)) in entries.indexed)
                    AnimatedPositioned(
                      key: ValueKey('slot-$id'),
                      duration: move,
                      curve: HomeMotion.curve,
                      left: placed[i].column * (cell + gap),
                      top: placed[i].row * (rowHeight + gap),
                      width:
                          placed[i].span.columns * cell +
                          (placed[i].span.columns - 1) * gap,
                      height:
                          placed[i].span.rows * rowHeight +
                          (placed[i].span.rows - 1) * gap,
                      child: EntranceAnimation(
                        delay: stagger
                            ? HomeMotion.stagger * i > HomeMotion.maxStagger
                                  ? HomeMotion.maxStagger
                                  : HomeMotion.stagger * i
                            : Duration.zero,
                        child: child,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: HomeMotion.of(context, HomeMotion.fade),
              child: tiles.isEmpty
                  ? _EmptyGrid(
                      title: filtered ? l10n.homeNoMatches : l10n.emptyItems,
                      body: filtered ? null : l10n.emptyItemsHint,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

/// No items (or none matching). Not [EmptyState]: that scrolls by itself,
/// and this sits inside the home list.
class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.event_repeat, size: 40, color: palette.secondaryText),
          const SizedBox(height: 12),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (body case final body?) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// --- item tile ---------------------------------------------------------------

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.tile, required this.metrics});

  final HomeTile tile;
  final _TileMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final main = settings?.mainCurrency;
    final brand = settings?.tileColors ?? false;
    final view = tile.view;
    final row = view.row;
    final preset = ref.watch(presetLibraryProvider).value?.byId[row.presetId];

    // Colours: monochrome by default, inverted when due soon, or the
    // service's own colour. Overdue adds a red outline either way.
    late final Color bg, fg, box;
    Color? border = palette.divider;
    if (brand) {
      bg = InitialBadge.parse(preset?.color ?? '#64748B');
      fg = InitialBadge.foregroundFor(bg);
      box = fg == Colors.black
          ? const Color(0x1A111111)
          : const Color(0x2EFFFFFF);
      border = null;
    } else if (tile.dueSoon) {
      bg = palette.primary;
      fg = palette.onPrimary;
      box = palette.brightness == Brightness.light
          ? const Color(0x29FFFFFF)
          : const Color(0x1A111111);
      border = palette.primary;
    } else {
      bg = palette.card;
      fg = palette.text;
      box = palette.pressed;
    }
    final borderSide = tile.overdue
        ? BorderSide(color: palette.error, width: 2)
        : border == null
        ? BorderSide.none
        : BorderSide(color: border);

    final paused = tile.status == ItemStatus.paused;
    final cancelled = tile.status == ItemStatus.cancelled;
    final flagged = tile.overdue || tile.newPrice || tile.needsDetails;
    final subColor = brand
        ? fg
        : tile.overdue
        ? palette.error
        : (tile.newPrice || tile.needsDetails)
        ? palette.warning
        : tile.dueSoon
        ? fg
        : fg.withValues(alpha: 0.72);

    final foreign = main != null && tile.amount.currency != main;
    final shown = tile.converted != null
        ? '≈ ${_format(context, ref, tile.converted!)}'
        : _format(context, ref, tile.amount);
    final amountText = tile.needsDetails
        ? '—'
        : tile.irregular
        // An irregular bill shows its monthly average, once it has one.
        ? (tile.lastPaid == null ? '—' : l10n.tilePerMonth(shown))
        : shown;
    final sub = switch (tile.status) {
      ItemStatus.paused => l10n.statusPaused,
      ItemStatus.cancelled when view.schedule.paidUntil != null =>
        l10n.statusCancelledUntil(
          _shortDate(context, view.schedule.paidUntil!),
        ),
      ItemStatus.cancelled => l10n.statusCancelled,
      _ when tile.needsDetails => l10n.detailNeedsDetails,
      _ when tile.irregular => [
        l10n.tileIrregular,
        if (tile.lastPaid case final last?)
          l10n.tileLastPaid(_shortDate(context, last))
        else
          l10n.tileNoPayments,
      ].join(' · '),
      _ => [
        if (tile.overdue) l10n.tileOverdue(-tile.daysLeft!),
        if (tile.newPrice)
          l10n.tileNewPrice(_format(context, ref, tile.amount))
        else if (foreign)
          _format(context, ref, tile.amount),
        if (!tile.overdue && tile.dueOn != null)
          _shortDate(context, tile.dueOn!),
        if (view.schedule.cycle != Cycle.monthly)
          l10n.cycle(view.schedule.cycle),
        if (view.sharingPlan case final plan?)
          switch (plan) {
            SharingPlan(role: SharingRole.member, :final payee?) =>
              l10n.tileMemberOf(payee),
            SharingPlan(role: SharingRole.member) => l10n.tileMemberRole,
            SharingPlan(split: SharingSplit.rotating) => switch (plan.payerOf(
              view.nextDue?.cycleIndex ?? 0,
            )) {
              null => l10n.tileYourTurn,
              final name => l10n.tileTurnOf(name),
            },
            _ => l10n.tileOrganizerOf(
              plan.peopleOn(tile.dueOn ?? LocalDate(2000, 1, 1)),
            ),
          },
      ].join(' · '),
    };
    final due = switch (tile.daysLeft) {
      final d? when !paused && !cancelled && d >= 0 => l10n.tileDueIn(d),
      _ => null,
    };

    final name = TextStyle(
      fontSize: metrics.nameSize,
      height: _TileMetrics.nameHeight,
      fontWeight: FontWeight.w600,
      color: fg,
    );
    final amount = tabularFigures(
      TextStyle(
        fontSize: metrics.amountSize,
        height: _TileMetrics.amountHeight,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    );
    final subStyle = TextStyle(
      fontSize: metrics.subSize,
      height: _TileMetrics.subHeight,
      fontWeight: flagged ? FontWeight.w600 : FontWeight.w400,
      color: subColor,
    );

    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MarqueeText(row.name, style: name),
                MarqueeText(amountText, style: amount),
                if (sub.isNotEmpty) MarqueeText(sub, style: subStyle),
              ],
            ),
          ),
        ),
        if (tile.overdue && view.nextDue != null) ...[
          const SizedBox(width: 8),
          FilledButton(
            key: ValueKey('tile-paid-${row.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: brand ? fg : palette.primary,
              foregroundColor: brand ? bg : palette.onPrimary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: () => showPaymentSheet(context, view),
            child: Text(l10n.actionMarkPaid),
          ),
        ],
      ],
    );

    final card = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.radius),
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('tile-${row.id}'),
        onTap: () => context.go(Routes.item(row.id)),
        onLongPress: () => _showTileMenu(context, tile),
        child: Semantics(
          label: [row.name, amountText, sub, ?due].join(', '),
          child: Padding(
            padding: metrics.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TileIcon(
                      name: row.name,
                      icon: tileIcons[settings?.tileIcons[row.id]],
                      size: metrics.icon,
                      background: box,
                      color: fg,
                    ),
                    const Spacer(),
                    ExcludeSemantics(
                      child: CountdownRing(
                        daysLeft: tile.daysLeft,
                        elapsed: tile.elapsed,
                        overdueLap: tile.overdueLap,
                        paused: paused || cancelled,
                        onDark: bg.computeLuminance() < 0.4,
                        textColor: fg,
                        size: metrics.ring,
                      ),
                    ),
                  ],
                ),
                // Never overflows: should wrapped text (animations off) be
                // taller than the tile, its top is clipped instead.
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.bottomLeft,
                      maxHeight: double.infinity,
                      child: info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // A change of look (due soon, overdue, paid, colours switched)
    // crossfades instead of snapping.
    final look = [
      brand,
      tile.dueSoon,
      tile.overdue,
      paused || cancelled,
      palette.brightness,
    ].join();
    return PressScale(
      child: AnimatedOpacity(
        opacity: paused || cancelled ? 0.5 : 1,
        duration: HomeMotion.of(context, HomeMotion.fade),
        child: AnimatedSwitcher(
          duration: HomeMotion.of(context, HomeMotion.fade),
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: KeyedSubtree(key: ValueKey(look), child: card),
        ),
      ),
    );
  }
}

/// A built-in line icon, or the name's initial, on a rounded square.
class _TileIcon extends StatelessWidget {
  const _TileIcon({
    required this.name,
    required this.icon,
    required this.size,
    required this.background,
    required this.color,
  });

  final String name;
  final IconData? icon;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: size * 0.58, color: color)
                : MediaQuery.withNoTextScaling(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: size * 0.47,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Long press on a tile: wide or single, icon, mark paid, open.
Future<void> _showTileMenu(BuildContext context, HomeTile tile) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _TileMenu(tile: tile),
    );

class _TileMenu extends ConsumerWidget {
  const _TileMenu({required this.tile});

  final HomeTile tile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final repo = ref.read(settingsRepositoryProvider);
    final id = tile.id;
    final chosen = settings?.tileIcons[id];
    final next = tile.view.nextDue;

    Widget choice(String? key, Widget child, String label) {
      final selected = chosen == key;
      return Tooltip(
        message: label,
        child: IconButton(
          key: ValueKey('tile-icon-${key ?? 'initial'}'),
          isSelected: selected,
          style: IconButton.styleFrom(
            backgroundColor: selected ? palette.selected : null,
            side: BorderSide(
              color: selected ? palette.primary : palette.divider,
            ),
          ),
          onPressed: () => repo.setTileIcon(id, key),
          icon: child,
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tile.view.row.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('tile-wide'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tileWide),
              value: settings?.wideTiles.contains(id) ?? false,
              onChanged: (wide) => repo.setWideTile(id, wide: wide),
            ),
            if ((next != null || tile.irregular) &&
                tile.status == ItemStatus.active)
              ListTile(
                key: const Key('tile-mark-paid'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l10n.actionMarkPaid),
                subtitle: next == null
                    ? null
                    : Text(_shortDate(context, next.dueOn)),
                onTap: () {
                  Navigator.of(context).pop();
                  showPaymentSheet(context, tile.view);
                },
              ),
            ListTile(
              key: const Key('tile-open'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.tileOpen),
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.go(Routes.item(id));
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tileIcon,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: palette.secondaryText),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                choice(
                  null,
                  Text(
                    tile.view.row.name.trim().isEmpty
                        ? '?'
                        : String.fromCharCode(
                            tile.view.row.name.trim().runes.first,
                          ).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  l10n.tileIconInitial,
                ),
                for (final (i, MapEntry(:key, :value))
                    in tileIcons.entries.indexed)
                  choice(key, Icon(value), '${l10n.tileIcon} ${i + 1}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- tablet cards -------------------------------------------------------------

/// A flat card for the tablet dashboard.
class _DashCard extends StatelessWidget {
  const _DashCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarqueeText(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          // Bottom-aligned; with very large text the top is clipped rather
          // than overflowing the fixed-height tile.
          Expanded(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomLeft,
                maxHeight: double.infinity,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed spending of the last 12 months (CLAUDE.md: tablet home card).
class _Last12Card extends StatelessWidget {
  const _Last12Card();

  @override
  Widget build(BuildContext context) => _DashCard(
    title: AppLocalizations.of(context).reportsLast12,
    child: const MonthBars(height: 48),
  );
}

/// The top categories by monthly cost.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard();

  @override
  Widget build(BuildContext context) => _DashCard(
    title: AppLocalizations.of(context).reportsByCategory,
    child: const CategoryBars(limit: 3),
  );
}

/// The last tablet tile: add an item.
class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    return CustomPaint(
      painter: _DashedBorder(color: palette.outline, radius: 16),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('tile-add'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => openAddItem(context),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 26, color: palette.secondaryText),
                const SizedBox(height: 8),
                MarqueeText(
                  l10n.homeAddItem,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
