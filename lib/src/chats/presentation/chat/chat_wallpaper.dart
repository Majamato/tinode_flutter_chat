import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/dot_grid_painter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Behind a chat's messages: the wallpaper color with two offset grids of
/// faint dots. Records once; scrolling only re-rasterizes the cached picture.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: DotGridPainter(
          background: theme.wallpaperColor,
          dot: theme.wallpaperDotColor,
          grid: 28,
          shifts: const [Offset(4, 4), Offset(18, 18)],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
