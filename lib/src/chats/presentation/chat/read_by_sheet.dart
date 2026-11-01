import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
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

    return ChatSheet(
      title: strings.readBy,
      children: [
        if (read.isEmpty)
          _Note(strings.notReadYet)
        else
          ...read.map(_MemberTile.new),
        if (delivered.isNotEmpty) ...[
          _Heading(strings.deliveredTo),
          ...delivered.map(_MemberTile.new),
        ],
      ],
    );
  }
}

/// A section label, as over a group of settings.
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile(this.member);

  final ChatMember member;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        ProfileAvatar(
          initials: member.initials,
          photo: member.photo,
          radius: 20,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            member.name ?? TinodeChatStrings.of(context).unknownMember,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
