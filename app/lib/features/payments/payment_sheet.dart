import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/items/item_repository.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../theme/palette.dart';

/// Records a payment for [view]'s next charge (or a charge of an irregular
/// bill). Returns true once saved.
Future<bool> showPaymentSheet(
  BuildContext context,
  ItemView view, {
  OccurrenceRow? charge,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentSheet(view: view, charge: charge ?? view.nextDue),
    ) ??
    false;

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.view, required this.charge});

  final ItemView view;
  final OccurrenceRow? charge;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final _amount = TextEditingController();
  late Money _expected;
  late LocalDate _date;
  String? _accountId;
  bool _inMain = false;
  bool _saving = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final charge = widget.charge;
    _expected = charge == null
        ? widget.view.schedule.prices.stablePrice
        : Money(charge.expectedMinor, charge.currency);
    final today = todayFrom(ref.read(clockProvider));
    _date = charge == null || charge.dueOn > today ? today : charge.dueOn;
    _accountId = widget.view.row.accountId;
    _amount.text = _plain(_expected);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Currency get _main =>
      ref.read(userSettingsProvider).value?.mainCurrency ?? _expected.currency;

  Currency get _currency => _inMain ? _main : _expected.currency;

  String _plain(Money m) => formatMoney(
    m,
    locale: 'en',
    decimals: m.currency.minorUnits,
  ).replaceAll(RegExp(r'[^0-9.]'), '');

  Money? get _paid => parseMoney(_amount.text, _currency);

  Future<void> _toggleMain(bool on) async {
    setState(() => _inMain = on);
    if (on) {
      final fx = ref.read(fxConverterProvider).value;
      final fee = await _feeFor(_accountId);
      final estimate = fx?.convert(_expected, _main, feeBasisPoints: fee);
      _amount.text = estimate == null ? '' : _plain(estimate.amount);
    } else {
      _amount.text = _plain(_expected);
    }
  }

  /// A card's foreign fee: what it has charged lately, else its set fee.
  Future<int> _feeFor(String? accountId) async {
    if (accountId == null) return 0;
    final learned = await ref
        .read(paymentRepositoryProvider)
        .learnedMarkup(accountId);
    if (learned != null) return learned;
    final methods = ref.read(paymentMethodListProvider).value ?? const [];
    return methods
            .where((m) => m.id == accountId)
            .firstOrNull
            ?.fxFeeBasisPoints ??
        0;
  }

  Future<void> _save() async {
    final paid = _paid;
    if (paid == null) return;
    final l10n = AppLocalizations.of(context);
    var updatePrice = false;
    if (!_inMain && paid != _expected && widget.charge != null) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.paymentDifferent),
          actions: [
            TextButton(
              key: const Key('payment-once'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.paymentJustOnce),
            ),
            FilledButton(
              key: const Key('payment-update-price'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.paymentUpdatePrice),
            ),
          ],
        ),
      );
      if (choice == null) return;
      updatePrice = choice;
    }
    setState(() => _saving = true);
    final fx = ref.read(fxConverterProvider).value;
    await ref
        .read(paymentRepositoryProvider)
        .record(
          itemId: widget.view.row.id,
          occurrenceId: widget.charge?.id,
          expected: _expected,
          paid: paid,
          paidOn: _date,
          main: _main,
          accountId: _accountId,
          marketRate: paid.currency == _expected.currency
              ? null
              : fx?.rate(_expected.currency, paid.currency)?.rate,
          updateFuturePrice: updatePrice,
        );
    await HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final methods = ref.watch(paymentMethodListProvider).value ?? const [];
    final foreign = _expected.currency != _main;
    final locale = intlLocaleOf(context);
    final dateText = DateFormat.yMMMd(locale)
        .format(DateTime(_date.year, _date.month, _date.day));

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
            Text(
              l10n.paymentTitle(widget.view.row.name),
              style: text.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.paymentExpected(formatMoney(_expected, locale: locale)),
              style: text.bodyMedium?.copyWith(color: palette.secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('payment-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.paymentAmount,
                suffixText: _currency.code,
                errorText: _amount.text.isNotEmpty && _paid == null
                    ? l10n.paymentInvalid
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (foreign)
              SwitchListTile(
                key: const Key('payment-in-main'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.paymentInMain(_main.code)),
                subtitle: Text(l10n.paymentInMainHint),
                value: _inMain,
                onChanged: _toggleMain,
              ),
            ListTile(
              key: const Key('payment-date'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.paymentDate),
              trailing: Text(dateText),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(_date.year, _date.month, _date.day),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _date = LocalDate.fromDateTime(picked));
                }
              },
            ),
            DropdownButtonFormField<String?>(
              key: const Key('payment-method'),
              initialValue: methods.any((m) => m.id == _accountId)
                  ? _accountId
                  : null,
              decoration: InputDecoration(labelText: l10n.paymentMethod),
              items: [
                DropdownMenuItem(child: Text(l10n.paymentMethodNone)),
                for (final m in methods)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      m.cardLast4 == null
                          ? m.name
                          : '${m.name} ··${m.cardLast4}',
                    ),
                  ),
              ],
              onChanged: (v) async {
                setState(() => _accountId = v);
                if (_inMain) await _toggleMain(true);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('payment-save'),
              onPressed: _saving || _paid == null ? null : _save,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
