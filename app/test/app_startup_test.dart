import 'package:cashrotate/app.dart';
import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate/platform/keystore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _BrokenKeystore implements DatabaseKeySource {
  int calls = 0;

  @override
  Future<String> databaseKeyHex() async {
    calls++;
    throw StateError('Keystore unavailable');
  }
}

void main() {
  testWidgets('a database that cannot open shows an error with retry', (
    tester,
  ) async {
    final keystore = _BrokenKeystore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseKeySourceProvider.overrideWithValue(keystore)],
        child: const CashRotateApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your data could not be opened'), findsOneWidget);
    expect(find.textContaining('Keystore unavailable'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(keystore.calls, 2);
  });
}
