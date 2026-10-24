import 'dart:ui' show PointMode;

import 'package:flutter/rendering.dart';

/// A [background] with grids of [dot]s every [grid] pixels, one per
/// [shifts] offset: the chat's wallpaper and the login backdrop. All dots
/// go in one batched draw, so a `RepaintBoundary` around it records once.
class DotGridPainter extends CustomPainter {
  DotGridPainter({
    required this.background,
    required this.dot,
    required this.grid,
    required this.shifts,
    this.radius = 1.4,
  });

  final Color background;
  final Color dot;
  final double grid;
  final List<Offset> shifts;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (dot.a == 0) {
      return;
    }
    final points = [
      for (final shift in shifts)
        for (var y = shift.dy; y < size.height; y += grid)
          for (var x = shift.dx; x < size.width; x += grid) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = dot
        ..strokeWidth = radius * 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.background != background ||
      old.dot != dot ||
      old.grid != grid ||
      old.radius != radius ||
      old.shifts != shifts;
}
