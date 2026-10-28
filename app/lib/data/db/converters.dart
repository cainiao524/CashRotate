import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';

/// Calendar dates as `yyyy-MM-dd` text: sortable, readable, zone-free.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toString();
}

/// ISO 4217 code.
class CurrencyConverter extends TypeConverter<Currency, String> {
  const CurrencyConverter();

  @override
  Currency fromSql(String fromDb) => Currency.parse(fromDb);

  @override
  String toSql(Currency value) => value.code;
}
