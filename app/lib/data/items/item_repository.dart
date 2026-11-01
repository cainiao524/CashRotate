import 'dart:convert';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../journal.dart';

/// What the user enters to create (or replace the details of) a fixed
/// expense.
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
    this.typeFields = const {},
    this.sharing,
    this.remindDays = const [3],
    this.needsDetails = false,
  });

  final ItemType type;
  final String name;
  final Cycle cycle;

  /// Due date of the first charge.
  final LocalDate anchor;
  final PriceSchedule prices;
  final String? presetId;

  /// Preset category name until user categories arrive with the ledger (M4).
  final String? categoryId;
  final String? accountId;
  final LocalDate? paidUntil;
  final String note;

  /// Type-specific fields (plan, trial end, domain, VPS …), JSON-encodable.
  final Map<String, Object?> typeFields;

  /// Cost sharing (total, people, my share, members), JSON-encodable.
  final Map<String, Object?>? sharing;

  /// Days before each charge to remind; reminder kinds arrive in M3.
  final List<int> remindDays;

  /// Amount or date still to be filled in (quick setup).
  final bool needsDetails;
}

/// An item with everything the list and detail screens show.
class ItemView {
  ItemView(this.row, this.schedule, this.nextDue);

  final ItemRow row;
  final ItemSchedule schedule;

  /// Next pending occurrence, if any.
  final OccurrenceRow? nextDue;

  Map<String, Object?> get typeFields =>
      (jsonDecode(row.typeFields) as Map).cast<String, Object?>();
  Map<String, Object?>? get sharing => row.sharing == null
      ? null
      : (jsonDecode(row.sharing!) as Map).cast<String, Object?>();
  List<int> get remindDays => [
    for (final r in jsonDecode(row.reminderRules) as List)
      if (r is Map && r['daysBefore'] is int) r['daysBefore'] as int,
  ];

  /// Average monthly cost of the long-term price.
  Money get stableMonthly =>
      schedule.cycle.monthlyEquivalent(schedule.prices.stablePrice);

  /// Back to the editor's input shape, for editing or duplicating.
  NewItem toNewItem() => NewItem(
    type: row.type,
    name: row.name,
    cycle: schedule.cycle,
    anchor: schedule.anchor,
    prices: schedule.prices,
    presetId: row.presetId,
    categoryId: row.categoryId,
    accountId: row.accountId,
    paidUntil: schedule.paidUntil,
    note: row.note,
    typeFields: typeFields,
    sharing: sharing,
    remindDays: remindDays,
    needsDetails: row.needsDetails,
  );
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

  static String occurrenceId(String itemId, LocalDate dueOn) =>
      '$itemId:$dueOn';
  static String phaseId(String itemId, int seq) => '$itemId:$seq';

  Future<String> create(NewItem item) => _db.transaction(() async {
    final id = _uuid.v7();
    final now = _nowMillis();
    final row = _rowFor(id, item, createdAt: now, status: ItemStatus.active);
    await _db.into(_db.items).insert(row);
    await _journal.inserted('items', id, row);
    await _writePhases(id, item.prices);
    await _replan(id);
    return id;
  });

  /// Creates several items in one transaction (quick setup).
  Future<List<String>> createAll(List<NewItem> items) =>
      _db.transaction(() async => [for (final i in items) await create(i)]);

  /// Replaces an item's details. Status and paid occurrences are kept;
  /// pending occurrences are re-planned from the new schedule.
  ///
  /// [NewItem.paidUntil] wins when given: the editor sets it to the next
  /// charge date the user entered, which is an explicit instruction even if
  /// the old schedule was paid further ahead. Otherwise it is kept.
  Future<void> update(String itemId, NewItem item) => _db.transaction(() async {
    final before = await _item(itemId);
    final after = _rowFor(
      itemId,
      item,
      createdAt: before.createdAt,
      status: before.status,
      statusSince: before.statusSince,
      paidUntil: item.paidUntil ?? before.paidUntil,
    );
    await _db.update(_db.items).replace(after);
    await _journal.updated('items', itemId, before, after);
    await _writePhases(itemId, item.prices);
    await _replan(itemId);
  });

  /// A copy of [itemId] as a new active item, named [name].
  Future<String> duplicate(String itemId, {required String name}) async {
    final source = await view(itemId);
    final copy = source.toNewItem();
    return create(
      NewItem(
        type: copy.type,
        name: name,
        cycle: copy.cycle,
        anchor: copy.anchor,
        prices: copy.prices,
        presetId: copy.presetId,
        categoryId: copy.categoryId,
        accountId: copy.accountId,
        note: copy.note,
        typeFields: copy.typeFields,
        sharing: copy.sharing,
        remindDays: copy.remindDays,
        needsDetails: copy.needsDetails,
      ),
    );
  }

