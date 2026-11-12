import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A bubble's bone: on the end side in the own bubbles' colour when [own],
/// else on the start side in the others', [width] of the widest a bubble
/// grows and [height] tall. Put it under a `SkeletonShimmer`. Watches
/// nothing.
class SkeletonBubble extends StatelessWidget {
  const SkeletonBubble({
    required this.own,
    required this.width,
    required this.height,
    super.key,
  });

  /// The widest a bubble grows, of the list's width.
  static const maxWidth = 0.78;

  final bool own;

  /// The part of [maxWidth] it takes.
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final chat = TinodeChatTheme.of(context);
    return Align(
      alignment: own
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: maxWidth * width,
        child: SkeletonBone.fill(
          height: height,
          radius: chat.bubbleRadius,
          color: own ? chat.ownBubbleColor : chat.peerBubbleColor,
        ),
      ),
    );
  }
}
