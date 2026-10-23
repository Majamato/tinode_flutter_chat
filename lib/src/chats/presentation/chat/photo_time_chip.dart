import 'package:flutter/material.dart';

/// The time and status over a photo with no caption: white on a dark,
/// translucent pill, so they read on any photo.
class PhotoTimeChip extends StatelessWidget {
  const PhotoTimeChip({required this.child, super.key});

  /// The footer, in white.
  static const Color footerColor = Colors.white;

  static const _background = Color(0x73000000);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: _background,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: child,
      ),
    );
  }
}
