import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/items/item_repository.dart';
import '../../data/presets.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';
import '../../widgets/preset_badge.dart';
import '../../widgets/state_views.dart';
import 'fx_line.dart';
import 'item_draft.dart';
import 'labels.dart';

/// Creates or edits a fixed expense. Exactly one of [itemId] (edit),
/// [presetId] (new from a preset) or neither (custom) is used.
class ItemEditorPage extends ConsumerStatefulWidget {
  const ItemEditorPage({super.key, this.itemId, this.presetId});

  final String? itemId;
  final String? presetId;

  @override
  ConsumerState<ItemEditorPage> createState() => _ItemEditorPageState();
}

class _ItemEditorPageState extends ConsumerState<ItemEditorPage> {
  ItemDraft? _draft;
  Object? _loadError;
  bool _showErrors = false;
  bool _saving = false;
  final _controllers = <String, TextEditingController>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draft == null && _loadError == null) _load();
  }

  Future<void> _load() async {
    try {
      final library = await ref.read(presetLibraryProvider.future);
      final settings = await ref.read(userSettingsProvider.future);
      if (!mounted) return;
      final lang = contentLanguageOf(context);
      ItemDraft draft;
      if (widget.itemId case final id?) {
        final view = await ref.read(itemRepositoryProvider).view(id);
        draft = ItemDraft.fromItem(
          view,
          locale: 'en',
          preset: library.byId[view.row.presetId],
        );
      } else if (library.byId[widget.presetId] case final preset?) {
        draft = ItemDraft.fromPreset(
          preset,
          language: lang,
          mainCurrency: settings.mainCurrency,
        );
      } else {
        draft = ItemDraft(
          type: ItemType.subscription,
          currency: settings.mainCurrency,
          cycle: Cycle.monthly,
        );
      }
      if (mounted) setState(() => _draft = draft);
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, String initial) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: initial));

  Future<void> _save() async {
    final draft = _draft!;
    if (!draft.isValid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(itemRepositoryProvider);
    final item = draft.toNewItem();
    final id = widget.itemId;
    if (id == null) {
      final created = await repo.create(item);
      if (mounted) Navigator.of(context).pop(created);
    } else {
      await repo.update(id, item);
      if (mounted) Navigator.of(context).pop(id);
    }
  }

  String? _error(DraftField field) {
    if (!_showErrors) return null;
    final l10n = AppLocalizations.of(context);
    return switch (_draft!.validate()[field]) {
      null => null,
      DraftError.required => l10n.errorRequired,
      DraftError.amount => l10n.errorAmount,
      DraftError.renewalRequired => l10n.errorRenewalRequired,
      DraftError.periods => l10n.errorPeriods,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemId == null ? l10n.editorNewTitle : l10n.editorEditTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('editor-save'),
              onPressed: draft == null || _saving ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ),
        ],
      ),
      body: switch ((draft, _loadError)) {
        (_, final Object error) => ErrorState(message: '$error'),
        (null, _) => const LoadingState(),
        (final ItemDraft d, _) => _form(context, d),
      },
    );
  }

  Widget _form(BuildContext context, ItemDraft d) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final library = ref.watch(presetLibraryProvider).value;
    final preset = library?.byId[d.presetId];
    void update(VoidCallback change) => setState(change);

    return ListView(
      key: const PageStorageKey('item-editor'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            InitialBadge(
              name: d.name.isEmpty ? '?' : d.name,
              color: preset?.color ?? '#6B7280',
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('field-name'),
                controller: _controller('name', d.name),
                decoration: InputDecoration(
                  labelText: l10n.fieldName,
                  errorText: _error(DraftField.name),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (v) => update(() => d.name = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Label(l10n.fieldType),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ItemType.values)
              ChoiceChip(
                label: Text(l10n.itemType(t)),
                selected: d.type == t,
                onSelected: (_) => update(() => d.type = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (d.intro) ...[
          _amountRow(
            context,
            d,
            key: 'introAmount',
            label: l10n.fieldIntroAmount,
            text: d.introAmountText,
            error: _error(DraftField.introAmount),
            onChanged: (v) => d.introAmountText = v,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('field-introPeriods'),
            controller: _controller('introPeriods', d.introPeriodsText),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.fieldIntroPeriods,
              errorText: _error(DraftField.introPeriods),
            ),
            onChanged: (v) => update(() => d.introPeriodsText = v),
          ),
          const SizedBox(height: 12),
        ],
        _amountRow(
          context,
          d,
          key: 'amount',
          label: d.intro ? l10n.fieldRenewal : l10n.fieldAmount,
          text: d.amountText,
          error: _error(DraftField.amount),
          onChanged: (v) => d.amountText = v,
          withCurrency: true,
        ),
        FxLine(amount: d.amount, currency: d.currency),
        SwitchListTile(
          key: const Key('field-intro'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fieldIntro),
          value: d.intro,
          onChanged: (v) => update(() => d.intro = v),
        ),
        const SizedBox(height: 8),
        _Label(l10n.fieldCycle),
        _CyclePicker(
          cycle: d.cycle,
          onChanged: (c) => update(() => d.cycle = c),
        ),
        const SizedBox(height: 8),
        _DateTile(
          key: const Key('field-nextCharge'),
          label: l10n.fieldNextCharge,
          date: d.nextCharge,
          error: _error(DraftField.nextCharge),
          onChanged: (date) => update(() => d.nextCharge = date),
        ),
        const SizedBox(height: 8),
        _Label(l10n.fieldRemindDays),
        // Several at once: e.g. a week before and on the day.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in remindDayChoices)
              FilterChip(
                key: ValueKey('remind-$days'),
                label: Text(l10n.remindDaysBefore(days)),
                selected: d.remindDays.contains(days),
                onSelected: (on) => update(() {
                  d.remindDays = on
                      ? ({...d.remindDays, days}.toList()..sort())
                      : (d.remindDays.where((x) => x != days).toList());
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final group in d.groups) ..._group(context, d, group),
        const SizedBox(height: 8),
        TextField(
          controller: _controller('note', d.note),
          decoration: InputDecoration(labelText: l10n.fieldNote),
          maxLines: null,
          onChanged: (v) => d.note = v,
        ),
        if (preset != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.category(preset.category),
            style: TextStyle(color: palette.secondaryText),
          ),
        ],
      ],
    );
  }

  Widget _amountRow(
    BuildContext context,
    ItemDraft d, {
    required String key,
    required String label,
    required String text,
    required String? error,
    required void Function(String) onChanged,
    bool withCurrency = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    final field = TextField(
      key: Key('field-$key'),
      controller: _controller(key, text),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        errorMaxLines: 3,
      ),
      onChanged: (v) => setState(() => onChanged(v)),
    );
    if (!withCurrency) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('field-currency'),
          icon: const Icon(Icons.currency_exchange),
          label: Text('${l10n.fieldCurrency}: ${d.currency.code}'),
          onPressed: () async {
            final picked = await showCurrencyPicker(
              context,
              region: settings?.region ?? 'US',
              selected: d.currency,
            );
            if (picked != null) setState(() => d.currency = picked);
          },
        ),
      ],
    );
  }

  List<Widget> _group(BuildContext context, ItemDraft d, FieldGroup group) {
    final l10n = AppLocalizations.of(context);
    Widget text(String key, String label, {TextInputType? keyboard}) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        key: Key('field-$key'),
        controller: _controller('f.$key', '${d.fields[key] ?? ''}'),
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => d.fields[key] = keyboard == TextInputType.number
            ? int.tryParse(v)
            : v,
      ),
    );
    Widget toggle(String key, String label) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: d.fields[key] == true,
      onChanged: (v) => setState(() => d.fields[key] = v),
    );
    Widget date(String key, String label) => _DateTile(
      label: label,
      date: d.fields[key] is String
          ? LocalDate.parse(d.fields[key]! as String)
          : null,
      onChanged: (v) => setState(() => d.fields[key] = v?.toString()),
    );

    return switch (group) {
      FieldGroup.subscription => [
        if (d.plans.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Label(l10n.fieldPlan),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in d.plans)
                ChoiceChip(
                  label: Text(p.name.resolve(contentLanguageOf(context))),
                  selected: d.fields['plan'] == p.id,
                  onSelected: (s) =>
                      setState(() => d.fields['plan'] = s ? p.id : null),
                ),
            ],
          ),
        ],
        toggle('autoRenew', l10n.fieldAutoRenew),
        text('cancelUrl', l10n.fieldCancelUrl, keyboard: TextInputType.url),
      ],
      FieldGroup.bill => [toggle('variableAmount', l10n.fieldVariableAmount)],
      FieldGroup.trial => [date('trialEndsOn', l10n.fieldTrialEnds)],
      FieldGroup.contract => [date('contractEndsOn', l10n.fieldContractEnds)],
      FieldGroup.repayment => [
        text(
          'totalPeriods',
          l10n.fieldTotalPeriods,
          keyboard: TextInputType.number,
        ),
        text(
          'remainingPeriods',
          l10n.fieldRemainingPeriods,
          keyboard: TextInputType.number,
        ),
        text(
          'statementDay',
          l10n.fieldStatementDay,
          keyboard: TextInputType.number,
        ),
        text('remainingPrincipal', l10n.fieldRemainingPrincipal),
      ],
      FieldGroup.policy => [
        text('policyNumber', l10n.fieldPolicyNumber),
        date('expiresOn', l10n.fieldExpiresOn),
      ],
      FieldGroup.transfer => [text('transferTo', l10n.fieldTransferTo)],
      FieldGroup.domain => [
        text('domain', l10n.fieldDomain, keyboard: TextInputType.url),
        text('registrar', l10n.fieldRegistrar),
        text(
          'paidThroughYear',
          l10n.fieldPaidThroughYear,
          keyboard: TextInputType.number,
        ),
        toggle('autoRenew', l10n.fieldAutoRenew),
        text('graceDays', l10n.fieldGraceDays, keyboard: TextInputType.number),
      ],
      FieldGroup.vps => [
        text('provider', l10n.fieldProvider),
        text('hostNote', l10n.fieldHostNote),
        text('specs', l10n.fieldSpecs),
        text('location', l10n.fieldLocation),
        toggle('hourly', l10n.fieldHourly),
        if (d.fields['hourly'] == true)
          text('hourlyRate', l10n.fieldHourlyRate),
      ],
      FieldGroup.gameServer => [
        text('game', l10n.fieldGame),
        _RunsOnPicker(
          value: d.fields['runsOnItemId'] as String?,
          excludeId: widget.itemId,
          onChanged: (v) => setState(() => d.fields['runsOnItemId'] = v),
        ),
      ],
      FieldGroup.sharing => _sharing(context, d),
    };
  }

  List<Widget> _sharing(BuildContext context, ItemDraft d) {
    final l10n = AppLocalizations.of(context);
    final share = d.myShare;
    return [
      SwitchListTile(
        key: const Key('field-sharing'),
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.sharingTitle),
        value: d.sharing,
        onChanged: (v) => setState(() {
          d.sharing = v;
          if (v && d.members.isEmpty) {
            d.members = [
              for (var i = 2; i <= d.sharingPeople; i++)
                SharingMember(name: l10n.sharingMember(i)),
            ];
          }
        }),
      ),
      if (d.sharing) ...[
        TextField(
          controller: _controller('sharingTotal', d.sharingTotalText),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.sharingTotal,
            suffixText: d.currency.code,
          ),
          onChanged: (v) => setState(() => d.sharingTotalText = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(l10n.sharingPeople)),
            IconButton(
              tooltip: '-',
              onPressed: d.sharingPeople <= 2
                  ? null
                  : () => setState(() {
                      d.sharingPeople--;
                      if (d.members.length > d.sharingPeople - 1) {
                        d.members.removeLast();
                      }
                    }),
              icon: const Icon(Icons.remove),
            ),
            Text(
              '${d.sharingPeople}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: '+',
              onPressed: () => setState(() {
                d.sharingPeople++;
                d.members.add(
                  SharingMember(name: l10n.sharingMember(d.sharingPeople)),
                );
              }),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (share != null)
          Text(
            '${l10n.sharingMyShare}: ${formatMoney(share, locale: intlLocaleOf(context))}',
          ),
        for (final (i, m) in d.members.indexed)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: m.paid,
            title: TextField(
              controller: _controller('member$i', m.name),
              decoration: InputDecoration(labelText: l10n.sharingMember(i + 2)),
              onChanged: (v) => m.name = v,
            ),
            subtitle: Text(l10n.sharingPaid),
            onChanged: (v) => setState(() => m.paid = v ?? false),
          ),
      ],
    ];
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.error,
  });

  final String label;
  final LocalDate? date;
  final String? error;
  final ValueChanged<LocalDate?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final locale = intlLocaleOf(context);
    final d = date;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text(
        error ??
            (d == null
                ? '—'
                : DateFormat.yMMMEd(locale)
                      .format(DateTime(d.year, d.month, d.day))),
        style: error == null ? null : TextStyle(color: palette.error),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: d == null ? now : DateTime(d.year, d.month, d.day),
          firstDate: DateTime(now.year - 10),
          lastDate: DateTime(now.year + 30),
        );
        if (picked != null) onChanged(LocalDate.fromDateTime(picked));
      },
    );
  }
}

