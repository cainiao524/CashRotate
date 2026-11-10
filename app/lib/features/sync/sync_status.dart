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

/// Sync at a glance on the home page, once sync is set up: failed, needs a
/// decision, waiting to upload, or up to date. Each state has its own icon
/// (not only a colour) and says what it means; tapping opens sync settings.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(syncConfigProvider).value;
    if (config == null || !config.unlocked) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final status = ref.watch(syncPendingProvider).value;
    final conflicts = status?.conflicts ?? 0;
    final pending = status?.pending ?? 0;
    final (IconData icon, String label, Color? color) = switch (null) {
      _ when config.lastError != null => (
        Icons.cloud_off_outlined,
        l10n.syncFailed(config.lastError!),
        palette.error,
      ),
      _ when conflicts > 0 => (
        Icons.sync_problem_outlined,
        l10n.syncConflicts(conflicts),
        palette.warning,
      ),
      _ when pending > 0 => (
        Icons.cloud_upload_outlined,
        l10n.syncPending(pending),
        null,
      ),
      _ => (
        Icons.cloud_done_outlined,
        syncStatusText(context, l10n, config),
        null,
      ),
    };
    return IconButton(
      key: const Key('home-sync-status'),
      tooltip: label,
      icon: Icon(icon, color: color),
      onPressed: () => context.go(Routes.settingsSync),
    );
  }
}
