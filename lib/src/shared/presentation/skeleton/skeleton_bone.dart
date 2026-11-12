import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One shape of a skeleton, standing in for an avatar, a line of text or a
/// box, in the theme's `skeletonColor` unless given a [color]. Put the
/// bones of a skeleton under one `SkeletonShimmer`. Watches nothing.
class SkeletonBone extends StatelessWidget {
  /// A box [width] × [height] with corners of [radius].
  const SkeletonBone.rect({
    required double this.width,
    required this.height,
    this.radius = 8,
    this.color,
    super.key,
  }) : widthFactor = null,
       circle = false;

  /// A box as wide as its parent allows, [height] tall, with corners of
  /// [radius].
  const SkeletonBone.fill({
    required this.height,
    this.radius = 8,
    this.color,
    super.key,
  }) : width = null,
       widthFactor = 1,
       circle = false;

  /// A circle [diameter] across, for an avatar or an icon.
  const SkeletonBone.circle(double diameter, {this.color, super.key})
    : width = diameter,
      height = diameter,
      radius = 0,
      widthFactor = null,
      circle = true;

  /// A rounded line of text, [width] wide, or [widthFactor] of its parent's
  /// width when [width] is null.
  const SkeletonBone.line({
    this.width,
    this.widthFactor = 1,
    this.height = 12,
    this.color,
    super.key,
  }) : radius = height / 2,
       circle = false;

  final double? width;

  /// The part of the parent's width taken when [width] is null.
  final double? widthFactor;
  final double height;
  final double radius;
  final bool circle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bone = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? TinodeChatTheme.of(context).skeletonColor,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
    if (width != null) {
      return bone;
    }
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: bone,
    );
  }
}
