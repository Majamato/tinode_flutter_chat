import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_controller.g.dart';

/// Messages fetched per history request.
const historyPageSize = 32;

/// One open chat: attaches to the topic, loads its history, merges live
/// messages, catches up after a reconnect and marks what the user sees as
/// read. Detaches when the chat screen closes.
@riverpod
class ChatController extends _$ChatController {
  late TinodeSession _session;
  late String _me;
  late BuildLifetime _lifetime;
  var _lastMarkedRead = 0;

  @override
  ChatState build(String topic) {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);

    if (session == null || me == null) {
      return const ChatState.loading().failed(ChatFailure.connectionLost);
    }

    _session = session;
    _me = me;
    _lastMarkedRead = 0;

    final live = session.messages
        .where((m) => m.topic == topic)
        .listen(_onLive);
    final reconnects = session.statusChanges
        .where((s) => s is Connected)
        .listen((_) => unawaited(_catchUp(lifetime)));
    ref.onDispose(() {
      unawaited(live.cancel());
      unawaited(reconnects.cancel());
      unawaited(session.detach(topic).then((_) {}, onError: (_) {}));
    });
    unawaited(_load(lifetime));
    return const ChatState.loading();
  }

  /// Loads the page before the oldest loaded message.
  Future<void> loadOlder() async {
    final before = state.firstSeq;
    if (!state.hasOlder || state.loadingOlder || before == null) {
      return;
    }

    final lifetime = _lifetime;
    state = state.withLoadingOlder(loading: true);
    try {
      final page = await _session.history(
        topic,
        before: before,
        limit: historyPageSize,
      );
      if (!lifetime.isActive) {
        return;
      }
      state = state
          .withMessages(page.map(_toMessage))
          .withLoadingOlder(loading: false, hasOlder: _hasOlder(page));
    } on Object {
      if (lifetime.isActive) {
        state = state.withLoadingOlder(loading: false);
      }
    }
  }

  /// Loads the chat again, e.g. after a failure.
  void reload() => ref.invalidateSelf();

  /// Shows a message this user just published, before its echo arrives.
  void addOwn(PublishResult rs, MessageContent content) {
    state = state.withMessages([
      ChatMessage(
        seq: rs.seq,
        time: rs.time,
        content: content,
        from: _me,
        isOwn: true,
      ),
    ]);
    _markRead(rs.seq);
  }

  Future<void> _load(BuildLifetime lifetime) async {
    try {
      await _session.attach(topic);
      if (!lifetime.isActive) {
        return;
      }

      final page = await _session.history(topic, limit: historyPageSize);
      if (!lifetime.isActive) {
        return;
      }

      state = state
          .withMessages(page.map(_toMessage))
          .ready(hasOlder: _hasOlder(page));
      if (state.lastSeq case final seq?) {
        _markRead(seq);
      }
    } on Object catch (e) {
      if (lifetime.isActive) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }

  /// Fetches what arrived while the link was down. A full page may hide
  /// a bigger gap, and a failure leaves one, so both reload the chat.
  Future<void> _catchUp(BuildLifetime lifetime) async {
    final last = state.lastSeq;
    if (state.status != LoadStatus.ready || last == null) {
      return reload();
    }
    try {
      final page = await _session.history(
        topic,
        since: last + 1,
        limit: historyPageSize,
      );
      if (!lifetime.isActive) {
        return;
      }
      if (page.length >= historyPageSize) {
        return reload();
      }
      state = state.withMessages(page.map(_toMessage));
      if (state.lastSeq case final seq?) {
        _markRead(seq);
      }
    } on Object {
      if (lifetime.isActive) {
        reload();
      }
    }
  }

  void _onLive(DataMessage message) {
    state = state.withMessages([_toMessage(message)]);
    _markRead(message.seq);
  }

  void _markRead(int seq) {
    if (seq <= _lastMarkedRead) {
      return;
    }
    _lastMarkedRead = seq;
    _session.markRead(topic, seq);
    ref.read(chatListControllerProvider.notifier).markRead(topic, seq);
  }

  ChatMessage _toMessage(DataMessage message) =>
      ChatMessage.fromData(message, me: _me);

  static bool _hasOlder(List<DataMessage> page) =>
      page.length >= historyPageSize && page.first.seq > 1;
}

/// One message of an open chat. Each bubble watches its own.
@riverpod
ChatMessage? chatMessage(Ref ref, String topic, int seq) =>
    ref.watch(chatControllerProvider(topic).select((chat) => chat.bySeq[seq]));
