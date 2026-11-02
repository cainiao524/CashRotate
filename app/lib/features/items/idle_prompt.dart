import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/money_text.dart' show hiddenAmount;
import '../home/fixed_summary.dart';
import 'item_detail.dart' show openCancelPage;

/// How often a rarely used item is asked about.
const idleAskEvery = 91;

/// Rarely used items due for their quarterly "still want it?" (CLAUDE.md
/// item 18): marked rarely used, active, and last asked a quarter ago.
List<ItemView> idleItemsDue(List<ItemView> items, LocalDate today) => [
  for (final v in items)
    if (v.typeFields['rarelyUsed'] == true &&
        v.row.status == ItemStatus.active &&
        _askedOn(v, today).addDays(idleAskEvery) <= today)
      v,
];

LocalDate _askedOn(ItemView v, LocalDate today) {
  try {
    return LocalDate.parse(v.typeFields['idleAskedOn'] as String);
  } on Object {
    return today; // not asked yet: first ask a quarter from now
  }
}

final idleItemsProvider = Provider<List<ItemView>>(
  (ref) => idleItemsDue(
    ref.watch(itemsProvider).value ?? const [],
    todayFrom(ref.watch(clockProvider)),
  ),
);

/// The question for the first rarely used item due, on the home page.
class IdlePrompt extends ConsumerWidget {
  const IdlePrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(idleItemsProvider);
    if (due.isEmpty) return const SizedBox.shrink();
    final v = due.first;
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(userSettingsProvider).value;
    final today = todayFrom(ref.watch(clockProvider));
    final preset = ref.watch(presetLibraryProvider).value?.byId[v.row.presetId];
    final cancelUrl =
        (v.typeFields['cancelUrl'] as String?) ?? preset?.cancelUrl;
    final monthly = monthlyCostOf(v, today: today);
    final amount = monthly == null
        ? '—'
        : settings?.hideAmounts ?? false
        ? hiddenAmount
        : formatMoney(monthly, locale: intlLocaleOf(context));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: ValueKey('idle-${v.row.id}'),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.idleAsk(v.row.name), style: text.titleSmall),
            const SizedBox(height: 2),
            Text(
              l10n.idleAskBody(amount),
              style: text.bodySmall?.copyWith(color: palette.secondaryText),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  key: const Key('idle-review'),
                  onPressed: () => context.go(Routes.item(v.row.id)),
                  child: Text(l10n.idleReview),
                ),
                if (cancelUrl != null && cancelUrl.isNotEmpty)
                  TextButton(
                    key: const Key('idle-cancel'),
                    onPressed: () => openCancelPage(context, ref, cancelUrl),
                    child: Text(l10n.actionGoCancel),
                  ),
                TextButton(
                  key: const Key('idle-keep'),
                  onPressed: () =>
                      ref.read(itemRepositoryProvider).setTypeFields(v.row.id, {
                        'idleAskedOn': today.toString(),
                      }),
                  child: Text(l10n.idleKeep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
