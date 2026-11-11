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
        // An irregular bill has no cycle, next charge or reminders.
        if (!d.irregular) ...[
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
        ],
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
      FieldGroup.bill => [
        toggle('irregular', l10n.fieldIrregular),
        if (d.fields['irregular'] != true)
          toggle('variableAmount', l10n.fieldVariableAmount),
      ],
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
        if (d.fields['hourly'] == true) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              key: const Key('field-hourlyRate'),
              controller: _controller(
                'f.hourlyRate',
                '${d.fields['hourlyRate'] ?? ''}',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.fieldHourlyRate,
                suffixText: d.currency.code,
              ),
              onChanged: (v) => setState(() => d.fields['hourlyRate'] = v),
            ),
          ),
          if (hourlyEstimate(d) case (:final amount, :final hours))
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  l10n.hourlyEstimate(
                    formatMoney(amount, locale: intlLocaleOf(context)),
                    hours,
                  ),
                  key: const Key('hourly-estimate'),
                ),
                TextButton(
                  key: const Key('hourly-use'),
                  onPressed: () => setState(() {
                    final text = formatAmount(
                      amount,
                      locale: 'en',
                      decimals: amount.currency.minorUnits,
                    ).replaceAll(',', '');
                    d.amountText = text;
                    _controller('amount', text).text = text;
                  }),
                  child: Text(l10n.hourlyUse),
                ),
              ],
            ),
        ],
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
    final palette = Palette.of(context);
    final share = d.myShare;
    final locale = intlLocaleOf(context);
    final organizer = d.sharingRole == SharingRole.organizer;
    return [
      SwitchListTile(
        key: const Key('field-sharing'),
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.sharingTitle),
        value: d.sharing,
        onChanged: (v) => setState(() {
          d.sharing = v;
          if (v && d.members.isEmpty) {
            d.members = [SharingMember(name: l10n.sharingMember(2))];
          }
        }),
      ),
      if (d.sharing) ...[
        _Label(l10n.sharingRole),
        Wrap(
          spacing: 8,
          children: [
            for (final r in SharingRole.values)
              ChoiceChip(
                key: ValueKey('sharing-role-${r.name}'),
                label: Text(switch (r) {
                  SharingRole.organizer => l10n.sharingOrganizer,
                  SharingRole.member => l10n.sharingMemberRole,
                }),
                selected: d.sharingRole == r,
                onSelected: (_) => setState(() => d.sharingRole = r),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!organizer) ...[
          Text(
            l10n.sharingMemberHint,
            style: TextStyle(color: palette.secondaryText),
          ),
          TextField(
            key: const Key('sharing-payee'),
            controller: _controller('payee', d.payee),
            decoration: InputDecoration(labelText: l10n.sharingPayee),
            onChanged: (v) => d.payee = v,
          ),
          TextField(
            key: const Key('sharing-payee-method'),
            controller: _controller('payeeMethod', d.payeeMethod),
            decoration: InputDecoration(labelText: l10n.sharingPayeeMethod),
            onChanged: (v) => d.payeeMethod = v,
          ),
        ] else ...[
          _Label(l10n.sharingSplit),
          Wrap(
            spacing: 8,
            children: [
              for (final s in SharingSplit.values)
                ChoiceChip(
                  key: ValueKey('sharing-split-${s.name}'),
                  label: Text(switch (s) {
                    SharingSplit.equal => l10n.sharingSplitEqual,
                    SharingSplit.custom => l10n.sharingSplitCustom,
                    SharingSplit.rotating => l10n.sharingSplitRotating,
                  }),
                  selected: d.sharingSplit == s,
                  onSelected: (_) => setState(() => d.sharingSplit = s),
                ),
            ],
          ),
          if (d.sharingSplit == SharingSplit.custom) ...[
            TextField(
              key: const Key('sharing-my-share'),
              controller: _controller('myShare', d.myShareText),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.sharingMyShare,
                suffixText: d.currency.code,
              ),
              onChanged: (v) => setState(() => d.myShareText = v),
            ),
            SwitchListTile(
              key: const Key('sharing-follow-price'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sharingFollowPrice),
              value: d.followPrice,
              onChanged: (v) => setState(() => d.followPrice = v),
            ),
          ],
          if (d.sharingSplit == SharingSplit.rotating)
            SwitchListTile(
              key: const Key('sharing-my-turn-first'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sharingMyTurnFirst),
              value: d.myTurnFirst,
              onChanged: (v) => setState(() => d.myTurnFirst = v),
            ),
          if (share != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${l10n.sharingMyShare}: ${formatMoney(share, locale: locale)}',
                key: const Key('sharing-my-share-result'),
              ),
            ),
          for (final (i, m) in d.members.indexed)
            ListTile(
              key: ValueKey('sharing-member-$i'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                m.paid ? Icons.check_circle : Icons.person_outline,
                color: m.paid ? palette.primary : null,
              ),
              title: Text(m.name.isEmpty ? l10n.sharingMember(i + 2) : m.name),
              subtitle: Text(
                [
                  if (d.sharingSplit == SharingSplit.custom &&
                      m.shareText.isNotEmpty)
                    '${m.shareText} ${(m.shareCurrency ?? d.currency).code}',
                  if (m.paidUntil case final until?)
                    l10n.sharingPaidUntil(until.toString()),
                  if (m.leftOn case final left?)
                    l10n.sharingLeftOn(left.toString()),
                  if (m.paidUntil == null)
                    m.paid ? l10n.sharingPaid : l10n.sharingNotPaid,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editMember(context, d, i),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('sharing-add-member'),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.sharingAddMember),
              onPressed: () => setState(
                () => d.members.add(
                  SharingMember(name: l10n.sharingMember(d.sharingPeople + 1)),
                ),
              ),
            ),
          ),
        ],
      ],
    ];
  }

  /// One member: name, share and its currency, paid / paid ahead, joined
  /// and left dates; or remove them.
  Future<void> _editMember(BuildContext context, ItemDraft d, int i) async {
    final l10n = AppLocalizations.of(context);
    final m = d.members[i];
    final name = TextEditingController(text: m.name);
    final share = TextEditingController(text: m.shareText);
    final region = ref.read(userSettingsProvider).value?.region ?? 'US';
    var removed = false;
    Future<LocalDate?> pick(LocalDate? initial) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial == null
            ? now
            : DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      return picked == null ? null : LocalDate.fromDateTime(picked);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          Widget dateRow(
            String key,
            String label,
            LocalDate? value,
            void Function(LocalDate?) set,
          ) => ListTile(
            key: Key(key),
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            trailing: Text(value?.toString() ?? '—'),
            onTap: () async {
              final picked = await pick(value);
              setSheet(() => set(picked));
            },
            onLongPress: () => setSheet(() => set(null)),
          );
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('member-name'),
                    controller: name,
                    decoration: InputDecoration(labelText: l10n.sharingName),
                  ),
                  if (d.sharingSplit == SharingSplit.custom)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('member-share'),
                            controller: share,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.sharingTheirShare,
                              helperText: l10n.sharingFreeSeatHint,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final c = await showCurrencyPicker(
                              context,
                              region: region,
                              selected: m.shareCurrency ?? d.currency,
                            );
                            if (c != null) setSheet(() => m.shareCurrency = c);
                          },
                          child: Text((m.shareCurrency ?? d.currency).code),
                        ),
                      ],
                    ),
                  CheckboxListTile(
                    key: const Key('member-paid'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.sharingPaid),
                    value: m.paid,
                    onChanged: (v) => setSheet(() => m.paid = v ?? false),
                  ),
                  dateRow(
                    'member-paid-until',
                    l10n.sharingPaidAhead,
                    m.paidUntil,
                    (v) => m.paidUntil = v,
                  ),
                  dateRow(
                    'member-joined',
                    l10n.sharingJoined,
                    m.joinedOn,
                    (v) => m.joinedOn = v,
                  ),
                  dateRow(
                    'member-left',
                    l10n.sharingLeft,
                    m.leftOn,
                    (v) => m.leftOn = v,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        key: const Key('member-remove'),
                        onPressed: () {
                          removed = true;
                          Navigator.pop(context);
                        },
                        child: Text(l10n.actionDelete),
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('member-done'),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.actionDone),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      if (removed) {
        d.members.removeAt(i);
      } else {
        m
          ..name = name.text
          ..shareText = share.text;
      }
    });
    name.dispose();
    share.dispose();
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

/// Hours in one billing cycle, for hourly-billed servers: a month is a
/// twelfth of an average Gregorian year (730 h).
int hoursPerCycle(Cycle c) => switch (c.unit) {
  CycleUnit.day => 24 * c.every,
  CycleUnit.week => 168 * c.every,
  CycleUnit.month => (8765.82 * c.every / 12).round(),
  CycleUnit.year => (8765.82 * c.every).round(),
};

/// What an hourly-billed server costs per charge when it runs all the time;
/// null without a usable rate.
({Money amount, int hours})? hourlyEstimate(ItemDraft d) {
  // Hourly rates go below the currency's smallest unit (€0.007 an hour).
  final rate = double.tryParse(
    '${d.fields['hourlyRate'] ?? ''}'.trim().replaceAll(',', '.'),
  );
  if (rate == null || rate <= 0) return null;
  final hours = hoursPerCycle(d.cycle);
  return (
    amount: Money(
      (rate * hours * d.currency.minorPerMajor).round(),
      d.currency,
    ),
    hours: hours,
  );
}
