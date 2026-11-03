import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_indicator.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The line under the chat's title: a small spinner and "Reconnecting…" in
/// `outline` while the link is being restored (typing and presence are
/// stale meanwhile), else who is typing, else "online" in the link colour
/// for a direct chat whose peer is, else nothing.
class ChatStatus extends ConsumerWidget {
  const ChatStatus({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(reconnectingNoticeProvider)) {
      return const _Reconnecting();
    }
    if (ref.watch(anyoneTypingProvider(topic))) {
      return TypingIndicator(topic: topic);
    }
    final online = ref.watch(
      chatSummaryProvider(topic).select(
        (chat) => chat != null && chat.kind == TopicKind.direct && chat.online,
      ),
    );
    if (!online) {
      return const SizedBox.shrink();
    }
    return Text(
      TinodeChatStrings.of(context).online,
      maxLines: 1,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: TinodeChatTheme.of(context).linkColor,
      ),
    );
  }
}

class _Reconnecting extends StatelessWidget {
  const _Reconnecting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          SizedBox.square(
            dimension: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
          ),
          Flexible(
            child: Text(
              TinodeChatStrings.of(context).reconnecting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
