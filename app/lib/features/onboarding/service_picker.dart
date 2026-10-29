import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/preset_badge.dart';
import '../items/labels.dart';
import 'batch.dart';

/// Pick the services you pay for: search on top, category filter chips,
/// tappable tiles, "N selected" counter, and a custom entry when nothing
/// matches.
class ServicePicker extends ConsumerStatefulWidget {
  const ServicePicker({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final BatchDraft draft;
  final VoidCallback onChanged;

  @override
  ConsumerState<ServicePicker> createState() => _ServicePickerState();
}

class _ServicePickerState extends ConsumerState<ServicePicker> {
  String _query = '';
  PresetCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(presetLibraryProvider).value;
    final settings = ref.watch(userSettingsProvider).value;
    if (library == null || settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final lang = contentLanguageOf(context);
    final region = settings.region;

    final base = _query.trim().isEmpty
        ? library.availableIn(region)
        : library.search.search(_query, region: region, limit: 80);
    final shown = _category == null
        ? base
        : base.where((p) => p.category == _category).toList();
    final categories = {
      for (final p in library.availableIn(region)) p.category,
    }.toList()..sort((a, b) => a.index.compareTo(b.index));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            key: const Key('picker-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.itemsSearchPresets,
              border: const OutlineInputBorder(),
            ),
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(l10n.obAllCategories),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.category(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.obSelectedCount(widget.draft.rows.length),
              key: const Key('picker-count'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 320).floor().clamp(1, 4);
              final tiles = [
                for (final p in shown)
                  _tile(context, p, lang, settings.mainCurrency),
                if (_query.trim().isNotEmpty)
                  ListTile(
                    key: const Key('picker-add-custom'),
                    leading: const Icon(Icons.add),
                    title: MarqueeText(l10n.obAddCustom(_query.trim())),
                    onTap: () {
                      widget.draft.toggle(
                        BatchRow.custom(
                          _query.trim(),
                          mainCurrency: settings.mainCurrency,
                        ),
                      );
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
              ];
              if (columns == 1) {
                return ListView(
                  key: const PageStorageKey('picker-list'),
                  children: tiles,
                );
              }
              return GridView.count(
                key: const PageStorageKey('picker-grid'),
                crossAxisCount: columns,
                childAspectRatio:
                    constraints.maxWidth /
                    columns /
                    (72 * MediaQuery.textScalerOf(context).scale(1)),
                children: tiles,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, Preset p, String lang, Currency main) {
    final selected = widget.draft.contains(p.id);
    return CheckboxListTile(
      key: ValueKey('preset-${p.id}'),
      value: selected,
      secondary: InitialBadge(name: p.name.resolve(lang), color: p.color),
      title: MarqueeText(p.name.resolve(lang)),
      onChanged: (_) {
        widget.draft.toggle(
          BatchRow.fromPreset(p, language: lang, mainCurrency: main),
        );
        widget.onChanged();
        setState(() {});
      },
    );
  }
}
