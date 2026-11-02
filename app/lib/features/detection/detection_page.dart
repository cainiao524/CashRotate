import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/detection/detection_service.dart';
import '../../data/detection/notice_platform.dart';
import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_tags.dart';
import '../../routing/routes.dart';
import '../../theme/palette.dart';
import '../../widgets/money_text.dart';
import '../home/fixed_summary.dart';
import '../items/add_item_page.dart';

/// The settings row that opens [DetectionPage], with how many charges wait.
class DetectionSettingsTile extends ConsumerWidget {
  const DetectionSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(detectionSettingsProvider).value;
    final pending = (ref.watch(detectionsProvider).value ?? const [])
        .where((d) => d.status == DetectionStatus.pending)
        .length;
    return ListTile(
      key: const Key('settings-detection'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.detectTitle),
      subtitle: Text(
        pending > 0
            ? l10n.detectPendingCount(pending)
            : (settings?.enabled ?? false)
            ? l10n.detectOn
            : l10n.detectOff,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.settingsDetection),
    );
  }
}

final _accessProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(noticePlatformProvider).accessGranted(),
);

/// Automatic charge detection: on/off and notification access, the apps to
/// read, charges waiting for a decision, automatic matches (with undo) and
/// possible new subscriptions.
class DetectionPage extends ConsumerStatefulWidget {
  const DetectionPage({super.key});

  @override
  ConsumerState<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends ConsumerState<DetectionPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system's notification access screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(_accessProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final service = ref.read(detectionServiceProvider);
    final platform = ref.read(noticePlatformProvider);
    final settings =
        ref.watch(detectionSettingsProvider).value ?? const DetectionSettings();
    final access = ref.watch(_accessProvider).value ?? false;
    final all = ref.watch(detectionsProvider).value ?? const <Detection>[];
    final pending = all
        .where((d) => d.status == DetectionStatus.pending)
        .toList();
    final auto = all
        .where((d) => d.status == DetectionStatus.auto)
        .take(20)
        .toList();
    final suggestions = service.suggestions(all);
    final items = ref.watch(itemsProvider).value ?? const [];
    String nameOf(String? id) =>
        items.where((v) => v.row.id == id).firstOrNull?.row.name ?? '—';
    final locale = intlLocaleOf(context);
    String when(Detection d) => DateFormat.MMMd(locale).add_Hm().format(d.at);

