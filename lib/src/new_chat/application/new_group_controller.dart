import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/new_group.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'new_group_controller.g.dart';

/// Creating a group: loading while the server creates it and adds its
/// members, an error when the group could not be created. Only the new
/// group screen and its create button watch it.
@riverpod
class NewGroupController extends _$NewGroupController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Creates a group named [name] with [members], and returns it once
  /// created; null when it could not be (the state says why) or [name] is
  /// blank. A member the server refuses doesn't undo the group: they are
  /// listed in [NewGroup.notAdded].
  Future<NewGroup?> create(String name, List<SearchResult> members) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return null;
    }
    state = const AsyncLoading();

    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      final topic = await session.createGroup(public: Profile(name: trimmed));
      final List<String?> refused;
      try {
        refused = await Future.wait([
          for (final member in members)
            session
                .addMember(topic, member.topic)
                .then<String?>((_) => null, onError: (_) => member.title),
        ]);
      } finally {
        // Creating attached the group; the chat screen attaches it again.
        unawaited(session.detach(topic).then((_) {}, onError: (_) {}));
      }
      if (ref.mounted) {
        // The server sends the creator no presence for the new group.
        ref.read(chatListControllerProvider.notifier).refresh();
        state = const AsyncData(null);
      }
      return NewGroup(topic: topic, notAdded: refused.nonNulls.toList());
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return null;
    }
  }
}
