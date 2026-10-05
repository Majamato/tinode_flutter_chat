import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_list_controller.g.dart';

/// The chat list of the logged-in user, kept current from `me` presence
/// and from the messages of attached chats.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost.
@Riverpod(keepAlive: true)
class ChatListController extends _$ChatListController {
  late BuildLifetime _lifetime;

  @override
  ChatListState build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    if (session == null || me == null) {
      return const ChatListState.loading().failed(ChatFailure.connectionLost);
    }
    final subscriptions = [
      session.presence
          .where((p) => p.topic == 'me')
          .listen((p) => _onPresence(session, p)),
      session.messages.listen((m) => _onMessage(m, me: me)),
    ];
    ref.onDispose(() {
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
    });
    unawaited(_load(session, lifetime));
    return const ChatListState.loading();
  }

  /// Loads the list again, e.g. after a failure.
  void reload() => ref.invalidateSelf();

  /// The user read [topic] up to [seq] on this device.
  void markRead(String topic, int seq) =>
      state = state.update(topic, (chat) => chat.withRead(seq));

  Future<void> _load(TinodeSession session, BuildLifetime lifetime) async {
    try {
      await session.attach('me');
      final chats = await session.chatList();
      if (!lifetime.isActive) return;
      state = state.loaded(chats.map(ChatSummary.fromSubscription));
    } on Object catch (e) {
      if (lifetime.isActive) state = state.failed(ChatFailure.of(e));
    }
  }

  void _onPresence(TinodeSession session, PresMessage presence) {
    final topic = presence.source;
    final seq = presence.seq;
    if (topic == null || seq == null) return;
    switch (presence.event) {
      case PresenceEvent.message when !state.contains(topic):
        // A chat this list has not seen yet: someone started it.
        unawaited(_refresh(session));
      case PresenceEvent.message:
        state = state.update(
          topic,
          (chat) => chat.withMessage(seq, DateTime.now()),
        );
      case PresenceEvent.read:
        // Read on another of the user's devices.
        markRead(topic, seq);
      case _:
        break;
    }
  }

  void _onMessage(DataMessage message, {required String me}) {
    state = state.update(message.topic, (chat) {
      final updated = chat.withMessage(message.seq, message.time);
      return message.from == me ? updated.withRead(message.seq) : updated;
    });
  }

  Future<void> _refresh(TinodeSession session) async {
    final lifetime = _lifetime;
    try {
      final chats = await session.chatList();
      if (lifetime.isActive) {
        state = state.loaded(chats.map(ChatSummary.fromSubscription));
      }
    } on Object {
      // The list stays as it was; the next message tries again.
    }
  }
}

/// One chat of the list. List tiles watch single fields of it.
@riverpod
ChatSummary? chatSummary(Ref ref, String topic) =>
    ref.watch(chatListControllerProvider.select((list) => list.byTopic[topic]));
