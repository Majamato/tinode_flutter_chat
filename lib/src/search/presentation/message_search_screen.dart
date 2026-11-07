import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_field.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_results.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

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
    return GlassScaffold(
      screen: TinodeMessageSearchScreen(topic),
      appBar: TinodeAppBar(
        centerTitle: false,
        titleOnGlass: true,
        leading: const TinodeBackButton(),
        title: GlassField(child: MessageSearchField(topic: topic)),
      ),
      body: SafeArea(bottom: false, child: MessageSearchResults(topic: topic)),
    );
  }
}
