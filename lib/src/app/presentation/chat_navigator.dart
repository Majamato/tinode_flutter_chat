import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_banner.dart';

/// The logged-in chat's own navigator, starting at the chat list, so chat
/// routes stay below the package's provider scope. System back pops it
/// first, then the host's routes. The reconnecting banner sits below it,
/// so it shows over every chat route.
class ChatNavigator extends StatefulWidget {
  const ChatNavigator({super.key});

  @override
  State<ChatNavigator> createState() => _ChatNavigatorState();
}

class _ChatNavigatorState extends State<ChatNavigator> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigator.currentState?.maybePop(),
      child: Column(
        children: [
          Expanded(
            child: Navigator(
              key: _navigator,
              onGenerateInitialRoutes: (_, _) => [
                MaterialPageRoute<void>(builder: (_) => const ChatListScreen()),
              ],
            ),
          ),
          const ReconnectingBanner(),
        ],
      ),
    );
  }
}
