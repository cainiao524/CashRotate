import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../journal.dart';

/// Exchange rates: typed by the user (`manual`) or downloaded daily
/// (source = provider id). One row per currency pair, in either direction;
/// writing a pair replaces both directions so they can never disagree.
class ExchangeRateRepository {
  ExchangeRateRepository(
    this._db,
    this._journal, {
    int Function()? nowMillis,
    LocalDate Function()? today,
  }) : _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _today = today ?? (() => LocalDate.fromDateTime(DateTime.now()));

  final AppDatabase _db;
  final Journal _journal;
  final int Function() _nowMillis;
  final LocalDate Function() _today;

  static const manualSource = 'manual';

  /// Device-local: each device downloads for itself.
  static const _fetchedOnKey = 'rates_fetched_on';

  static String rowId(Currency base, Currency quote) =>
      '${base.code}/${quote.code}';

  /// All stored rates as a converter, updating as rates change.
  Stream<FxConverter> watchConverter() => _db
      .select(_db.exchangeRates)
      .watch()
      .map((rows) => FxConverter(rows.map(_toRate)));

  /// Stored rates (one direction per pair), by base then quote.
  Stream<List<ExchangeRate>> watchRates() =>
      (_db.select(_db.exchangeRates)..orderBy([
            (r) => OrderingTerm.asc(r.base),
            (r) => OrderingTerm.asc(r.quote),
          ]))
          .watch()
          .map((rows) => rows.map(_toRate).toList());

  Future<FxConverter> converter() async =>
      FxConverter((await _db.select(_db.exchangeRates).get()).map(_toRate));

  /// Records "1 [base] = [rate] [quote]" typed by the user, dated today.
  Future<void> setManualRate(Currency base, Currency quote, Ratio rate) =>
      _db.transaction(() => _put(base, quote, rate, _today(), manualSource));

  /// Stores downloaded rates for [only] (all fetched currencies when null)
  /// as "1 main = rate c", replacing manual or older rates for those pairs.
  Future<void> setAutoRates(FetchedRates fetched, {Set<Currency>? only}) =>
      _db.transaction(() async {
        for (final MapEntry(key: c, value: rate) in fetched.rates.entries) {
          if (only != null && !only.contains(c)) continue;
          await _put(fetched.base, c, rate, fetched.asOf, fetched.source);
        }
      });

  /// Last day rates were downloaded on this device.
  Future<LocalDate?> lastFetchedOn() async {
    final row = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_fetchedOnKey))).getSingleOrNull();
    return row == null ? null : LocalDate.parse(row.value);
  }

  Future<void> markFetched(LocalDate day) => _db
      .into(_db.meta)
      .insertOnConflictUpdate(
        MetaCompanion.insert(key: _fetchedOnKey, value: day.toString()),
      );

  Future<void> _put(
    Currency base,
    Currency quote,
    Ratio rate,
    LocalDate asOf,
    String source,
  ) async {
    if (base == quote) throw ArgumentError('A rate needs two currencies');
    final inverse = await _row(quote, base);
    if (inverse != null) {
      await (_db.delete(_db.exchangeRates)..where(
            (r) => r.base.equalsValue(quote) & r.quote.equalsValue(base),
          ))
          .go();
      await _journal.deleted('exchange_rates', rowId(quote, base));
    }
    final before = await _row(base, quote);
    final after = ExchangeRateRow(
      base: base,
      quote: quote,
      rate: rate.toDecimalString(maxDecimals: 12),
      asOf: asOf,
      source: source,
      updatedAt: _nowMillis(),
    );
    if (before != null &&
        before.rate == after.rate &&
        before.asOf == after.asOf &&
        before.source == after.source) {
      return; // unchanged: no write, no journal entry
    }
    await _db.into(_db.exchangeRates).insertOnConflictUpdate(after);
    if (before == null) {
      await _journal.inserted('exchange_rates', rowId(base, quote), after);
    } else {
      await _journal.updated(
        'exchange_rates',
        rowId(base, quote),
        before,
        after,
      );
    }
  }

  Future<ExchangeRateRow?> _row(Currency base, Currency quote) =>
      (_db.select(_db.exchangeRates)..where(
            (r) => r.base.equalsValue(base) & r.quote.equalsValue(quote),
          ))
          .getSingleOrNull();

  static ExchangeRate _toRate(ExchangeRateRow r) => ExchangeRate(
    base: r.base,
    quote: r.quote,
    rate: Ratio.tryParse(r.rate)!,
    asOf: r.asOf,
    source: r.source,
  );
}
