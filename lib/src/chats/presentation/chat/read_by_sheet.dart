import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// Who read the user's group message [seq], and who only received it.
/// Follows the members' markers while it is open.
class ReadBySheet extends ConsumerWidget {
  const ReadBySheet({required this.topic, required this.seq, super.key});

  final String topic;
  final int seq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    final (:read, :delivered) = ref.watch(messageReadByProvider(topic, seq));
    final headingStyle = Theme.of(context).textTheme.titleSmall;

    Widget tile(ChatMember member) => ListTile(
      leading: ProfileAvatar(initials: member.initials, photo: member.photo),
      title: Text(
        member.name ?? strings.unknownMember,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: headingStyle),
    );

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          heading(strings.readBy),
          if (read.isEmpty)
            ListTile(title: Text(strings.notReadYet))
          else
            ...read.map(tile),
          if (delivered.isNotEmpty) ...[
            heading(strings.deliveredTo),
            ...delivered.map(tile),
          ],
        ],
      ),
    );
  }
}
