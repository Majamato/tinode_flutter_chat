import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_message.dart';
import 'package:tinode_flutter_chat/src/search/presentation/found_sender_name.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_snippet_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';

/// One found message: its sender, its time and the words around the match.
/// A tap goes back to the chat, which scrolls to the message. Watches
/// nothing itself.
class FoundMessageTile extends ConsumerWidget {
  const FoundMessageTile({required this.found, super.key});

  final FoundMessage found;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = found.topic;
    return ListTile(
      title: FoundSenderName(topic: topic, from: found.from),
      subtitle: MessageSnippetText(snippet: found.snippet),
      trailing: Text(
        MaterialLocalizations.of(context).chatListTime(found.time),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        unawaited(
          ref.read(chatControllerProvider(topic).notifier).reveal(found.seq),
        );
        ChatScreen.backTo(context, topic);
      },
    );
  }
}
