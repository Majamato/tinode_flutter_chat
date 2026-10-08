import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_list_controller.g.dart';

/// The chat list of the logged-in user: shown from the cache first, then
/// synced with the server, kept current from `me` presence and from the
/// messages of attached chats, and synced again after a reconnect.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost. Offline, the cached list stays as it is.
@Riverpod(keepAlive: true)
class ChatListController extends _$ChatListController {
  late BuildLifetime _lifetime;

  /// Whether this build attached `me`; the client keeps it attached
  /// across reconnects from then on.
  var _attachedMe = false;

  @override
  ChatListState build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    if (session == null || me == null) {
      return const ChatListState.loading().failed(ChatFailure.connectionLost);
    }
    _attachedMe = false;
    final subscriptions = [
      session.presence
          .where((p) => p.topic == 'me')
          .listen((p) => _onPresence(session, p)),
      session.messages.listen((m) => _onMessage(m, me: me)),
      // Presence missed while the link was down is never replayed.
      session.statusChanges
          .where((s) => s is Connected)
          .listen((_) => unawaited(_sync(session, lifetime))),
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

  Future<void> _load(ChatSession session, BuildLifetime lifetime) async {
    try {
      final cached = await session.storedChatList();
      if (lifetime.isActive && cached.isNotEmpty) {
        state = state.loaded(cached.map(ChatSummary.fromSubscription));
      }
    } on Object {
      // The cache is a convenience: the server fills the list instead.
    }
    await _sync(session, lifetime);
  }

  /// Attaches `me` if this build has not yet, and syncs the list with the
  /// server. A failure fails the list only when there is nothing to show.
  Future<void> _sync(ChatSession session, BuildLifetime lifetime) async {
    try {
      if (!_attachedMe) {
        await session.attach('me');
        if (!lifetime.isActive) {
          return;
        }
        _attachedMe = true;
      }
      final chats = await session.chatList();
      if (lifetime.isActive) {
        state = state.loaded(chats.map(ChatSummary.fromSubscription));
      }
    } on Object catch (e) {
      if (lifetime.isActive && state.status != LoadStatus.ready) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }

  void _onPresence(ChatSession session, PresMessage presence) {
    final topic = presence.source;
    final seq = presence.seq;
    if (topic == null || seq == null) {
      return;
    }
    switch (presence.event) {
      case PresenceEvent.message when !state.contains(topic):
        // A chat this list has not seen yet: someone started it.
        unawaited(_sync(session, _lifetime));
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
}

/// One chat of the list. List tiles watch single fields of it.
@riverpod
ChatSummary? chatSummary(Ref ref, String topic) =>
    ref.watch(chatListControllerProvider.select((list) => list.byTopic[topic]));
