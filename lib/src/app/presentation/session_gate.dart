import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/app/presentation/chat_navigator.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/presentation/connecting_view.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/session_error_view.dart';

/// Picks the screen for the session's phase; rebuilds only when the phase
/// changes.
///
/// It sits above the chat's navigator on purpose: Riverpod pauses
/// consumers on routes covered by another route, so a gate inside the
/// navigator would miss a lost connection while a chat is open. Here,
/// losing the session removes the navigator and every chat route with it.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(
      sessionControllerProvider.select(SessionPhase.of),
    )) {
      SessionPhase.connecting => const ConnectingView(),
      SessionPhase.awaitingLogin => const LoginScreen(),
      SessionPhase.loggedIn => const ChatNavigator(),
      SessionPhase.failed => const SessionErrorView(),
    };
  }
}