class _CyclePicker extends StatelessWidget {
  const _CyclePicker({required this.cycle, required this.onChanged});

  final Cycle cycle;
  final ValueChanged<Cycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preset = PresetCycle.values
        .where((p) => p.cycle == cycle)
        .firstOrNull;
    final custom = preset == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in PresetCycle.values)
              ChoiceChip(
                label: Text(l10n.presetCycle(p)),
                selected: p == preset,
                onSelected: (_) => onChanged(p.cycle),
              ),
            ChoiceChip(
              key: const Key('cycle-custom'),
              label: Text(l10n.cycleCustom),
              selected: custom,
              onSelected: (_) => onChanged(Cycle(CycleUnit.day, 10)),
            ),
          ],
        ),
        if (custom)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.fieldEvery),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: const Key('cycle-every'),
                    initialValue: '${cycle.every}',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1) onChanged(Cycle(cycle.unit, n));
                    },
                  ),
                ),
                DropdownButton<CycleUnit>(
                  value: cycle.unit,
                  items: [
                    for (final u in CycleUnit.values)
                      DropdownMenuItem(
                        value: u,
                        child: Text(l10n.cycleUnit(u)),
                      ),
                  ],
                  onChanged: (u) => onChanged(Cycle(u!, cycle.every)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Game servers can run on one of the user's own servers; its cost is then
/// already counted with that server.
class _RunsOnPicker extends ConsumerWidget {
  const _RunsOnPicker({
    required this.value,
    required this.onChanged,
    this.excludeId,
  });

  final String? value;
  final String? excludeId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servers = ref.watch(_serversProvider).value ?? const <ItemView>[];
    final options = servers.where((s) => s.row.id != excludeId).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: options.any((s) => s.row.id == value) ? value : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldRunsOn),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.fieldRunsOnProvider),
              ),
              for (final s in options)
                DropdownMenuItem(value: s.row.id, child: Text(s.row.name)),
            ],
            onChanged: onChanged,
          ),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.runsOnServerNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Items that look like servers: VPS fields or the hosting category.
final _serversProvider = StreamProvider<List<ItemView>>(
  (ref) => ref
      .watch(itemRepositoryProvider)
      .watchAll()
      .map(
        (all) => all
            .where(
              (v) =>
                  v.row.categoryId == PresetCategory.hosting.name ||
                  v.typeFields.containsKey('hostNote'),
            )
            .toList(),
      ),
);
