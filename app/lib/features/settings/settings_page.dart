import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/entitlements.dart';
import '../../data/fx/auto_rate_service.dart';
import '../../data/fx/exchange_rate_repository.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';
import '../home/fixed_summary.dart';
import '../items/fx_line.dart';
import 'amount_settings_page.dart';
import 'basic_settings_fields.dart';
import 'reminder_settings.dart';

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
              const AmountsSettingsTile(),
              _Section(l10n.navHome),
              SwitchListTile(
                key: const Key('settings-tile-colors'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsTileColors),
                subtitle: Text(l10n.settingsTileColorsHint),
                value:
                    ref.watch(userSettingsProvider).value?.tileColors ?? false,
                onChanged: (on) =>
                    ref.read(settingsRepositoryProvider).setTileColors(on),
              ),
              _Section(l10n.settingsReminders),
              const ReminderSettings(),
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

/// Exchange rates: automatic daily rates (status, source, "update now") and
/// manual ones. Lists the currencies in use plus any manual rate; tap a
/// manual rate to change it, or add one for a currency that is not
/// automatic.
class _RatesSettings extends ConsumerStatefulWidget {
  const _RatesSettings();

  @override
  ConsumerState<_RatesSettings> createState() => _RatesSettingsState();
}

class _RatesSettingsState extends ConsumerState<_RatesSettings> {
  bool _updating = false;
  AutoRateResult? _last;

  Future<void> _updateNow() async {
    setState(() => _updating = true);
    final result = await ref.read(autoRateServiceProvider).refresh(force: true);
    if (mounted) {
      setState(() {
        _updating = false;
        _last = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final rates = ref.watch(_ratesProvider).value ?? const [];
    final items = ref.watch(itemsProvider).value ?? const [];
    final locale = intlLocaleOf(context);
    final palette = Palette.of(context);
    final secondary = TextStyle(color: palette.secondaryText);
    if (settings == null) return const SizedBox.shrink();

    final service = ref.watch(autoRateServiceProvider);
    final auto = service.autoCurrencies(settings); // null = every currency
    bool isAuto(Currency c) => auto == null || auto.contains(c);
    final inUse = {
      for (final v in items) v.schedule.prices.stablePrice.currency,
    }..remove(settings.mainCurrency);
    final shown = rates
        .where(
          (r) =>
              r.source == ExchangeRateRepository.manualSource ||
              inUse.contains(r.base) ||
              inUse.contains(r.quote),
        )
        .toList();
    final latestAuto = rates
        .where((r) => r.source != ExchangeRateRepository.manualSource)
        .map((r) => r.asOf)
        .fold<LocalDate?>(null, (a, b) => a == null || b > a ? b : a);
    String date(LocalDate d) =>
        DateFormat.yMMMd(locale).format(DateTime(d.year, d.month, d.day));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.autorenew),
          title: Text(
            auto == null
                ? l10n.settingsAutoRatesAll
                : l10n.settingsAutoRatesSome(
                    auto.map((c) => c.code).join(', '),
                  ),
          ),
          subtitle: Text(
            switch (_last?.status) {
              AutoRateStatus.failed => l10n.settingsUpdateFailed,
              _ =>
                latestAuto == null
                    ? l10n.settingsAutoRatesNever
                    : l10n.settingsAutoRatesAsOf(date(latestAuto)),
            },
            style: _last?.status == AutoRateStatus.failed
                ? TextStyle(color: palette.error)
                : null,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('settings-update-rates'),
            icon: _updating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(l10n.settingsUpdateNow),
            onPressed: _updating ? null : _updateNow,
          ),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty) Text(l10n.settingsNoRates, style: secondary),
        for (final r in shown)
          ListTile(
            key: Key('settings-rate-${r.base.code}-${r.quote.code}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r.source == ExchangeRateRepository.manualSource
                  ? Icons.edit_note
                  : Icons.currency_exchange,
            ),
            title: Text(
              l10n.settingsRateLine(
                r.base.code,
                r.rate.toDecimalString(),
                r.quote.code,
              ),
            ),
            subtitle: Text(
              r.source == ExchangeRateRepository.manualSource
                  ? l10n.settingsRateUpdated(date(r.asOf))
                  : l10n.settingsRateAuto(date(r.asOf)),
            ),
            trailing: r.source == ExchangeRateRepository.manualSource
                ? const Icon(Icons.edit_outlined)
                : null,
            onTap: r.source != ExchangeRateRepository.manualSource
                ? null
                : () => showManualRateDialog(
                    context,
                    ref,
                    from: r.base,
                    to: r.quote,
                    initial: r.rate.toDecimalString(maxDecimals: 6),
                  ),
          ),
        if (auto != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const Key('settings-add-rate'),
              icon: const Icon(Icons.add),
              label: Text(l10n.settingsAddRate),
              onPressed: () async {
                final c = await showCurrencyPicker(
                  context,
                  region: settings.region,
                );
                if (c == null ||
                    c == settings.mainCurrency ||
                    isAuto(c) ||
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
        ],
        const SizedBox(height: 12),
        Text(l10n.settingsRatesAttribution, style: secondary),
        if (unlockProInPreview) ...[
          const SizedBox(height: 8),
          Text(l10n.settingsPreviewUnlocked, style: secondary),
        ],
      ],
    );
  }
}
