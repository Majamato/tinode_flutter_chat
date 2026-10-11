import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_exit_tile.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_members_section.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// About one chat: its photo and name, a group's members, and deleting or
/// leaving it. A failed action shows in a snack bar.
class ChatInfoScreen extends ConsumerWidget {
  const ChatInfoScreen({required this.topic, super.key});

  /// Pushes the info of the chat named [topic] over the chat.
  static Future<void> open(BuildContext context, String topic) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ChatInfoScreen(topic: topic)));

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(chatActionFailureProvider(topic), (_, failure) {
      if (failure != null) {
        final strings = TinodeChatStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(strings, failure))),
        );
      }
    });
    final kind = TopicKind.of(topic);
    return Scaffold(
      appBar: AppBar(title: Text(TinodeChatStrings.of(context).chatInfo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Center(child: ChatAvatar(topic: topic, radius: 48)),
            const SizedBox(height: 12),
            Center(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleLarge,
                child: ChatTitle(topic: topic),
              ),
            ),
            const SizedBox(height: 24),
            if (kind == TopicKind.group) ChatMembersSection(topic: topic),
            const Divider(),
            ChatExitTile(topic: topic),
          ],
        ),
      ),
    );
  }
}
