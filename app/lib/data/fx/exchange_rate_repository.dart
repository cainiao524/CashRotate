import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../journal.dart';

/// Exchange rates the user entered by hand (free tier). Automatic daily
/// rates from open.er-api.com (Pro, M4+) will write to the same table.
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

  static String rowId(Currency base, Currency quote) =>
      '${base.code}/${quote.code}';

  /// All stored rates as a converter, updating as rates change.
  Stream<FxConverter> watchConverter() => _db
      .select(_db.exchangeRates)
      .watch()
      .map((rows) => FxConverter(rows.map(_toRate)));

  Future<FxConverter> converter() async =>
      FxConverter((await _db.select(_db.exchangeRates).get()).map(_toRate));

  /// Records "1 [base] = [rate] [quote]" as of today. Replaces the inverse
  /// pair if one was stored, so there is a single source of truth per pair.
  Future<void> setManualRate(Currency base, Currency quote, Ratio rate) =>
      _db.transaction(() async {
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
          rate: rate.toDecimalString(maxDecimals: 10),
          asOf: _today(),
          source: 'manual',
          updatedAt: _nowMillis(),
        );
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
      });

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
