import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/providers.dart';
import '../features/backup/backup_page.dart';
import '../features/home/home_page.dart';
import '../features/items/items_page.dart';
import '../features/ledger/ledger_page.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/payments/payment_methods_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/amount_settings_page.dart';
import '../features/settings/settings_page.dart';
import '../features/sync/sync_settings_page.dart';
import '../layout/window_class.dart';
import 'adaptive_shell.dart';
import 'routes.dart';

export 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Whether first-launch setup is finished; null until settings load. A
  // notifier (not a watch) so the router is not rebuilt and keeps its state.
  final onboarded = ValueNotifier<bool?>(null);
  ref
    ..listen(
      userSettingsProvider,
      (_, next) => onboarded.value = next.value?.onboardingDone,
      fireImmediately: true,
    )
    ..onDispose(onboarded.dispose);

  final router = GoRouter(
    initialLocation: Routes.home,
    restorationScopeId: 'router',
    refreshListenable: onboarded,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      return switch (onboarded.value) {
        false when !atOnboarding => Routes.onboarding,
        true when atOnboarding => Routes.home,
        _ => null,
      };
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingFlow(),
      ),
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'shell',
        builder: (context, state, shell) =>
            AdaptiveShell(shell: shell, location: state.uri.path),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'amounts',
                        builder: (_, _) => const AmountSettingsPage(),
                      ),
                      GoRoute(
                        path: 'sync',
                        builder: (_, _) => const SyncSettingsPage(),
                      ),
                      GoRoute(
                        path: 'backup',
                        builder: (_, _) => const BackupPage(),
                      ),
                      GoRoute(
                        path: 'payment-methods',
                        builder: (_, _) => const PaymentMethodsPage(),
                      ),
                    ],
                  ),
                ],
              ),
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
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
