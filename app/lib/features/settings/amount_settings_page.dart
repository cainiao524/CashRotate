import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../home/fixed_summary.dart';

/// Currencies whose display decimals the user can choose: the main currency
/// first, then the ones items are billed in, for currencies that have a
/// minor unit. Rate-only currencies are left out (automatic rates cover
/// every currency); a currency appears once an item uses it.
final decimalCurrenciesProvider = Provider<List<Currency>>((ref) {
  final settings = ref.watch(userSettingsProvider).value;
  if (settings == null) return const [];
  final items = ref.watch(itemsProvider).value ?? const [];
  return <Currency>{
    settings.mainCurrency,
    ...{for (final v in items) v.schedule.prices.stablePrice.currency}.toList()
      ..sort((a, b) => a.code.compareTo(b.code)),
  }.where((c) => c.minorUnits > 0).toList();
});

/// The settings row that opens [AmountSettingsPage], previewing how each
/// currency in use is shown.
class AmountsSettingsTile extends ConsumerWidget {
  const AmountsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final currencies = ref.watch(decimalCurrenciesProvider);
    final locale = intlLocaleOf(context);
    return ListTile(
      key: const Key('settings-amounts'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.pin_outlined),
      title: Text(l10n.settingsAmounts),
      subtitle: settings == null || currencies.isEmpty
          ? null
          : Text(
              [
                for (final c in currencies)
                  formatMoney(
                    Money(123456, c),
                    locale: locale,
                    decimals: settings.decimalsFor(c),
                  ),
              ].join(' · '),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.settingsAmounts),
    );
  }
}

/// "Show decimals" per currency in use.
class AmountSettingsPage extends ConsumerWidget {
  const AmountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final currencies = ref.watch(decimalCurrenciesProvider);
    final locale = intlLocaleOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAmounts)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const PageStorageKey('settings-amounts'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (settings != null)
                for (final c in currencies)
                  SwitchListTile(
                    key: Key('settings-decimals-${c.code}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsShowDecimals(c.code)),
                    subtitle: Text(
                      formatMoney(
                        Money(123456, c),
                        locale: locale,
                        decimals: settings.decimalsFor(c),
                      ),
                    ),
                    value: settings.decimalsFor(c) > 0,
                    onChanged: (on) => ref
                        .read(settingsRepositoryProvider)
                        .setDecimals(c, on ? c.minorUnits : 0),
                  ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsAmountsHint,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Palette.of(context).secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
