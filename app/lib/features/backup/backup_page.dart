import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/backup/backup_service.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';

/// The settings row that opens [BackupPage].
class BackupSettingsTile extends StatelessWidget {
  const BackupSettingsTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('settings-backup'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.history),
    title: Text(AppLocalizations.of(context).backupTitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go(Routes.settingsBackup),
  );
}

final _backupsProvider = FutureProvider.autoDispose<List<LocalBackup>>(
  (ref) async => (await ref.watch(backupServiceProvider.future)).list(),
);

/// Automatic backups on the phone (restore any of the last seven), and
/// encrypted backup files to keep elsewhere.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function(BackupService s) action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await action(
        await ref.read(backupServiceProvider.future),
      );
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } on BackupException {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).backupWrongPassword),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(_backupsProvider);
    }
  }

  String _date(DateTime at) =>
      DateFormat.yMMMd(intlLocaleOf(context)).add_Hm().format(at.toLocal());

  Future<bool> _confirmRestore(String date) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.backupRestoreConfirm(date)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                key: const Key('backup-restore-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.backupRestore),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Asks for a backup file password; [confirm] asks twice (exporting).
  Future<String?> _password({required bool confirm}) => showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(confirm: confirm),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final backups = ref.watch(_backupsProvider).value;
    final picker = ref.read(filePickerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const PageStorageKey('settings-backup'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                l10n.backupAutoHint,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
              const SizedBox(height: 8),
              if (backups != null && backups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.backupNone),
                ),
              for (final b in backups ?? const <LocalBackup>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore),
                  title: Text(_date(b.createdAt)),
                  subtitle: Text('${(b.size / 1024).ceil()} KB'),
                  trailing: TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (!await _confirmRestore(_date(b.createdAt))) {
                              return;
                            }
                            await _run((s) async {
                              await s.restoreLocal(b);
                              return l10n.backupRestored;
                            });
                          },
                    child: Text(l10n.backupRestore),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const Key('backup-now'),
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(l10n.backupNow),
                  onPressed: _busy
                      ? null
                      : () => _run((s) async {
                          await s.backUpNow();
                          return null;
                        }),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                key: const Key('backup-export'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file),
                title: Text(l10n.backupExport),
                subtitle: Text(l10n.backupExportHint),
                onTap: _busy
                    ? null
                    : () async {
                        final password = await _password(confirm: true);
                        if (password == null) return;
                        await _run((s) async {
                          final bytes = await s.export(password);
                          final stamp = DateFormat('yyyyMMdd-HHmm')
                              .format(DateTime.now());
                          final saved = await picker.save(
                            'CashRotate-$stamp.crb',
                            bytes,
                          );
                          return saved ? l10n.backupSaved : null;
                        });
                      },
              ),
              ListTile(
                key: const Key('backup-import'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_open_outlined),
                title: Text(l10n.backupImport),
                onTap: _busy
                    ? null
                    : () async {
                        final bytes = await picker.open();
                        if (bytes == null || !context.mounted) return;
                        final password = await _password(confirm: false);
                        if (password == null) return;
                        if (!await _confirmRestore(l10n.backupImport)) return;
                        await _run((s) async {
                          await s.import(bytes, password);
                          return l10n.backupRestored;
                        });
                      },
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.confirm});

  final bool confirm;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final short = _a.text.isNotEmpty && _a.text.length < 8;
    final mismatch = widget.confirm && _b.text.isNotEmpty && _a.text != _b.text;
    final ok = _a.text.length >= 8 && (!widget.confirm || _a.text == _b.text);
    return AlertDialog(
      title: Text(l10n.backupFilePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('backup-password'),
            controller: _a,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.backupFilePassword,
              errorText: widget.confirm && short
                  ? l10n.syncPasswordShort
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.confirm)
            TextField(
              key: const Key('backup-password-again'),
              controller: _b,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.syncPasswordAgain,
                errorText: mismatch ? l10n.syncPasswordMismatch : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('backup-password-ok'),
          onPressed: ok || (!widget.confirm && _a.text.isNotEmpty)
              ? () => Navigator.pop(context, _a.text)
              : null,
          child: Text(l10n.actionDone),
        ),
      ],
    );
  }
}
