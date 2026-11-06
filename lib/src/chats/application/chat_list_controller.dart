import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/uncounted_seqs.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_list_controller.g.dart';

/// The chat list of the logged-in user: shown from the cache first, then
/// synced with the server, kept current from `me` presence and from the
/// messages of attached chats, and synced again after a reconnect.
///
/// Who is online comes from the sync and then from `pres on` / `off`; the
/// cached list shows everyone offline until the sync. Last seen comes from
/// the cache and the sync, and is now when `pres off` arrives. The session
/// drops all of it while the host turns presence off, and a peer who hides
/// theirs shows none (`ChatSummary.presenceHidden`).
///
/// It also tells the senders their messages reached this device (`note
/// recv`): as they arrive, live or as `pres msg`, and after each sync for
/// what came while the link was down.
///
/// A chat's unread count leaves out what isn't an unread message (see
/// `uncountedBy`), such as how a call ended, or a call that was answered
/// or declined: as they arrive live, and for those that came as `pres
/// msg`, which doesn't tell, once the cache has them.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost. Offline, the cached list stays as it is.
@Riverpod(keepAlive: true)
class ChatListController extends _$ChatListController {
  late BuildLifetime _lifetime;
  ChatSession? _session;

  /// Whether this build attached `me`; the client keeps it attached
  /// across reconnects from then on.
  var _attachedMe = false;

  /// Each chat's `ChatSummary.uncountedSeqs`, kept apart since the list is
  /// rebuilt from subscriptions, which don't have them.
  var _uncounted = <String, Set<int>>{};

  /// The chats to read [_uncounted] of again.
  final _changed = <String>{};

  @override
  ChatListState build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _session = session;
    if (session == null || me == null) {
      return const ChatListState.loading().failed(ChatFailure.connectionLost);
    }

    _attachedMe = false;
    _uncounted = {};
    _changed.clear();
    final subscriptions = [
      session.presence
          .where((p) => p.topic == 'me')
          .listen((p) => _onPresence(session, p)),
      session.messages.listen((m) => _onMessage(session, m, me: me)),
      session.storedChanges.listen((topic) {
        if (_changed.isEmpty) {
          scheduleMicrotask(
            () => unawaited(_reloadUncounted(session, lifetime)),
          );
        }
        _changed.add(topic);
      }),
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

  /// Syncs the list with the server, keeping what it shows meanwhile, e.g.
  /// after this user started a chat: the server sends its creator no
  /// presence for it.
  void refresh() {
    if (_session case final session?) {
      unawaited(_sync(session, _lifetime));
    }
  }

  /// The chat [topic] is gone for this user: deleted, or left.
  void remove(String topic) => state = state.without(topic);

  /// The peer of the direct chat [topic] was last online at [when], e.g. as
  /// the chat's description says.
  void markSeen(String topic, DateTime when) =>
      state = state.update(topic, (chat) => chat.withLastSeen(when));

  /// The user read [topic] up to [seq] on this device.
  void markRead(String topic, int seq) =>
      state = state.update(topic, (chat) => chat.withRead(seq));

  Future<void> _load(ChatSession session, BuildLifetime lifetime) async {
    try {
      final cached = await session.storedChatList();
      final updates = await session.storedUncountedSeqs();
      if (lifetime.isActive) {
        // A chat read again meanwhile is newer than this first read.
        _uncounted = {...updates, ..._uncounted};
        if (cached.isNotEmpty) {
          state = state.loaded(cached.map(_summary));
        }
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
        state = state.loaded(chats.map(_summary));
        for (final chat in chats) {
          if (chat.lastSeq > chat.received) {
            session.markReceived(chat.topic!, chat.lastSeq);
          }
        }
      }
    } on Object catch (e) {
      if (lifetime.isActive && state.status != LoadStatus.ready) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }

  ChatSummary _summary(Subscription chat) => ChatSummary.fromSubscription(
    chat,
  ).withUncounted(_uncounted[chat.topic] ?? const {});

  Future<void> _reloadUncounted(
    ChatSession session,
    BuildLifetime lifetime,
  ) async {
    final topics = Set.of(_changed);
    _changed.clear();
    try {
      final updates = <String, Set<int>>{
        for (final topic in topics)
          ...await session.storedUncountedSeqs(topic: topic),
      };
      if (lifetime.isActive) {
        for (final topic in topics) {
          _setUncounted(topic, updates[topic] ?? const {});
        }
      }
    } on Object {
      // The count stays as it is until the next change.
    }
  }

  void _setUncounted(String topic, Set<int> seqs) {
    _uncounted[topic] = seqs;
    state = state.update(topic, (chat) => chat.withUncounted(seqs));
  }

  void _onPresence(ChatSession session, PresMessage presence) {
    final topic = presence.source;
    if (topic == null) {
      return;
    }
    if ((presence.event, presence.seq) case (
      PresenceEvent.message,
      final seq?,
    )) {
      // A message in a chat this device isn't attached to.
      session.markReceived(topic, seq);
    }
    switch ((presence.event, presence.seq)) {
      case (PresenceEvent.message || PresenceEvent.access, _)
          when !state.contains(topic):
        // A chat this list has not seen yet: someone started it, or added
        // the user to it (`acs`, which carries no seq).
        unawaited(_sync(session, _lifetime));
      case (PresenceEvent.message, final seq?):
        state = state.update(
          topic,
          (chat) => chat.withMessage(seq, DateTime.now()),
        );
      case (PresenceEvent.read, final seq?):
        // Read on another of the user's devices.
        markRead(topic, seq);
      case (PresenceEvent.gone, _):
        // Deleted, or the user left or was removed, maybe elsewhere.
        remove(topic);
      case (PresenceEvent.online || PresenceEvent.offline, _):
        state = state.update(
          topic,
          (chat) => presence.event == PresenceEvent.online
              ? chat.withOnline(online: true)
              // `off` comes a few seconds late; close enough for last seen.
              : chat.withOnline(online: false, lastSeen: DateTime.now()),
        );
      case (PresenceEvent.updated, _):
        // The peer changed their profile: name, photo, or whether they
        // hide their presence.
        unawaited(_sync(session, _lifetime));
      case (PresenceEvent.access, _):
        // The user's access changed, maybe muted on another device: `acs`
        // doesn't say how, so the list is synced.
        unawaited(_sync(session, _lifetime));
      case _:
        break;
    }
  }

  void _onMessage(
    ChatSession session,
    DataMessage message, {
    required String me,
  }) {
    if (message.from case final from? when from != me) {
      session.markReceived(message.topic, message.seq);
    }
    final uncounted = uncountedBy(message.seq, message.head);
    if (uncounted.isNotEmpty) {
      _setUncounted(message.topic, {
        ...?_uncounted[message.topic],
        ...uncounted,
      });
    }
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
