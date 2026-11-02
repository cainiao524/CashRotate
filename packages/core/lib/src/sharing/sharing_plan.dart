import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import '../schedule/cycle.dart';
import '../time/local_date.dart';

/// My place in a shared or family plan (CLAUDE.md item 4).
enum SharingRole {
  /// I pay the service in full; the others pay me their share.
  organizer,

  /// Someone else pays the service; I pay them. The item's price and dates
  /// are what I pay the organizer.
  member,
}

/// How an organizer's plan is divided.
enum SharingSplit {
  /// Price ÷ people (members who joined later or left are counted only
  /// while in).
  equal,

  /// Fixed shares per person (a free seat is a share of 0).
  custom,

  /// One person pays the whole bill each period, in turn.
  rotating,
}

/// Someone else in the plan.
@immutable
class SharingMemberPlan {
  const SharingMemberPlan({
    required this.name,
    this.share,
    this.paid = false,
    this.paidUntil,
    this.joinedOn,
    this.leftOn,
  });

  factory SharingMemberPlan.fromJson(Map<String, Object?> j) {
    final currency = Currency.tryParse(j['currency'] as String? ?? '');
    final minor = j['share'];
    return SharingMemberPlan(
      name: j['name'] as String? ?? '',
      share: minor is int && currency != null ? Money(minor, currency) : null,
      paid: j['paid'] == true,
      paidUntil: _date(j['paidUntil']),
      joinedOn: _date(j['joinedOn']),
      leftOn: _date(j['leftOn']),
    );
  }

  final String name;

  /// Custom split: what they pay per charge, in their own currency (they
  /// may pay NT$ for a US$ plan).
  final Money? share;

  /// Paid for the current period (simple tracking).
  final bool paid;

  /// Paid ahead through this date (a member paying a year at once).
  final LocalDate? paidUntil;
  final LocalDate? joinedOn;
  final LocalDate? leftOn;

  bool activeOn(LocalDate day) =>
      (joinedOn == null || joinedOn! <= day) &&
      (leftOn == null || day < leftOn!);

  SharingMemberPlan copyWith({bool? paid, LocalDate? paidUntil}) =>
      SharingMemberPlan(
        name: name,
        share: share,
        paid: paid ?? this.paid,
        paidUntil: paidUntil ?? this.paidUntil,
        joinedOn: joinedOn,
        leftOn: leftOn,
      );

  Map<String, Object?> toJson() => {
    'name': name,
    if (share != null) 'share': share!.minor,
    if (share != null) 'currency': share!.currency.code,
    'paid': paid,
    if (paidUntil != null) 'paidUntil': paidUntil.toString(),
    if (joinedOn != null) 'joinedOn': joinedOn.toString(),
    if (leftOn != null) 'leftOn': leftOn.toString(),
  };
}

/// A shared plan as stored in an item's `sharing` JSON. Older items (no
/// `role`) read as an organizer splitting equally.
@immutable
class SharingPlan {
  const SharingPlan({
    this.role = SharingRole.organizer,
    this.split = SharingSplit.equal,
    this.members = const [],
    this.myShare,
    this.basePriceMinor,
    this.followPrice = true,
    this.payee,
    this.payeeMethod,
    this.myTurnFirst = true,
  });

  factory SharingPlan.fromJson(Map<String, Object?> j, Currency currency) {
    final people = j['people'] as int? ?? 2;
    final members = [
      for (final m in (j['members'] as List? ?? const []))
        if (m is Map) SharingMemberPlan.fromJson(m.cast<String, Object?>()),
    ];
    // Legacy: a head count with unnamed seats.
    while (members.length < people - 1 && j['role'] == null) {
      members.add(SharingMemberPlan(name: '${members.length + 2}'));
    }
    return SharingPlan(
      role: SharingRole.values.asNameMap()[j['role']] ?? SharingRole.organizer,
      split: SharingSplit.values.asNameMap()[j['split']] ?? SharingSplit.equal,
      members: members,
      myShare: j['myShare'] is int && j['split'] == SharingSplit.custom.name
          ? Money(j['myShare']! as int, currency)
          : null,
      basePriceMinor: j['basePrice'] as int?,
      followPrice: j['followPrice'] != false,
      payee: j['payee'] as String?,
      payeeMethod: j['payeeMethod'] as String?,
      myTurnFirst: j['myTurnFirst'] != false,
    );
  }

  final SharingRole role;
  final SharingSplit split;
  final List<SharingMemberPlan> members;

