import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../journal.dart';

/// What the user enters to create a fixed expense.
class NewItem {
  const NewItem({
    required this.type,
    required this.name,
    required this.cycle,
    required this.anchor,
    required this.prices,
    this.presetId,
    this.categoryId,
    this.accountId,
    this.paidUntil,
    this.note = '',
  });

  final ItemType type;
  final String name;
  final Cycle cycle;

  /// Due date of the first charge.
  final LocalDate anchor;
  final PriceSchedule prices;
  final String? presetId;
  final String? categoryId;
  final String? accountId;
  final LocalDate? paidUntil;
  final String note;
}

/// Writes items, their price phases and expanded occurrences, journaling
/// every change for sync. Occurrences are always re-planned from the
/// schedule after a write, so they cannot drift out of step.
class ItemRepository {
  ItemRepository(
    this._db,
    this._journal, {
    LocalDate Function()? today,
    int Function()? nowMillis,
    Uuid? uuid,
  }) : _today = today ?? (() => LocalDate.fromDateTime(DateTime.now())),
       _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Journal _journal;
  final LocalDate Function() _today;
  final int Function() _nowMillis;
  final Uuid _uuid;

  static String occurrenceId(String itemId, int index) => '$itemId:$index';
  static String phaseId(String itemId, int seq) => '$itemId:$seq';

  Future<String> create(NewItem item) => _db.transaction(() async {
    final id = _uuid.v7();
    final now = _nowMillis();
    final row = ItemRow(
      id: id,
      type: item.type,
      name: item.name,
      presetId: item.presetId,
      categoryId: item.categoryId,
      accountId: item.accountId,
      currency: item.prices.stablePrice.currency,
      cycleUnit: item.cycle.unit,
      cycleEvery: item.cycle.every,
      anchorOn: item.anchor,
      paidUntil: item.paidUntil,
      status: ItemStatus.active,
      reminderRules: '[]',
      typeFields: '{}',
      note: item.note,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.items).insert(row);
    await _journal.inserted('items', id, row);
    await _writePhases(id, item.prices);
    await _replan(id);
    return id;
  });

  Future<ItemSchedule> scheduleOf(String itemId) async {
    final row = await _item(itemId);
    return _schedule(row, await _phases(itemId));
  }

  /// Every charge from [fromIndex] on costs [amount]; earlier charges and
  /// anything already paid keep their amounts. Logged to price history.
  Future<void> changePrice(
    String itemId, {
    required int fromIndex,
    required Money amount,
  }) => _db.transaction(() async {
    final schedule = await scheduleOf(itemId);
    final old = schedule.prices.priceAt(
      schedule.cycle,
      schedule.anchor,
      fromIndex,
    );
    final history = PriceHistoryCompanion.insert(
      id: _uuid.v7(),
      itemId: itemId,
      fromCycleIndex: fromIndex,
      effectiveOn: schedule.cycle.dateAt(schedule.anchor, fromIndex),
      oldMinor: old.minor,
      newMinor: amount.minor,
      currency: amount.currency,
      recordedAt: _nowMillis(),
    );
    await _db.into(_db.priceHistory).insert(history);
    await _journal.inserted('price_history', history.id.value, history);
    await _writePhases(
      itemId,
      schedule.prices.changedFrom(
        schedule.cycle,
        schedule.anchor,
        fromIndex,
        amount,
      ),
    );
    await _touch(itemId);
    await _replan(itemId);
  });

  /// Pauses, cancels or resumes from [since]. A paused span is never billed,
  /// even after resuming.
  Future<void> setStatus(String itemId, ItemStatus status, LocalDate since) =>
      _db.transaction(() async {
        await _updateItem(
          itemId,
          (row) => row.copyWith(status: status, statusSince: Value(since)),
        );
        await _replan(itemId);
      });

  /// Marks a charge paid, covering [cycles] cycles (e.g. a domain renewed for
  /// three years). Pushes paidUntil forward and drops covered charges.
  Future<void> markPaid(String occurrenceId, {int cycles = 1}) =>
      _db.transaction(() async {
        final occ = await (_db.select(
          _db.occurrences,
        )..where((o) => o.id.equals(occurrenceId))).getSingle();
        final paid = occ.copyWith(state: OccurrenceState.paid);
        await _db.update(_db.occurrences).replace(paid);
        await _journal.updated('occurrences', occ.id, occ, paid);

        final schedule = await scheduleOf(occ.itemId);
        final until = schedule.paidUntilAfterPaying(
          occ.cycleIndex,
          count: cycles,
        );
        if (schedule.paidUntil == null || until > schedule.paidUntil!) {
          await _updateItem(
            occ.itemId,
            (row) => row.copyWith(paidUntil: Value(until)),
          );
        }
        await _replan(occ.itemId);
      });

  Future<void> delete(String itemId) => _db.transaction(() async {
    final occurrences = await (_db.select(
      _db.occurrences,
    )..where((o) => o.itemId.equals(itemId))).get();
    final phases = await _phases(itemId);
    await (_db.delete(_db.items)..where((i) => i.id.equals(itemId))).go();
    for (final o in occurrences) {
      await _journal.deleted('occurrences', o.id);
    }
    for (final p in phases) {
      await _journal.deleted('price_phases', p.id);
    }
    await _journal.deleted('items', itemId);
  });

