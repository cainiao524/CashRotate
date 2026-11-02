import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/preset_badge.dart';
import '../onboarding/batch.dart';

/// Services most people have, in order; those not offered in the user's
/// region are skipped.
const popularPresetIds = [
  'netflix',
  'spotify',
  'youtube-premium',
  'icloud-plus',
  'disney-plus',
  'chatgpt',
  'kkbox',
  'viu',
  'google-one',
  'apple-music',
  'microsoft-365',
  'nintendo-switch-online',
  'playstation-plus',
];

/// Empty home: popular services added with one tap, still to fill in
/// (CLAUDE.md item 18, empty-state guidance).
class PopularServices extends ConsumerWidget {
  const PopularServices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final library = ref.watch(presetLibraryProvider).value;
    final settings = ref.watch(userSettingsProvider).value;
    if (library == null || settings == null) return const SizedBox.shrink();
    final language = contentLanguageOf(context);
    final presets = [
      for (final id in popularPresetIds)
        if (library.byId[id] case final p? when p.availableIn(settings.region))
          p,
    ].take(8);

    Future<void> add(Preset p) async {
      final messenger = ScaffoldMessenger.of(context);
      final name = p.name.resolve(language);
      final today = todayFrom(ref.read(clockProvider));
      await ref
          .read(itemRepositoryProvider)
          .create(
            BatchRow.fromPreset(
              p,
              language: language,
              mainCurrency: settings.mainCurrency,
            ).toNewItem(today: today),
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.emptyPopularAdded(name))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.emptyPopularTitle, style: text.titleSmall),
        Text(
          l10n.emptyPopularHint,
          style: text.bodySmall?.copyWith(color: palette.secondaryText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in presets)
              ActionChip(
                key: ValueKey('popular-${p.id}'),
                avatar: InitialBadge(
                  name: p.name.resolve(language),
                  color: p.color,
                  size: 20,
                ),
                label: Text(p.name.resolve(language)),
                onPressed: () => add(p),
              ),
          ],
        ),
      ],
    );
  }
}
