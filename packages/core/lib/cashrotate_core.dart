/// CashRotate domain layer: money, FX, schedules and price phases,
/// reminders, ledger, reports, import pipeline and preset matching.
///
/// Pure Dart. Nothing here may depend on Flutter or platform code.
library;

export 'src/detection/charge_matcher.dart';
export 'src/detection/charge_parser.dart';
export 'src/entitlements/entitlements.dart';
export 'src/fx/auto_rates.dart';
export 'src/fx/exchange_rate.dart';
export 'src/model/kinds.dart';
export 'src/money/currency.dart';
export 'src/money/currency_info.dart';
export 'src/money/money.dart';
export 'src/money/money_format.dart';
export 'src/money/symbol_resolver.dart';
export 'src/presets/han_readings.dart';
export 'src/presets/preset.dart';
export 'src/presets/preset_search.dart';
export 'src/reminders/reminder_planner.dart';
export 'src/schedule/cycle.dart';
export 'src/schedule/occurrence_planner.dart';
export 'src/schedule/price_schedule.dart';
export 'src/time/local_date.dart';
