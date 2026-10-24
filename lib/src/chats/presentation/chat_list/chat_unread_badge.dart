import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// How many messages the user has not read, on a pill: the unread colour,
/// or the muted one for a muted chat. Nothing when none.
class ChatUnreadBadge extends ConsumerWidget {
  const ChatUnreadBadge({required this.topic, super.key});

  static const _height = 22.0;

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (unread, muted) = ref.watch(
      chatSummaryProvider(
        topic,
      ).select((chat) => (chat?.unread ?? 0, chat?.muted ?? false)),
    );
    if (unread == 0) {
      return const SizedBox.shrink();
    }
    final theme = TinodeChatTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: _height),
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: muted ? theme.mutedBadgeColor : theme.unreadBadgeColor,
      ),
      child: Text(
        '$unread',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: theme.onUnreadBadgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
