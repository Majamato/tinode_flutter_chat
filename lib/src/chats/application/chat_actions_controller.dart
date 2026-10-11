import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_exit.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_actions_controller.g.dart';

/// What the chat info screen does to one chat: deleting or leaving it, and
/// removing members. Loading while one runs, an error when it failed.
/// They need the link: offline they fail with a lost connection.
@riverpod
class ChatActionsController extends _$ChatActionsController {
  @override
  AsyncValue<void> build(String topic) => const AsyncData(null);

  /// Deletes or leaves the chat, as [exit] says, and drops it from the
  /// chat list. Returns whether it is gone.
  Future<bool> exit(ChatExit exit) => _run((session) async {
    switch (exit) {
      case ChatExit.deleteChat || ChatExit.deleteGroup:
        await session.deleteChat(topic);
      case ChatExit.leaveGroup:
        await session.leaveChat(topic);
    }
    if (ref.mounted) {
      ref.read(chatListControllerProvider.notifier).remove(topic);
    }
  });

  /// Removes [userId] from the group. Returns whether they are out.
  Future<bool> removeMember(String userId) => _run((session) async {
    await session.removeMember(topic, userId);
    if (ref.mounted) {
      ref.read(chatMembersControllerProvider(topic).notifier).removed(userId);
    }
  });

  Future<bool> _run(Future<void> Function(ChatSession session) action) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await action(session);
    });
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}

/// Why the last action on the chat failed, if it did.
@riverpod
ChatFailure? chatActionFailure(Ref ref, String topic) => ref.watch(
  chatActionsControllerProvider(
    topic,
  ).select((s) => s.hasError ? ChatFailure.of(s.error!) : null),
);

/// How the user can get rid of the chat; null while the list lacks it.
@riverpod
ChatExit? chatExit(Ref ref, String topic) => ref.watch(
  chatSummaryProvider(
    topic,
  ).select((chat) => chat == null ? null : ChatExit.of(chat)),
);

/// The chat's members as its info screen lists them, by user ID.
@riverpod
List<String> chatMemberIds(Ref ref, String topic) => ref.watch(
  chatMembersControllerProvider(
    topic,
  ).select((members) => [for (final m in members.ordered) m.userId]),
);

/// One member of the chat; null once they left.
@riverpod
ChatMember? chatMember(Ref ref, String topic, String userId) => ref.watch(
  chatMembersControllerProvider(topic).select((members) => members[userId]),
);

/// Whether the user may remove [userId] from the group: they manage its
/// members, and it is neither the owner nor themselves.
@riverpod
bool memberRemovable(Ref ref, String topic, String userId) {
  final canManage = ref.watch(
    chatSummaryProvider(topic).select((c) => c?.canManageMembers ?? false),
  );
  final isOwner = ref.watch(
    chatMemberProvider(topic, userId).select((m) => m?.isOwner ?? true),
  );
  return canManage && !isOwner && userId != ref.watch(currentUserIdProvider);
}
