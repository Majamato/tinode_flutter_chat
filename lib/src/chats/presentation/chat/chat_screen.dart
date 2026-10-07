import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_body.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer_area.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';

/// One chat: its messages, the call buttons and, where the user may post,
/// the composer. Watches nothing itself.
class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.topic, super.key});

  /// Pushes the chat named [topic] onto the chat's navigator.
  static Future<void> open(BuildContext context, String topic) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(topic: topic)));

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ChatTitle(topic: topic),
        actions: [
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
