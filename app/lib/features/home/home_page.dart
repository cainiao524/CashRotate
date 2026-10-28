import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../layout/window_class.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../theme/pearl_surface.dart';
import '../../widgets/marquee_text.dart';

/// Home dashboard skeleton: "how much is due this month, and what's next".
/// Cards are placeholders until M4 wires them to the ledger and reports.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      _DashboardCard(title: l10n.homeDueSoon, body: Text(l10n.emptyDueSoon)),
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

class _TotalCard extends StatelessWidget {
  const _TotalCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    return PearlSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeText(
            l10n.homeMonthlyFixedTotal,
            style: text.titleSmall?.copyWith(color: palette.secondaryText),
          ),
          const SizedBox(height: 8),
          Text('—', style: tabularFigures(text.displaySmall!)),
          const SizedBox(height: 8),
          Text(
            l10n.itemsPendingCount(0),
            style: text.bodyMedium?.copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
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
