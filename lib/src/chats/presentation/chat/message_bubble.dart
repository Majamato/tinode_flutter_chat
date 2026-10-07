import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_bubble_content.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One message: own messages on the right, others on the left. A call
/// message shows the call instead of its text.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({required this.topic, required this.seq, super.key});

  /// Bubbles take at most this share of the list's width.
  static const _maxWidthFactor = 0.78;

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(chatMessageProvider(topic, seq));
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = TinodeChatTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final own = message.isOwn;
    final foreground = own ? theme.onOwnBubbleColor : theme.onPeerBubbleColor;

    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: own ? theme.ownBubbleColor : theme.peerBubbleColor,
            borderRadius: BorderRadius.circular(theme.bubbleRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.call case final call?)
                CallBubbleContent(call: call, outgoing: own, color: foreground)
              else
                Text(
                  message.content.text,
                  style: textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              const SizedBox(height: 2),
              Text(
                MaterialLocalizations.of(context).messageTime(message.time),
                style: textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
