import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer_area.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_info_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_button.dart';

/// One chat: its messages, who is typing, message search, the call buttons
/// and, where the user may post, the composer. Tapping the title opens the
/// chat's info. Watches nothing itself.
class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.topic, super.key});

  /// The name of every chat's route; its arguments are the topic.
  static const routeName = 'tinode_chat';

  /// The route that shows the chat named [topic].
  static Route<void> route(String topic) => MaterialPageRoute<void>(
    settings: RouteSettings(name: routeName, arguments: topic),
    builder: (_) => ChatScreen(topic: topic),
  );

  /// Pushes the chat named [topic] onto the chat's navigator.
  static Future<void> open(BuildContext context, String topic) =>
      Navigator.of(context).push(route(topic));

  /// Opens the chat named [topic] right over the chat list, closing the
  /// screens in between, e.g. the search that found it.
  static Future<void> openOverList(BuildContext context, String topic) =>
      openOn(Navigator.of(context), topic);

  /// Like [openOverList], on the chat's own [navigator].
  static Future<void> openOn(NavigatorState navigator, String topic) {
    navigator.popUntil((route) => route.isFirst);
    return navigator.push(route(topic));
  }

  /// Goes back to the open chat named [topic] below the current screen,
  /// e.g. from its message search.
  static void backTo(BuildContext context, String topic) =>
      Navigator.of(context).popUntil(
        (route) =>
            route.isFirst ||
            (route.settings.name == routeName &&
                route.settings.arguments == topic),
      );

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => ChatInfoScreen.open(context, topic),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatTitle(topic: topic),
              TypingIndicator(topic: topic),
            ],
          ),
        ),
        actions: [
          MessageSearchButton(topic: topic),
          CallButton(topic: topic, video: false),
          CallButton(topic: topic, video: true),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ChatBody(topic: topic)),
            ComposerArea(topic: topic),
          ],
        ),
      ),
    );
  }
}
