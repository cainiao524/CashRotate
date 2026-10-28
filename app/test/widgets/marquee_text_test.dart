import 'package:cashrotate/widgets/marquee_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _long = 'A very long subscription name that cannot fit in the space';

Widget _host(
  String text, {
  double width = 120,
  bool disableAnimations = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Material(
      child: Center(
        child: SizedBox(width: width, child: MarqueeText(text)),
      ),
    ),
  ),
);

double _offsetX(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(MarqueeText),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getTranslation()
    .x;

void main() {
  testWidgets('text that fits is static', (tester) async {
    await tester.pumpWidget(_host('Netflix', width: 300));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Netflix'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MarqueeText),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('overflowing text pauses, scrolls to the end, and comes back', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_long));
    await tester.pump(); // post-frame callback measures and starts the loop
    expect(_offsetX(tester), 0);

    final overflow = tester.getSize(find.text(_long)).width - 120;
    final travel = Duration(
      milliseconds: (overflow / MarqueeText.speed * 1000).round(),
    );
    const half = Duration(milliseconds: 750);

    await tester.pump(half);
    expect(_offsetX(tester), 0, reason: 'still in the opening pause');

    // Each step below advances one pause + one travel: mid-pause to mid-pause.
    await tester.pump(MarqueeText.pause + travel); // pausing at the end
    expect(_offsetX(tester), moreOrLessEquals(-overflow, epsilon: 0.5));

    await tester.pump(
      MarqueeText.pause + travel,
    ); // back at the start, pausing again
    expect(_offsetX(tester), moreOrLessEquals(0, epsilon: 0.5));

    // Ends of the line: full text is shown, never an ellipsis.
    final text = tester.widget<Text>(find.text(_long));
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, 1);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('scroll distance equals the overflow, no more', (tester) async {
    await tester.pumpWidget(_host(_long));
    await tester.pump();
    final textWidth = tester.getSize(find.text(_long)).width;
    final overflow = textWidth - 120;
    final travel = Duration(
      milliseconds: (overflow / MarqueeText.speed * 1000).round(),
    );
    await tester.pump(
      MarqueeText.pause + travel + const Duration(milliseconds: 100),
    );
    expect(_offsetX(tester), moreOrLessEquals(-overflow, epsilon: 0.5));
  });

  testWidgets('with animations disabled, overflowing text wraps instead', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_long, disableAnimations: true));
    await tester.pump(const Duration(seconds: 3));
    final text = tester.widget<Text>(find.text(_long));
    expect(text.softWrap, isTrue);
    expect(text.maxLines, isNull);
    expect(tester.getSize(find.text(_long)).height, greaterThan(30));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('stops animating once the text fits again', (tester) async {
    await tester.pumpWidget(_host(_long));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(_host(_long, width: 2000));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
