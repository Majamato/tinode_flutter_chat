import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_dialog.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// One member of a group: avatar, name, whether it is the owner or the
/// user, and a remove button for those who manage the members. Watches
/// that member.
class MemberTile extends ConsumerWidget {
  const MemberTile({required this.topic, required this.userId, super.key});

  final String topic;
  final String userId;

  Future<void> _remove(BuildContext context, WidgetRef ref, String name) async {
    final strings = TinodeChatStrings.of(context);
    final controller = ref.read(chatActionsControllerProvider(topic).notifier);
    final confirmed = await ConfirmDialog.ask(
      context,
      message: strings.removeMemberConfirm(name),
      action: strings.removeMember,
    );
    if (confirmed) {
      await controller.removeMember(userId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(chatMemberProvider(topic, userId));
    if (member == null) {
      return const SizedBox.shrink();
    }
    final strings = TinodeChatStrings.of(context);
    final removable = ref.watch(memberRemovableProvider(topic, userId));
    final busy = ref.watch(
      chatActionsControllerProvider(topic).select((s) => s.isLoading),
    );
    final isMe = userId == ref.watch(currentUserIdProvider);
    final name = member.name ?? strings.unknownMember;
    return ListTile(
      leading: ProfileAvatar(initials: member.initials, photo: member.photo),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: switch ((member.isOwner, isMe)) {
        (true, _) => Text(strings.ownerLabel),
        (_, true) => Text(strings.youLabel),
        _ => null,
      },
      trailing: removable
          ? IconButton(
              tooltip: strings.removeMember,
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: busy
                  ? null
                  : () => unawaited(_remove(context, ref, name)),
            )
          : null,
    );
  }
}
