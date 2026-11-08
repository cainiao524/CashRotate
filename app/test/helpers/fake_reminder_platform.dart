import 'dart:async';
import 'dart:typed_data';

import 'package:cashrotate/data/reminders/reminder_platform.dart';

/// Records what the app hands to the native scheduler and plays back
/// events, permission answers and tapped notifications.
class FakeReminderPlatform implements ReminderPlatform {
  List<NativeReminder> reminders = const [];
  Map<String, String> labels = const {};
  int setCalls = 0;
  final queued = <ReminderEvent>[];
  final tests = <(String, String)>[];
  bool enabled = true;
  bool grant = true;
  int permissionRequests = 0;
  String maker = 'google';
  String? opened;
  int batteryOpened = 0;

  Map<String, Uint8List> badgeImages = const {};

  @override
  Future<void> setBadgeImages(Map<String, Uint8List> images) async =>
      badgeImages = images;

  final _events = StreamController<void>.broadcast();
  final _opened = StreamController<void>.broadcast();

  /// Simulates "Paid" or a delivery while the app is open.
  void emit(ReminderEvent event) {
    queued.add(event);
    _events.add(null);
  }

  void tap(String itemId) {
    opened = itemId;
    _opened.add(null);
  }

  @override
  Future<void> setReminders(
    List<NativeReminder> reminders,
    Map<String, String> labels,
  ) async {
    this.reminders = reminders;
    this.labels = labels;
    setCalls++;
  }

  @override
  Future<List<ReminderEvent>> takeEvents() async {
    final events = [...queued];
    queued.clear();
    return events;
  }

  @override
  Stream<void> get eventsAvailable => _events.stream;

  @override
  Stream<void> get itemOpened => _opened.stream;

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grant;
    return grant;
  }

  @override
  Future<bool> sendTest(String title, String body) async {
    tests.add((title, body));
    return enabled;
  }

  @override
  Future<String> manufacturer() async => maker;

  @override
  Future<bool> openBatterySettings() async {
    batteryOpened++;
    return true;
  }

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<String?> takeOpenedItem() async {
    final id = opened;
    opened = null;
    return id;
  }
}
