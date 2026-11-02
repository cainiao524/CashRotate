import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/presets.dart';
import '../../data/providers.dart';

/// Parses notices from the picked apps (and text shared into the app) when
/// the app opens, comes back, or a notice arrives while it is open.
class DetectionBridge extends ConsumerStatefulWidget {
  const DetectionBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DetectionBridge> createState() => _DetectionBridgeState();
}

class _DetectionBridgeState extends ConsumerState<DetectionBridge>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sub;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = ref
        .read(noticePlatformProvider)
        .noticesAvailable
        .listen((_) => _run());
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  @override
  void dispose() {
    _sub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _run() async {
    if (!mounted || _running) return;
    final settings = ref.read(userSettingsProvider).value;
    final fx = ref.read(fxConverterProvider).value;
    if (settings == null || fx == null) return;
    _running = true;
    try {
      await ref
          .read(detectionServiceProvider)
          .processWaiting(
            region: settings.region,
            main: settings.mainCurrency,
            fx: fx,
            presets: ref.read(presetLibraryProvider).value,
          );
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