    Future<void> assign(Detection d) async {
      final id = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(l10n.detectChooseItem),
          children: [
            for (final v in items)
              if (v.nextDue != null || v.irregular)
                SimpleDialogOption(
                  key: ValueKey('detect-item-${v.row.id}'),
                  onPressed: () => Navigator.pop(context, v.row.id),
                  child: Text(v.row.name),
                ),
          ],
        ),
      );
      if (id == null) return;
      final s = ref.read(userSettingsProvider).value!;
      await service.assign(
        d.id,
        id,
        main: s.mainCurrency,
        fx: ref.read(fxConverterProvider).value!,
      );
    }

    Widget charge(Detection d, List<Widget> actions, {String? item}) => Card(
      key: ValueKey('detection-${d.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.merchant ?? l10n.detectUnknownMerchant,
                    style: text.titleSmall,
                  ),
                ),
                MoneyText(d.amount, style: text.titleSmall),
              ],
            ),
            Text(
              [when(d), ?item].join(' · '),
              style: text.bodySmall?.copyWith(color: palette.secondaryText),
            ),
            Wrap(alignment: WrapAlignment.end, children: actions),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detectTitle)),
      body: ListView(
        key: const PageStorageKey('settings-detection'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            l10n.detectIntro,
            style: text.bodyMedium?.copyWith(color: palette.secondaryText),
          ),
          SwitchListTile(
            key: const Key('detect-enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.detectEnable),
            value: settings.enabled,
            onChanged: (on) => service.setSettings(
              DetectionSettings(enabled: on, packages: settings.packages),
            ),
          ),
          if (settings.enabled && !access)
            Card(
              key: const Key('detect-no-access'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.detectAccessNeeded),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('detect-open-access'),
                      onPressed: platform.openAccessSettings,
                      child: Text(l10n.detectOpenAccess),
                    ),
                  ],
                ),
              ),
            ),
          if (settings.enabled)
            ListTile(
              key: const Key('detect-apps'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps),
              title: Text(l10n.detectApps),
              subtitle: Text(
                settings.packages.isEmpty
                    ? l10n.detectAppsNone
                    : l10n.detectAppsCount(settings.packages.length),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _AppPicker(settings: settings),
              ),
            ),
          Text(
            l10n.detectShareHint,
            style: text.bodySmall?.copyWith(color: palette.secondaryText),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.detectPending, style: text.titleSmall),
            const SizedBox(height: 8),
            for (final d in pending)
              charge(d, [
                TextButton(
                  key: ValueKey('detect-ignore-${d.id}'),
                  onPressed: () => service.ignore(d.id),
                  child: Text(l10n.detectIgnore),
                ),
                TextButton(
                  key: ValueKey('detect-assign-${d.id}'),
                  onPressed: () => assign(d),
                  child: Text(
                    d.itemId == null
                        ? l10n.detectChooseItem
                        : l10n.detectConfirmFor(nameOf(d.itemId)),
                  ),
                ),
              ]),
          ],
          if (auto.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.detectAuto, style: text.titleSmall),
            const SizedBox(height: 8),
            for (final d in auto)
              charge(d, [
                TextButton(
                  key: ValueKey('detect-undo-${d.id}'),
                  onPressed: () => service.undo(d.id),
                  child: Text(l10n.detectUndo),
                ),
              ], item: nameOf(d.itemId)),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.detectSuggestions, style: text.titleSmall),
            for (final s in suggestions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline),
                title: Text(s.merchant),
                subtitle: Text(l10n.detectSuggestionHint),
                trailing: MoneyText(s.amount),
                onTap: () => openAddItem(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _AppPicker extends ConsumerStatefulWidget {
  const _AppPicker({required this.settings});

  final DetectionSettings settings;

  @override
  ConsumerState<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends ConsumerState<_AppPicker> {
  late final _chosen = {...widget.settings.packages};
  late final _apps = ref.read(noticePlatformProvider).apps();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('detect-app-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.detectAppsSearch,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<NoticeApp>>(
                future: _apps,
                builder: (context, snap) {
                  final apps = [...?snap.data]
                    ..retainWhere(
                      (a) =>
                          _query.isEmpty ||
                          a.label.toLowerCase().contains(_query) ||
                          a.package.contains(_query),
                    )
                    ..sort((a, b) {
                      final chosen = _chosen.contains(b.package) ? 1 : 0;
                      final other = _chosen.contains(a.package) ? 1 : 0;
                      if (chosen != other) return chosen - other;
                      if (a.charges != b.charges) return b.charges - a.charges;
                      return a.label.compareTo(b.label);
                    });
                  return ListView(
                    children: [
                      for (final a in apps)
                        CheckboxListTile(
                          key: ValueKey('detect-app-${a.package}'),
                          title: Text(a.label),
                          subtitle: a.charges > 0
                              ? Text(
                                  l10n.detectAppLooksLikeBank(a.charges),
                                  style: TextStyle(color: palette.warning),
                                )
                              : null,
                          value: _chosen.contains(a.package),
                          onChanged: (on) => setState(
                            () => on == true
                                ? _chosen.add(a.package)
                                : _chosen.remove(a.package),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                key: const Key('detect-apps-save'),
                onPressed: () async {
                  await ref
                      .read(detectionServiceProvider)
                      .setSettings(
                        DetectionSettings(
                          enabled: widget.settings.enabled,
                          packages: _chosen.toList()..sort(),
                        ),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
