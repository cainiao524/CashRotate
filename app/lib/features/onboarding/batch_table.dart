import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';
import '../../widgets/marquee_text.dart';
import 'batch.dart';

/// The quick-setup table: one row per service with amount, charge date and
/// currency. Blank cells are fine ("to fill in"). Select rows to apply one
/// date or currency to all of them; "Next" on the keyboard moves to the
/// next row's amount.
class BatchTable extends ConsumerStatefulWidget {
  const BatchTable({super.key, required this.draft, required this.onChanged});

  final BatchDraft draft;
  final VoidCallback onChanged;

  @override
  ConsumerState<BatchTable> createState() => _BatchTableState();
}

class _BatchTableState extends ConsumerState<BatchTable> {
  final _controllers = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _changed() {
    widget.onChanged();
    setState(() {});
  }

  Future<LocalDate?> _pickDate(LocalDate? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial == null
          ? now
          : DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    return picked == null ? null : LocalDate.fromDateTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = widget.draft;
    final region = ref.watch(userSettingsProvider).value?.region ?? 'US';
    final anySelected = draft.selected.isNotEmpty;
    final allSelected =
        draft.rows.isNotEmpty && draft.rows.every((r) => r.selected);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.obBatchHint,
            style: TextStyle(color: Palette.of(context).secondaryText),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    key: const Key('batch-select-all'),
                    value: allSelected,
                    onChanged: (v) {
                      draft.selectAll(v ?? false);
                      _changed();
                    },
                  ),
                  Text(l10n.obSelectAll),
                ],
              ),
              OutlinedButton.icon(
                key: const Key('batch-apply-date'),
                icon: const Icon(Icons.event_repeat_outlined),
                label: Text(l10n.obApplyDate),
                onPressed: !anySelected
                    ? null
                    : () async {
                        final date = await _pickDate(null);
                        if (date == null) return;
                        draft.applyDate(date);
                        _changed();
                      },
              ),
              OutlinedButton.icon(
                key: const Key('batch-apply-currency'),
                icon: const Icon(Icons.currency_exchange),
                label: Text(l10n.obApplyCurrency),
                onPressed: !anySelected
                    ? null
                    : () async {
                        final c = await showCurrencyPicker(
                          context,
                          region: region,
                        );
                        if (c == null) return;
                        draft.applyCurrency(c);
                        _changed();
                      },
              ),
            ],
          ),
        ),
        Expanded(
          child: FocusTraversalGroup(
            child: ListView.separated(
              key: const PageStorageKey('batch-table'),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
              itemCount: draft.rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) =>
                  _row(context, draft.rows[i], i, region),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, BatchRow row, int index, String region) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final locale = intlLocaleOf(context);
    final controller = _controllers.putIfAbsent(
      row.key,
      () => TextEditingController(text: row.amountText),
    );
    final focus = _focus.putIfAbsent(row.key, FocusNode.new);
    final isLast = index == widget.draft.rows.length - 1;
    final invalid = row.amountText.trim().isNotEmpty && row.amount == null;
    final date = row.date;

    return Padding(
      key: ValueKey('batch-row-${row.key}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: row.selected,
            onChanged: (v) {
              row.selected = v ?? false;
              _changed();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarqueeText(
                  row.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                TextField(
                  key: ValueKey('batch-amount-${row.key}'),
                  controller: controller,
                  focusNode: focus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: isLast
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.fieldAmount,
                    hintText: l10n.obPending,
                    suffixText: row.currency.code,
                    errorText: invalid ? l10n.errorAmount : null,
                    isDense: true,
                  ),
                  onChanged: (v) {
                    row.amountText = v;
                    _changed();
                  },
                  onSubmitted: (_) {
                    if (!isLast) {
                      _focus[widget.draft.rows[index + 1].key]?.requestFocus();
                    }
                  },
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      key: ValueKey('batch-date-${row.key}'),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        date == null
                            ? '${l10n.obColumnDate}: ${l10n.obPending}'
                            : DateFormat.yMMMd(locale).format(
                                DateTime(date.year, date.month, date.day),
                              ),
                        style: date == null
                            ? TextStyle(color: palette.warning)
                            : null,
                      ),
                      onPressed: () async {
                        final picked = await _pickDate(row.date);
                        if (picked == null) return;
                        row.date = picked;
                        _changed();
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.currency_exchange, size: 18),
                      label: Text(row.currency.code),
                      onPressed: () async {
                        final c = await showCurrencyPicker(
                          context,
                          region: region,
                          selected: row.currency,
                        );
                        if (c == null) return;
                        row.currency = c;
                        _changed();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
