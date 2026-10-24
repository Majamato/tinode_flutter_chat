import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_bubbles.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/dot_grid_painter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Behind the login sheet: the wallpaper colour with a 20 px dot grid,
/// and the floating bubbles. Watches nothing.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: DotGridPainter(
              background: theme.wallpaperColor,
              dot: theme.wallpaperDotColor,
              grid: 20,
              shifts: const [Offset(10, 10)],
              radius: 1.2,
            ),
          ),
        ),
        const LoginBubbles(),
      ],
    );
  }
}
