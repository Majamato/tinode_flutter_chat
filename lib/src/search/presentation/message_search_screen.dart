import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_field.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_results.dart';

/// Message search over the messages of the chat named [topic] kept on this
/// device. Tapping a result goes back to the chat, scrolled to the message.
/// Watches nothing itself.
class MessageSearchScreen extends StatelessWidget {
  const MessageSearchScreen({required this.topic, super.key});

  /// Pushes the search of the chat named [topic] over the chat.
  static Future<void> open(BuildContext context, String topic) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MessageSearchScreen(topic: topic),
        ),
      );

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MessageSearchField(topic: topic)),
      body: MessageSearchResults(topic: topic),
    );
  }
}
