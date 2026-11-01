import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/currency_picker.dart';

extension AccountTypeLabels on AppLocalizations {
  String accountType(AccountType t) => switch (t) {
    AccountType.cash => accountTypeCash,
    AccountType.bank => accountTypeBank,
    AccountType.creditCard => accountTypeCreditCard,
    AccountType.eWallet => accountTypeEWallet,
    AccountType.storedValue => accountTypeStoredValue,
    AccountType.investment => accountTypeInvestment,
    AccountType.loan => accountTypeLoan,
  };
}

/// The settings row that opens [PaymentMethodsPage].
class PaymentMethodsTile extends StatelessWidget {
  const PaymentMethodsTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('settings-payment-methods'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.credit_card),
    title: Text(AppLocalizations.of(context).paymentMethods),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go(Routes.settingsPaymentMethods),
  );
}

final _learnedProvider = FutureProvider.autoDispose.family<int?, String>(
  (ref, id) => ref.watch(paymentRepositoryProvider).learnedMarkup(id),
);

/// Cards, bank accounts and e-wallets: labels for payments, a foreign fee
/// for estimates, and the last four digits for matching bank notifications.
class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final methods = ref.watch(paymentMethodListProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethods)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('payment-method-add'),
        heroTag: null,
        icon: const Icon(Icons.add),
        label: Text(l10n.paymentMethodAdd),
        onPressed: () => _edit(context, ref, null),
      ),
      body: ListView(
        key: const PageStorageKey('settings-payment-methods'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            l10n.paymentMethodsHint,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.secondaryText),
          ),
          const SizedBox(height: 8),
          for (final m in methods)
            ListTile(
              key: ValueKey('payment-method-${m.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (m.type) {
                AccountType.creditCard => Icons.credit_card,
                AccountType.bank => Icons.account_balance_outlined,
                AccountType.eWallet => Icons.phone_iphone,
                _ => Icons.payments_outlined,
              }),
              title: Text(
                m.cardLast4 == null ? m.name : '${m.name} ··${m.cardLast4}',
              ),
              subtitle: Text(
                [
                  l10n.accountType(m.type),
                  if (m.fxFeeBasisPoints case final f? when f > 0)
                    '${(f / 100).toStringAsFixed(2)}%',
                  if (ref.watch(_learnedProvider(m.id)).value case final l?)
                    l10n.paymentMethodLearned((l / 100).toStringAsFixed(1)),
                ].join(' · '),
              ),
              onTap: () => _edit(context, ref, m),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AccountRow? m) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MethodForm(method: m),
      );
}

class _MethodForm extends ConsumerStatefulWidget {
  const _MethodForm({this.method});

  final AccountRow? method;

  @override
  ConsumerState<_MethodForm> createState() => _MethodFormState();
}

class _MethodFormState extends ConsumerState<_MethodForm> {
  late final _name = TextEditingController(text: widget.method?.name);
  late final _last4 = TextEditingController(text: widget.method?.cardLast4);
  late final _fee = TextEditingController(
    text: widget.method?.fxFeeBasisPoints == null
        ? ''
        : (widget.method!.fxFeeBasisPoints! / 100).toString(),
  );
  late AccountType _type = widget.method?.type ?? AccountType.creditCard;
  late Currency? _currency = widget.method?.currency;

  @override
  void dispose() {
    _name.dispose();
    _last4.dispose();
    _fee.dispose();
    super.dispose();
  }

  int? get _feeBps {
    final v = double.tryParse(_fee.text.replaceAll(',', '.'));
    return v == null ? null : (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency =
        _currency ??
        ref.watch(userSettingsProvider).value?.mainCurrency ??
        Currency.usd;
    final repo = ref.read(paymentMethodsProvider);
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
              key: const Key('payment-method-name'),
              controller: _name,
              autofocus: widget.method == null,
              decoration: InputDecoration(labelText: l10n.paymentMethodName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in const [
                  AccountType.creditCard,
                  AccountType.bank,
                  AccountType.eWallet,
                  AccountType.storedValue,
                  AccountType.cash,
                ])
                  ChoiceChip(
                    label: Text(l10n.accountType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final picked = await showCurrencyPicker(
                  context,
                  region: ref.read(userSettingsProvider).value?.region ?? 'US',
                  selected: currency,
                );
                if (picked != null) setState(() => _currency = picked);
              },
              child: Text(currency.code),
            ),
            TextField(
              key: const Key('payment-method-last4'),
              controller: _last4,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: l10n.paymentMethodLast4),
            ),
            TextField(
              key: const Key('payment-method-fee'),
              controller: _fee,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.paymentMethodFee),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.method != null)
                  TextButton(
                    key: const Key('payment-method-archive'),
                    onPressed: () async {
                      await repo.archive(widget.method!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(l10n.paymentMethodArchive),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('payment-method-save'),
                  onPressed: _name.text.trim().isEmpty
                      ? null
                      : () async {
                          if (widget.method == null) {
                            await repo.create(
                              name: _name.text,
                              type: _type,
                              currency: currency,
                              fxFeeBasisPoints: _feeBps,
                              cardLast4: _last4.text,
                            );
                          } else {
                            await repo.update(
                              widget.method!.id,
                              name: _name.text,
                              type: _type,
                              currency: currency,
                              fxFeeBasisPoints: _feeBps,
                              cardLast4: _last4.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
