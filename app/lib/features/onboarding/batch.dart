import 'package:cashrotate_core/cashrotate_core.dart';

import '../../data/items/item_repository.dart';

/// One line of the quick-setup table: only amount, charge date and currency
/// are asked for; everything else comes from the preset.
class BatchRow {
  BatchRow({
    required this.key,
    required this.name,
    required this.type,
    required this.cycle,
    required this.currency,
    this.presetId,
    this.category,
    this.remindDays = const [3],
    this.cancelUrl,
    this.amountText = '',
    this.date,
    this.selected = false,
  });

  factory BatchRow.fromPreset(
    Preset p, {
    required String language,
    required Currency mainCurrency,
  }) => BatchRow(
    key: p.id,
    presetId: p.id,
    name: p.name.resolve(language),
    type: p.type,
    cycle: p.defaultCycle.cycle,
    currency: p.currency ?? mainCurrency,
    category: p.category,
    remindDays: [p.remindDays],
    cancelUrl: p.cancelUrl,
  );

  factory BatchRow.custom(String name, {required Currency mainCurrency}) =>
      BatchRow(
        key: 'custom:$name',
        name: name,
        type: ItemType.subscription,
        cycle: Cycle.monthly,
        currency: mainCurrency,
      );

  factory BatchRow.fromJson(Map<String, Object?> j) => BatchRow(
    key: j['key']! as String,
    name: j['name']! as String,
    presetId: j['presetId'] as String?,
    type: ItemType.values.byName(j['type']! as String),
    cycle: Cycle(
      CycleUnit.values.byName(j['cycleUnit']! as String),
      j['cycleEvery']! as int,
    ),
    currency: Currency.parse(j['currency']! as String),
    category: j['category'] == null
        ? null
        : PresetCategory.values.byName(j['category']! as String),
    remindDays: [
      for (final d in j['remindDays'] as List? ?? const [3]) d as int,
    ],
    cancelUrl: j['cancelUrl'] as String?,
    amountText: j['amount'] as String? ?? '',
    date: j['date'] == null ? null : LocalDate.parse(j['date']! as String),
    selected: j['selected'] == true,
  );

  final String key;
  String name;
  final String? presetId;
  final ItemType type;
  final Cycle cycle;
  Currency currency;
  final PresetCategory? category;
  final List<int> remindDays;
  final String? cancelUrl;
  String amountText;
  LocalDate? date;
  bool selected;

  Money? get amount => parseMoney(amountText, currency);

  /// Blank or unreadable amount, or no date: still to fill in.
  bool get isPending => amount == null || date == null;

  Map<String, Object?> toJson() => {
    'key': key,
    'name': name,
    'presetId': presetId,
    'type': type.name,
    'cycleUnit': cycle.unit.name,
    'cycleEvery': cycle.every,
    'currency': currency.code,
    'category': category?.name,
    'remindDays': remindDays,
    'cancelUrl': cancelUrl,
    'amount': amountText,
    'date': date?.toString(),
    'selected': selected,
  };

  /// Blank fields become a zero price dated [today], flagged to fill in.
  NewItem toNewItem({required LocalDate today}) => NewItem(
    type: type,
    name: name,
    cycle: cycle,
    anchor: date ?? today,
    paidUntil: date ?? today,
    prices: PriceSchedule.fixed(amount ?? Money.zero(currency)),
    presetId: presetId,
    categoryId: category?.name,
    remindDays: remindDays,
    typeFields: {'cancelUrl': ?cancelUrl},
    needsDetails: isPending,
  );
}

/// The quick-setup state, saved after every change so leaving halfway and
/// coming back resumes where the user was.
class BatchDraft {
  BatchDraft({this.step = 0, List<BatchRow>? rows}) : rows = rows ?? [];

  factory BatchDraft.fromJson(Object? json) {
    if (json is! Map) return BatchDraft();
    return BatchDraft(
      step: json['step'] is int ? json['step'] as int : 0,
      rows: [
        for (final r in json['rows'] as List? ?? const [])
          if (r is Map) BatchRow.fromJson(r.cast<String, Object?>()),
      ],
    );
  }

  int step;
  final List<BatchRow> rows;

  bool contains(String key) => rows.any((r) => r.key == key);

  void toggle(BatchRow row) {
    final i = rows.indexWhere((r) => r.key == row.key);
    i >= 0 ? rows.removeAt(i) : rows.add(row);
  }

  Iterable<BatchRow> get selected => rows.where((r) => r.selected);

  void applyDate(LocalDate date) {
    for (final r in selected) {
      r.date = date;
    }
  }

  void applyCurrency(Currency c) {
    for (final r in selected) {
      r.currency = c;
    }
  }

  void selectAll(bool value) {
    for (final r in rows) {
      r.selected = value;
    }
  }

  Map<String, Object?> toJson() => {
    'step': step,
    'rows': [for (final r in rows) r.toJson()],
  };
}
