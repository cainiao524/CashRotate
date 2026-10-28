import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../widgets/state_views.dart';

/// Placeholder until M4 (basic charts).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: EmptyState(
        icon: Icons.insert_chart_outlined,
        title: l10n.emptyReports,
      ),
    );
  }
}
