import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../items/item_repository.dart';
import '../journal.dart';

/// A way of paying (card, bank, e-wallet …). Only a label for payment
/// records plus a card's foreign fee and learned markup; no balances
/// (ADR 0010). Stored in the `accounts` table.
class PaymentMethods {
  PaymentMethods(
    this._db,
    this._journal, {
    int Function()? nowMillis,
    Uuid? uuid,
  }) : _now = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Journal _journal;
  final int Function() _now;
  final Uuid _uuid;

  /// The method payments use when none is chosen. One fixed id, so every
  /// device creates the same row.
  static const unassignedId = 'unassigned';

  Stream<List<AccountRow>> watchAll() =>
      (_db.select(_db.accounts)
            ..where(
              (a) => a.archived.equals(false) & a.id.isNotValue(unassignedId),
            )
            ..orderBy([
              (a) => OrderingTerm.asc(a.sortOrder),
              (a) => OrderingTerm.asc(a.name),
            ]))
          .watch();

  Future<String> create({
    required String name,
    required AccountType type,
    required Currency currency,
    int? fxFeeBasisPoints,
    String? cardLast4,
  }) => _db.transaction(() async {
    final id = _uuid.v7();
    final row = AccountRow(
      id: id,
      type: type,
      name: name.trim(),
      currency: currency,
      openingBalanceMinor: 0,
      fxFeeBasisPoints: fxFeeBasisPoints,
      cardLast4: _last4(cardLast4),
      archived: false,
      sortOrder: 0,
      createdAt: _now(),
      updatedAt: _now(),
    );
    await _db.into(_db.accounts).insert(row);
    await _journal.inserted('accounts', id, row);
    return id;
  });

  Future<void> update(
    String id, {
    required String name,
    required AccountType type,
    required Currency currency,
    int? fxFeeBasisPoints,
    String? cardLast4,
  }) => _db.transaction(() async {
    final before = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingle();
    final after = before.copyWith(
      name: name.trim(),
      type: type,
      currency: currency,
      fxFeeBasisPoints: Value(fxFeeBasisPoints),
      cardLast4: Value(_last4(cardLast4)),
      updatedAt: _now(),
    );
    await _db.update(_db.accounts).replace(after);
    await _journal.updated('accounts', id, before, after);
  });

  /// Hidden from pickers; past payments keep showing its name.
  Future<void> archive(String id) => _db.transaction(() async {
    final before = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingle();
    final after = before.copyWith(archived: true, updatedAt: _now());
    await _db.update(_db.accounts).replace(after);
    await _journal.updated('accounts', id, before, after);
  });

  static String? _last4(String? s) {
    final digits = s?.replaceAll(RegExp(r'\D'), '') ?? '';
    return digits.length >= 4 ? digits.substring(digits.length - 4) : null;
  }

  Future<String> _ensureUnassigned(Currency main) async {
    final existing = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(unassignedId))).getSingleOrNull();
    if (existing != null) return unassignedId;
    final row = AccountRow(
      id: unassignedId,
      type: AccountType.cash,
      name: '',
      currency: main,
      openingBalanceMinor: 0,
      archived: false,
      sortOrder: 0,
      createdAt: _now(),
      updatedAt: _now(),
    );
    await _db.into(_db.accounts).insertOnConflictUpdate(row);
    await _journal.inserted('accounts', unassignedId, row);
    return unassignedId;
  }
}

/// What a recorded payment looks like.
class Payment {
  Payment(this.row);

  final TransactionRow row;

  Money get paid => Money(row.amountMinor, row.currency);

  /// What was due in the item's own currency, when paid in another.
  Money? get original => row.originalCurrency == null
      ? null
      : Money(row.originalAmountMinor!, row.originalCurrency!);

  LocalDate get paidOn => LocalDate.fromDateTime(
    DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
  );

  /// Rate actually charged: paid-currency units per one original unit.
  Ratio? get actualRate =>
      row.fxRate == null ? null : Ratio.tryParse(row.fxRate!);

  /// Markup over the published rate, in basis points (+150 = 1.5% more).
  int? get markupBasisPoints {
    final actual = actualRate;
    final market = row.marketFxRate == null
        ? null
        : Ratio.tryParse(row.marketFxRate!);
    if (actual == null || market == null) return null;
    final r = actual * market.inverse;
    return ((r.numerator * BigInt.from(10000)) ~/ r.denominator).toInt() -
        10000;
  }
}

/// Payment records: what each charge actually cost (ADR 0010).
class PaymentRepository {
  PaymentRepository(
    this._db,
    this._journal,
    this._items,
    this._methods, {
    int Function()? nowMillis,
    Uuid? uuid,
  }) : _now = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Journal _journal;
  final ItemRepository _items;
  final PaymentMethods _methods;
  final int Function() _now;
  final Uuid _uuid;

