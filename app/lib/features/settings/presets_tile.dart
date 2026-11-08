import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/presets.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';

/// The service library: how big it is, when it was updated, and "Update"
/// (CLAUDE.md item 6).
class PresetLibraryTile extends ConsumerStatefulWidget {
  const PresetLibraryTile({super.key});

  @override
  ConsumerState<PresetLibraryTile> createState() => _PresetLibraryTileState();
}

class _PresetLibraryTileState extends ConsumerState<PresetLibraryTile> {
  bool _busy = false;

  Future<void> _update() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final library = await ref.read(presetLibraryProvider.future);
    final result = await ref
        .read(presetUpdaterProvider)
        .update(current: library.downloadedJson);
    ref.invalidate(presetLibraryProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result.status) {
          PresetUpdateStatus.updated => l10n.presetsUpdated(result.count),
          PresetUpdateStatus.unchanged => l10n.presetsUpToDate,
          PresetUpdateStatus.failed => l10n.presetsFailed,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final library = ref.watch(presetLibraryProvider).value;
    final at = library?.downloadedAt?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('settings-presets'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.library_books_outlined),
          title: Text(l10n.presetsTitle),
          subtitle: library == null
              ? null
              : Text(
                  at == null
                      ? l10n.presetsBuiltIn(library.presets.length)
                      : l10n.presetsInfo(
                          library.presets.length,
                          DateFormat.yMMMd(intlLocaleOf(context)).format(at),
                        ),
                ),
          trailing: _busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  key: const Key('presets-update'),
                  onPressed: _update,
                  child: Text(l10n.presetsUpdate),
                ),
        ),
        Text(
          l10n.presetsSource,
          style: text.bodySmall?.copyWith(color: palette.secondaryText),
        ),
      ],
    );
  }
}