  /// Re-plans every item; run daily so the 12-month window keeps moving.
  Future<void> refreshAll() => _db.transaction(() async {
    final query = _db.selectOnly(_db.items)..addColumns([_db.items.id]);
    final ids = await query.map((r) => r.read(_db.items.id)!).get();
    for (final id in ids) {
      await _replan(id);
    }
  });

  /// Occurrences due in [from]..[to] (inclusive), soonest first.
  Stream<List<OccurrenceRow>> watchDue(LocalDate from, LocalDate to) {
    final q = _db.select(_db.occurrences)
      ..where(
        (o) =>
            o.dueOn.isBiggerOrEqualValue(from.toString()) &
            o.dueOn.isSmallerOrEqualValue(to.toString()),
      )
      ..orderBy([(o) => OrderingTerm.asc(o.dueOn)]);
    return q.watch();
  }

  // --- internals -----------------------------------------------------------

  Future<ItemRow> _item(String id) =>
      (_db.select(_db.items)..where((i) => i.id.equals(id))).getSingle();

  Future<List<PricePhaseRow>> _phases(String itemId) =>
      (_db.select(_db.pricePhases)
            ..where((p) => p.itemId.equals(itemId))
            ..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();

  Future<void> _touch(String itemId) => _updateItem(itemId, (row) => row);

  Future<void> _updateItem(String id, ItemRow Function(ItemRow) change) async {
    final before = await _item(id);
    final after = change(before).copyWith(updatedAt: _nowMillis());
    await _db.update(_db.items).replace(after);
    await _journal.updated('items', id, before, after);
  }

  Future<void> _writePhases(String itemId, PriceSchedule prices) async {
    final before = {for (final p in await _phases(itemId)) p.seq: p};
    for (final (seq, phase) in prices.phases.indexed) {
      final row = phaseToRow(itemId, seq, phase);
      final old = before.remove(seq);
      if (old == null) {
        await _db.into(_db.pricePhases).insert(row);
        await _journal.inserted('price_phases', row.id, row);
      } else if (old != row) {
        await _db.update(_db.pricePhases).replace(row);
        await _journal.updated('price_phases', row.id, old, row);
      }
    }
    for (final stale in before.values) {
      await (_db.delete(
        _db.pricePhases,
      )..where((p) => p.id.equals(stale.id))).go();
      await _journal.deleted('price_phases', stale.id);
    }
  }

  Future<void> _replan(String itemId) async {
    final schedule = await scheduleOf(itemId);
    final stored = await (_db.select(
      _db.occurrences,
    )..where((o) => o.itemId.equals(itemId))).get();
    final byId = {for (final o in stored) o.id: o};
    final plan = planOccurrences(schedule, [
      for (final o in stored)
        StoredOccurrence(
          id: o.id,
          index: o.cycleIndex,
          dueOn: o.dueOn,
          expected: Money(o.expectedMinor, o.currency),
          state: o.state,
        ),
    ], today: _today());
    for (final p in plan.toInsert) {
      final row = OccurrenceRow(
        id: occurrenceId(itemId, p.index),
        itemId: itemId,
        cycleIndex: p.index,
        dueOn: p.dueOn,
        expectedMinor: p.expected.minor,
        currency: p.expected.currency,
        state: OccurrenceState.pending,
      );
      await _db.into(_db.occurrences).insert(row);
      await _journal.inserted('occurrences', row.id, row);
    }
    for (final MapEntry(key: id, value: p) in plan.toUpdate.entries) {
      final before = byId[id]!;
      final after = before.copyWith(
        dueOn: p.dueOn,
        expectedMinor: p.expected.minor,
      );
      await _db.update(_db.occurrences).replace(after);
      await _journal.updated('occurrences', id, before, after);
    }
    for (final id in plan.toDelete) {
      await (_db.delete(_db.occurrences)..where((o) => o.id.equals(id))).go();
      await _journal.deleted('occurrences', id);
    }
  }
}

ItemSchedule _schedule(ItemRow row, List<PricePhaseRow> phases) => ItemSchedule(
  anchor: row.anchorOn,
  cycle: Cycle(row.cycleUnit, row.cycleEvery),
  prices: PriceSchedule([
    for (final p in phases) phaseFromRow(p, row.currency),
  ]),
  paidUntil: row.paidUntil,
  status: row.status,
  statusSince: row.statusSince,
);

PricePhaseRow phaseToRow(String itemId, int seq, PricePhase phase) {
  final (kind, periods, until) = switch (phase.length) {
    ForPeriods(:final periods) => ('periods', periods, null),
    UntilDate(:final date) => ('until', null, date),
    OpenEnded() => ('open', null, null),
  };
  return PricePhaseRow(
    id: ItemRepository.phaseId(itemId, seq),
    itemId: itemId,
    seq: seq,
    amountMinor: phase.amount.minor,
    lengthKind: kind,
    periods: periods,
    untilOn: until,
  );
}

PricePhase phaseFromRow(PricePhaseRow row, Currency currency) =>
    PricePhase(Money(row.amountMinor, currency), switch (row.lengthKind) {
      'periods' => ForPeriods(row.periods!),
      'until' => UntilDate(row.untilOn!),
      'open' => const OpenEnded(),
      final other => throw StateError('Unknown phase length "$other"'),
    });
