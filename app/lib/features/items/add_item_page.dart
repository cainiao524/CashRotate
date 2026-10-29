import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/preset_badge.dart';
import '../onboarding/batch.dart';
import '../onboarding/batch_table.dart';
import '../onboarding/service_picker.dart';
import 'item_editor_page.dart';
import 'labels.dart';

/// Opens the add flow above the shell; shows the new item when done.
Future<void> openAddItem(BuildContext context) async {
  final router = GoRouter.of(context);
  final id = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<String>(MaterialPageRoute(builder: (_) => const AddItemPage()));
  if (id != null) router.go(Routes.item(id));
}

/// Search the preset library, start from a template, or create a custom
/// item. "Add several" goes to the quick-setup table.
class AddItemPage extends ConsumerStatefulWidget {
  const AddItemPage({super.key});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  String _query = '';

  Future<void> _openEditor({String? presetId}) async {
    final navigator = Navigator.of(context);
    final id = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => ItemEditorPage(presetId: presetId)),
    );
    if (id != null && mounted) navigator.pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(presetLibraryProvider).value;
    final region = ref.watch(userSettingsProvider).value?.region ?? 'US';
    final lang = contentLanguageOf(context);
    final results = library == null
        ? const <Preset>[]
        : (_query.trim().isEmpty
              ? library.availableIn(region)
              : library.search.search(_query, region: region));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.itemsAddTitle),
        actions: [
          TextButton(
            key: const Key('add-several'),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<String>(builder: (_) => const BatchAddPage()),
            ),
            child: Text(l10n.itemsAddSeveral),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('add-search'),
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.itemsSearchPresets,
                border: const OutlineInputBorder(),
              ),
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          ListTile(
            key: const Key('add-custom'),
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.itemsCustom),
            onTap: _openEditor,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final p = results[i];
                return ListTile(
                  key: ValueKey('add-preset-${p.id}'),
                  leading: InitialBadge(
                    name: p.name.resolve(lang),
                    color: p.color,
                  ),
                  title: MarqueeText(p.name.resolve(lang)),
                  subtitle: Text(l10n.category(p.category)),
                  onTap: () => _openEditor(presetId: p.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick several services, then fill amounts and dates in one table.
class BatchAddPage extends ConsumerStatefulWidget {
  const BatchAddPage({super.key});

  @override
  ConsumerState<BatchAddPage> createState() => _BatchAddPageState();
}

class _BatchAddPageState extends ConsumerState<BatchAddPage> {
  final _draft = BatchDraft();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final picking = _draft.step == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(picking ? l10n.obPickTitle : l10n.obBatchTitle),
      ),
      body: picking
          ? ServicePicker(draft: _draft, onChanged: () => setState(() {}))
          : BatchTable(draft: _draft, onChanged: () => setState(() {})),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const Key('batch-next'),
            onPressed: _draft.rows.isEmpty || _saving
                ? null
                : () async {
                    if (picking) {
                      setState(() => _draft.step = 1);
                      return;
                    }
                    setState(() => _saving = true);
                    final navigator = Navigator.of(context);
                    final today = todayFrom(ref.read(clockProvider));
                    await ref.read(itemRepositoryProvider).createAll([
                      for (final r in _draft.rows) r.toNewItem(today: today),
                    ]);
                    navigator.pop();
                  },
            child: Text(picking ? l10n.actionNext : l10n.actionDone),
          ),
        ),
      ),
    );
  }
}
