import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../layout/window_class.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../theme/pearl_surface.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../items/items_page.dart';
import 'fixed_summary.dart';

/// Home dashboard: "how much a month, and what's next". Income/expense and
/// fixed-vs-variable cards wait for the ledger (M4).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      _DashboardCard(title: l10n.homeDueSoon, body: const _DueSoon()),
      _DashboardCard(
        title: l10n.homeIncomeExpense,
        body: const _AmountPlaceholder(),
      ),
      _DashboardCard(
        title: l10n.homeFixedVsVariable,
        body: const _AmountPlaceholder(),
      ),
    ];
    final columns = WindowClass.of(context) == WindowClass.expanded ? 2 : 1;

    return Scaffold(
      appBar: AppBar(title: const Text(Brand.appName)),
      body: ListView(
        key: const PageStorageKey('home'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _TotalCard(),
          const SizedBox(height: 16),
          _CardGrid(columns: columns, children: cards),
        ],
      ),
    );
  }
}

class _TotalCard extends ConsumerWidget {
  const _TotalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(fixedSummaryProvider).value;
    return PearlSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeText(
            l10n.homeMonthlyFixedTotal,
            style: text.titleSmall?.copyWith(color: palette.secondaryText),
          ),
          const SizedBox(height: 8),
          if (summary == null)
            Text('—', style: tabularFigures(text.displaySmall!))
          else
            MoneyText(
              summary.monthlyTotal,
              key: const Key('home-total'),
              style: text.displaySmall,
            ),
          const SizedBox(height: 8),
          Text(
            l10n.itemsPendingCount(summary?.needsDetails ?? 0),
            key: const Key('home-pending'),
            style: text.bodyMedium?.copyWith(
              color: (summary?.needsDetails ?? 0) > 0
                  ? palette.warning
                  : palette.secondaryText,
            ),
          ),
          if ((summary?.missingRates ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.obSummaryMissingRates,
                style: text.bodySmall?.copyWith(color: palette.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}

/// Items whose next charge is within 7 days (overdue included).
class _DueSoon extends ConsumerWidget {
  const _DueSoon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(itemsProvider).value ?? const [];
    final soon = todayFrom(ref.watch(clockProvider)).addDays(7);
    final due = items
        .where((v) => v.nextDue != null && v.nextDue!.dueOn <= soon)
        .toList();
    if (due.isEmpty) return Text(l10n.emptyDueSoon);
    return Column(children: [for (final v in due) ItemTile(view: v)]);
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: gap),
            child,
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarqueeText(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

class _AmountPlaceholder extends StatelessWidget {
  const _AmountPlaceholder();

  @override
  Widget build(BuildContext context) => Text(
    '—',
    style: tabularFigures(Theme.of(context).textTheme.headlineSmall!),
  );
}
