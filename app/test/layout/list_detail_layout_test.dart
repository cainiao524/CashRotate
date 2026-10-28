import 'dart:ui';

import 'package:cashrotate/layout/list_detail_layout.dart';
import 'package:cashrotate/layout/window_class.dart';
import 'package:flutter_test/flutter_test.dart';

DisplayFeature _vertical(
  double left,
  double width, {
  DisplayFeatureType type = DisplayFeatureType.hinge,
}) => DisplayFeature(
  bounds: Rect.fromLTWH(left, 0, width, 900),
  type: type,
  state: DisplayFeatureState.postureFlat,
);

void main() {
  group('WindowClass', () {
    test('breakpoints', () {
      expect(WindowClass.fromWidth(599.9), WindowClass.compact);
      expect(WindowClass.fromWidth(600), WindowClass.medium);
      expect(WindowClass.fromWidth(839.9), WindowClass.medium);
      expect(WindowClass.fromWidth(840), WindowClass.expanded);
    });
  });

  group('computeSplit', () {
    test('no display features: list takes ~40%, clamped', () {
      expect(
        computeSplit(width: 700, originX: 0, displayFeatures: const []),
        const PaneSplit(listWidth: 280, gap: 1),
      );
      expect(
        computeSplit(
          width: 1200,
          originX: 0,
          displayFeatures: const [],
        ).listWidth,
        400,
      );
    });

    test('hinge becomes the divider, in local coordinates', () {
      // Window 1700 wide, layout starts after an 81dp rail, hinge at 840–860.
      final split = computeSplit(
        width: 1619,
        originX: 81,
        displayFeatures: [_vertical(840, 20)],
      );
      expect(split, const PaneSplit(listWidth: 759, gap: 20));
    });

    test('zero-width fold still places the divider on the crease', () {
      final split = computeSplit(
        width: 800,
        originX: 0,
        displayFeatures: [_vertical(400, 0, type: DisplayFeatureType.fold)],
      );
      expect(split, const PaneSplit(listWidth: 400, gap: 1));
    });

    test('hinge that would leave a pane too narrow is ignored', () {
      final split = computeSplit(
        width: 700,
        originX: 0,
        displayFeatures: [_vertical(600, 10)],
      );
      expect(split.listWidth, 280);
    });

    test('horizontal fold (tabletop) and cutouts are ignored', () {
      final split = computeSplit(
        width: 800,
        originX: 0,
        displayFeatures: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 400, 800, 0),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
          DisplayFeature(
            bounds: Rect.fromLTWH(380, 0, 40, 30),
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          ),
        ],
      );
      expect(split.listWidth, 320);
    });
  });
}
