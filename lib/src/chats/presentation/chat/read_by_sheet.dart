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

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          _Heading(strings.readBy),
          if (read.isEmpty)
            ListTile(title: Text(strings.notReadYet))
          else
            ...read.map(_MemberTile.new),
          if (delivered.isNotEmpty) ...[
            _Heading(strings.deliveredTo),
            ...delivered.map(_MemberTile.new),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile(this.member);

  final ChatMember member;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ProfileAvatar(initials: member.initials, photo: member.photo),
    title: Text(
      member.name ?? TinodeChatStrings.of(context).unknownMember,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
