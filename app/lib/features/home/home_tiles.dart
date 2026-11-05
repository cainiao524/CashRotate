import 'package:cashrotate_core/cashrotate_core.dart';

import '../../data/items/item_repository.dart';

/// Order of the home tile grid.
enum TileSort { dueDate, amount, name }

/// What a home tile says about one fixed expense.
class HomeTile {
  HomeTile._({
    required this.view,
    this.lastPaid,
    required this.daysLeft,
    required this.periodDays,
    required this.amount,
    required this.converted,
    required this.newPrice,
    required this.monthlyMinor,
  });

  factory HomeTile.of(
    ItemView view, {
    required LocalDate today,
    required FxConverter? fx,
    required Currency main,
    Money? irregularAverage,
    LocalDate? lastPaid,
  }) {
    final next = view.nextDue;
    final schedule = view.schedule;
    final amount = view.irregular
        ? irregularAverage ?? Money.zero(schedule.prices.stablePrice.currency)
        : next == null
        ? schedule.prices.stablePrice
        : Money(next.expectedMinor, next.currency);
    Money? inMain(Money m) =>
        m.currency == main ? null : fx?.convert(m, main)?.amount;

    var periodDays = 30;
    var newPrice = false;
    if (next != null) {
      final start = schedule.cycle.dateAt(schedule.anchor, next.cycleIndex - 1);
      periodDays = start.daysUntil(next.dueOn).clamp(1, 1 << 20);
      newPrice =
          next.cycleIndex > 0 &&
          schedule.prices.changeAfter(
                schedule.cycle,
                schedule.anchor,
                next.cycleIndex - 1,
              ) !=
              null;
    }
    final monthly = view.irregular ? amount : view.stableMonthly;
    return HomeTile._(
      lastPaid: lastPaid,
      view: view,
      daysLeft: next == null ? null : today.daysUntil(next.dueOn),
      periodDays: periodDays,
      amount: amount,
      converted: inMain(amount),
      newPrice: newPrice,
      monthlyMinor: monthly.currency == main
          ? monthly.minor
          : inMain(monthly)?.minor ?? 0,
    );
  }

  final ItemView view;

  /// For an irregular bill: the latest payment (its [amount] is the monthly
  /// average of its payments).
  final LocalDate? lastPaid;

  bool get irregular => view.irregular;

  /// Days to the next pending charge, negative once overdue; null without one.
  final int? daysLeft;

  /// Length of the billing period that ends with the next charge.
  final int periodDays;

  /// The next charge (the long-term price without one), as billed.
  final Money amount;

  /// [amount] in the main currency, for a foreign price with a known rate.
  final Money? converted;

  /// The next charge is the first one at a new price (intro price ended,
  /// price rise).
  final bool newPrice;

  /// Monthly cost in the main currency, for sorting by amount (0 unknown).
  final int monthlyMinor;

  String get id => view.row.id;
  ItemStatus get status => view.row.status;
  bool get needsDetails => view.row.needsDetails;
  LocalDate? get dueOn => view.nextDue?.dueOn;

  bool get overdue =>
      status == ItemStatus.active && daysLeft != null && daysLeft! < 0;

  /// Due within two days: drawn inverted so it stands out.
  bool get dueSoon =>
      status == ItemStatus.active &&
      !needsDetails &&
      daysLeft != null &&
      daysLeft! >= 0 &&
      daysLeft! <= 2;

  /// Share of the current period already gone, for the countdown ring.
  double get elapsed {
    if (status != ItemStatus.active || daysLeft == null) return 0;
    if (daysLeft! < 0) return 1;
    return (1 - daysLeft! / periodDays).clamp(0.05, 1.0);
  }

  /// Extra lap drawn past a full ring once overdue, up to half a turn.
  double get overdueLap =>
      overdue ? (-daysLeft! / periodDays).clamp(0.05, 0.5) : 0;
}

/// The tiles the home grid shows, in order. Leaves out cancelled items no
/// longer paid for; paused and cancelled ones go last when sorting by date.
List<HomeTile> homeTiles(
  List<ItemView> items, {
  required LocalDate today,
  required FxConverter? fx,
  required Currency main,
  TileSort sort = TileSort.dueDate,
  ItemType? type,
  String query = '',
  Map<String, Money?> irregularAverages = const {},
  Map<String, LocalDate> lastPaid = const {},
}) {
  final q = query.trim().toLowerCase();
  final tiles = [
    for (final v in items)
      if (v.schedule.isUsableOn(today) &&
          !v.schedule.paidOff &&
          (type == null || v.row.type == type) &&
          (q.isEmpty || v.row.name.toLowerCase().contains(q)))
        HomeTile.of(
          v,
          today: today,
          fx: fx,
          main: main,
          irregularAverage: irregularAverages[v.row.id],
          lastPaid: lastPaid[v.row.id],
        ),
  ];
  int byName(HomeTile a, HomeTile b) =>
      a.view.row.name.toLowerCase().compareTo(b.view.row.name.toLowerCase());
  int rank(HomeTile t) => switch (t.status) {
    ItemStatus.active => t.dueOn == null ? 1 : 0,
    ItemStatus.paused => 2,
    ItemStatus.cancelled => 3,
  };
  return tiles..sort(
    (a, b) => switch (sort) {
      TileSort.dueDate => switch (rank(a).compareTo(rank(b))) {
        0 when a.dueOn != null && b.dueOn != null => switch (a.dueOn!.compareTo(
          b.dueOn!,
        )) {
          0 => byName(a, b),
          final c => c,
        },
        0 => byName(a, b),
        final c => c,
      },
      TileSort.amount => switch (b.monthlyMinor.compareTo(a.monthlyMinor)) {
        0 => byName(a, b),
        final c => c,
      },
      TileSort.name => byName(a, b),
    },
  );
}
