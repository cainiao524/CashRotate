import 'package:material_ui/material_ui.dart';

/// Layout is chosen by window width in dp, never by device model.
enum WindowClass {
  /// < 600dp: phones, folded outer screens. Bottom navigation, single pane.
  compact,

  /// 600–840dp: unfolded inner screens, small tablets. Rail + list/detail.
  medium,

  /// ≥ 840dp: tablets in landscape. Rail + list/detail + card dashboard.
  expanded;

  static WindowClass fromWidth(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };

  static WindowClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isTwoPane => this != compact;
}
