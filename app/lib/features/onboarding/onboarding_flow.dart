import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../brand.dart';
import '../../data/providers.dart';
import '../../data/settings/settings_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/pearl_surface.dart';
import '../../widgets/money_text.dart';
import '../../widgets/state_views.dart';
import '../home/fixed_summary.dart';
import '../settings/basic_settings_fields.dart';
import 'batch.dart';
import 'batch_table.dart';
import 'service_picker.dart';

enum OnboardingStep { basics, importMethod, pick, batch, summary }

/// First launch: basics → import method → pick services → amounts and
/// dates → summary. Progress is saved after every change, so leaving
/// halfway resumes at the same step with the same rows.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  BatchDraft? _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .getJson(SettingsRepository.onboardingDraftKey);
    if (mounted) setState(() => _draft = BatchDraft.fromJson(saved));
  }

  OnboardingStep get _step =>
      OnboardingStep.values[_draft!.step.clamp(
        0,
        OnboardingStep.values.length - 1,
      )];

  void _persist() => unawaited(
    ref
        .read(settingsRepositoryProvider)
        .setJson(SettingsRepository.onboardingDraftKey, _draft!.toJson()),
  );

  void _goTo(OnboardingStep step) {
    setState(() => _draft!.step = step.index);
    _persist();
  }

  Future<void> _createItems() async {
    setState(() => _saving = true);
    final today = todayFrom(ref.read(clockProvider));
    await ref.read(itemRepositoryProvider).createAll([
      for (final r in _draft!.rows) r.toNewItem(today: today),
    ]);
    _draft!.rows.clear();
    setState(() => _saving = false);
    _goTo(OnboardingStep.summary);
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setJson(SettingsRepository.onboardingDraftKey, null);
    await settings.setOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_draft == null) return const Scaffold(body: LoadingState());
    final step = _step;
    final title = switch (step) {
      OnboardingStep.basics => l10n.obBasicsTitle,
      OnboardingStep.importMethod => l10n.obImportTitle,
      OnboardingStep.pick => l10n.obPickTitle,
      OnboardingStep.batch => l10n.obBatchTitle,
      OnboardingStep.summary => l10n.obSummaryTitle,
    };
    final back = switch (step) {
      OnboardingStep.basics || OnboardingStep.summary => null,
      _ => OnboardingStep.values[step.index - 1],
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: back == null
            ? null
            : IconButton(
                tooltip: l10n.actionBack,
                icon: const BackButtonIcon(),
                onPressed: () => _goTo(back),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: switch (step) {
              OnboardingStep.basics => const _Basics(),
              OnboardingStep.importMethod => _ImportMethod(
                onPick: () => _goTo(OnboardingStep.pick),
              ),
              OnboardingStep.pick => ServicePicker(
                draft: _draft!,
                onChanged: _persist,
              ),
              OnboardingStep.batch => BatchTable(
                draft: _draft!,
                onChanged: _persist,
              ),
              OnboardingStep.summary => const _Summary(),
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: switch (step) {
            OnboardingStep.basics => FilledButton(
              key: const Key('ob-next'),
              onPressed: () => _goTo(OnboardingStep.importMethod),
              child: Text(l10n.actionNext),
            ),
            OnboardingStep.importMethod => const SizedBox.shrink(),
            OnboardingStep.pick => FilledButton(
              key: const Key('ob-next'),
              onPressed: () => _goTo(
                _draft!.rows.isEmpty
                    ? OnboardingStep.summary
                    : OnboardingStep.batch,
              ),
              child: Text(l10n.actionNext),
            ),
            OnboardingStep.batch => FilledButton(
              key: const Key('ob-next'),
              onPressed: _saving ? null : _createItems,
              child: Text(l10n.actionNext),
            ),
            OnboardingStep.summary => FilledButton(
              key: const Key('ob-finish'),
              onPressed: _finish,
              child: Text(l10n.obFinish),
            ),
          },
        ),
      ),
    );
  }
}

class _Basics extends ConsumerWidget {
  const _Basics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).value;
    if (settings == null) return const LoadingState();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.obBasicsBody, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        const BasicSettingsFields(keyPrefix: 'ob'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Palette.of(context).secondaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.obSyncLater,
                style: TextStyle(color: Palette.of(context).secondaryText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImportMethod extends StatelessWidget {
  const _ImportMethod({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            key: const Key('ob-import-pick'),
            leading: const Icon(Icons.checklist),
            title: Text(l10n.obImportPick),
            subtitle: Text(l10n.obImportPickHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPick,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            enabled: false,
            leading: const Icon(Icons.content_paste),
            title: Text(l10n.obImportPaste),
            subtitle: Text(l10n.obComingLater),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            enabled: false,
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(l10n.obImportRestore),
            subtitle: Text(l10n.obComingLater),
          ),
        ),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(fixedSummaryProvider);
    return switch (summary) {
      AsyncData(value: final s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PearlSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.obSummaryMonthly, style: text.titleSmall),
                const SizedBox(height: 8),
                MoneyText(
                  s.monthlyTotal,
                  key: const Key('ob-summary-total'),
                  style: text.displaySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: Text(l10n.obSummaryDueSoon(s.dueSoon)),
          ),
          if (s.needsDetails > 0)
            ListTile(
              leading: Icon(
                Icons.edit_note,
                color: Palette.of(context).warning,
              ),
              title: Text(l10n.itemsPendingCount(s.needsDetails)),
            ),
          if (s.missingRates > 0)
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text(l10n.obSummaryMissingRates),
            ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.obSummaryReminders),
          ),
          const SizedBox(height: 8),
          Text(
            Brand.appName,
            textAlign: TextAlign.center,
            style: text.labelSmall,
          ),
        ],
      ),
      AsyncError(:final error) => ErrorState(message: '$error'),
      _ => const LoadingState(),
    };
  }
}
