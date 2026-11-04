import 'dart:async';
import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../widgets/money_text.dart' show hiddenAmount;
import '../home/fixed_summary.dart';
import '../home/tile_icons.dart';

/// Most charges a widget lists (the large size).
const widgetMaxItems = 6;

/// What the home-screen widgets show, localised and formatted here so the
/// widgets need no strings of their own. Days left are worked out on the
/// widget side from `dueOn`, so "in N days" stays right after midnight.
/// Hidden-amounts mode masks every amount.
Map<String, Object?> buildWidgetSnapshot({
  required List<ItemView> items,
  required FixedSummary summary,
  required MonthCharges? month,
  required UserSettings settings,
  required AppLocalizations l10n,
  required String locale,
}) {
  String money(Money m) => settings.hideAmounts
      ? hiddenAmount
      : formatMoney(
          m,
          locale: locale,
          decimals: settings.decimalsFor(m.currency),
        );
  // Plural templates with the count left for the widget to fill in.
  String template(String Function(int) phrase) =>
      phrase(99).replaceAll('99', '{n}');

  final upcoming = [
    for (final v in items)
      if (v.row.status == ItemStatus.active && !v.row.needsDetails)
        if (v.nextDue case final next?) (view: v, next: next),
  ]..sort((a, b) => a.next.dueOn.compareTo(b.next.dueOn));

  return {
    'title': l10n.homeMonthlyFixedTotal,
    'total': money(summary.monthlyTotal),
    'summary': month == null
        ? ''
        : '${l10n.homePaid} ${money(month.paid)} · '
              '${l10n.homePending} ${money(month.pending)}',
    'paidShare': month?.paidShare ?? 0,
    'empty': l10n.reportsDayCharges(0),
    'labels': {
      'today': l10n.tileDueIn(0),
      'tomorrow': l10n.tileDueIn(1),
      'inDays': template((n) => l10n.tileDueIn(n)),
      'overdue': template((n) => l10n.tileOverdue(n)),
    },
    'items': [
      for (final (:view, :next) in upcoming.take(widgetMaxItems))
        {
          'id': view.row.id,
          'name': view.row.name,
          'letter': badgeOf(view.row.id, view.row.name, settings).text,
          'dueOn': next.dueOn.toString(),
          'amount': money(Money(next.expectedMinor, next.currency)),
        },
    ],
  };
}

/// Keeps the home-screen widgets in step with the data and the language.
class WidgetBridge extends ConsumerStatefulWidget {
  const WidgetBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetBridge> createState() => _WidgetBridgeState();
}

class _WidgetBridgeState extends ConsumerState<WidgetBridge> {
  Timer? _debounce;
  String? _last;

  @override
  void initState() {
    super.initState();
    ref
      ..listenManual(itemsProvider, (_, _) => _schedule())
      ..listenManual(fixedSummaryProvider, (_, _) => _schedule())
      ..listenManual(monthChargesProvider, (_, _) => _schedule())
      ..listenManual(userSettingsProvider, (_, _) => _schedule());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule(); // first run, and after a language change
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _push);
  }

  Future<void> _push() async {
    if (!mounted) return;
    final items = ref.read(itemsProvider).value;
    final summary = ref.read(fixedSummaryProvider).value;
    final settings = ref.read(userSettingsProvider).value;
    if (items == null || summary == null || settings == null) return;
    final json = jsonEncode(
      buildWidgetSnapshot(
        items: items,
        summary: summary,
        month: ref.read(monthChargesProvider),
        settings: settings,
        l10n: AppLocalizations.of(context),
        locale: intlLocaleOf(context),
      ),
    );
    if (json == _last) return;
    _last = json;
    try {
      await ref.read(homeWidgetPlatformProvider).update(json);
    } on Object {
      _last = null; // try again on the next change
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
