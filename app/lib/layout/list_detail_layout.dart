import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';

/// Where the list pane ends and the detail pane begins, in local coordinates.
@immutable
class PaneSplit {
  const PaneSplit({required this.listWidth, required this.gap});

  final double listWidth;

  /// Width the divider occupies; equals the hinge width when one is present.
  final double gap;

  @override
  bool operator ==(Object other) =>
      other is PaneSplit && other.listWidth == listWidth && other.gap == gap;

  @override
  int get hashCode => Object.hash(listWidth, gap);

  @override
  String toString() => 'PaneSplit(listWidth: $listWidth, gap: $gap)';
}

/// Panes narrower than this are unusable, so a hinge that would create one is ignored.
const minPaneWidth = 280.0;

/// Computes the list/detail split for a layout [width] wide whose left edge
/// sits at [originX] in window coordinates.
///
/// A vertical hinge or fold inside the layout becomes the divider so no
/// content lands on the crease; otherwise the list takes about 40%.
PaneSplit computeSplit({
  required double width,
  required double originX,
  required Iterable<DisplayFeature> displayFeatures,
}) {
  for (final feature in displayFeatures) {
    if (feature.type != DisplayFeatureType.hinge &&
        feature.type != DisplayFeatureType.fold) {
      continue;
    }
    final bounds = feature.bounds;
    // Horizontal folds mean tabletop posture, which is out of v1 scope.
    if (bounds.width > bounds.height) continue;
    final left = bounds.left - originX;
    final right = bounds.right - originX;
    if (left >= minPaneWidth && width - right >= minPaneWidth) {
      return PaneSplit(listWidth: left, gap: (right - left).clamp(1, width));
    }
  }
  return PaneSplit(listWidth: (width * 0.4).clamp(minPaneWidth, 400), gap: 1);
}

/// List and detail side by side, with the divider kept off any hinge.
class ListDetailLayout extends StatefulWidget {
  const ListDetailLayout({super.key, required this.list, required this.detail});

  final Widget list;
  final Widget detail;

  @override
  State<ListDetailLayout> createState() => _ListDetailLayoutState();
}

class _ListDetailLayoutState extends State<ListDetailLayout> {
  // Window x of this layout's left edge. Hinges are reported in window
  // coordinates, so it is measured after layout and corrected on the next frame.
  double _originX = 0;

  void _measureOrigin(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final x = box.localToGlobal(Offset.zero).dx;
    if (x != _originX) setState(() => _originX = x);
  }

  @override
  Widget build(BuildContext context) {
    final features = MediaQuery.displayFeaturesOf(context);
    if (features.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(_measureOrigin);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = computeSplit(
          width: constraints.maxWidth,
          originX: _originX,
          displayFeatures: features,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: split.listWidth, child: widget.list),
            SizedBox(
              width: split.gap,
              child: const VerticalDivider(width: 1, thickness: 1),
            ),
            Expanded(child: widget.detail),
          ],
        );
      },
    );
  }
}
