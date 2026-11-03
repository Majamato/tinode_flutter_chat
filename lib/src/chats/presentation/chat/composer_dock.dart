import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/edge_fade.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Where the composer floats: [child] over a fade of the wallpaper, 8 px
/// above the keyboard, or above the home indicator when that is more. The
/// chat's bottom bar, so its height, keyboard included, is the room the
/// messages leave under them. Only this widget reads the keyboard, so its
/// animation never rebuilds [child].
class ComposerDock extends StatelessWidget {
  const ComposerDock({required this.child, super.key});

  static const _gap = 8.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final system = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        // Nothing under the composer can be tapped through it.
        const Positioned.fill(child: AbsorbPointer()),
        Positioned.fill(
          child: EdgeFade(
            color: TinodeChatTheme.of(context).wallpaperColor,
            edge: VerticalDirection.down,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: math.max(keyboard + _gap, math.max(system, _gap)),
          ),
          child: child,
        ),
      ],
    );
  }
}
