import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../home/fixed_summary.dart';
import 'sync_status.dart';

/// Syncs in the background once sync is set up: when the app opens, when it
/// comes back to the foreground, and a little after local changes settle.
/// Failures are recorded on the sync settings page; nothing here blocks or
/// interrupts the user.
class SyncBridge extends ConsumerStatefulWidget {
  const SyncBridge({super.key, required this.child});

  final Widget child;

  /// Quiet time after the last local change before uploading it.
  static const afterChanges = Duration(seconds: 20);

  @override
  ConsumerState<SyncBridge> createState() => _SyncBridgeState();
}

class _SyncBridgeState extends ConsumerState<SyncBridge>
    with WidgetsBindingObserver {
  Timer? _debounce;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final p in [itemsProvider, userSettingsProvider]) {
      ref.listenManual(p, (previous, _) {
        if (previous != null) _soon();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _soon() {
    _debounce?.cancel();
    _debounce = Timer(SyncBridge.afterChanges, _sync);
  }

  Future<void> _sync() async {
    if (!mounted || _running) return;
    final config = ref.read(syncConfigProvider).value;
    if (config == null || !config.unlocked) return;
    _running = true;
    final shown = ref.read(syncRunningProvider.notifier)..set(true);
    try {
      await (await ref.read(syncServiceProvider.future)).syncNow();
    } finally {
      _running = false;
      if (mounted) shown.set(false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
