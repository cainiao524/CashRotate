import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/providers.dart';
import '../../data/security/app_lock.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/palette.dart';

/// A numeric PIN pad. Calls [onComplete] when [exactLength] digits are in,
/// or on "OK" once at least [minLength] are (setting a new PIN).
///
/// Used outside the Navigator too (the lock screen), so it uses no
/// tooltips or other overlay-dependent widgets.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.exactLength,
    this.minLength = 4,
    this.maxLength = 6,
    this.message,
    this.messageIsError = false,
    this.enabled = true,
    this.onBiometric,
  });

  final String title;
  final ValueChanged<String> onComplete;
  final int? exactLength;
  final int minLength;
  final int maxLength;
  final String? message;
  final bool messageIsError;
  final bool enabled;
  final VoidCallback? onBiometric;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  void clear() => setState(() => _pin = '');

  int get _max => widget.exactLength ?? widget.maxLength;

  void _digit(String d) {
    if (!widget.enabled || _pin.length >= _max) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (widget.exactLength != null && _pin.length == widget.exactLength) {
      final pin = _pin;
      widget.onComplete(pin);
    }
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final showOk = widget.exactLength == null;

    Widget key(String label, VoidCallback? onTap, {Key? k, Widget? child}) =>
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: SizedBox(
            width: 76,
            height: 64,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: k,
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Center(
                  child:
                      child ??
                      Text(
                        label,
                        style: text.headlineSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                ),
              ),
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Semantics(
          label: '${_pin.length} / $_max',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _max; i++)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? palette.primary : null,
                    border: Border.all(color: palette.outline),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: Center(
            child: widget.message == null
                ? null
                : Text(
                    widget.message!,
                    key: const Key('pin-message'),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: widget.messageIsError
                          ? palette.error
                          : palette.secondaryText,
                    ),
                  ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in row) key(d, () => _digit(d), k: Key('pin-$d')),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onBiometric != null)
              key(
                l10n.lockUseBiometric,
                widget.onBiometric,
                k: const Key('pin-biometric'),
                child: const Icon(Icons.fingerprint, size: 30),
              )
            else if (showOk)
              key(
                l10n.actionDone,
                _pin.length >= widget.minLength
                    ? () => widget.onComplete(_pin)
                    : null,
                k: const Key('pin-ok'),
                child: Icon(
                  Icons.check,
                  color: _pin.length >= widget.minLength
                      ? palette.text
                      : palette.outline,
                ),
              )
            else
              const SizedBox(width: 76, height: 64),
            key('0', () => _digit('0'), k: const Key('pin-0')),
            key(
              l10n.actionDelete,
              _back,
              k: const Key('pin-back'),
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

/// Covers the app until the PIN (or a fingerprint / face) unlocks it.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.config, required this.onUnlock});

  final AppLockConfig config;
  final VoidCallback onUnlock;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pad = GlobalKey<PinPadState>();
  int _wrong = 0;
  DateTime? _waitUntil;
  Timer? _tick;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.config.biometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _biometric() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(biometricAuthProvider)
        .authenticate(l10n.lockReason(Brand.appName));
    if (ok && mounted) widget.onUnlock();
  }

  Future<void> _check(String pin) async {
    setState(() => _checking = true);
    final repo = await ref.read(appLockRepositoryProvider.future);
    final ok = await repo.verify(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlock();
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    _pad.currentState?.clear();
    setState(() {
      _checking = false;
      _wrong++;
      if (_wrong >= AppLockRepository.freeAttempts) {
        // 30 s, doubling with each further miss.
        final seconds = 30 << (_wrong - AppLockRepository.freeAttempts);
        _waitUntil = ref.read(clockProvider)().add(Duration(seconds: seconds));
        _tick?.cancel();
        _tick = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return t.cancel();
          setState(() {});
          if (_remaining <= 0) t.cancel();
        });
      }
    });
  }

  int get _remaining {
    final until = _waitUntil;
    if (until == null) return 0;
    final left = until.difference(ref.read(clockProvider)()).inSeconds;
    return left < 0 ? 0 : left + 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final wait = _remaining;
    return Material(
      key: const Key('lock-screen'),
      color: palette.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: palette.secondaryText,
                ),
                const SizedBox(height: 16),
                PinPad(
                  key: _pad,
                  title: l10n.lockEnterPin,
                  exactLength: widget.config.pinLength,
                  enabled: wait == 0 && !_checking,
                  message: wait > 0
                      ? l10n.lockWait(wait)
                      : _wrong > 0
                      ? l10n.lockWrongPin
                      : null,
                  messageIsError: wait > 0 || _wrong > 0,
                  onComplete: _check,
                  onBiometric: widget.config.biometric ? _biometric : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts [LockScreen] over the app when the lock is on: at start, and when
/// the app comes back after being away longer than the chosen time. The
/// app stays mounted underneath, so nothing typed is lost.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool? _locked;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = ref.read(clockProvider)();
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _leftAt ??= now;
      case AppLifecycleState.resumed:
        final config = ref.read(appLockConfigProvider).value;
        final left = _leftAt;
        _leftAt = null;
        if (config != null &&
            left != null &&
            now.difference(left).inSeconds >= config.timeoutSeconds) {
          setState(() => _locked = true);
        }
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appLockConfigProvider);
    if (!async.hasValue) {
      // Never flash the app before knowing whether it is locked.
      return ColoredBox(color: Palette.of(context).background);
    }
    final config = async.value;
    _locked ??= config != null;
    final locked = config != null && _locked!;
    return Stack(
      children: [
        ExcludeSemantics(excluding: locked, child: widget.child),
        if (locked)
          Positioned.fill(
            child: LockScreen(
              config: config,
              onUnlock: () => setState(() => _locked = false),
            ),
          ),
      ],
    );
  }
}
