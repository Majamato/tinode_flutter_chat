import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
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
        painter: _DotsPainter(
          background: theme.wallpaperColor,
          dot: theme.wallpaperDotColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.background, required this.dot});

  static const _grid = 28.0;
  static const _radius = 1.4;

  final Color background;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (dot.a == 0) {
      return;
    }
    // One batched draw: the raster thread replays this picture every frame.
    final points = [
      for (final shift in const [Offset(4, 4), Offset(18, 18)])
        for (var y = shift.dy; y < size.height; y += _grid)
          for (var x = shift.dx; x < size.width; x += _grid) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = dot
        ..strokeWidth = _radius * 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.background != background || old.dot != dot;
}
