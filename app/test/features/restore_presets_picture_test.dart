import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/presets.dart';
import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate/widgets/thumbnail.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sodium/sodium_sumo.dart';

import '../helpers/pump_app.dart';
import 'home_tiles_test.dart' show tile;
import 'sync_settings_test.dart' show connect, fast, syncWith, tapVisible;

/// A solid-colour PNG of [w] × [h] pixels.
Future<Uint8List> png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF1D4ED8),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<void> openOnboardingAtImport(TestData d) => d.settings.setJson(
  SettingsRepository.onboardingDraftKey,
  {'step': 1, 'rows': <Object?>[]},
);

void main() {
  group('restore from WebDAV on first launch', () {
    testApp('joins the existing folder and lands on home', (tester) async {
      final folder = MemoryFolder();
      await pumpApp(
        tester,
        onboarded: false,
        overrides: [syncWith(folder)],
        seed: (d) async {
          await openOnboardingAtImport(d);
          final sodium = await SodiumSumoInit.init();
          await SyncSetup(SyncKeys(sodium, kdf: fast), folder).create(
            password: 'secret-1',
            recoveryCode: 'gT7#qL2v!Wm9@zR4xK8&',
            deviceId: 'old-phone',
            deviceName: 'Pixel',
          );
        },
      );
      await tester.tap(find.byKey(const Key('ob-import-restore')));
      await settle(tester);
      await connect(tester);
      await tester.enterText(
        find.byKey(const Key('sync-password')),
        'secret-1',
      );
      await settle(tester);
      await tapVisible(tester, const Key('sync-join'));
      await settle(tester, frames: 12);
      expect(find.byKey(const Key('home-total')), findsOneWidget);
    });

    testApp('an empty folder is not set up as a new sync', (tester) async {
      final folder = MemoryFolder();
      await pumpApp(
        tester,
        onboarded: false,
        overrides: [syncWith(folder)],
        seed: openOnboardingAtImport,
      );
      await tester.tap(find.byKey(const Key('ob-import-restore')));
      await settle(tester);
      await connect(tester);
      expect(find.textContaining('No synced CashRotate data'), findsOneWidget);
      expect(find.byKey(const Key('sync-create')), findsNothing);
      expect(folder.files, isEmpty);
    });
  });

  group('online preset updates', () {
    final builtIn = File('assets/presets/presets.json').readAsStringSync();
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    String withExtra() {
      final list = jsonDecode(builtIn) as List<Object?>;
      final extra = {
        ...(list.first! as Map).cast<String, Object?>(),
        'id': 'brand-new-service',
        'name': {'en': 'Brand New'},
      };
      return jsonEncode([...list, extra]);
    }

    test('a valid library is kept; the same one again is no change', () async {
      final updater = PresetUpdater(db, get: (_) async => withExtra());
      final first = await updater.update(current: null);
      expect(first.status, PresetUpdateStatus.updated);
      final stored = await updater.stored();
      expect(stored.json, withExtra());
      expect(stored.checkedAt, isNotNull);
      final again = await updater.update(current: stored.json);
      expect(again.status, PresetUpdateStatus.unchanged);
    });

    test('broken, tiny or unreachable: nothing is replaced', () async {
      final sources = <Uri>[];
      final broken = PresetUpdater(
        db,
        get: (uri) async {
          sources.add(uri);
          return '[{"id": "x"}]';
        },
      );
      expect(
        (await broken.update(current: null)).status,
        PresetUpdateStatus.failed,
      );
      expect(sources, hasLength(2), reason: 'the fallback was tried too');
      final offline = PresetUpdater(db, get: (_) => throw Exception('off'));
      expect(
        (await offline.update(current: null)).status,
        PresetUpdateStatus.failed,
      );
      expect((await broken.stored()).json, isNull);
    });

    test('checked at most once a week', () async {
      var now = DateTime.utc(2026, 11, 1);
      var calls = 0;
      final updater = PresetUpdater(
        db,
        now: () => now,
        get: (_) async {
          calls++;
          return builtIn;
        },
      );
      expect(await updater.updateIfDue(current: null), isNotNull);
      now = now.add(const Duration(days: 3));
      expect(await updater.updateIfDue(current: null), isNull);
      now = now.add(const Duration(days: 5));
      expect(await updater.updateIfDue(current: null), isNotNull);
      expect(calls, 2);
    });

    test('downloaded entries replace and extend the built-in ones', () {
      final library = PresetLibrary.withUpdate(
        PresetLibrary(PresetUpdater.parse(builtIn)!),
        (json: withExtra(), checkedAt: DateTime.utc(2026, 11, 8)),
      );
      expect(
        library.byId['brand-new-service']?.name.resolve('en'),
        'Brand New',
      );
      expect(library.presets.length, PresetUpdater.parse(builtIn)!.length + 1);
      expect(library.downloadedAt, DateTime.utc(2026, 11, 8));
    });
  });

  group('picture as a tile icon', () {
    testWidgets('cropped to a centred square of 128 px', (tester) async {
      final result = await tester.runAsync(() async {
        final square = await squareThumbnail(await png(600, 300));
        final codec = await ui.instantiateImageCodec(square!);
        final image = (await codec.getNextFrame()).image;
        return (image.width, image.height);
      });
      expect(result, (thumbnailSize, thumbnailSize));
      expect(
        await tester.runAsync(() => squareThumbnail(Uint8List(10))),
        isNull,
      );
    });

    testApp('shown on the home tile and synced as its own setting', (
      tester,
    ) async {
      late Map<String, String> ids;
      final data = await pumpApp(
        tester,
        seed: (d) async {
          ids = await d.seedItems();
          await d.settings.setTileImage(ids['rent']!, await png(8, 8));
        },
      );
      expect(
        find.descendant(of: tile(ids['rent']!), matching: find.byType(Image)),
        findsOneWidget,
      );
      final rows = await tester.runAsync(
        () => data.db.select(data.db.appSettings).get(),
      );
      expect(
        rows!.map((r) => r.key),
        contains('${SettingsRepository.tileImagePrefix}${ids['rent']}'),
      );
    });
  });
}
