import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/skeleton_bubble.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Bubbles' bones while a chat's messages load, from the composer up, in
/// runs on both sides, padded as the messages are: by the bars (the
/// [MediaQuery] padding) and the list's own room. Watches nothing.
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  /// Newest first: whether it is own, its width of the widest a bubble
  /// grows, its height, and whether a new run starts above it. More than
  /// any screen shows.
  static const _bubbles = [
    (true, 0.42, 36.0, false),
    (true, 0.7, 56.0, true),
    (false, 0.56, 36.0, false),
    (false, 0.86, 56.0, false),
    (false, 0.38, 36.0, true),
    (true, 0.62, 36.0, true),
    (false, 0.74, 76.0, false),
    (false, 0.46, 36.0, true),
    (true, 0.52, 56.0, false),
    (true, 0.34, 36.0, true),
    (false, 0.66, 36.0, true),
    (true, 0.8, 76.0, true),
    (false, 0.5, 36.0, false),
    (false, 0.7, 56.0, true),
  ];

  @override
  Widget build(BuildContext context) {
    final chat = TinodeChatTheme.of(context);
    final padding = MediaQuery.paddingOf(context);
    return SkeletonShimmer(
      highlightColor: chat.wallpaperColor.withValues(alpha: 0.6),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ListView.builder(
          reverse: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            10,
            padding.top + 4,
            10,
            padding.bottom + 12,
          ),
          itemCount: _bubbles.length,
          itemBuilder: (context, index) {
            final (own, width, height, runStart) = _bubbles[index];
            return Padding(
              padding: EdgeInsets.only(
                top: runStart ? chat.newRunGap : chat.sameRunGap,
              ),
              child: SkeletonBubble(own: own, width: width, height: height),
            );
          },
        ),
      ),
    );
  }
}
