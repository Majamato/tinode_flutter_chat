import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_layer.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_banner.dart';

/// The logged-in chat's own navigator, starting at the chat list, so chat
/// routes stay below the package's provider scope. System back pops it
/// first, then the host's routes; during a call it does nothing. The call
/// layer sits over it and the reconnecting banner below it, so both show
/// over every chat route.
class ChatNavigator extends ConsumerStatefulWidget {
  const ChatNavigator({super.key});

  @override
  ConsumerState<ChatNavigator> createState() => _ChatNavigatorState();
}

class _ChatNavigatorState extends ConsumerState<ChatNavigator> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) {
        if (ref.read(callControllerProvider) == null) {
          unawaited(_navigator.currentState?.maybePop());
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Navigator(
                  key: _navigator,
                  onGenerateInitialRoutes: (_, _) => [
                    MaterialPageRoute<void>(
                      builder: (_) => const ChatListScreen(),
                    ),
                  ],
                ),
                const CallLayer(),
              ],
            ),
          ),
          const ReconnectingBanner(),
        ],
      ),
    );
  }
}
