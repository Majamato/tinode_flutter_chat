import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/member_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A group's members under a heading, the owner first. Watches who they
/// are, not their counters.
class ChatMembersSection extends ConsumerWidget {
  const ChatMembersSection({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(chatMemberIdsProvider(topic));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            TinodeChatStrings.of(context).members,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final userId in ids) MemberTile(topic: topic, userId: userId),
      ],
    );
  }
}
