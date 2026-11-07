import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// Back to the chat list, with how many messages wait unread in the other
/// chats. Watches only that count.
class ChatBackButton extends ConsumerWidget {
  const ChatBackButton({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(otherUnreadProvider(topic));
    return TinodeBackButton(
      tooltip: TinodeChatStrings.of(context).backToChats,
      badge: unread > 0 ? _UnreadBadge(unread) : null,
    );
  }
}

/// How many messages wait unread, on a pill. Watches nothing.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge(this.unread);

  final int unread;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.unreadBadgeColor,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          '$unread',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: theme.onUnreadBadgeColor,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
