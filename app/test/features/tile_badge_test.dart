import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'home_tiles_test.dart' show tile;

void main() {
  group('TileBadge', () {
    test('reads back what it wrote; junk is ignored', () {
      const badge = TileBadge(text: 'B站', color: '#1D4ED8');
      expect(TileBadge.fromJson(badge.toJson()), badge);
      expect(TileBadge.fromJson({'text': '  ', 'color': 'blue'}), isNull);
      expect(TileBadge.fromJson({'color': '#B91C1C'})?.text, isNull);
      expect(TileBadge.fromJson('B站'), isNull);
    });
  });

  testApp('own badge text and colour on the tile and in the list', (
    tester,
  ) async {
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
    );
    final netflix = ids['netflix']!;
    await tester.longPress(tile(netflix));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('badge-text')));
    await tester.enterText(find.byKey(const Key('badge-text')), 'NF');
    await settle(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('badge-color-#B91C1C')),
    );
    await tester.tap(find.byKey(const ValueKey('badge-color-#B91C1C')));
    await settle(tester);
    await tester.binding.handlePopRoute(); // close the sheet (back)
    await settle(tester);

    expect(
      find.descendant(of: tile(netflix), matching: find.text('NF')),
      findsOneWidget,
    );
    final settings = await tester.runAsync(
      () => data.settings.read(
        const UserSettings(mainCurrency: Currency.twd, region: 'TW'),
      ),
    );
    expect(
      settings!.tileBadges[netflix],
      const TileBadge(text: 'NF', color: '#B91C1C'),
    );

    await tester.tap(find.byIcon(Icons.event_repeat_outlined));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('item-$netflix')),
        matching: find.text('NF'),
      ),
      findsOneWidget,
    );
  });

  testApp('reset goes back to the initial', (tester) async {
    late Map<String, String> ids;
    await pumpApp(
      tester,
      seed: (d) async {
        ids = await d.seedItems();
        await d.settings.setTileBadge(
          ids['rent']!,
          const TileBadge(text: '房租'),
        );
      },
    );
    final rent = ids['rent']!;
    expect(
      find.descendant(of: tile(rent), matching: find.text('房租')),
      findsOneWidget,
    );
    await tester.longPress(tile(rent));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('badge-reset')));
    await tester.tap(find.byKey(const Key('badge-reset')));
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(
      find.descendant(of: tile(rent), matching: find.text('R')),
      findsOneWidget,
    );
  });
}
