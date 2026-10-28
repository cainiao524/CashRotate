import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';

import 'converters.dart';

// Storage conventions (ADR 0004):
// - ids are UUIDv7 text, or derived ids for rows every device can regenerate
//   identically (occurrences, price phases);
// - money is an integer count of minor units next to its currency code;
// - calendar dates are yyyy-MM-dd text, instants are UTC epoch milliseconds;
// - enums are stored by name so adding a value never shifts existing rows;
// - free-form, type-specific data is JSON text.

mixin _Timestamps on Table {
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// A fixed expense: subscription, bill, repayment, insurance/fee or transfer.
@DataClassName('ItemRow')
class Items extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get type => textEnum<ItemType>()();
  TextColumn get name => text()();
  TextColumn get presetId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();

  /// Currency of every price phase.
  TextColumn get currency => text().map(const CurrencyConverter())();
  TextColumn get cycleUnit => textEnum<CycleUnit>()();
  IntColumn get cycleEvery => integer()();
  TextColumn get anchorOn => text().map(const LocalDateConverter())();
  TextColumn get paidUntil =>
      text().map(const LocalDateConverter()).nullable()();
  TextColumn get status => textEnum<ItemStatus>()();
  TextColumn get statusSince =>
      text().map(const LocalDateConverter()).nullable()();

  /// JSON list of reminder rules (days before, kinds). Shape defined in M3.
  TextColumn get reminderRules => text().withDefault(const Constant('[]'))();

  /// JSON object of type-specific fields (domain registrar, VPS specs,
  /// repayment periods …). Shapes defined with the item editor in M2.
  TextColumn get typeFields => text().withDefault(const Constant('{}'))();

  /// JSON cost-sharing settings (total, people, my share, who has paid).
  TextColumn get sharing => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One phase of an item's price; together they form a [PriceSchedule].
@DataClassName('PricePhaseRow')
class PricePhases extends Table {
  /// `<itemId>:<seq>`.
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  IntColumn get amountMinor => integer()();

  /// `periods`, `until` or `open`.
  TextColumn get lengthKind => text()();
  IntColumn get periods => integer().nullable()();
  TextColumn get untilOn => text().map(const LocalDateConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {itemId, seq},
  ];
}

/// One expected charge of an item, expanded 12 months ahead.
@DataClassName('OccurrenceRow')
@TableIndex(name: 'occurrences_due', columns: {#dueOn})
class Occurrences extends Table {
  /// `<itemId>:<cycleIndex>`, so every device plans the same row.
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get cycleIndex => integer()();
  TextColumn get dueOn => text().map(const LocalDateConverter())();
  IntColumn get expectedMinor => integer()();
  TextColumn get currency => text().map(const CurrencyConverter())();
  TextColumn get state => textEnum<OccurrenceState>()();
  TextColumn get transactionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {itemId, cycleIndex},
  ];
}

/// Price changes as they were announced, for the price-history report.
@DataClassName('PriceHistoryRow')
class PriceHistory extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get fromCycleIndex => integer()();
  TextColumn get effectiveOn => text().map(const LocalDateConverter())();
  IntColumn get oldMinor => integer()();
  IntColumn get newMinor => integer()();
  TextColumn get currency => text().map(const CurrencyConverter())();
  IntColumn get recordedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get name => text()();
  TextColumn get currency => text().map(const CurrencyConverter())();

  /// Balance = opening balance + transactions; never stored separately.
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get creditLimitMinor => integer().nullable()();

  /// Day of month the statement closes / payment is due (credit cards).
  IntColumn get statementDay => integer().nullable()();
  IntColumn get paymentDueDay => integer().nullable()();

  /// Foreign transaction fee in basis points (150 = 1.5%).
  IntColumn get fxFeeBasisPoints => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get kind => textEnum<CategoryKind>()();

  /// User-entered name; empty for built-ins, which use [builtinKey].
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Localisation key of a built-in category, e.g. `streaming`.
  TextColumn get builtinKey => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Income that reports can leave out of work income (e.g. item sales).
  BoolColumn get excludeFromWorkIncome =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_occurred', columns: {#occurredAt})
@TableIndex(name: 'transactions_account', columns: {#accountId})
class Transactions extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get status => textEnum<TransactionStatus>()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().map(const CurrencyConverter())();

  /// Main-currency units per one unit of [currency] at the time, as a decimal
  /// string. Fixed once confirmed; later rate changes never rewrite it.
  TextColumn get fxRate => text().nullable()();
  TextColumn get fxMainCurrency =>
      text().map(const CurrencyConverter()).nullable()();
  @ReferenceName('outgoingTransactions')
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Transfers only.
  @ReferenceName('incomingTransfers')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();
  IntColumn get toAmountMinor => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get occurredAt => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get occurrenceId => text().nullable()();

  /// Created by reconciling a balance.
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionTagRow')
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

/// Receipt photos and PDFs; the file lives in app storage.
@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's own names for preset services, learnt from import corrections.
@DataClassName('AliasRow')
class Aliases extends Table {
  TextColumn get id => text()();
  TextColumn get presetId => text()();

  /// Normalised (case-folded, trimmed) text that should match the preset.
  TextColumn get alias => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {alias},
  ];
}

/// Planned versus actual notification delivery, to detect OEM delays.
@DataClassName('ReminderLogRow')
class ReminderLog extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().nullable()();
  TextColumn get occurrenceId => text().nullable()();
  TextColumn get kind => text()();
  IntColumn get scheduledAt => integer()();
  IntColumn get deliveredAt => integer().nullable()();

  /// What the user did from the notification: `paid`, `snoozed`, or null.
  TextColumn get action => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Field-level change journal for sync: one row per changed column.
/// Local-only bookkeeping (meta, reminder log) is not journaled.
@DataClassName('ChangeLogRow')
@TableIndex(name: 'change_log_row', columns: {#entity, #rowId, #field})
class ChangeLog extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get rowId => text()();

  /// SQL column name, or `_deleted` for a tombstone.
  TextColumn get field => text()();

  /// JSON-encoded SQL value.
  TextColumn get value => text()();

  /// Packed HLC; the newer one wins when devices merge.
  TextColumn get hlc => text()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
}

/// Device-local settings and bookkeeping: device id, last HLC.
@DataClassName('MetaRow')
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
