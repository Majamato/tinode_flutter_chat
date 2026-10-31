import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_chat_button.dart';

/// The user's chats, newest first, under a header with
/// the search for people and groups, and the button that starts a new
/// chat. [inTabs] when it is the chats tab: the settings are then a tab
/// rather than the header's menu, and the button sits above the tab bar.
/// Watches nothing itself.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({this.inTabs = false, super.key});

  final bool inTabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatListHeader(accountMenu: !inTabs),
      body: const ChatListBody(),
      floatingActionButton: inTabs
          // 18 px from the side and 20 px above the tab bar.
          ? const Padding(
              padding: EdgeInsetsDirectional.only(end: 2, bottom: 4),
              child: NewChatButton(),
            )
          : const NewChatButton(),
    );
  }
}
