import 'dart:async';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../data/reminders/reminder_platform.dart';
import '../../data/settings/settings_repository.dart';
import '../../features.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/router.dart';
import '../../widgets/preset_badge.dart';
import '../home/fixed_summary.dart';
import '../home/tile_icons.dart';

/// The notification's large icon for [v], like its home tile: the chosen
/// line icon or the initial; monochrome unless tiles use service colours.
NotificationBadge notificationBadge(
  ItemView v,
  UserSettings settings,
  Map<String, Preset> presets,
) {
  final badge = badgeOf(v.row.id, v.row.name, settings);
  final background = badge.color != null
      ? InitialBadge.parse(badge.color!)
      : settings.tileColors
      ? InitialBadge.parse(presets[v.row.presetId]?.color ?? '#64748B')
      : const Color(0xFF111111);
  return NotificationBadge(
    letter: badge.text,
    background: background.toARGB32(),
    foreground: InitialBadge.foregroundFor(background).toARGB32(),
    iconCodePoint: badge.icon?.codePoint,
  );
}

/// Pending and recent charges the reminder planner looks at.
final reminderOccurrencesProvider = StreamProvider<List<OccurrenceRow>>((ref) {
  final today = todayFrom(ref.watch(clockProvider));
  return ref
      .watch(itemRepositoryProvider)
      .watchDue(today.addDays(-366), today.addDays(reminderHorizonDays));
});

/// Keeps the native reminders in step with the data, and brings back what
/// happened while the app was closed:
///
/// - re-plans (worded in the current language) whenever items, charges or
///   settings change, the language changes, or the app comes back;
/// - copies deliveries and notification actions into ReminderLog and
///   settles charges marked "Paid" from a notification;
/// - opens the item whose notification was tapped.
class ReminderBridge extends ConsumerStatefulWidget {
  const ReminderBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderBridge> createState() => _ReminderBridgeState();
}

class _ReminderBridgeState extends ConsumerState<ReminderBridge>
    with WidgetsBindingObserver {
  Timer? _debounce;
  final _subscriptions = <StreamSubscription<void>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final platform = ref.read(reminderPlatformProvider);
    _subscriptions
      ..add(platform.eventsAvailable.listen((_) => _applyEvents()))
      ..add(platform.itemOpened.listen((_) => _openTappedItem()));
    for (final p in <ProviderListenable<AsyncValue<Object?>>>[
      itemsProvider,
      reminderOccurrencesProvider,
      userSettingsProvider,
      presetLibraryProvider, // cancel links and badge colours
    ]) {
      ref.listenManual(p, (_, _) => _schedule());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyEvents();
      _openTappedItem();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule(); // first run, and after a language change
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _applyEvents();
    _openTappedItem();
    _schedule(); // the day may have changed
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-plans shortly after the last change, so a batch of edits plans once.
  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _sync);
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final items = ref.read(itemsProvider).value;
    final occurrences = ref.read(reminderOccurrencesProvider).value;
    final settings = ref.read(userSettingsProvider).value;
    if (items == null || occurrences == null || settings == null) return;
    final l10n = AppLocalizations.of(context);
    final locale = intlLocaleOf(context);
    final service = ref.read(reminderServiceProvider);
    final presets = ref.read(presetLibraryProvider).value?.byId ?? const {};
    final planned = await service.sync(
      items: items,
      occurrences: occurrences,
      settings: settings,
      l10n: l10n,
      locale: locale,
      badges: {
        for (final v in items)
          v.row.id: notificationBadge(v, settings, presets),
      },
      cancelUrls: {
        if (Features.goCancel)
          for (final v in items)
            if ((v.typeFields['cancelUrl'] as String?) ??
                    presets[v.row.presetId]?.cancelUrl
                case final url? when url.isNotEmpty)
              v.row.id: url,
      },
    );
    if (planned.isNotEmpty) await service.askPermissionOnce();
  }

  Future<void> _applyEvents() async {
    if (!mounted) return;
    await ref
        .read(reminderServiceProvider)
        .applyEvents(main: ref.read(userSettingsProvider).value?.mainCurrency);
  }

  Future<void> _openTappedItem() async {
    if (!mounted) return;
    final id = await ref.read(reminderPlatformProvider).takeOpenedItem();
    if (id == null || id.isEmpty || !mounted) return;
    ref.read(routerProvider).go(Routes.item(id));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
