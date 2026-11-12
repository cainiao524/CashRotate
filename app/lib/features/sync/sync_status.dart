import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../data/sync/conflict_resolver.dart';
import '../../data/sync/drift_sync_store.dart';
import '../../data/sync/sync_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';

/// "Not set up", "Not synced yet" or "Last synced Mar 15 10:02".
String syncStatusText(
  BuildContext context,
  AppLocalizations l10n,
  SyncConfig? c,
) {
  if (c == null || !c.unlocked) return l10n.syncNotSetUp;
  if (c.lastSyncAt == null) return l10n.syncNever;
  final at = DateTime.fromMillisecondsSinceEpoch(c.lastSyncAt!);
  return l10n.syncLast(
    DateFormat.MMMd(intlLocaleOf(context)).add_Hm().format(at),
  );
}

/// Changes waiting to upload, conflicts waiting for the user, and the
/// deleted items those conflicts are about.
typedef SyncPending = ({
  int pending,
  int conflicts,
  List<DeletedItemConflict> deleted,
});

/// Refreshed whenever the local clock or the sync state changes (both are
/// kept in `meta`, which every journaled write touches).
final syncPendingProvider = StreamProvider<SyncPending>((ref) async* {
  final db = await ref.watch(appDatabaseProvider.future);
  final store = DriftSyncStore(db, ref.watch(journalProvider));
  final service = await ref.watch(syncServiceProvider.future);
  final resolver = ref.watch(conflictResolverProvider);
  await for (final _ in db.select(db.meta).watch()) {
    yield (
      pending: await service.pendingCount(),
      conflicts: (await store.conflictsJson()).length,
      deleted: await resolver.deletedItems(),
    );
  }
});

/// Whether a background sync is running, for the header animation.
class SyncRunningNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool running) => state = running;
}

final syncRunningProvider = NotifierProvider<SyncRunningNotifier, bool>(
  SyncRunningNotifier.new,
);

/// "Just now", "5 min ago", "3 h ago", else the date.
String syncAgo(
  BuildContext context,
  AppLocalizations l10n,
  DateTime at,
  DateTime now,
) {
  final minutes = now.difference(at).inMinutes;
  if (minutes < 1) return l10n.syncAgoJustNow;
  if (minutes < 60) return l10n.syncAgoMinutes(minutes);
  if (minutes < 24 * 60) return l10n.syncAgoHours(minutes ~/ 60);
  return DateFormat.MMMd(intlLocaleOf(context)).format(at);
}

/// Sync at a glance on the home page, once sync is set up: syncing (the
/// icon turns), failed, needs a decision, waiting to upload, or up to date
/// with how long ago. Each state has its own icon (not only a colour) and
/// says what it means; tapping opens sync settings.
class SyncStatusButton extends ConsumerStatefulWidget {
  const SyncStatusButton({super.key});

  @override
  ConsumerState<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends ConsumerState<SyncStatusButton>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "5 min ago" moves on by itself.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(syncConfigProvider).value;
    if (config == null || !config.unlocked) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final status = ref.watch(syncPendingProvider).value;
    final running = ref.watch(syncRunningProvider);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (running && !reduced) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
    final conflicts = status?.conflicts ?? 0;
    final pending = status?.pending ?? 0;
    final now = ref.watch(clockProvider)();
    final last = config.lastSyncAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(config.lastSyncAt!);
    final (
      IconData icon,
      String label,
      String? short,
      Color? color,
    ) = switch (null) {
      _ when running => (Icons.sync, l10n.syncRunning, l10n.syncRunning, null),
      _ when config.lastError != null => (
        Icons.cloud_off_outlined,
        l10n.syncFailed(config.lastError!),
        null,
        palette.error,
      ),
      _ when conflicts > 0 => (
        Icons.sync_problem_outlined,
        l10n.syncConflicts(conflicts),
        null,
        palette.warning,
      ),
      _ when pending > 0 => (
        Icons.cloud_upload_outlined,
        l10n.syncPending(pending),
        null,
        null,
      ),
      _ => (
        Icons.cloud_done_outlined,
        syncStatusText(context, l10n, config),
        last == null ? null : syncAgo(context, l10n, last, now),
        null,
      ),
    };
    // The short text only while it fits beside the title.
    final showText =
        short != null && MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final glyph = RotationTransition(
      // The arrows turn the way they point.
      turns: Tween(begin: 0.0, end: -1.0).animate(_spin),
      child: Icon(icon, color: color, size: 22),
    );
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          key: const Key('home-sync-status'),
          radius: 24,
          onTap: () => context.go(Routes.settingsSync),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  glyph,
                  if (showText) ...[
                    const SizedBox(width: 6),
                    Text(
                      short,
                      key: const Key('home-sync-ago'),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
