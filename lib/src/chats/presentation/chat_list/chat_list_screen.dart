import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';

/// The user's chats, newest first, scrolling under the glass app bar with
/// the new chat button and the search for people and groups. [inTabs] when
/// it is the chats tab: the settings are then a tab rather than the
/// header's menu. Watches nothing itself.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({this.inTabs = false, super.key});

  final bool inTabs;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: const TinodeChatListScreen(),
      appBar: ChatListHeader(accountMenu: !inTabs),
      body: const ChatListBody(),
    );
  }
}
