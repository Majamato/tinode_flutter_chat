import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// How many messages the user has not read; nothing when none.
class ChatUnreadBadge extends ConsumerWidget {
  const ChatUnreadBadge({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.unread ?? 0),
    );
    if (unread == 0) {
      return const SizedBox.shrink();
    }
    final theme = TinodeChatTheme.of(context);

    return Badge.count(
      count: unread,
      backgroundColor: theme.unreadBadgeColor,
      textColor: theme.onUnreadBadgeColor,
    );
  }
}
