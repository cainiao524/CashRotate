import 'package:cashrotate_core/cashrotate_core.dart';

import '../../data/items/item_repository.dart';

/// Field groups the editor can show beyond the common fields.
enum FieldGroup {
  subscription,
  bill,
  repayment,
  policy,
  transfer,
  trial,
  contract,
  domain,
  vps,
  gameServer,
  sharing,
}

enum DraftField {
  name,
  amount,
  introAmount,
  introPeriods,
  nextCharge,
  customEvery,
}

enum DraftError { required, amount, renewalRequired, periods }

/// One person in a shared subscription.
class SharingMember {
  SharingMember({required this.name, this.paid = false});
  String name;
  bool paid;

  Map<String, Object?> toJson() => {'name': name, 'paid': paid};
}

/// Mutable editor state for one fixed expense, with validation and
/// conversion to [NewItem]. Free of widgets so it can be unit-tested.
class ItemDraft {
  ItemDraft({
    required this.type,
    required this.currency,
    required this.cycle,
    this.name = '',
    this.presetId,
    this.category,
    this.amountText = '',
    this.nextCharge,
    this.note = '',
    Map<String, Object?>? fields,
    this.presetFields = const [],
    this.plans = const [],
    this.remindDays = const [3],
  }) : fields = fields ?? {};

  /// Pre-filled from a preset: name, type, cycle, billing currency (or the
  /// user's main currency), category, reminder days, cancel link.
  factory ItemDraft.fromPreset(
    Preset p, {
    required String language,
    required Currency mainCurrency,
  }) => ItemDraft(
    type: p.type,
    name: p.name.resolve(language),
    presetId: p.id,
    category: p.category,
    currency: p.currency ?? mainCurrency,
    cycle: p.defaultCycle.cycle,
    presetFields: p.fields,
    plans: p.plans,
    remindDays: [p.remindDays],
    fields: {if (p.cancelUrl != null) 'cancelUrl': p.cancelUrl},
  );

  /// Editing an existing item.
  factory ItemDraft.fromItem(
    ItemView view, {
    required String locale,
    Preset? preset,
  }) {
    final item = view.toNewItem();
    final prices = item.prices;
    final draft = ItemDraft(
      type: item.type,
      name: item.name,
      presetId: item.presetId,
      category: PresetCategory.values
          .where((c) => c.name == item.categoryId)
          .firstOrNull,
      currency: prices.stablePrice.currency,
      cycle: item.cycle,
      amountText: item.needsDetails && prices.stablePrice.isZero
          ? ''
          : formatAmount(
              prices.stablePrice,
              locale: 'en',
              decimals: prices.stablePrice.currency.minorUnits,
            ),
      nextCharge: item.needsDetails
          ? null
          : (view.nextDue?.dueOn ?? item.anchor),
      note: item.note,
      fields: {...item.typeFields},
      presetFields: preset?.fields ?? const [],
      plans: preset?.plans ?? const [],
      remindDays: item.remindDays,
    );
    // Simple intro schedules (n periods, then the stable price) are editable;
    // anything more complex is preserved as is unless the price is changed.
    if (prices.phases case [
      PricePhase(length: ForPeriods(:final periods)),
      _,
    ]) {
      draft
        ..intro = true
        ..introAmountText = formatAmount(
          prices.phases.first.amount,
          locale: 'en',
          decimals: prices.phases.first.amount.currency.minorUnits,
        )
        ..introPeriodsText = '$periods';
    } else if (prices.phases.length > 1) {
      draft._keptSchedule = prices;
    }
    draft._anchor = item.anchor;
    if (item.sharing case final s?) {
      draft
        ..sharing = true
        ..sharingPeople = (s['people'] as int?) ?? 2
        ..sharingTotalText = s['total'] is int
            ? formatAmount(
                Money(s['total']! as int, draft.currency),
                locale: 'en',
                decimals: draft.currency.minorUnits,
              )
            : ''
        ..members = [
          for (final m in (s['members'] as List? ?? const []))
            if (m is Map)
              SharingMember(
                name: '${m['name'] ?? ''}',
                paid: m['paid'] == true,
              ),
        ];
    }
    return draft;
  }

  ItemType type;
  String name;
  String? presetId;
  PresetCategory? category;
  Currency currency;
  Cycle cycle;

  /// The price per charge, or the renewal price when [intro] is on.
  String amountText;
  LocalDate? nextCharge;
  String note;

