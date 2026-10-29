import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../l10n/regions.dart';
import '../../widgets/currency_picker.dart';

/// Language, region and main currency: shown during first-launch setup and
/// in Settings. Keys are prefixed with [keyPrefix] (`ob`, `settings`).
class BasicSettingsFields extends ConsumerWidget {
  const BasicSettingsFields({super.key, required this.keyPrefix});

  final String keyPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final repo = ref.read(settingsRepositoryProvider);
    final lang = contentLanguageOf(context);
    final main = CurrencyInfo.of(settings.mainCurrency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          key: Key('$keyPrefix-language'),
          initialValue: settings.language,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.obLanguage),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.obLanguageSystem)),
            const DropdownMenuItem(value: 'zh-Hant', child: Text('繁體中文')),
            const DropdownMenuItem(value: 'zh-Hans', child: Text('简体中文')),
            const DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: repo.setLanguage,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: Key('$keyPrefix-region'),
          initialValue: settings.region,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.obRegion),
          items: [
            for (final r in regionChoices(settings.region))
              DropdownMenuItem(value: r, child: Text(regionName(r, lang))),
          ],
          // Choosing a region also proposes its currency; it can be changed
          // right below.
          onChanged: (r) async {
            if (r == null) return;
            await repo.setRegion(r);
            await repo.setMainCurrency(CurrencyInfo.forRegion(r));
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          key: Key('$keyPrefix-currency'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.obMainCurrency),
          subtitle: Text('${main.symbol} · ${main.name.resolve(lang)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final c = await showCurrencyPicker(
              context,
              region: settings.region,
              selected: settings.mainCurrency,
            );
            if (c != null) await repo.setMainCurrency(c);
          },
        ),
      ],
    );
  }
}
