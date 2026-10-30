import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preview builds unlock every Pro feature so everything can be tried
/// before release. Set to false when Google Play Billing arrives (M7); the
/// free/Pro rules (e.g. 4 automatic rate currencies for free users) then
/// apply without further changes.
const unlockProInPreview = true;

final entitlementsProvider = Provider<Entitlements>(
  (ref) => unlockProInPreview ? Entitlements.pro : Entitlements.free,
);
