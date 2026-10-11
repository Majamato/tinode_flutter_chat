import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/search/application/found_sender.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_sender.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Who sent a found message, from the user ID [from]: "You", a group
/// member's name, or the chat's title.
class FoundSenderName extends ConsumerWidget {
  const FoundSenderName({required this.topic, required this.from, super.key});

  final String topic;
  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sender = ref.watch(foundSenderProvider(topic, from));
    final strings = TinodeChatStrings.of(context);
    return switch (sender.kind) {
      FoundSenderKind.chat => ChatTitle(topic: topic),
      FoundSenderKind.own => Text(strings.youLabel),
      FoundSenderKind.member => Text(
        sender.name ?? strings.unknownMember,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    };
  }
}
