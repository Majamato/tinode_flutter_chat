import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/attachment_message_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/call_bubble_content.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_actions_sheet.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_footer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/sender_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/sender_name.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One numbered message. A call message shows the call instead of its
/// text, and a message with images or files shows them above its
/// caption. In a group, others' messages carry the sender's name and
/// avatar at the edges of a run. A long press offers to delete it.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({required this.topic, required this.seq, super.key});

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(chatMessageProvider(topic, seq));
    final (fromMember, startsRun) = ref.watch(
      messageSenderProvider(
        topic,
        seq,
      ).select((s) => (s != null, s?.showName ?? false)),
    );
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = TinodeChatTheme.of(context);
    final own = message.isOwn;
    final foreground = own ? theme.onOwnBubbleColor : theme.onPeerBubbleColor;

    final frame = BubbleFrame(
      own: own,
      onLongPress: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => MessageActionsSheet(topic: topic, seq: seq),
        ),
      ),
      header: startsRun ? SenderName(topic: topic, seq: seq) : null,
      body: switch (message) {
        ChatMessage(:final call?) => CallBubbleContent(
          call: call,
          outgoing: own,
          color: foreground,
        ),
        ChatMessage(:final attachments) when attachments.isNotEmpty =>
          AttachmentMessageBody(
            attachments: attachments,
            caption: message.caption,
            color: foreground,
          ),
        _ => Text(
          message.caption,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: foreground),
        ),
      },
      footer: MessageFooter(
        topic: topic,
        seq: seq,
        time: message.time,
        color: foreground,
        own: own,
      ),
    );
    if (!fromMember) {
      return frame;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SenderAvatar(topic: topic, seq: seq),
        Expanded(child: frame),
      ],
    );
  }
}
