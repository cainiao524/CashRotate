import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  testApp('first launch: pick, fill, summary, then the app', (tester) async {
    await pumpApp(tester, onboarded: false);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const Key('ob-next')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ob-import-pick')));
    await pumpUntil(tester, find.byKey(const Key('picker-search')));

    expect(find.text('Nothing selected'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('picker-search')), 'netflix');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('preset-netflix')));
    await tester.enterText(find.byKey(const Key('picker-search')), '房租');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('preset-template-rent')));
    await settle(tester);
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ob-next')));
    await settle(tester);
    expect(find.text('Amounts and dates'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('batch-amount-netflix')),
      '390',
    );
    await settle(tester);

    // Same charge date for both rows at once.
    await tester.tap(find.byKey(const Key('batch-select-all')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('batch-apply-date')));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.textContaining('Charge date: To fill in'), findsNothing);

    await tester.tap(find.byKey(const Key('ob-next')));
    await settle(tester, frames: 10);
    expect(find.text("You're all set"), findsOneWidget);
    expect(find.text(r'NT$390'), findsOneWidget, reason: 'rent was left blank');
    expect(find.text('1 item still needs details'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ob-finish')));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('1 item still needs details'),
      findsOneWidget,
      reason: 'home banner',
    );
  });

  testApp('leaving halfway resumes at the same step with the same rows', (
    tester,
  ) async {
    await pumpApp(
      tester,
      onboarded: false,
      seed: (d) => d.settings.setJson(SettingsRepository.onboardingDraftKey, {
        'step': 2,
        'rows': [
          {
            'key': 'netflix',
            'name': 'Netflix',
            'presetId': 'netflix',
            'type': 'subscription',
            'cycleUnit': 'month',
            'cycleEvery': 1,
            'currency': 'TWD',
            'category': 'streaming',
            'remindDays': [3],
          },
        ],
      }),
    );
    expect(find.text('Which of these do you pay for?'), findsOneWidget);
    await pumpUntil(tester, find.byKey(const Key('picker-count')));
    expect(find.text('1 selected'), findsOneWidget);
  });

  testApp('picker shows local services for the region only', (tester) async {
    await pumpApp(tester, onboarded: false, region: 'HK');
    await tester.tap(find.byKey(const Key('ob-next')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('ob-import-pick')));
    await pumpUntil(tester, find.byKey(const Key('picker-search')));
    await tester.enterText(find.byKey(const Key('picker-search')), '中華電信');
    await settle(tester);
    expect(
      find.byKey(const ValueKey('preset-tw-chunghwa-telecom')),
      findsNothing,
    );
    await tester.enterText(find.byKey(const Key('picker-search')), 'csl');
    await settle(tester);
    expect(find.byKey(const ValueKey('preset-hk-csl')), findsOneWidget);
  });
}