  /// Payments learned from to estimate a card's markup.
  static const markupSamples = 5;

  /// Records a payment and settles [occurrenceId] (when given).
  ///
  /// [expected] is what was due in the item's currency; [paid] what was
  /// actually charged, possibly in another currency (a card statement in
  /// the main currency). [marketRate] is today's published rate from the
  /// item currency to [paid]'s, to learn the card's markup.
  /// [updateFuturePrice]: the amount changed for good ("update the price"),
  /// not just this once; only for a same-currency difference.
  Future<String> record({
    required String itemId,
    required Money expected,
    required Money paid,
    required LocalDate paidOn,
    required Currency main,
    String? occurrenceId,
    String? accountId,
    Ratio? marketRate,
    bool updateFuturePrice = false,
    String note = '',
  }) => _db.transaction(() async {
    final account = accountId ?? await _methods._ensureUnassigned(main);
    final foreign = paid.currency != expected.currency;
    final id = _uuid.v7();
    final row = TransactionRow(
      id: id,
      type: TransactionType.expense,
      status: TransactionStatus.confirmed,
      amountMinor: paid.minor,
      currency: paid.currency,
      fxRate: foreign
          ? _rate(paid, expected).toDecimalString(maxDecimals: 8)
          : null,
      fxMainCurrency: main,
      accountId: account,
      occurredAt: DateTime.utc(
        paidOn.year,
        paidOn.month,
        paidOn.day,
        12,
      ).millisecondsSinceEpoch,
      note: note,
      occurrenceId: occurrenceId,
      itemId: itemId,
      originalAmountMinor: foreign ? expected.minor : null,
      originalCurrency: foreign ? expected.currency : null,
      marketFxRate: foreign
          ? marketRate?.toDecimalString(maxDecimals: 8)
          : null,
      isAdjustment: false,
      createdAt: _now(),
      updatedAt: _now(),
    );
    await _db.into(_db.transactions).insert(row);
    await _journal.inserted('transactions', id, row);

    if (occurrenceId != null) {
      final occ = await (_db.select(
        _db.occurrences,
      )..where((o) => o.id.equals(occurrenceId))).getSingleOrNull();
      if (occ != null && occ.state == OccurrenceState.pending) {
        await _items.markPaid(occurrenceId, transactionId: id);
        if (updateFuturePrice && !foreign && paid != expected) {
          await _items.changePrice(
            itemId,
            fromIndex: occ.cycleIndex + 1,
            amount: paid,
          );
        }
      }
    }
    return id;
  });

  /// [paid] per one unit of [expected], from the two amounts.
  static Ratio _rate(Money paid, Money expected) {
    final ten = BigInt.from(10);
    return Ratio(
      BigInt.from(paid.minor) * ten.pow(expected.currency.minorUnits),
      BigInt.from(expected.minor) * ten.pow(paid.currency.minorUnits),
    );
  }

  Stream<List<Payment>> watchForItem(String itemId) =>
      (_db.select(_db.transactions)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch()
          .map((rows) => [for (final r in rows) Payment(r)]);

  Stream<List<Payment>> watchAll() =>
      (_db.select(_db.transactions)
            ..where((t) => t.itemId.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .watch()
          .map((rows) => [for (final r in rows) Payment(r)]);

  /// The average markup of a card's last [markupSamples] foreign payments,
  /// in basis points; null before it has any.
  Future<int?> learnedMarkup(String accountId) async {
    final rows =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.accountId.equals(accountId) &
                    t.marketFxRate.isNotNull() &
                    t.fxRate.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
              ..limit(markupSamples))
            .get();
    final marks = [for (final r in rows) ?Payment(r).markupBasisPoints];
    if (marks.isEmpty) return null;
    return (marks.reduce((a, b) => a + b) / marks.length).round();
  }

  Future<void> delete(String id) => _db.transaction(() async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    await _journal.deleted('transactions', id);
  });

  /// Deletes a payment and makes the charge it paid due again (paid-until
  /// goes back to that charge). Irregular bills have no charge to reopen.
  Future<void> deleteAndReopen(String id) => _db.transaction(() async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await delete(id);
    final occurrenceId = row.occurrenceId;
    if (occurrenceId == null) return;
    final occurrence = await (_db.select(
      _db.occurrences,
    )..where((o) => o.id.equals(occurrenceId))).getSingleOrNull();
    if (occurrence == null || occurrence.transactionId != id) return;
    await _items.reopen(occurrenceId, occurrence.dueOn);
  });
}
