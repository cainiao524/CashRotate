import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/providers.dart';
import '../l10n/locale_tags.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

/// What an amount reads as in hidden-amounts mode.
const hiddenAmount = '••••';

/// An amount in tabular figures, formatted for the current locale and the
/// user's display precision.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.approximate = false,
  });

  final Money money;
  final TextStyle? style;

  /// Prefix with "≈" for converted estimates.
  final bool approximate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider).value;
    final text = settings?.hideAmounts ?? false
        ? hiddenAmount
        : formatMoney(
            money,
            locale: intlLocaleOf(context),
            decimals: settings?.decimalsFor(money.currency),
          );
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(approximate ? '≈ $text' : text, style: tabularFigures(base));
  }
}

/// List and total style: the main-currency amount large, and for foreign
/// items the original price small underneath ("NT$652 · US$20").
class DualMoneyText extends ConsumerWidget {
  const DualMoneyText(
    this.original, {
    super.key,
    this.largeStyle,
    this.crossAxisAlignment = CrossAxisAlignment.end,
  });

  final Money original;
  final TextStyle? largeStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider).value;
    final fx = ref.watch(fxConverterProvider).value;
    final main = settings?.mainCurrency;
    final text = Theme.of(context).textTheme;
    final large = largeStyle ?? text.titleMedium!;
    final small = text.bodySmall!.copyWith(
      color: Palette.of(context).secondaryText,
    );

    if (main == null || original.currency == main) {
      return MoneyText(original, style: large);
    }
    final converted = fx?.convert(original, main);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (converted != null)
          MoneyText(converted.amount, style: large, approximate: true)
        else
          MoneyText(original, style: large),
        if (converted != null) MoneyText(original, style: small),
      ],
    );
  }
}
