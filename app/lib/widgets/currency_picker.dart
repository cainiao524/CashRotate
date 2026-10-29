import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/locale_tags.dart';
import '../theme/palette.dart';
import 'marquee_text.dart';

/// Opens the currency picker. Suggestions on top: the region's currency,
/// then USD, EUR and JPY. Search matches codes, names in every language,
/// country names and symbols.
Future<Currency?> showCurrencyPicker(
  BuildContext context, {
  required String region,
  Currency? selected,
}) => showModalBottomSheet<Currency>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => CurrencyPickerSheet(region: region, selected: selected),
);

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({super.key, required this.region, this.selected});

  final String region;
  final Currency? selected;

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  String _query = '';

  List<Currency> get _suggested => {
    CurrencyInfo.forRegion(widget.region),
    Currency.usd,
    Currency.eur,
    Currency.jpy,
  }.toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = CurrencyInfo.search(_query);
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.currencySearchHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (_query.trim().isEmpty) ...[
                  _Header(l10n.currencySuggested),
                  for (final c in _suggested)
                    _tile(context, CurrencyInfo.of(c)),
                  _Header(l10n.currencyAll),
                ],
                for (final info in results) _tile(context, info),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.currencyNoMatch,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, CurrencyInfo info) {
    final lang = contentLanguageOf(context);
    final selected = info.currency == widget.selected;
    return ListTile(
      key: ValueKey('currency-${info.currency.code}'),
      selected: selected,
      leading: SizedBox(
        width: 56,
        child: Text(
          info.symbol,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      title: MarqueeText(info.name.resolve(lang)),
      subtitle: Text(info.currency.code),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(info.currency),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Palette.of(context).secondaryText),
    ),
  );
}
