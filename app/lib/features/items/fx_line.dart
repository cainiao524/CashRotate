import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';

/// "≈ NT$652 · rate 32.59 · updated 27 Oct 2026" under a foreign amount, or
/// a prompt to set a rate when none is known. Nothing for main-currency
/// amounts.
class FxLine extends ConsumerWidget {
  const FxLine({super.key, required this.amount, required this.currency});

  final Money? amount;
  final Currency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final fx = ref.watch(fxConverterProvider).value;
    if (settings == null || currency == settings.mainCurrency) {
      return const SizedBox.shrink();
    }
    final main = settings.mainCurrency;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.of(context).secondaryText);
    final locale = intlLocaleOf(context);
    final rate = fx?.rate(currency, main);

    if (rate == null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(l10n.fxNoRate(currency.code), style: style),
          TextButton(
            onPressed: () =>
                showManualRateDialog(context, ref, from: currency, to: main),
            child: Text(l10n.fxSetRate),
          ),
        ],
      );
    }
    final converted = amount == null
        ? null
        : fx!.convert(amount!, main)?.amount;
    final text = l10n.fxEstimate(
      converted == null
          ? '—'
          : formatMoney(
              converted,
              locale: locale,
              decimals: settings.decimalsFor(main),
            ),
      rate.rate.toDecimalString(maxDecimals: 4),
      DateFormat.yMMMd(locale)
          .format(DateTime.utc(rate.asOf.year, rate.asOf.month, rate.asOf.day)),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(text, style: style),
        TextButton(
          onPressed: () => showManualRateDialog(
            context,
            ref,
            from: currency,
            to: main,
            initial: rate.rate.toDecimalString(maxDecimals: 6),
          ),
          child: Text(l10n.fxSetRate),
        ),
      ],
    );
  }
}

/// Lets the user type "1 USD = 32.59 TWD". Saved as a manual rate dated today.
Future<void> showManualRateDialog(
  BuildContext context,
  WidgetRef ref, {
  required Currency from,
  required Currency to,
  String? initial,
}) async {
  final rate = await showDialog<Ratio>(
    context: context,
    builder: (_) => _RateDialog(from: from, to: to, initial: initial ?? ''),
  );
  if (rate != null) {
    await ref
        .read(exchangeRateRepositoryProvider)
        .setManualRate(from, to, rate);
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog({
    required this.from,
    required this.to,
    required this.initial,
  });

  final Currency from;
  final Currency to;
  final String initial;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  Ratio? get _parsed => Ratio.tryParse(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.fxRateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('fx-rate-field'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '${l10n.fxRateLabel(widget.from.code)} ',
              suffixText: widget.to.code,
              errorText: _controller.text.isEmpty || _parsed != null
                  ? null
                  : l10n.errorAmount,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(l10n.fxManualNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _parsed == null
              ? null
              : () => Navigator.pop(context, _parsed),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
