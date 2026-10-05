import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_last_message_time.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_unread_badge.dart';

/// One chat in the list. Watches nothing: each part watches its own field,
/// so a new message rebuilds only the time and the unread badge.
class ChatListTile extends StatelessWidget {
  const ChatListTile({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ChatAvatar(topic: topic),
      title: ChatTitle(topic: topic),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ChatLastMessageTime(topic: topic),
          const SizedBox(height: 4),
          ChatUnreadBadge(topic: topic),
        ],
      ),
      onTap: () => ChatScreen.open(context, topic),
    );
  }
}
