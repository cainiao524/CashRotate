import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../widgets/state_views.dart';

/// Placeholder until settings arrive with their features (M2 onward).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: EmptyState(icon: Icons.settings_outlined, title: l10n.comingSoon),
    );
  }
}
