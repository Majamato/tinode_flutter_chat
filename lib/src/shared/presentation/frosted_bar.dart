import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The frosted glass behind translucent bars: a blur of [sigma] and a
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

/// A translucent bar that blurs what scrolls under it: the composer. A
/// hairline marks its [edge] towards the content.
class FrostedBar extends StatelessWidget {
  const FrostedBar({
    required this.child,
    this.edge = AxisDirection.down,
    super.key,
  });

  /// The blur and the saturation boost behind the glass.
  static final ImageFilter _filter = glassFilter(22);

  final Widget child;

  /// Where the content is: down for a header, up for a bottom bar.
  final AxisDirection edge;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final hairline = BorderSide(color: theme.glassEdgeColor, width: 0.5);
    return ClipRect(
      child: BackdropFilter(
        filter: _filter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.glassColor,
            border: Border(
              bottom: edge == AxisDirection.down ? hairline : BorderSide.none,
              top: edge == AxisDirection.up ? hairline : BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