  Future<ItemView> view(String itemId) async {
    final row = await _item(itemId);
    return ItemView(
      row,
      _schedule(row, await _phases(itemId)),
      await _nextDue(itemId),
    );
  }

  /// Every item, soonest next charge first; items without one go last.
  Stream<List<ItemView>> watchAll() {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.items, _db.pricePhases, _db.occurrences},
        )
        .watch()
        .asyncMap((_) => _loadAll());
  }

  Stream<ItemView?> watchOne(String itemId) =>
      watchAll().map((all) => all.where((v) => v.row.id == itemId).firstOrNull);

  // One transaction: never see an item without its phases mid-write.
  Future<List<ItemView>> _loadAll() => _db.transaction(() async {
    final rows = await _db.select(_db.items).get();
    final phases = await (_db.select(
      _db.pricePhases,
    )..orderBy([(p) => OrderingTerm.asc(p.seq)])).get();
    final pending =
        await (_db.select(_db.occurrences)
              ..where((o) => o.state.equalsValue(OccurrenceState.pending))
              ..orderBy([(o) => OrderingTerm.asc(o.dueOn)]))
            .get();
    final phasesByItem = <String, List<PricePhaseRow>>{};
    for (final p in phases) {
      (phasesByItem[p.itemId] ??= []).add(p);
    }
    final nextByItem = <String, OccurrenceRow>{};
    for (final o in pending) {
      nextByItem.putIfAbsent(o.itemId, () => o);
    }
    final views = [
      for (final r in rows)
        ItemView(
          r,
          _schedule(r, phasesByItem[r.id] ?? const []),
          nextByItem[r.id],
        ),
    ];
    int byNextDue(ItemView a, ItemView b) {
      final da = a.nextDue?.dueOn;
      final db = b.nextDue?.dueOn;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1; // items with a next charge first
      if (db != null) return 1;
      return 0;
    }

    return views..sort((a, b) {
      final c = byNextDue(a, b);
      return c != 0 ? c : a.row.name.compareTo(b.row.name);
    });
  });

  Future<OccurrenceRow?> _nextDue(String itemId) =>
      (_db.select(_db.occurrences)
            ..where(
              (o) =>
                  o.itemId.equals(itemId) &
                  o.state.equalsValue(OccurrenceState.pending),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.dueOn)])
            ..limit(1))
          .getSingleOrNull();

  ItemRow _rowFor(
    String id,
    NewItem item, {
    required int createdAt,
    required ItemStatus status,
    LocalDate? statusSince,
    LocalDate? paidUntil,
  }) => ItemRow(
    id: id,
    type: item.type,
    name: item.name.trim(),
    presetId: item.presetId,
    categoryId: item.categoryId,
    accountId: item.accountId,
    currency: item.prices.stablePrice.currency,
    cycleUnit: item.cycle.unit,
    cycleEvery: item.cycle.every,
    anchorOn: item.anchor,
    paidUntil: paidUntil ?? item.paidUntil,
    status: status,
    statusSince: statusSince,
    reminderRules: jsonEncode([
      for (final d in item.remindDays) {'daysBefore': d},
    ]),
    typeFields: jsonEncode(item.typeFields),
    sharing: item.sharing == null ? null : jsonEncode(item.sharing),
    note: item.note,
    needsDetails: item.needsDetails,
    createdAt: createdAt,
    updatedAt: _nowMillis(),
  );

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
  /// [transactionId] links the payment record (M4).
  Future<void> markPaid(
    String occurrenceId, {
    int cycles = 1,
    String? transactionId,
  }) => _db.transaction(() async {
    final occ = await (_db.select(
      _db.occurrences,
    )..where((o) => o.id.equals(occurrenceId))).getSingle();
    final paid = occ.copyWith(
      state: OccurrenceState.paid,
      transactionId: transactionId == null
          ? const Value.absent()
          : Value(transactionId),
    );
    await _db.update(_db.occurrences).replace(paid);
    await _journal.updated('occurrences', occ.id, occ, paid);

    final schedule = await scheduleOf(occ.itemId);
    final until = schedule.paidUntilAfterPaying(occ.cycleIndex, count: cycles);
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
        id: occurrenceId(itemId, p.dueOn),
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
