import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_chat_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/size_reporter.dart';

/// The user's chats, newest first, scrolling under a frosted header with
/// the search for people and groups, and the button that starts a new
/// chat. [inTabs] when it is the chats tab: the settings are then a tab
/// rather than the header's menu, and the button sits above the tab bar.
/// Watches nothing itself.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({this.inTabs = false, super.key});

  final bool inTabs;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  /// The header's height, so the list can scroll out from under it.
  final _headerHeight = ValueNotifier<double>(0);

  @override
  void dispose() {
    _headerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ChatListBody(topInset: _headerHeight)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizeReporter(
              height: _headerHeight,
              child: ChatListHeader(accountMenu: !widget.inTabs),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.inTabs
          // 18 px from the side and 20 px above the tab bar.
          ? const Padding(
              padding: EdgeInsetsDirectional.only(end: 2, bottom: 4),
              child: NewChatButton(),
            )
          : const NewChatButton(),
    );
  }
}
