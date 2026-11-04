import 'dart:async';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../../features.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routing/router.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/money_text.dart';
import '../home/fixed_summary.dart';
import '../items/add_item_page.dart';
import '../payments/payment_sheet.dart';

/// Shortcut ids; stored by the launcher, so never rename one.
abstract final class AppShortcuts {
  static const add = 'add';
  static const pay = 'pay';
}

/// Sets the launcher shortcuts (in the current language) and acts on the
/// one the app was opened from: add an item, or record a payment.
class ShortcutBridge extends ConsumerStatefulWidget {
  const ShortcutBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShortcutBridge> createState() => _ShortcutBridgeState();
}

class _ShortcutBridgeState extends ConsumerState<ShortcutBridge>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _opened;
  String? _labels;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _opened = ref.read(shortcutPlatformProvider).opened.listen((_) => _take());
    WidgetsBinding.instance.addPostFrameCallback((_) => _take());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final shortcuts = Features.appShortcuts
        ? {
            AppShortcuts.add: l10n.shortcutAdd,
            AppShortcuts.pay: l10n.shortcutPay,
          }
        : const <String, String>{};
    // Only when the language (or the switch) changed.
    final labels = shortcuts.values.join('|');
    if (labels == _labels) return;
    _labels = labels;
    unawaited(
      ref.read(shortcutPlatformProvider).set(shortcuts).catchError((_) {}),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _take();
  }

  @override
  void dispose() {
    _opened?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _take() async {
    if (!mounted || !Features.appShortcuts) return;
    final String? id;
    try {
      id = await ref.read(shortcutPlatformProvider).takeOpened();
    } on Object {
      return;
    }
    if (id == null || !mounted) return;
    final router = ref.read(routerProvider);
    router.go(Routes.home);
    // Wait for the home page, under the navigator the sheets need.
    await WidgetsBinding.instance.endOfFrame;
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    switch (id) {
      case AppShortcuts.add:
        await openAddItem(context);
      case AppShortcuts.pay:
        await showPayPicker(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Record payment": pick the item, then the payment sheet. Items due
/// soonest come first.
Future<void> showPayPicker(BuildContext context) async {
  final view = await showModalBottomSheet<ItemView>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PayPicker(),
  );
  if (view != null && context.mounted) await showPaymentSheet(context, view);
}

class _PayPicker extends ConsumerWidget {
  const _PayPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items =
        [
          for (final v in ref.watch(itemsProvider).value ?? const <ItemView>[])
            if (v.row.status == ItemStatus.active && !v.row.needsDetails) v,
        ]..sort((a, b) {
          final da = a.nextDue?.dueOn, db = b.nextDue?.dueOn;
          if (da == null || db == null) return da == null ? 1 : -1;
          return da.compareTo(db);
        });
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.shortcutPickItem,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final v in items)
              ListTile(
                key: ValueKey('pay-pick-${v.row.id}'),
                title: MarqueeText(v.row.name),
                trailing: MoneyText(switch (v.nextDue) {
                  final next? => Money(next.expectedMinor, next.currency),
                  null => v.schedule.prices.stablePrice,
                }),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      ),
    );
  }
}
