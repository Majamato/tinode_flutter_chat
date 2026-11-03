import 'package:flutter/widgets.dart';

/// Marks the bodies below it as running under floating glass at their
/// bottom (the tab bar): their bottom padding is the glass's room, and the
/// glass blurs what is under it, so they paint only a light veil there,
/// not a solid fade. Touches there still stop. Watches nothing.
class GlassBelow extends InheritedWidget {
  const GlassBelow({required super.child, super.key});

  /// Whether floating glass covers the bottom of the body at [context].
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GlassBelow>() != null;

  @override
  bool updateShouldNotify(GlassBelow oldWidget) => false;
}
