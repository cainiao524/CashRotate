import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/items/item_repository.dart';
import '../../data/payments/payment_repository.dart';

/// Sharing role as a filter: not shared, I organize, I'm a member.
enum RoleFilter { none, organizer, member }

/// Search and filters of the fixed-expense list (CLAUDE.md item 18). An
/// empty set means "any".
@immutable
class ItemsFilter {
  const ItemsFilter({
    this.query,
    this.categories = const {},
    this.accounts = const {},
    this.roles = const {},
  });

  /// Null while the search field is closed.
  final String? query;
  final Set<String> categories;

  /// Payment method ids; [noAccount] for items without one.
  final Set<String> accounts;
  final Set<RoleFilter> roles;

  static const noAccount = '';

  /// Filter groups in use (the search not counted).
  int get count =>
      (categories.isEmpty ? 0 : 1) +
      (accounts.isEmpty ? 0 : 1) +
      (roles.isEmpty ? 0 : 1);

  bool get isActive => count > 0 || (query ?? '').trim().isNotEmpty;

  static String categoryOf(ItemView v) =>
      v.row.categoryId ?? PresetCategory.other.name;

  static String accountOf(ItemView v) => switch (v.row.accountId) {
    null || PaymentMethods.unassignedId => noAccount,
    final id => id,
  };

  static RoleFilter roleOf(ItemView v) => switch (v.sharingPlan?.role) {
    null => RoleFilter.none,
    SharingRole.organizer => RoleFilter.organizer,
    SharingRole.member => RoleFilter.member,
  };

  bool matches(ItemView v) {
    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty &&
        !v.row.name.toLowerCase().contains(q) &&
        !v.row.note.toLowerCase().contains(q)) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(categoryOf(v))) {
      return false;
    }
    if (accounts.isNotEmpty && !accounts.contains(accountOf(v))) return false;
    if (roles.isNotEmpty && !roles.contains(roleOf(v))) return false;
    return true;
  }

  ItemsFilter copyWith({
    String? Function()? query,
    Set<String>? categories,
    Set<String>? accounts,
    Set<RoleFilter>? roles,
  }) => ItemsFilter(
    query: query == null ? this.query : query(),
    categories: categories ?? this.categories,
    accounts: accounts ?? this.accounts,
    roles: roles ?? this.roles,
  );

  /// Clears the filters, keeping the search.
  ItemsFilter cleared() => ItemsFilter(query: query);
}

class ItemsFilterNotifier extends Notifier<ItemsFilter> {
  @override
  ItemsFilter build() => const ItemsFilter();

  void set(ItemsFilter filter) => state = filter;
}

/// Kept in a provider so it survives rotating and folding.
final itemsFilterProvider = NotifierProvider<ItemsFilterNotifier, ItemsFilter>(
  ItemsFilterNotifier.new,
);

/// Ids picked for a batch edit; null when not selecting.
class ItemsSelectionNotifier extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  void start(String id) => state = {id};

  void toggle(String id) {
    final current = {...?state};
    if (!current.remove(id)) current.add(id);
    state = current.isEmpty ? null : current;
  }

  void end() => state = null;
}

final itemsSelectionProvider =
    NotifierProvider<ItemsSelectionNotifier, Set<String>?>(
      ItemsSelectionNotifier.new,
    );
