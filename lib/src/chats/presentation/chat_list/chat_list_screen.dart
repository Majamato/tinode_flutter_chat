import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/log_out_button.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_chat_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The user's chats, newest first, and the button that starts a new one.
/// Watches nothing itself.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TinodeChatStrings.of(context).chatListTitle),
        actions: const [LogOutButton()],
      ),
      body: const ChatListBody(),
      floatingActionButton: const NewChatButton(),
    );
  }
}
