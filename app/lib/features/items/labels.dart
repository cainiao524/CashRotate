import 'package:cashrotate_core/cashrotate_core.dart';

import '../../l10n/gen/app_localizations.dart';

/// Display names for domain enums. Kept in one place so every screen says
/// the same thing.
extension DomainLabels on AppLocalizations {
  String itemType(ItemType t) => switch (t) {
    ItemType.subscription => itemTypeSubscription,
    ItemType.bill => itemTypeBill,
    ItemType.repayment => itemTypeRepayment,
    ItemType.insuranceAndFees => itemTypeInsuranceAndFees,
    ItemType.transferOut => itemTypeTransferOut,
  };

  String presetCycle(PresetCycle c) => switch (c) {
    PresetCycle.daily => cycleDaily,
    PresetCycle.weekly => cycleWeekly,
    PresetCycle.monthly => cycleMonthly,
    PresetCycle.bimonthly => cycleBimonthly,
    PresetCycle.quarterly => cycleQuarterly,
    PresetCycle.halfYearly => cycleHalfYearly,
    PresetCycle.yearly => cycleYearly,
  };

  String cycle(Cycle c) {
    for (final p in PresetCycle.values) {
      if (p.cycle == c) return presetCycle(p);
    }
    return switch (c.unit) {
      CycleUnit.day => cycleEveryDays(c.every),
      CycleUnit.week => cycleEveryWeeks(c.every),
      CycleUnit.month => cycleEveryMonths(c.every),
      CycleUnit.year => cycleEveryYears(c.every),
    };
  }

  String cycleUnit(CycleUnit u) => switch (u) {
    CycleUnit.day => unitDays,
    CycleUnit.week => unitWeeks,
    CycleUnit.month => unitMonths,
    CycleUnit.year => unitYears,
  };

  String category(PresetCategory c) => switch (c) {
    PresetCategory.streaming => categoryStreaming,
    PresetCategory.music => categoryMusic,
    PresetCategory.cloud => categoryCloud,
    PresetCategory.software => categorySoftware,
    PresetCategory.ai => categoryAi,
    PresetCategory.gaming => categoryGaming,
    PresetCategory.reading => categoryReading,
    PresetCategory.creator => categoryCreator,
    PresetCategory.vpn => categoryVpn,
    PresetCategory.education => categoryEducation,
    PresetCategory.fitness => categoryFitness,
    PresetCategory.shopping => categoryShopping,
    PresetCategory.communication => categoryCommunication,
    PresetCategory.domain => categoryDomain,
    PresetCategory.hosting => categoryHosting,
    PresetCategory.devtools => categoryDevtools,
    PresetCategory.gameServer => categoryGameServer,
    PresetCategory.telecom => categoryTelecom,
    PresetCategory.broadband => categoryBroadband,
    PresetCategory.utilities => categoryUtilities,
    PresetCategory.housing => categoryHousing,
    PresetCategory.insurance => categoryInsurance,
    PresetCategory.loan => categoryLoan,
    PresetCategory.tax => categoryTax,
    PresetCategory.transport => categoryTransport,
    PresetCategory.family => categoryFamily,
    PresetCategory.investing => categoryInvesting,
    PresetCategory.other => categoryOther,
  };
}
