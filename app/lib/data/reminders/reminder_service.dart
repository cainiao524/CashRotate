import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../db/app_database.dart';
import '../items/item_repository.dart';
import '../settings/settings_repository.dart';
import 'reminder_platform.dart';

/// Plans reminders from the items and hands them to the platform; copies
/// what the platform reports back into ReminderLog and applies "Paid".
class ReminderService {
  ReminderService(this._db, this._items, this._platform, this._now);

  final AppDatabase _db;
  final ItemRepository _items;
  final ReminderPlatform _platform;
  final DateTime Function() _now;

  /// A reminder that arrives this much after its time counts as late.
  static const lateAfter = Duration(hours: 1);

  /// Plans and hands over every reminder for the next 60 days, worded in
  /// [l10n]. With reminders turned off, clears them.
  Future<List<NativeReminder>> sync({
    required List<ItemView> items,
    required List<OccurrenceRow> occurrences,
    required UserSettings settings,
    required AppLocalizations l10n,
    required String locale,
  }) async {
    final today = LocalDate.fromDateTime(_now());
    final reminders = settings.remindersOn
        ? buildNativeReminders(
            items: items,
            occurrences: occurrences,
            settings: settings,
            l10n: l10n,
            locale: locale,
            today: today,
          )
        : const <NativeReminder>[];
    await _platform.setReminders(reminders, {
      'paid': l10n.actionMarkPaid,
      'snooze': l10n.reminderSnooze,
      'channelName': l10n.reminderChannelName,
      'channelDescription': l10n.reminderChannelDescription,
    });
    return reminders;
  }

  /// Copies delivery and action events into ReminderLog; settles charges
  /// marked "Paid" from a notification. Returns the number of events.
  Future<int> applyEvents() async {
    final events = await _platform.takeEvents();
    for (final e in events) {
      final existing = await (_db.select(
        _db.reminderLog,
      )..where((r) => r.id.equals(e.reminderId))).getSingleOrNull();
      final row = ReminderLogRow(
        id: e.reminderId,
        itemId: e.itemId.isEmpty ? null : e.itemId,
        occurrenceId: e.occurrenceId,
        kind: e.kind,
        scheduledAt: e.scheduledAt,
        deliveredAt: e.type == 'delivered' ? e.at : existing?.deliveredAt,
        action: e.type == 'delivered' ? existing?.action : e.type,
      );
      await _db.into(_db.reminderLog).insertOnConflictUpdate(row);

      if (e.type == 'paid' && e.occurrenceId != null) {
        final occurrence = await (_db.select(
          _db.occurrences,
        )..where((o) => o.id.equals(e.occurrenceId!))).getSingleOrNull();
        // Already paid in the app, or replanned away: nothing to do.
        if (occurrence?.state == OccurrenceState.pending) {
          await _items.markPaid(occurrence!.id);
        }
      }
    }
    return events.length;
  }

  static const _askedKey = 'notification_permission_asked';

  /// Asks for notification permission once per install, the first time
  /// there is something to remind about. Returns whether it is granted.
  Future<bool> askPermissionOnce() async {
    if (await _platform.notificationsEnabled()) return true;
    final asked = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_askedKey))).getSingleOrNull();
    if (asked != null) return false;
    await _db
        .into(_db.meta)
        .insertOnConflictUpdate(
          MetaCompanion.insert(key: _askedKey, value: '1'),
        );
    return _platform.requestPermission();
  }

  /// Reminders in the last [days] days that arrived over [lateAfter] late:
  /// a sign the phone stops the app in the background.
  Future<int> lateCount({int days = 30}) async {
    final since = _now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final late = lateAfter.inMilliseconds;
    final rows =
        await (_db.select(_db.reminderLog)..where(
              (r) =>
                  r.deliveredAt.isNotNull() &
                  r.scheduledAt.isBiggerOrEqualValue(since),
            ))
            .get();
    return rows.where((r) => r.deliveredAt! - r.scheduledAt > late).length;
  }
}

/// The reminders for [items], worded for the notification shade. Pure, so
/// planning and wording are unit-tested without a platform.
List<NativeReminder> buildNativeReminders({
  required List<ItemView> items,
  required List<OccurrenceRow> occurrences,
  required UserSettings settings,
  required AppLocalizations l10n,
  required String locale,
  required LocalDate today,
}) {
  final pending = <String, List<OccurrenceRow>>{};
  for (final o in occurrences) {
    if (o.state == OccurrenceState.pending) {
      pending.putIfAbsent(o.itemId, () => []).add(o);
    }
  }
  final byId = {for (final v in items) v.row.id: v};
  final planned = planReminders([
    for (final v in items)
      if (!v.row.needsDetails)
        ReminderSource(
          itemId: v.row.id,
          type: v.row.type,
          schedule: v.schedule,
          remindDays: v.remindDays,
          typeFields: v.typeFields,
          sharing: v.sharing,
          charges: [
            for (final o in [
              ...?pending[v.row.id],
            ]..sort((a, b) => a.dueOn.compareTo(b.dueOn)))
              ReminderCharge(
                occurrenceId: o.id,
                index: o.cycleIndex,
                dueOn: o.dueOn,
                expected: Money(o.expectedMinor, o.currency),
              ),
          ],
        ),
  ], today: today);

  // Hidden-amounts mode keeps amounts off the lock screen too.
  String money(Money m) => settings.hideAmounts
      ? '••••'
      : formatMoney(
          m,
          locale: locale,
          decimals: settings.decimalsFor(m.currency),
        );
  String date(LocalDate d) =>
      DateFormat.MMMd(locale).format(DateTime(d.year, d.month, d.day));
  final hour = settings.reminderMinutes ~/ 60;
  final minute = settings.reminderMinutes % 60;

  return [
    for (final r in planned)
      if (byId[r.itemId] case final view?)
        NativeReminder(
          id: r.id,
          at: DateTime(r.date.year, r.date.month, r.date.day, hour, minute),
          title: view.row.name,
          body: reminderBody(r, l10n: l10n, money: money, date: date),
          itemId: r.itemId,
          kind: r.kind.name,
          occurrenceId: switch (r.kind) {
            ReminderKind.charge ||
            ReminderKind.confirmAmount ||
            ReminderKind.graceEnd => r.charge?.occurrenceId,
            _ => null,
          },
        ),
  ];
}

/// The notification text for [r].
String reminderBody(
  PlannedReminder r, {
  required AppLocalizations l10n,
  required String Function(Money) money,
  required String Function(LocalDate) date,
}) {
  final days = r.daysBefore;
  final event = r.date.addDays(days);
  return switch (r.kind) {
    ReminderKind.charge => [
      l10n.reminderCharge(days, date(event), money(r.charge!.expected)),
      if (r.priceChange case final c?)
        l10n.detailPriceChange(money(c.from), money(c.to)),
    ].join('\n'),
    ReminderKind.trialEnd => l10n.reminderTrialEnd(days, date(event)),
    ReminderKind.contractEnd => l10n.reminderContractEnd(days, date(event)),
    ReminderKind.policyExpiry => l10n.reminderPolicyExpiry(days, date(event)),
    ReminderKind.graceEnd => l10n.reminderGraceEnd(days, date(event)),
    ReminderKind.confirmAmount => l10n.reminderConfirmAmount(
      money(r.charge!.expected),
    ),
    ReminderKind.sharedUnpaid => l10n.reminderSharedUnpaid(r.unpaidPeople),
  };
}
