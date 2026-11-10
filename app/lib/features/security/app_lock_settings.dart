import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/palette.dart';
import 'lock_screen.dart';

/// App lock in settings: on/off (setting a PIN), fingerprint or face, when
/// to lock again, change PIN.
class AppLockSettings extends ConsumerWidget {
  const AppLockSettings({super.key});

  static const timeouts = [0, 60, 300];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final config = ref.watch(appLockConfigProvider).value;
    final biometricAvailable =
        ref.watch(_biometricAvailableProvider).value ?? false;

    Future<void> setPin() async {
      final pin = await Navigator.of(context)
          .push<String>(MaterialPageRoute(builder: (_) => const SetPinPage()));
      if (pin == null) return;
      await (await ref.read(appLockRepositoryProvider.future)).setPin(pin);
    }

    Future<bool> confirmPin() async {
      final ok = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const ConfirmPinPage()));
      return ok ?? false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('settings-app-lock'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.lock_outline),
          title: Text(l10n.appLockTitle),
          subtitle: Text(config == null ? l10n.appLockOff : l10n.appLockOn),
          value: config != null,
          onChanged: (on) async {
            if (on) {
              await setPin();
            } else if (await confirmPin()) {
              await (await ref.read(appLockRepositoryProvider.future))
                  .disable();
            }
          },
        ),
        if (config != null) ...[
          if (biometricAvailable)
            SwitchListTile(
              key: const Key('settings-app-lock-biometric'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.appLockBiometric),
              value: config.biometric,
              onChanged: (on) async =>
                  (await ref.read(appLockRepositoryProvider.future))
                      .update((c) => c.copyWith(biometric: on)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.appLockTimeout),
            subtitle: Wrap(
              spacing: 8,
              children: [
                for (final s in timeouts)
                  ChoiceChip(
                    key: ValueKey('app-lock-timeout-$s'),
                    label: Text(
                      s == 0
                          ? l10n.appLockImmediately
                          : l10n.appLockAfterMinutes(s ~/ 60),
                    ),
                    selected: config.timeoutSeconds == s,
                    onSelected: (_) async =>
                        (await ref.read(appLockRepositoryProvider.future))
                            .update((c) => c.copyWith(timeoutSeconds: s)),
                  ),
              ],
            ),
          ),
          ListTile(
            key: const Key('settings-app-lock-change'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password),
            title: Text(l10n.appLockChangePin),
            onTap: () async {
              if (await confirmPin()) await setPin();
            },
          ),
          Text(
            l10n.appLockForgotHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.lockRecentsHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.secondaryText),
          ),
        ],
      ],
    );
  }
}

final _biometricAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(biometricAuthProvider).available(),
);

/// Choose a new PIN: type it, then type it again. Pops with the PIN.
class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final _pad = GlobalKey<PinPadState>();
  String? _first;
  bool _mismatch = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLockSetPin)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            key: _pad,
            title: _first == null ? l10n.appLockNewPin : l10n.appLockConfirmPin,
            exactLength: _first?.length,
            message: _mismatch ? l10n.appLockMismatch : null,
            messageIsError: _mismatch,
            onComplete: (pin) {
              if (_first == null) {
                setState(() {
                  _first = pin;
                  _mismatch = false;
                });
                _pad.currentState?.clear();
              } else if (pin == _first) {
                Navigator.of(context).pop(pin);
              } else {
                setState(() {
                  _first = null;
                  _mismatch = true;
                });
                _pad.currentState?.clear();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Asks for the current PIN before turning the lock off or changing it.
class ConfirmPinPage extends ConsumerStatefulWidget {
  const ConfirmPinPage({super.key});

  @override
  ConsumerState<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends ConsumerState<ConfirmPinPage> {
  final _pad = GlobalKey<PinPadState>();
  bool _wrong = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appLockConfigProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLockTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            key: _pad,
            title: l10n.lockEnterPin,
            exactLength: config?.pinLength,
            message: _wrong ? l10n.lockWrongPin : null,
            messageIsError: _wrong,
            onComplete: (pin) async {
              final repo = await ref.read(appLockRepositoryProvider.future);
              final ok = await repo.verify(pin);
              if (!context.mounted) return;
              if (ok) {
                Navigator.of(context).pop(true);
              } else {
                _pad.currentState?.clear();
                setState(() => _wrong = true);
              }
            },
          ),
        ),
      ),
    );
  }
}
