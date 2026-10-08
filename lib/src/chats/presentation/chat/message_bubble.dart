import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_footer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_bubble_content.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_actions_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One numbered message. A call message shows the call instead of its
/// text. A long press offers to delete it.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({required this.topic, required this.seq, super.key});

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(chatMessageProvider(topic, seq));
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = TinodeChatTheme.of(context);
    final own = message.isOwn;
    final foreground = own ? theme.onOwnBubbleColor : theme.onPeerBubbleColor;

    return BubbleFrame(
      own: own,
      onLongPress: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => MessageActionsSheet(topic: topic, seq: seq),
        ),
      ),
      body: switch (message.call) {
        final call? => CallBubbleContent(
          call: call,
          outgoing: own,
          color: foreground,
        ),
        null => Text(
          message.content.text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: foreground),
        ),
      },
      footer: BubbleFooter(time: message.time, color: foreground, own: own),
    );
  }
}