  bool intro = false;
  String introAmountText = '';
  String introPeriodsText = '1';

  bool sharing = false;
  String sharingTotalText = '';
  int sharingPeople = 2;
  List<SharingMember> members = [];

  /// Type-specific values keyed as stored in Items.typeFields.
  final Map<String, Object?> fields;
  final List<PresetField> presetFields;
  final List<PresetPlan> plans;
  List<int> remindDays;

  PriceSchedule? _keptSchedule;
  LocalDate? _anchor;

  /// Groups to show for the current type and preset.
  Set<FieldGroup> get groups => {
    switch (type) {
      ItemType.subscription => FieldGroup.subscription,
      ItemType.bill => FieldGroup.bill,
      ItemType.repayment => FieldGroup.repayment,
      ItemType.insuranceAndFees => FieldGroup.policy,
      ItemType.transferOut => FieldGroup.transfer,
    },
    if (type == ItemType.subscription) FieldGroup.trial,
    if (type == ItemType.bill) FieldGroup.contract,
    for (final f in presetFields)
      switch (f) {
        PresetField.trial => FieldGroup.trial,
        PresetField.contract => FieldGroup.contract,
        PresetField.domain => FieldGroup.domain,
        PresetField.vps => FieldGroup.vps,
        PresetField.gameServer => FieldGroup.gameServer,
        PresetField.repayment => FieldGroup.repayment,
        PresetField.policy => FieldGroup.policy,
      },
    if (type == ItemType.subscription || type == ItemType.bill)
      FieldGroup.sharing,
  };

  Money? get amount => parseMoney(amountText, currency);
  Money? get introAmount => parseMoney(introAmountText, currency);
  int? get introPeriods {
    final n = int.tryParse(introPeriodsText.trim());
    return n != null && n >= 1 ? n : null;
  }

  /// My share when sharing: an even split of the total by default.
  Money? get myShare {
    final total = parseMoney(sharingTotalText, currency) ?? amount;
    if (total == null || sharingPeople < 1) return null;
    return Money(divideRoundHalfEven(total.minor, sharingPeople), currency);
  }

  Map<DraftField, DraftError> validate() => {
    if (name.trim().isEmpty) DraftField.name: DraftError.required,
    if (amountText.trim().isEmpty)
      DraftField.amount: intro
          ? DraftError.renewalRequired
          : DraftError.required
    else if (amount == null)
      DraftField.amount: DraftError.amount,
    if (intro && introAmount == null)
      DraftField.introAmount: introAmountText.trim().isEmpty
          ? DraftError.required
          : DraftError.amount,
    if (intro && introPeriods == null)
      DraftField.introPeriods: DraftError.periods,
    if (nextCharge == null) DraftField.nextCharge: DraftError.required,
  };

  bool get isValid => validate().isEmpty;

  PriceSchedule get prices {
    final price = amount!;
    if (intro) {
      return PriceSchedule.intro(
        intro: introAmount!,
        periods: introPeriods!,
        renewal: price,
      );
    }
    final kept = _keptSchedule;
    if (kept != null && kept.stablePrice == price) return kept;
    return PriceSchedule.fixed(price);
  }

  /// Call only when [isValid]. The next charge date becomes the anchor for
  /// new items; when editing, the original anchor is kept if the next charge
  /// still falls on its schedule so charge numbering stays stable.
  NewItem toNewItem() {
    final next = nextCharge!;
    var anchor = next;
    final original = _anchor;
    if (original != null && next >= original) {
      final index = cycle.firstIndexOnOrAfter(original, next);
      if (cycle.dateAt(original, index) == next) anchor = original;
    }
    return NewItem(
      type: type,
      name: name.trim(),
      cycle: cycle,
      anchor: anchor,
      // "Next charge date" means everything before it is settled.
      paidUntil: next,
      prices: prices,
      presetId: presetId,
      categoryId: category?.name,
      note: note.trim(),
      typeFields: {
        for (final MapEntry(:key, :value) in fields.entries)
          if (value != null && value != '') key: value,
      },
      sharing: sharing
          ? {
              'people': sharingPeople,
              'total': ?parseMoney(sharingTotalText, currency)?.minor,
              'myShare': ?myShare?.minor,
              'members': [for (final m in members) m.toJson()],
            }
          : null,
      remindDays: remindDays,
    );
  }
}
