import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/skeleton_bubble.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A few bubbles' bones above the oldest message while older ones load.
class OlderMessagesIndicator extends ConsumerWidget {
  const OlderMessagesIndicator({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      chatControllerProvider(topic).select((s) => s.loadingOlder),
    );
    if (!loading) {
      return const SizedBox.shrink();
    }

    final chat = TinodeChatTheme.of(context);
    return SkeletonShimmer(
      highlightColor: chat.wallpaperColor.withValues(alpha: 0.6),
      child: Padding(
        padding: EdgeInsets.only(bottom: chat.newRunGap),
        child: Column(
          spacing: chat.sameRunGap,
          children: [
            const SkeletonBubble(own: false, width: 0.62, height: 36),
            const SkeletonBubble(own: false, width: 0.84, height: 56),
            Padding(
              padding: EdgeInsets.only(top: chat.newRunGap - chat.sameRunGap),
              child: const SkeletonBubble(own: true, width: 0.48, height: 36),
            ),
          ],
        ),
      ),
    );
  }
}
