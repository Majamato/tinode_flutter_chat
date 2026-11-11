import 'package:flutter/material.dart';

/// The time and status over a photo with no caption: white on a dark,
/// translucent pill, so they read on any photo, even a white one.
class PhotoTimeChip extends StatelessWidget {
  const PhotoTimeChip({required this.child, super.key});

  /// The footer, in white.
  static const Color footerColor = Colors.white;

  /// 60 % black: white passes 4.5:1 on it over a white photo.
  static const background = Color(0x99000000);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: background,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: child,
      ),
    );
  }
}
