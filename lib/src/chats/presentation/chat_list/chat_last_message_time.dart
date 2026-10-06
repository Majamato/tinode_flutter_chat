import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';

/// When the chat's last message was sent: the time today, else the date.
class ChatLastMessageTime extends ConsumerWidget {
  const ChatLastMessageTime({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(
      chatSummaryProvider(topic).select((chat) => chat?.lastMessageAt),
    );
    if (time == null) {
      return const SizedBox.shrink();
    }
    return Text(
      MaterialLocalizations.of(context).chatListTime(time),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
