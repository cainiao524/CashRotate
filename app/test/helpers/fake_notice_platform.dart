import 'dart:async';

import 'package:cashrotate/data/detection/notice_platform.dart';

/// Plays back notices and shared text; records the configuration.
class FakeNoticePlatform implements NoticePlatform {
  final queued = <Notice>[];
  String? shared;
  bool granted = true;
  bool enabled = false;
  List<String> packages = const [];
  List<NoticeApp> installed = const [
    NoticeApp('com.bank.app', 'My Bank', 3),
    NoticeApp('com.chat.app', 'Chat', 0),
  ];
  final _events = StreamController<void>.broadcast();

  void post(String text, DateTime at, {String source = 'com.bank.app'}) {
    queued.add(Notice(source: source, text: text, postedAt: at));
    _events.add(null);
  }

  @override
  Future<bool> accessGranted() async => granted;

  @override
  Future<bool> openAccessSettings() async => true;

  @override
  Future<void> setConfig({
    required bool enabled,
    required List<String> packages,
  }) async {
    this.enabled = enabled;
    this.packages = packages;
  }

  @override
  Future<List<Notice>> takeNotices() async {
    final out = [...queued];
    queued.clear();
    return out;
  }

  @override
  Future<String?> takeSharedText() async {
    final s = shared;
    shared = null;
    return s;
  }

  @override
  Future<List<NoticeApp>> apps() async => installed;

  @override
  Stream<void> get noticesAvailable => _events.stream;
}
