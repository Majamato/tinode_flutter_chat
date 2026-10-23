import 'package:flutter/material.dart';

/// The small pointed tail of the last bubble of a run, in the bubble's
/// [color]: at its bottom left, or mirrored at its bottom right for the
/// user's own. Decoration only.
class BubbleTail extends StatelessWidget {
  const BubbleTail({required this.color, required this.own, super.key});

  static const size = Size(16, 12);

  /// How far the tail reaches below its bubble.
  static const overhang = 7.0;

  final Color color;
  final bool own;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: own,
      child: CustomPaint(size: size, painter: _TailPainter(color)),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  /// The design's tail (`M6.6 0.6 L0 11.6 L15.4 3.9 Z`), with its base
  /// reaching into the bubble: the base points sit inside the rounded
  /// corner, and inside the 4 px rim around a photo, so the tail never
  /// floats apart from its bubble.
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(7.4, 0.4)
      ..lineTo(0, 11.6)
      ..lineTo(15.4, 3.9)
      ..lineTo(11, -0.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
