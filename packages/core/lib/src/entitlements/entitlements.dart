import 'package:meta/meta.dart';

/// Features that need Pro. Checked in one place so the free/Pro split is
/// easy to see and change; Google Play Billing feeds this in M7.
enum ProFeature {
  webdavSync,

  /// Daily automatic rates for every currency. Free users get
  /// [Entitlements.freeAutoRateSlots] currencies of their choice.
  autoRatesAllCurrencies,
  homeWidgets,
  advancedReports,
  customThemes,
  costSharing,
  presetUpdates,
}

@immutable
final class Entitlements {
  const Entitlements({required this.isPro});

  static const free = Entitlements(isPro: false);
  static const pro = Entitlements(isPro: true);

  /// Currencies a free user can have updated automatically every day.
  static const freeAutoRateSlots = 4;

  final bool isPro;

  bool has(ProFeature feature) => isPro;
}
