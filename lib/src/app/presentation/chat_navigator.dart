import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_minimized.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_bar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_layer.dart';
import 'package:tinode_flutter_chat/src/chats/application/requested_chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_banner.dart';

/// The logged-in chat's own navigator, starting at the chat list, so chat
/// routes stay below the package's provider scope. System back pops it
/// first, then the host's routes; during a call it minimizes the call to
/// the call bar instead, and does nothing while the call rings or ends.
/// The call layer sits over it, the call bar above it and the
/// reconnecting banner below it, so they show over every chat route. It
/// opens the chats the host asks for (`TinodeChatController.openChat`)
/// over the chat list.
class ChatNavigator extends ConsumerStatefulWidget {
  const ChatNavigator({super.key});

  @override
  ConsumerState<ChatNavigator> createState() => _ChatNavigatorState();
}

class _ChatNavigatorState extends ConsumerState<ChatNavigator> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // A chat asked for before login, e.g. from the notification that
    // started the app, opens once the navigator is there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openRequested(ref.read(requestedChatControllerProvider));
      }
    });
  }

  void _openRequested(String? topic) {
    final navigator = _navigator.currentState;
    if (topic == null || navigator == null) {
      return;
    }
    ref.read(requestedChatControllerProvider.notifier).opened();
    unawaited(ChatScreen.openOn(navigator, topic));
  }

  /// System back: minimizes a call on screen, otherwise pops the chats.
  void _back() {
    final call = ref.read(callControllerProvider);
    if (call == null || ref.read(callMinimizedProvider)) {
      unawaited(_navigator.currentState?.maybePop());
    } else if (call.stage != CallStage.incoming && !call.isOver) {
      ref.read(callMinimizedProvider.notifier).minimize();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(requestedChatControllerProvider, (_, topic) {
      _openRequested(topic);
    });
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _back(),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CallBar(
                  child: Navigator(
                    key: _navigator,
                    onGenerateInitialRoutes: (_, _) => [
                      MaterialPageRoute<void>(
                        builder: (_) => const ChatListScreen(),
                      ),
                    ],
                  ),
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
