import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// A notification from a picked app, or text shared into the app.
class Notice {
  const Notice({
    required this.source,
    required this.text,
    required this.postedAt,
  });

  factory Notice.fromJson(Map<String, Object?> j) => Notice(
    source: j['package']! as String,
    text: '${j['title'] ?? ''}\n${j['text'] ?? ''}'.trim(),
    postedAt: DateTime.fromMillisecondsSinceEpoch(j['postedAt']! as int),
  );

  /// Package name, or [shared] for text shared into the app.
  final String source;
  final String text;
  final DateTime postedAt;

  static const shared = 'shared';
}

/// A launchable app, and how many charge-like notifications it posted.
class NoticeApp {
  const NoticeApp(this.package, this.label, this.charges);

  final String package;
  final String label;
  final int charges;
}

/// The native notification listener, behind an interface for tests.
abstract interface class NoticePlatform {
  Future<bool> accessGranted();
  Future<bool> openAccessSettings();
  Future<void> setConfig({
    required bool enabled,
    required List<String> packages,
  });
  Future<List<Notice>> takeNotices();
  Future<String?> takeSharedText();
  Future<List<NoticeApp>> apps();

  /// Fires when new notices or shared text are waiting.
  Stream<void> get noticesAvailable;
}

class MethodChannelNoticePlatform implements NoticePlatform {
  MethodChannelNoticePlatform() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'noticesAvailable') _events.add(null);
    });
  }

  static const _channel = MethodChannel('app.cashrotate/notices');
  final _events = StreamController<void>.broadcast();

  @override
  Future<bool> accessGranted() async =>
      await _channel.invokeMethod<bool>('accessGranted') ?? false;

  @override
  Future<bool> openAccessSettings() async =>
      await _channel.invokeMethod<bool>('openAccessSettings') ?? false;

  @override
  Future<void> setConfig({
    required bool enabled,
    required List<String> packages,
  }) => _channel.invokeMethod('setConfig', {
    'enabled': enabled,
    'packages': packages,
  });

  @override
  Future<List<Notice>> takeNotices() async {
    final raw = await _channel.invokeMethod<String>('takeNotices') ?? '[]';
    return [
      for (final n in jsonDecode(raw) as List)
        Notice.fromJson((n as Map).cast<String, Object?>()),
    ];
  }

  @override
  Future<String?> takeSharedText() =>
      _channel.invokeMethod<String>('takeSharedText');

  @override
  Future<List<NoticeApp>> apps() async {
    final raw = await _channel.invokeMethod<String>('apps') ?? '[]';
    return [
      for (final a in jsonDecode(raw) as List)
        NoticeApp(
          (a as Map)['package'] as String,
          a['label'] as String,
          a['charges'] as int? ?? 0,
        ),
    ];
  }

  @override
  Stream<void> get noticesAvailable => _events.stream;
}
