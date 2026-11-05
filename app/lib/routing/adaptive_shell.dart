import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/items/add_item_page.dart';
import '../l10n/gen/app_localizations.dart';
import '../layout/window_class.dart';
import 'routes.dart';

/// Navigation labels sit in fixed-width slots under icons. Beyond this text
/// scale they would be clipped, so they stop growing here; page content still
/// scales to 200%, and TalkBack reads the full label either way.
const navLabelMaxTextScale = 1.3;

/// Top-level frame: bottom navigation on compact windows, a rail otherwise.
/// Settings is not a tab: phones open it from the home header, the rail
/// keeps it at its foot under an add button.
///
/// Branch state (scroll position, half-filled forms) lives in the
/// [StatefulNavigationShell]'s indexed stack, so it survives switching tabs,
/// rotating, folding and entering split screen.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell, required this.location});

  final StatefulNavigationShell shell;

  /// Current path, to mark settings as selected on the rail.
  final String location;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.home_outlined, Icons.home, l10n.navHome),
      (Icons.event_repeat_outlined, Icons.event_repeat, l10n.navItems),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navPayments),
      (Icons.insert_chart_outlined, Icons.insert_chart, l10n.navReports),
    ];

    if (!WindowClass.of(context).isTwoPane) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: MediaQuery.withClampedTextScaling(
          maxScaleFactor: navLabelMaxTextScale,
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            destinations: [
              for (final (icon, selected, label) in destinations)
                NavigationDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selected),
                  label: label,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: navLabelMaxTextScale,
            child: NavigationRail(
              selectedIndex: location == Routes.settings
                  ? null
                  : shell.currentIndex,
              onDestinationSelected: _select,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FloatingActionButton(
                  key: const Key('rail-add'),
                  heroTag: null,
                  elevation: 2,
                  tooltip: l10n.actionAdd,
                  onPressed: () => openAddItem(context),
                  child: const Icon(Icons.add),
                ),
              ),
              trailingAtBottom: true,
              // Short landscape windows: destinations scroll between the
              // add button and settings.
              scrollable: true,
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RailButton(
                  key: const Key('nav-settings'),
                  icon: Icons.tune,
                  label: l10n.navSettings,
                  selected: location == Routes.settings,
                  onTap: () => context.go(Routes.settings),
                ),
              ),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

/// A rail entry outside the destination list (settings at the rail's foot),
/// drawn like a destination.
class _RailButton extends StatelessWidget {
  const _RailButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NavigationRailTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? theme.indicatorColor : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: selected
                      ? theme.selectedLabelTextStyle ?? text.labelMedium
                      : theme.unselectedLabelTextStyle ?? text.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
