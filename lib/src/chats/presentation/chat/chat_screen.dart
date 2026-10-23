import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_header.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_wallpaper.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer_area.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/size_reporter.dart';

/// One chat: its messages over the wallpaper, scrolling under the frosted
/// header (who is typing, message search, the call buttons) and, where the
/// user may post, the frosted composer. Tapping the title opens the chat's
/// info. Watches nothing itself.
class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// The composer's height, so the messages can scroll out from under it.
  final _composerHeight = ValueNotifier<double>(0);

  @override
  void dispose() {
    _composerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ChatHeader(topic: topic),
      body: Stack(
        children: [
          const Positioned.fill(child: ChatWallpaper()),
          Positioned.fill(
            child: ChatBody(topic: topic, bottomInset: _composerHeight),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizeReporter(
              height: _composerHeight,
              child: FrostedBar(
                edge: AxisDirection.up,
                child: SafeArea(top: false, child: ComposerArea(topic: topic)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
