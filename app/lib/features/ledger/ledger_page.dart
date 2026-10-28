import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../widgets/state_views.dart';

/// Placeholder until M4 (accounts and transactions).
class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ledgerTitle)),
      body: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.emptyLedger,
      ),
    );
  }
}
