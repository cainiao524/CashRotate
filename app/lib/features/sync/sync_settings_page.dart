import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../data/sync/conflict_resolver.dart';
import '../../data/sync/drift_sync_store.dart';
import '../../data/sync/sync_crypto.dart';
import '../../data/sync/sync_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import 'sync_status.dart';

export 'sync_status.dart' show syncStatusText;

/// The settings row: sync status at a glance, opens [SyncSettingsPage].
class SyncSettingsTile extends ConsumerWidget {
  const SyncSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(syncConfigProvider).value;
    return ListTile(
      key: const Key('settings-sync'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cloud_sync_outlined),
      title: Text(l10n.syncTitle),
      subtitle: Text(syncStatusText(context, l10n, config)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.settingsSync),
    );
  }
}

/// Connect a WebDAV folder, set up or unlock its encryption, and see how
/// syncing goes.
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key, this.onRestored});

  /// First launch, "restore from WebDAV": only joining an existing folder is
  /// offered, and this runs once its data has been downloaded.
  final VoidCallback? onRestored;

  bool get restoreOnly => onRestored != null;

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

enum _Step { connect, create, join, recover }

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _serverPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  final _ownCode = TextEditingController();
  final _recoveryInput = TextEditingController();

  _Step? _step;
  bool _busy = false;
  String? _error;
  bool _generate = true;
  String? _generated;
  bool _saved = false;

  @override
  void dispose() {
    for (final c in [
      _url,
      _user,
      _serverPassword,
      _password,
      _passwordAgain,
      _ownCode,
      _recoveryInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function(SyncService s) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      await action(await ref.read(syncServiceProvider.future));
    } on WebDavException catch (e) {
      _error = e.isAuth
          ? l10n.syncAuthFailed
          : l10n.syncConnectFailed(e.summary);
    } on SyncCipherException {
      _error = _step == _Step.recover
          ? l10n.syncWrongRecovery
          : l10n.syncWrongPassword;
    } on Exception catch (e) {
      _error = l10n.syncConnectFailed('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run((s) async {
    final nothing = AppLocalizations.of(context).syncRestoreNothing;
    final existing = await s.connect(
      _url.text.trim(),
      _user.text.trim(),
      _serverPassword.text,
    );
    if (!existing && widget.restoreOnly) {
      // Nothing to restore here; don't start a new sync folder instead.
      _error = nothing;
      await s.disconnect();
      return;
    }
    _step = existing ? _Step.join : _Step.create;
    if (!existing) {
      _generated ??= SyncKeys(await ref.read(sodiumProvider.future))
          .generateRecoveryCode();
    }
  });

  String? get _passwordProblem {
    final l10n = AppLocalizations.of(context);
    if (_password.text.length < 8) return l10n.syncPasswordShort;
    if (_step == _Step.create && _password.text != _passwordAgain.text) {
      return l10n.syncPasswordMismatch;
    }
    return null;
  }

  String get _recoveryCode => _generate ? _generated ?? '' : _ownCode.text;

  bool get _canCreate =>
      _passwordProblem == null &&
      _saved &&
      (_generate || SyncKeys.strength(_ownCode.text) == RecoveryStrength.ok);

  Future<void> _finish(Future<void> Function(SyncService s) unlock) async {
    await _run((s) async {
      await unlock(s);
      _step = null;
      await s.syncNow();
    });
    if (_error == null && mounted) widget.onRestored?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(syncConfigProvider).value;
    final step = _step ?? (config?.unlocked ?? false ? null : _Step.connect);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const PageStorageKey('settings-sync'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                l10n.syncIntro,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
              const SizedBox(height: 16),
              ...switch (step) {
                null => _statusView(context, config!),
                _Step.connect => _connectForm(context),
                _Step.create => _createForm(context),
                _Step.join => _joinForm(context),
                _Step.recover => _recoverForm(context),
              },
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('sync-error'),
                  style: text.bodyMedium?.copyWith(color: palette.error),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                if (step == _Step.create ||
                    step == _Step.join ||
                    step == _Step.recover) ...[
                  const SizedBox(height: 8),
                  Text(l10n.syncDeriving, style: text.bodySmall),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    String? hint,
    String? error,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: Key(key),
      controller: controller,
      obscureText: obscure,
      enableSuggestions: !obscure,
      autocorrect: false,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        errorMaxLines: 3,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  List<Widget> _connectForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _field(
        'sync-url',
        _url,
        l10n.syncServerUrl,
        hint: l10n.syncServerHint,
        keyboard: TextInputType.url,
      ),
      _field('sync-user', _user, l10n.syncUser),
      _field(
        'sync-server-password',
        _serverPassword,
        l10n.syncAppPassword,
        obscure: true,
      ),
      FilledButton(
        key: const Key('sync-connect'),
        onPressed: _busy || _url.text.trim().isEmpty ? null : _connect,
        child: Text(l10n.syncConnect),
      ),
    ];
  }

  List<Widget> _createForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final typed = _password.text.isNotEmpty;
    final ownStrength = SyncKeys.strength(_ownCode.text);
    return [
      Text(l10n.syncCreateTitle, style: text.titleMedium),
      const SizedBox(height: 12),
      _field(
        'sync-password',
        _password,
        l10n.syncPassword,
        obscure: true,
        error: typed && _password.text.length < 8
            ? l10n.syncPasswordShort
            : null,
      ),
      _field(
        'sync-password-again',
        _passwordAgain,
        l10n.syncPasswordAgain,
        obscure: true,
        error:
            _passwordAgain.text.isNotEmpty &&
                _password.text != _passwordAgain.text
            ? l10n.syncPasswordMismatch
            : null,
      ),
      const SizedBox(height: 8),
      Text(l10n.syncRecoveryTitle, style: text.titleSmall),
      RadioGroup<bool>(
        groupValue: _generate,
        onChanged: (v) => setState(() => _generate = v ?? true),
        child: Column(
          children: [
            RadioListTile<bool>(
              key: const Key('sync-recovery-generate'),
              contentPadding: EdgeInsets.zero,
              value: true,
              title: Text(l10n.syncRecoveryGenerate),
            ),
            RadioListTile<bool>(
              key: const Key('sync-recovery-own'),
              contentPadding: EdgeInsets.zero,
              value: false,
              title: Text(l10n.syncRecoveryOwn),
            ),
          ],
        ),
      ),
      if (_generate && _generated != null)
        Row(
          children: [
            Expanded(
              child: SelectableText(
                _generated!,
                key: const Key('sync-recovery-code'),
                style: text.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l10n.syncRecoveryCopy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _generated!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.syncRecoveryCopied)),
                );
              },
            ),
          ],
        )
      else if (!_generate)
        _field(
          'sync-recovery-input',
          _ownCode,
          l10n.syncRecoveryTitle,
          obscure: true,
          error: _ownCode.text.isNotEmpty && ownStrength != RecoveryStrength.ok
              ? l10n.syncRecoveryWeak
              : null,
        ),
      const SizedBox(height: 8),
      Text(
        l10n.syncRecoveryWarning,
        style: text.bodyMedium?.copyWith(color: palette.warning),
      ),
      CheckboxListTile(
        key: const Key('sync-recovery-saved'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _saved,
        title: Text(l10n.syncRecoveryConfirm),
        onChanged: (v) => setState(() => _saved = v ?? false),
      ),
      const SizedBox(height: 8),
      FilledButton(
        key: const Key('sync-create'),
        onPressed: _busy || !_canCreate
            ? null
            : () => _finish(
                (s) => s.create(
                  password: _password.text,
                  recoveryCode: _recoveryCode,
                ),
              ),
        child: Text(l10n.syncCreate),
      ),
    ];
  }

  List<Widget> _joinForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      Text(l10n.syncJoinTitle, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      _field('sync-password', _password, l10n.syncPassword, obscure: true),
      FilledButton(
        key: const Key('sync-join'),
        onPressed: _busy || _password.text.isEmpty
            ? null
            : () => _finish((s) => s.join(_password.text)),
        child: Text(l10n.syncJoin),
      ),
      TextButton(
        key: const Key('sync-forgot'),
        onPressed: () => setState(() {
          _step = _Step.recover;
          _error = null;
        }),
        child: Text(l10n.syncForgot),
      ),
    ];
  }

  List<Widget> _recoverForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _field('sync-recovery-input', _recoveryInput, l10n.syncRecoveryTitle),
      _field(
        'sync-password',
        _password,
        l10n.syncNewPassword,
        obscure: true,
        error: _password.text.isNotEmpty && _password.text.length < 8
            ? l10n.syncPasswordShort
            : null,
      ),
      FilledButton(
        key: const Key('sync-recover'),
        onPressed:
            _busy || _recoveryInput.text.isEmpty || _password.text.length < 8
            ? null
            : () => _finish(
                (s) => s.recover(
                  recoveryCode: _recoveryInput.text,
                  newPassword: _password.text,
                ),
              ),
        child: Text(l10n.syncRecover),
      ),
    ];
  }

  List<Widget> _statusView(BuildContext context, SyncConfig config) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_done_outlined),
        title: Text(syncStatusText(context, l10n, config)),
        subtitle: Text(config.url),
      ),
      if (config.lastError != null)
        Text(
          l10n.syncFailed(config.lastError!),
          key: const Key('sync-last-error'),
          style: text.bodyMedium?.copyWith(color: palette.error),
        ),
      const _PendingAndConflicts(),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const Key('sync-now'),
        icon: const Icon(Icons.sync),
        label: Text(l10n.syncNow),
        onPressed: _busy ? null : () => _run((s) async => s.syncNow()),
      ),
      const SizedBox(height: 24),
      ListTile(
        key: const Key('sync-disconnect'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(l10n.syncDisconnect),
        subtitle: Text(l10n.syncDisconnectHint),
        onTap: () => _run((s) async {
          await s.disconnect();
          _step = _Step.connect;
        }),
      ),
    ];
  }
}

