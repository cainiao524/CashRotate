import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/foundation.dart' show immutable;

/// What kind of money comes in (CLAUDE.md item 19).
enum IncomeType {
  salary,
  bonus,
  freelance,
  business,
  rental,
  investment,
  pension,
  benefits,
  allowance,
  sales,
  other,
}

/// One source of income the user expects: an amount per cycle. Not a ledger
/// of each deposit; it only gives the fixed expenses something to compare
/// against ("fixed costs are 38% of income").
@immutable
class IncomeSource {
  const IncomeSource({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.cycle,
    this.countsInShare = true,
  });

  final String id;
  final IncomeType type;

  /// Optional label ("Company A", "Flat on Main St"); empty for the type's
  /// own name.
  final String name;

  /// Take-home amount per [cycle], in the source's own currency.
  final Money amount;
  final Cycle cycle;

  /// Included when comparing fixed expenses with income. Off for money that
  /// should not be relied on (one-off sales, windfalls).
  final bool countsInShare;

  /// Average per month.
  Money get monthly => cycle.monthlyEquivalent(amount);

  static IncomeSource? fromJson(Object? json) {
    if (json is! Map) return null;
    try {
      final currency = Currency.parse(json['currency']! as String);
      return IncomeSource(
        id: json['id']! as String,
        type: IncomeType.values.asNameMap()[json['type']] ?? IncomeType.other,
        name: json['name'] as String? ?? '',
        amount: Money(json['amountMinor']! as int, currency),
        cycle: Cycle(
          CycleUnit.values.byName(json['cycleUnit']! as String),
          json['cycleEvery']! as int,
        ),
        countsInShare: json['countsInShare'] != false,
      );
    } on Object {
      return null; // unreadable entries (another app version) are skipped
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
    'cycleUnit': cycle.unit.name,
    'cycleEvery': cycle.every,
    'countsInShare': countsInShare,
  };

  IncomeSource copyWith({
    IncomeType? type,
    String? name,
    Money? amount,
    Cycle? cycle,
    bool? countsInShare,
  }) => IncomeSource(
    id: id,
    type: type ?? this.type,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    cycle: cycle ?? this.cycle,
    countsInShare: countsInShare ?? this.countsInShare,
  );

  @override
  bool operator ==(Object other) =>
      other is IncomeSource &&
      other.id == id &&
      other.type == type &&
      other.name == name &&
      other.amount == amount &&
      other.cycle == cycle &&
      other.countsInShare == countsInShare;

  @override
  int get hashCode => Object.hash(id, type, name, amount, cycle, countsInShare);
}

/// Monthly income against monthly fixed expenses, in the main currency.
@immutable
class IncomeComparison {
  const IncomeComparison({
    required this.income,
    required this.fixed,
    required this.missingRates,
    required this.byType,
  });

  /// Counted income per month.
  final Money income;
  final Money fixed;

  /// Counted sources left out for lack of an exchange rate.
  final int missingRates;

  /// Counted monthly income per type, largest first.
  final List<({IncomeType type, Money monthly})> byType;

  /// Fixed expenses as a share of income (0.38 = 38%); null without income.
  double? get share => income.minor <= 0 ? null : fixed.minor / income.minor;

  /// What is left once fixed expenses are paid (negative when they exceed
  /// income).
  Money get remaining => Money(income.minor - fixed.minor, income.currency);
}

/// Compares [sources] (those counted) with [fixedMonthly]; null when no
/// source is counted.
IncomeComparison? compareIncome(
  List<IncomeSource> sources, {
  required Money fixedMonthly,
  required FxConverter fx,
}) {
  final main = fixedMonthly.currency;
  final counted = [
    for (final s in sources)
      if (s.countsInShare) s,
  ];
  if (counted.isEmpty) return null;
  var total = 0;
  var missing = 0;
  final byType = <IncomeType, int>{};
  for (final s in counted) {
    final converted = fx.convert(s.monthly, main);
    if (converted == null) {
      missing++;
      continue;
    }
    total += converted.amount.minor;
    byType[s.type] = (byType[s.type] ?? 0) + converted.amount.minor;
  }
  final types = byType.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return IncomeComparison(
    income: Money(total, main),
    fixed: fixedMonthly,
    missingRates: missing,
    byType: [
      for (final e in types) (type: e.key, monthly: Money(e.value, main)),
    ],
  );
}
