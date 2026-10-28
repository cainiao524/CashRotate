import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/home/home_page.dart';
import '../features/items/items_page.dart';
import '../features/ledger/ledger_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/settings_page.dart';
import '../layout/window_class.dart';
import 'adaptive_shell.dart';

abstract final class Routes {
  static const home = '/home';
  static const items = '/items';
  static String item(String id) => '$items/$id';
  static const ledger = '/ledger';
  static const reports = '/reports';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    restorationScopeId: 'router',
    routes: [
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'shell',
        builder: (context, state, shell) => AdaptiveShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.items,
                builder: (_, _) => const ItemsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    // Two-pane windows show the selection beside the list
                    // without a page transition; compact windows push a page.
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return WindowClass.of(context).isTwoPane
                          ? NoTransitionPage(
                              key: state.pageKey,
                              child: ItemsPage(selectedId: id),
                            )
                          : MaterialPage(
                              key: state.pageKey,
                              child: ItemDetailPage(id: id),
                            );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ledger,
                builder: (_, _) => const LedgerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, _) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
