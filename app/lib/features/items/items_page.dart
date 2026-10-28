import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../layout/list_detail_layout.dart';
import '../../layout/window_class.dart';
import '../../widgets/state_views.dart';

/// Fixed expenses: list alone on compact windows, list + detail otherwise.
class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const list = _ItemsList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemsTitle)),
      body: WindowClass.of(context).isTwoPane
          ? ListDetailLayout(
              list: list,
              detail: switch (selectedId) {
                final id? => _ItemDetail(id: id),
                null => EmptyState(
                  icon: Icons.touch_app_outlined,
                  title: l10n.detailPlaceholder,
                ),
              },
            )
          : list,
    );
  }
}

/// Full-page detail used on compact windows.
class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: _ItemDetail(id: id),
  );
}

class _ItemsList extends StatelessWidget {
  const _ItemsList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.event_repeat_outlined,
      title: l10n.emptyItems,
      body: l10n.emptyItemsHint,
    );
  }
}

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.construction_outlined,
    title: AppLocalizations.of(context).comingSoon,
  );
}
