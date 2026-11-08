import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// A notification's large icon: the item's chosen line icon (a Material
/// Icons code point) or else its initial, on a round badge.
class NotificationBadge {
  const NotificationBadge({
    required this.letter,
    required this.background,
    required this.foreground,
    this.iconCodePoint,
  });

  final String letter;

  /// ARGB colours.
  final int background;
  final int foreground;
  final int? iconCodePoint;

  Map<String, Object?> toJson() => {
    'letter': letter,
    'background': background,
    'foreground': foreground,
    'icon': iconCodePoint,
  };
}

/// A reminder ready for the platform: when, and the localised text.
class NativeReminder {
  const NativeReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.itemId,
    required this.kind,
    this.occurrenceId,
    this.badge,
    this.cancelUrl,
  });

  final String id;

  /// Local time it should show, as an instant.
  final DateTime at;
  final String title;
  final String body;
  final String itemId;
  final String kind;

  /// The charge "Paid" on the notification settles.
  final String? occurrenceId;

  final NotificationBadge? badge;

  /// Trials and renewals: "Go cancel" opens this page.
  final String? cancelUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'itemId': itemId,
    'occurrenceId': occurrenceId,
    'kind': kind,
    'badge': badge?.toJson(),
    'cancelUrl': cancelUrl,
  };
}

/// Something that happened on the platform side: a reminder shown, or an
/// action taken on its notification.
class ReminderEvent {
  const ReminderEvent({
    required this.type,
    required this.reminderId,
    required this.itemId,
    required this.kind,
    required this.scheduledAt,
    required this.at,
    this.occurrenceId,
  });

  factory ReminderEvent.fromJson(Map<String, Object?> j) => ReminderEvent(
    type: j['type']! as String,
    reminderId: j['id']! as String,
    itemId: j['itemId']! as String,
    occurrenceId: j['occurrenceId'] as String?,
    kind: j['kind'] as String? ?? 'charge',
    scheduledAt: j['scheduledAt']! as int,
    at: j['at']! as int,
  );

  /// `delivered`, `paid` or `snoozed`.
  final String type;
  final String reminderId;
  final String itemId;
  final String? occurrenceId;
  final String kind;

  /// Epoch milliseconds (UTC instants).
  final int scheduledAt;
  final int at;
}

/// The native reminder scheduler (Kotlin: AlarmManager, notifications,
/// WorkManager), behind an interface so tests can fake it.
abstract interface class ReminderPlatform {
  /// Replaces the pictures used as notification large icons (square PNG per
  /// item id); items without one draw their badge.
  Future<void> setBadgeImages(Map<String, Uint8List> images);

  /// Replaces the planned reminders. [labels]: `paid`, `snooze`,
  /// `goCancel`, `channelName`, `channelDescription`.
  Future<void> setReminders(
    List<NativeReminder> reminders,
    Map<String, String> labels,
  );

  /// Events since the last call, oldest first.
  Future<List<ReminderEvent>> takeEvents();

  /// Fires when new events are waiting (an action while the app is open).
  Stream<void> get eventsAvailable;

  Future<bool> notificationsEnabled();
  Future<bool> requestPermission();
  Future<bool> sendTest(String title, String body);

  /// Lower-case `Build.MANUFACTURER`, for battery-setting guidance.
  Future<String> manufacturer();
  Future<bool> openBatterySettings();
  Future<bool> openNotificationSettings();

  /// The item whose notification opened the app, once.
  Future<String?> takeOpenedItem();

  /// Fires when a notification is tapped while the app is running.
  Stream<void> get itemOpened;
}

class MethodChannelReminderPlatform implements ReminderPlatform {
  MethodChannelReminderPlatform() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'eventsAvailable':
          _events.add(null);
        case 'itemOpened':
          _opened.add(null);
      }
    });
  }

  static const _channel = MethodChannel('app.cashrotate/reminders');
  final _events = StreamController<void>.broadcast();
  final _opened = StreamController<void>.broadcast();

  @override
  Future<void> setBadgeImages(Map<String, Uint8List> images) =>
      _channel.invokeMethod('setBadgeImages', images);

  @override
  Future<void> setReminders(
    List<NativeReminder> reminders,
    Map<String, String> labels,
  ) => _channel.invokeMethod(
    'setReminders',
    jsonEncode({
      'reminders': [for (final r in reminders) r.toJson()],
      'labels': labels,
    }),
  );

  @override
  Future<List<ReminderEvent>> takeEvents() async {
    final raw = await _channel.invokeMethod<String>('takeEvents') ?? '[]';
    return [
      for (final e in jsonDecode(raw) as List)
        ReminderEvent.fromJson((e as Map).cast<String, Object?>()),
    ];
  }

  @override
  Stream<void> get eventsAvailable => _events.stream;

  @override
  Stream<void> get itemOpened => _opened.stream;

  @override
  Future<bool> notificationsEnabled() async =>
      await _channel.invokeMethod<bool>('notificationsEnabled') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<bool> sendTest(String title, String body) async =>
      await _channel.invokeMethod<bool>(
        'sendTest',
        jsonEncode({'title': title, 'body': body}),
      ) ??
      false;

  @override
  Future<String> manufacturer() async =>
      await _channel.invokeMethod<String>('manufacturer') ?? '';

  @override
  Future<bool> openBatterySettings() async =>
      await _channel.invokeMethod<bool>('openBatterySettings') ?? false;

  @override
  Future<bool> openNotificationSettings() async =>
      await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;

  @override
  Future<String?> takeOpenedItem() =>
      _channel.invokeMethod<String>('takeOpenedItem');
}
