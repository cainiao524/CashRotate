import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/money_text.dart';
import '../home/fixed_summary.dart';
import '../payments/payment_sheet.dart';

/// A member who owes me (I organize), or an organizer I owe (I'm a member).
typedef OwedLine = ({
  ItemView view,
  String who,
  Money amount,
  int? memberIndex,
  OccurrenceRow? charge,
});

/// Charges of the last year and the coming week, for working out who owes.
final _chargesProvider = StreamProvider<List<OccurrenceRow>>((ref) {
  final today = todayFrom(ref.watch(clockProvider));
  return ref
      .watch(itemRepositoryProvider)
      .watchDue(today.addDays(-366), today.addDays(7));
});

/// "Owed to me" and "I owe" across shared plans (CLAUDE.md item 4).
final owedProvider = Provider<({List<OwedLine> toMe, List<OwedLine> byMe})>((
  ref,
) {
  final items = ref.watch(itemsProvider).value ?? const [];
  final charges = ref.watch(_chargesProvider).value ?? const [];
  final today = todayFrom(ref.watch(clockProvider));
  final toMe = <OwedLine>[];
  final byMe = <OwedLine>[];
  for (final v in items) {
    final plan = v.sharingPlan;
    if (plan == null || v.row.status != ItemStatus.active) continue;
    final mine = [
      for (final c in charges)
        if (c.itemId == v.row.id) c,
    ];
    if (plan.role == SharingRole.member) {
      for (final c in mine) {
        if (c.state == OccurrenceState.pending && c.dueOn <= today.addDays(7)) {
          byMe.add((
            view: v,
            who: plan.payee ?? v.row.name,
            amount: Money(c.expectedMinor, c.currency),
            memberIndex: null,
            charge: c,
          ));
        }
      }
      continue;
    }
    final price = v.schedule.prices.stablePrice;
    final due = [for (final c in mine) c.dueOn]..sort();
    for (final (i, m) in plan.members.indexed) {
      final owed = plan.owedBy(m, price, due, today);
      if (owed != null) {
        toMe.add((
          view: v,
          who: m.name,
          amount: owed,
          memberIndex: i,
          charge: null,
        ));
      }
    }
  }
  return (toMe: toMe, byMe: byMe);
});

/// The settings row that opens [OwedPage].
class OwedTile extends ConsumerWidget {
  const OwedTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final owed = ref.watch(owedProvider);
    final count = owed.toMe.length + owed.byMe.length;
    return ListTile(
      key: const Key('settings-owed'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.group_outlined),
      title: Text(l10n.owedTitle),
      subtitle: count == 0
          ? null
          : Text(
              '${l10n.owedToMe} ${owed.toMe.length} · '
              '${l10n.owedByMe} ${owed.byMe.length}',
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.settingsOwed),
    );
  }
}

class OwedPage extends ConsumerWidget {
  const OwedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final owed = ref.watch(owedProvider);
    final locale = intlLocaleOf(context);
    String date(LocalDate d) =>
        DateFormat.MMMd(locale).format(DateTime(d.year, d.month, d.day));

    Future<void> received(OwedLine line) async {
      final plan = line.view.sharingPlan!;
      final members = [...plan.members];
      final today = todayFrom(ref.read(clockProvider));
      // Settled through today: owed again from the first charge after it.
      final schedule = line.view.schedule;
      final next = schedule.cycle.dateAt(
        schedule.anchor,
        schedule.cycle.firstIndexOnOrAfter(schedule.anchor, today.addDays(1)),
      );
      members[line.memberIndex!] = members[line.memberIndex!].copyWith(
        paid: true,
        paidUntil: next,
      );
      await ref
          .read(itemRepositoryProvider)
          .updateSharing(
            line.view.row.id,
            SharingPlan(
              role: plan.role,
              split: plan.split,
              members: members,
              myShare: plan.myShare,
              basePriceMinor: plan.basePriceMinor,
              followPrice: plan.followPrice,
              payee: plan.payee,
              payeeMethod: plan.payeeMethod,
              myTurnFirst: plan.myTurnFirst,
            ),
          );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.owedTitle)),
      body: ListView(
        key: const PageStorageKey('settings-owed'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (owed.toMe.isEmpty && owed.byMe.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.owedNothing,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ),
          if (owed.toMe.isNotEmpty) ...[
            Text(l10n.owedToMe, style: text.titleSmall),
            for (final line in owed.toMe)
              ListTile(
                key: ValueKey(
                  'owed-to-me-${line.view.row.id}-${line.memberIndex}',
                ),
                contentPadding: EdgeInsets.zero,
                title: Text(line.who),
                subtitle: Text(line.view.row.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(line.amount),
                    TextButton(
                      key: ValueKey(
                        'owed-received-${line.view.row.id}-${line.memberIndex}',
                      ),
                      onPressed: () => received(line),
                      child: Text(l10n.owedReceived),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
          if (owed.byMe.isNotEmpty) ...[
            Text(l10n.owedByMe, style: text.titleSmall),
            for (final line in owed.byMe)
              ListTile(
                key: ValueKey('owed-by-me-${line.charge!.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(line.view.row.name),
                subtitle: Text(
                  l10n.owedDue(line.who, date(line.charge!.dueOn)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(line.amount),
                    TextButton(
                      key: ValueKey('owed-pay-${line.charge!.id}'),
                      onPressed: () => showPaymentSheet(
                        context,
                        line.view,
                        charge: line.charge,
                      ),
                      child: Text(l10n.paymentRecord),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
