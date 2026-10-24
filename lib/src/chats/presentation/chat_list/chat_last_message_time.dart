import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// When the chat's last message was sent: the time today, "Yesterday",
/// else the date. In the link colour while there is something unread, in a
/// chat that isn't muted.
class ChatLastMessageTime extends ConsumerWidget {
  const ChatLastMessageTime({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (time, highlighted) = ref.watch(
      chatSummaryProvider(topic).select(
        (chat) => (
          chat?.lastMessageAt,
          chat != null && chat.unread > 0 && !chat.muted,
        ),
      ),
    );
    if (time == null) {
      return const SizedBox.shrink();
    }
    return Text(
      MaterialLocalizations.of(
        context,
      ).chatListTime(time, yesterday: TinodeChatStrings.of(context).yesterday),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: highlighted
            ? TinodeChatTheme.of(context).linkColor
            : Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
