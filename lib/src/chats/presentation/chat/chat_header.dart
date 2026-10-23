import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_back_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_info_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';

/// The frosted bar over a chat: back (with the other chats' unread
/// count), the chat's avatar, name and who is typing, then message search
/// and the call buttons. Tapping the name opens the chat's info. Watches
/// nothing itself.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({required this.topic, super.key});

  static const _height = 56.0;

  final String topic;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      toolbarHeight: _height,
      titleSpacing: 4,
      centerTitle: false,
      flexibleSpace: const FrostedBar(child: SizedBox.expand()),
      title: Row(
        children: [
          ChatBackButton(topic: topic),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => ChatInfoScreen.open(context, topic),
              child: Row(
                children: [
                  ChatAvatar(topic: topic, radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle.merge(
                          style: textTheme.titleMedium,
                          child: ChatTitle(topic: topic),
                        ),
                        TypingIndicator(topic: topic),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        MessageSearchButton(topic: topic),
        CallButton(topic: topic, video: true),
        CallButton(topic: topic, video: false),
      ],
    );
  }
}
