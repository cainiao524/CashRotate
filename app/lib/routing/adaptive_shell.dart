import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import '../layout/window_class.dart';

/// Navigation labels sit in fixed-width slots under icons. Beyond this text
/// scale they would be clipped, so they stop growing here; page content still
/// scales to 200%, and TalkBack reads the full label either way.
const navLabelMaxTextScale = 1.3;

/// Top-level frame: bottom navigation on compact windows, a rail otherwise.
///
/// Branch state (scroll position, half-filled forms) lives in the
/// [StatefulNavigationShell]'s indexed stack, so it survives switching tabs,
/// rotating, folding and entering split screen.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.home_outlined, Icons.home, l10n.navHome),
      (Icons.event_repeat_outlined, Icons.event_repeat, l10n.navItems),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        l10n.navLedger,
      ),
      (Icons.insert_chart_outlined, Icons.insert_chart, l10n.navReports),
      (Icons.settings_outlined, Icons.settings, l10n.navSettings),
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
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
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
