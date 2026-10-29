import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';
import '../home/fixed_summary.dart';
import '../items/fx_line.dart';
import 'basic_settings_fields.dart';

final _ratesProvider = StreamProvider<List<ExchangeRate>>(
  (ref) => ref.watch(exchangeRateRepositoryProvider).watchRates(),
);

/// General settings, amount display, manual exchange rates, quick setup and
/// about. Sync, security and Pro settings join in later milestones.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const PageStorageKey('settings'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Section(l10n.settingsGeneral),
              const BasicSettingsFields(keyPrefix: 'settings'),
              _Section(l10n.settingsAmounts),
              const _DecimalsSettings(),
              _Section(l10n.settingsRates),
              const _RatesSettings(),
              _Section(l10n.settingsSetup),
              ListTile(
                key: const Key('settings-run-setup'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.checklist),
                title: Text(l10n.settingsRunSetup),
                subtitle: Text(l10n.settingsRunSetupHint),
                onTap: () => ref
                    .read(settingsRepositoryProvider)
                    .setOnboardingDone(done: false),
              ),
              _Section(l10n.settingsAbout),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text(Brand.appName),
                subtitle: Text(l10n.settingsPrivacy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Palette.of(context).secondaryText),
    ),
  );
}

/// "Show decimals" per currency in use (main currency, item currencies,
/// rate currencies), for currencies that have a minor unit.
class _DecimalsSettings extends ConsumerWidget {
  const _DecimalsSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final items = ref.watch(itemsProvider).value ?? const [];
    final rates = ref.watch(_ratesProvider).value ?? const [];
    final inUse = <Currency>{
      settings.mainCurrency,
      for (final v in items) v.schedule.prices.stablePrice.currency,
      for (final r in rates) ...[r.base, r.quote],
    }.where((c) => c.minorUnits > 0).toList();
    final locale = intlLocaleOf(context);

    return Column(
      children: [
        for (final c in inUse)
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
      ],
    );
  }
}

/// Manual exchange rates: tap one to change it, or add a rate for another
/// currency against the main currency.
class _RatesSettings extends ConsumerWidget {
  const _RatesSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final rates = ref.watch(_ratesProvider).value ?? const [];
    final locale = intlLocaleOf(context);
    final secondary = TextStyle(color: Palette.of(context).secondaryText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rates.isEmpty) Text(l10n.settingsNoRates, style: secondary),
        for (final r in rates)
          ListTile(
            key: Key('settings-rate-${r.base.code}-${r.quote.code}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange),
            title: Text(
              l10n.settingsRateLine(
                r.base.code,
                r.rate.toDecimalString(),
                r.quote.code,
              ),
            ),
            subtitle: Text(
              l10n.settingsRateUpdated(
                DateFormat.yMMMd(locale)
                    .format(DateTime(r.asOf.year, r.asOf.month, r.asOf.day)),
              ),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => showManualRateDialog(
              context,
              ref,
              from: r.base,
              to: r.quote,
              initial: r.rate.toDecimalString(maxDecimals: 6),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('settings-add-rate'),
            icon: const Icon(Icons.add),
            label: Text(l10n.settingsAddRate),
            onPressed: settings == null
                ? null
                : () async {
                    final c = await showCurrencyPicker(
                      context,
                      region: settings.region,
                    );
                    if (c == null ||
                        c == settings.mainCurrency ||
                        !context.mounted) {
                      return;
                    }
                    await showManualRateDialog(
                      context,
                      ref,
                      from: c,
                      to: settings.mainCurrency,
                    );
                  },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.fxManualNote, style: secondary),
      ],
    );
  }
}
