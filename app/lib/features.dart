/// Switches for the small add-ons of CLAUDE.md item 18. Each can be turned
/// off here without touching the rest of the app.
abstract final class Features {
  /// Yearly and daily cost next to monthly (item detail, reports).
  static const costConversion = true;

  /// "Rarely used" items are asked about every quarter.
  static const idleReminder = true;

  /// Price changes with the difference ("+NT$40 (+10%)") on item detail.
  static const priceComparison = true;

  /// "Go cancel" on item detail, opening the service's cancel page.
  static const goCancel = true;

  /// Search and filters (category, payment method, sharing role) on the
  /// fixed-expense list.
  static const searchFilter = true;

  /// Multi-select on the fixed-expense list: category, payment method,
  /// pause / resume.
  static const batchEdit = true;

  /// Popular services to add with one tap when there are no items yet.
  static const emptyStateOnboarding = true;

  /// Launcher shortcuts: add an item, record a payment.
  static const appShortcuts = true;
}