/// Changes waiting to upload, and conflicts waiting for the user: each
/// deleted item that was edited elsewhere can be restored or kept deleted.
class _PendingAndConflicts extends ConsumerWidget {
  const _PendingAndConflicts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final status = ref.watch(syncPendingProvider).value;
    if (status == null) return const SizedBox.shrink();
    final resolver = ref.read(conflictResolverProvider);
    // Conflicts not about an item (rare) can only be dismissed.
    final others =
        status.conflicts - status.deleted.fold(0, (n, d) => n + d.changes);

    String nameOf(DeletedItemConflict d) =>
        d.name.isEmpty ? l10n.itemsTitle : d.name;

    Future<void> restore(DeletedItemConflict d) async {
      final messenger = ScaffoldMessenger.of(context);
      final restored = await resolver.restore(d.itemId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            restored == null
                ? l10n.syncRestoreFailed
                : l10n.syncRestored(nameOf(d)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.syncPending(status.pending), key: const Key('sync-pending')),
        if (status.conflicts > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.syncConflicts(status.conflicts),
            style: TextStyle(color: palette.warning),
          ),
        ],
        for (final d in status.deleted)
          Padding(
            key: ValueKey('sync-conflict-${d.itemId}'),
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.syncConflictItem(nameOf(d))),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(
                      key: ValueKey('sync-restore-${d.itemId}'),
                      onPressed: () => restore(d),
                      child: Text(l10n.syncRestoreItem),
                    ),
                    TextButton(
                      key: ValueKey('sync-keep-deleted-${d.itemId}'),
                      onPressed: () => resolver.keepDeleted(d.itemId),
                      child: Text(l10n.syncKeepDeleted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (others > 0) ...[
          Text(l10n.syncConflictsHint),
          TextButton(
            key: const Key('sync-dismiss-conflicts'),
            onPressed: () => DriftSyncStore(
              ref.read(appDatabaseProvider).requireValue,
              ref.read(journalProvider),
            ).clearConflicts(),
            child: Text(l10n.syncDismissConflicts),
          ),
        ],
      ],
    );
  }
}
