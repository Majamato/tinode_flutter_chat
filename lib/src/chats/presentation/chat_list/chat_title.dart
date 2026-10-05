import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';

/// The chat's name, on one line. Used by list tiles and the chat's app bar.
class ChatTitle extends ConsumerWidget {
  const ChatTitle({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.title ?? topic),
    );
    return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