  /// Custom split: my share per charge, in the item's currency.
  final Money? myShare;

  /// The price the custom shares were set for, so they can follow a price
  /// change proportionally when [followPrice] is on.
  final int? basePriceMinor;
  final bool followPrice;

  /// Member role: who I pay, and how (a transfer, LINE Pay …).
  final String? payee;
  final String? payeeMethod;

  /// Rotating split: I pay the first charge, then each member in order.
  final bool myTurnFirst;

  int peopleOn(LocalDate day) =>
      1 + members.where((m) => m.activeOn(day)).length;

  double _scale(Money price) =>
      followPrice && basePriceMinor != null && basePriceMinor! > 0
      ? price.minor / basePriceMinor!
      : 1;

  /// What a charge of [price] (due on [dueOn], charge number [index]) costs
  /// me. Reports and the monthly total use this, not the plan price.
  Money myCost(Money price, {required LocalDate dueOn, int index = 0}) {
    if (role == SharingRole.member) return price;
    return switch (split) {
      SharingSplit.equal => Money(
        divideRoundHalfEven(price.minor, peopleOn(dueOn)),
        price.currency,
      ),
      SharingSplit.custom => Money(
        ((myShare?.minor ?? price.minor) * _scale(price)).round(),
        price.currency,
      ),
      SharingSplit.rotating =>
        myTurn(index) ? price : Money.zero(price.currency),
    };
  }

  /// Average monthly cost to me (rotating: my turns spread over the cycle).
  Money myMonthly(Money price, Cycle cycle, {required LocalDate on}) {
    if (role == SharingRole.organizer && split == SharingSplit.rotating) {
      final turns = peopleOn(on);
      return cycle.monthlyEquivalent(
        Money(divideRoundHalfEven(price.minor, turns), price.currency),
      );
    }
    return cycle.monthlyEquivalent(myCost(price, dueOn: on));
  }

  /// Rotating split: whether charge [index] is mine to pay.
  bool myTurn(int index) {
    final turns = 1 + members.length;
    final slot = index % turns;
    return myTurnFirst ? slot == 0 : slot == turns - 1;
  }

  /// Rotating split: who pays charge [index] (null: me).
  String? payerOf(int index) {
    if (myTurn(index)) return null;
    final turns = 1 + members.length;
    final slot = index % turns;
    return members[myTurnFirst ? slot - 1 : slot].name;
  }

  /// What [member] owes per charge of [price], in their currency.
  Money memberShare(SharingMemberPlan member, Money price, LocalDate dueOn) =>
      switch (split) {
        SharingSplit.custom when member.share != null => Money(
          member.share!.currency == price.currency
              ? (member.share!.minor * _scale(price)).round()
              : member.share!.minor,
          member.share!.currency,
        ),
        SharingSplit.rotating => Money.zero(price.currency),
        _ => Money(
          divideRoundHalfEven(price.minor, peopleOn(dueOn)),
          price.currency,
        ),
      };

  /// Organizer: what [member] owes as of [today] for charges due on [due]
  /// (past and present charge dates): every charge after their paidUntil
  /// while they were in, or just this one when tracked by "paid".
  Money? owedBy(
    SharingMemberPlan member,
    Money price,
    List<LocalDate> due,
    LocalDate today,
  ) {
    if (role != SharingRole.organizer || split == SharingSplit.rotating) {
      return null;
    }
    final past = [
      for (final d in due)
        if (d <= today && member.activeOn(d)) d,
    ];
    if (past.isEmpty) return null;
    final count = member.paidUntil == null
        ? (member.paid ? 0 : 1)
        : past.where((d) => d >= member.paidUntil!).length;
    if (count == 0) return null;
    final share = memberShare(member, price, past.last);
    if (share.minor == 0) return null; // a free seat owes nothing
    return Money(share.minor * count, share.currency);
  }

  Map<String, Object?> toJson() => {
    'role': role.name,
    'split': split.name,
    'people': 1 + members.length,
    'members': [for (final m in members) m.toJson()],
    if (myShare != null) 'myShare': myShare!.minor,
    if (basePriceMinor != null) 'basePrice': basePriceMinor,
    'followPrice': followPrice,
    if (payee != null) 'payee': payee,
    if (payeeMethod != null) 'payeeMethod': payeeMethod,
    'myTurnFirst': myTurnFirst,
  };
}

LocalDate? _date(Object? v) {
  if (v is! String) return null;
  try {
    return LocalDate.parse(v);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}
