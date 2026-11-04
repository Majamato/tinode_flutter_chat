import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The frosted glass behind translucent surfaces: a blur of [sigma] and a
/// saturation boost of 1.6.
ImageFilter glassFilter(double sigma) => ImageFilter.compose(
  outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  inner: const ColorFilter.matrix(_saturate),
);

/// Saturation 1.6, keeping luminance.
const _saturate = <double>[
  1.4722, -0.4290, -0.0432, 0, 0, //
  -0.1278, 1.1710, -0.0432, 0, 0, //
  -0.1278, -0.4290, 1.5568, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// A floating piece of glass: [child] on `glassColor` over a blur of what
/// lies behind, with a hairline edge and a soft shadow, deeper when
/// [raised]. A stadium (a circle when square) unless [radius] rounds it
/// less. [tonal] glass is solid `primaryContainer`, as the palette has it
/// in light and dark, with no blur or edge: a main action's button.
///
/// The blur joins the nearest [BackdropGroup], so all the glass of a
/// screen reads what is behind it once. Glass that overlaps other glass
/// must not share a group. Watches nothing.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.radius,
    this.raised = false,
    this.tonal = false,
    super.key,
  });

  /// The blur and the saturation boost behind every piece of glass.
  static final ImageFilter filter = glassFilter(22);

  /// Fully round: clamped to half the shorter side.
  static const _stadium = Radius.circular(999);

  final Widget child;

  /// The corners' radius; null for a stadium.
  final double? radius;

  /// A larger, darker shadow, for glass that floats high over the content
  /// (the tab bar).
  final bool raised;

  /// Filled with `primaryContainer` rather than see-through, so a main
  /// action stands out from the glass around it.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final corners = BorderRadius.all(
      radius == null ? _stadium : Radius.circular(radius!),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: [
          if (raised)
            BoxShadow(
              color: theme.glassShadowColor.withValues(
                alpha: (theme.glassShadowColor.a * 2).clamp(0, 1),
              ),
              blurRadius: 34,
              spreadRadius: -10,
              offset: const Offset(0, 12),
            )
          else
            BoxShadow(
              color: theme.glassShadowColor,
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: corners,
        child: tonal
            // A Material, so the button's splash paints on it.
            ? Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: child,
              )
            : BackdropFilter.grouped(
                filter: filter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.glassColor,
                    borderRadius: corners,
                    border: Border.all(color: theme.glassEdgeColor, width: 0.5),
                  ),
                  child: child,
                ),
              ),
      ),
    );
  }
}
