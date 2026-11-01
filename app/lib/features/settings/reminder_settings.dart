import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/palette.dart';

/// Whether notifications may show, the phone maker (for battery guidance)
/// and how many reminders arrived late lately. Refreshed when the settings
/// page opens and after the user changes something.
typedef ReminderHealth = ({bool allowed, String manufacturer, int late});

final reminderHealthProvider = FutureProvider.autoDispose<ReminderHealth>((
  ref,
) async {
  final platform = ref.watch(reminderPlatformProvider);
  return (
    allowed: await platform.notificationsEnabled(),
    manufacturer: await platform.manufacturer(),
    late: await ref.watch(reminderServiceProvider).lateCount(),
  );
});

/// Reminders: on/off, time of day, notification permission, a test
/// notification and the battery settings guide for the phone's maker.
class ReminderSettings extends ConsumerWidget {
  const ReminderSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(userSettingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final health = ref.watch(reminderHealthProvider).value;
    final repo = ref.read(settingsRepositoryProvider);
    final platform = ref.read(reminderPlatformProvider);
    final time = TimeOfDay(
      hour: settings.reminderMinutes ~/ 60,
      minute: settings.reminderMinutes % 60,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('settings-reminders-on'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsRemindersOn),
          subtitle: Text(l10n.settingsRemindersOnHint),
          value: settings.remindersOn,
          onChanged: repo.setRemindersOn,
        ),
        if (settings.remindersOn) ...[
          ListTile(
            key: const Key('settings-reminder-time'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.settingsReminderTime),
            trailing: Text(time.format(context), style: text.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                await repo.setReminderMinutes(picked.hour * 60 + picked.minute);
              }
            },
          ),
          if (health != null && !health.allowed)
            _Notice(
              key: const Key('settings-notifications-off'),
              color: palette.warning,
              icon: Icons.notifications_off_outlined,
              message: l10n.settingsNotificationsOff,
              action: l10n.settingsAllowNotifications,
              onAction: () async {
                if (!await platform.requestPermission()) {
                  await platform.openNotificationSettings();
                }
                ref.invalidate(reminderHealthProvider);
              },
            ),
          if (health != null && health.late > 0)
            _Notice(
              key: const Key('settings-reminders-late'),
              color: palette.warning,
              icon: Icons.schedule,
              message: l10n.settingsRemindersLate(health.late),
            ),
          ListTile(
            key: const Key('settings-test-notification'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsTestNotification),
            onTap: () async {
              await platform.requestPermission();
              await platform.sendTest(
                l10n.testNotificationTitle,
                l10n.testNotificationBody,
              );
              ref.invalidate(reminderHealthProvider);
            },
          ),
          const SizedBox(height: 8),
          Text(l10n.settingsBatteryTitle, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            batteryGuide(l10n, health?.manufacturer ?? ''),
            key: const Key('settings-battery-guide'),
            style: text.bodyMedium?.copyWith(color: palette.secondaryText),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('settings-open-battery'),
              onPressed: platform.openBatterySettings,
              child: Text(l10n.settingsOpenBatterySettings),
            ),
          ),
        ],
      ],
    );
  }
}

/// Battery settings steps for the phone's maker, the usual reason
/// reminders arrive late on Chinese-brand phones and Samsung.
String batteryGuide(AppLocalizations l10n, String manufacturer) =>
    switch (manufacturer.toLowerCase()) {
      'xiaomi' || 'redmi' || 'poco' => l10n.batteryXiaomi,
      'huawei' || 'honor' => l10n.batteryHuawei,
      'oppo' || 'realme' || 'oneplus' => l10n.batteryOppo,
      'vivo' || 'iqoo' => l10n.batteryVivo,
      'samsung' => l10n.batterySamsung,
      _ => l10n.batteryGeneric,
    };

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.color,
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: text.bodyMedium?.copyWith(color: color)),
                if (action != null)
                  TextButton(onPressed: onAction, child: Text(action!)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
