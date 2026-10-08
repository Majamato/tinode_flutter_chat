import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_footer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/outgoing_actions_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A message of the user's still in the outbox, with its status. A long
/// press offers to retry or discard it.
class OutgoingBubble extends ConsumerWidget {
  const OutgoingBubble({
    required this.topic,
    required this.clientId,
    super.key,
  });

  final String topic;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(outgoingMessageProvider(topic, clientId));
    if (message == null) {
      return const SizedBox.shrink();
    }
    final foreground = TinodeChatTheme.of(context).onOwnBubbleColor;

    return BubbleFrame(
      own: true,
      onLongPress: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) =>
              OutgoingActionsSheet(topic: topic, clientId: clientId),
        ),
      ),
      body: Text(
        message.content.text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: foreground),
      ),
      footer: BubbleFooter(
        time: message.createdAt,
        color: foreground,
        own: true,
        status: message.status,
      ),
    );
  }
}
