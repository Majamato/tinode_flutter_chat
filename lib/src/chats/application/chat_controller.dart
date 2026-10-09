import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'chat_controller.g.dart';

/// Messages fetched per history request.
const historyPageSize = 32;

/// One open chat: shows what the cache holds, attaches to the topic,
/// catches up with the server, merges live messages and the outbox, and
/// marks what the user sees as read. Each attach also syncs the chat's
/// members. Detaches when the chat screen closes.
@riverpod
class ChatController extends _$ChatController {
  late ChatSession _session;
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
    final link = _Link();
    // Alive as long as the chat: it syncs once attached.
    ref.listen(chatMembersControllerProvider(topic), (_, _) {});

    final subscriptions = [
      session.messages.where((m) => m.topic == topic).listen(_onLive),
      session.outbox.where((e) => e.topic == topic).listen(_onOutbox),
      session.deletions.where((d) => d.topic == topic).listen(_onDeletion),
      session.statusChanges
          .where((s) => s is Connected)
          .listen((_) => _sync(lifetime, link)),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      if (link.attached) {
        unawaited(session.detach(topic).then((_) {}, onError: (_) {}));
      }
    });
    unawaited(_load(lifetime, link));
    return const ChatState.loading();
  }

  /// Loads the page before the oldest loaded message: from the cache, or
  /// from the server for what it lacks.
  Future<void> loadOlder() async {
    final before = state.firstSeq;
    if (!state.hasOlder || state.loadingOlder || before == null) {
      return;
    }

    final lifetime = _lifetime;
    state = state.withLoadingOlder(loading: true);
    try {
      final page = await _session.olderPage(
        topic,
        before: before,
        limit: historyPageSize,
      );
      if (!lifetime.isActive) {
        return;
      }
      state = state
          .withMessages(page.messages.map(_toMessage))
          .withLoadingOlder(loading: false, hasOlder: !page.reachedStart);
    } on Object {
      if (lifetime.isActive) {
        state = state.withLoadingOlder(loading: false);
      }
    }
  }

  /// Loads the chat again, e.g. after a failure.
  void reload() => ref.invalidateSelf();

  /// Deletes the messages [seqs], for this user or for everyone.
  Future<void> delete(Set<int> seqs, {required bool forEveryone}) =>
      _session.delete(topic, _ranges(seqs), forEveryone: forEveryone);

  /// Queues a failed message again.
  Future<void> retry(String clientId) => _session.retry(clientId);

  /// Drops a message that was not sent.
  Future<void> discard(String clientId) => _session.discard(clientId);

  Future<void> _load(BuildLifetime lifetime, _Link link) async {
    try {
      final stored = await _session.storedPage(topic, limit: historyPageSize);
      final outgoing = await _session.storedOutgoing(topic);
      if (!lifetime.isActive) {
        return;
      }
      if (stored.messages.isNotEmpty || outgoing.isNotEmpty) {
        state = outgoing
            .fold(state, (chat, message) => chat.withOutgoing(message))
            .withMessages(stored.messages.map(_toMessage))
            .ready(hasOlder: !stored.reachedStart);
        _markLastRead();
      }
    } on Object {
      // The cache is a convenience: the server fills the chat instead.
    }
    if (lifetime.isActive) {
      _sync(lifetime, link);
    }
  }

  /// Brings the chat up to date with the server: one run at a time, and
  /// one more when asked during a run.
  void _sync(BuildLifetime lifetime, _Link link) {
    if (link.syncing) {
      link.syncAgain = true;
      return;
    }
    link.syncing = true;
    unawaited(() async {
      try {
        do {
          link.syncAgain = false;
          await _syncOnce(lifetime, link);
        } while (link.syncAgain && lifetime.isActive);
      } finally {
        link.syncing = false;
      }
    }());
  }

  /// Attaches if needed, then fetches the newest page, or what arrived
  /// after the cached messages. Offline, a chat shown from the cache stays
  /// as it is until the next connect.
  Future<void> _syncOnce(BuildLifetime lifetime, _Link link) async {
    try {
      if (!link.attached) {
        await _session.attach(topic);
        if (!lifetime.isActive) {
          unawaited(_session.detach(topic).then((_) {}, onError: (_) {}));
          return;
        }
        link.attached = true;
        // A chat the user just started, e.g. with someone they found: the
        // server sends its creator no presence for it.
        if (!ref.read(chatListControllerProvider).contains(topic)) {
          ref.read(chatListControllerProvider.notifier).refresh();
        }
      }
      // After the first attach, and after each reconnect, which attaches
      // again: members' counters may have moved meanwhile.
      unawaited(ref.read(chatMembersControllerProvider(topic).notifier).sync());

      if (state.status != LoadStatus.ready || state.lastSeq == null) {
        final page = await _session.history(topic, limit: historyPageSize);
        if (!lifetime.isActive) {
          return;
        }
        state = state
            .withMessages(page.map(_toMessage))
            .ready(hasOlder: _hasOlder(page));
      } else {
        final caughtUp = await _session.catchUp(topic, limit: historyPageSize);
        if (!lifetime.isActive) {
          return;
        }
        final messages = caughtUp.messages.map(_toMessage);
        state = caughtUp.gap
            // Too much arrived to show at once: start over from the newest
            // page; older ones load from there, cached or not.
            ? state
                  .restartedWith(messages)
                  .ready(hasOlder: _startsAfterFirst(caughtUp.messages))
            : state.withMessages(messages);
      }
      _markLastRead();
    } on Object catch (e) {
      if (lifetime.isActive && state.status != LoadStatus.ready) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }

  void _onLive(DataMessage message) {
    state = state.withMessages([_toMessage(message)]);
    _markRead(message.seq);
  }

  void _onOutbox(OutboxEvent event) {
    switch (event) {
      case OutgoingChanged(:final message):
        state = state.withOutgoing(message);
      case OutgoingSent(:final clientId, :final message):
        state = state.withoutOutgoing(clientId).withMessages([
          _toMessage(message),
        ]);
        _markRead(message.seq);
      case OutgoingDiscarded(:final clientId):
        state = state.withoutOutgoing(clientId);
    }
  }

  void _onDeletion(TopicDeletion deletion) {
    if (deletion.restored) {
      // A deletion of this user's failed: the messages are back.
      return reload();
    }
    state = state.withoutSeqs(deletion.ranges);
  }

  void _markLastRead() {
    if (state.lastSeq case final seq?) {
      _markRead(seq);
    }
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

  static bool _startsAfterFirst(List<DataMessage> page) =>
      page.isNotEmpty && page.first.seq > 1;

  /// [seqs] as ranges, neighbours joined.
  static List<SeqRange> _ranges(Set<int> seqs) {
    final sorted = seqs.toList()..sort();
    final ranges = <SeqRange>[];
    for (final seq in sorted) {
      if (ranges.lastOrNull case final last? when last.high == seq) {
        ranges.last = SeqRange(last.low, seq + 1);
      } else {
        ranges.add(SeqRange.single(seq));
      }
    }
    return ranges;
  }
}

/// One build's hold on the topic and its sync runs.
final class _Link {
  bool attached = false;
  bool syncing = false;
  bool syncAgain = false;
}

/// One message of an open chat. Each bubble watches its own.
@riverpod
ChatMessage? chatMessage(Ref ref, String topic, int seq) =>
    ref.watch(chatControllerProvider(topic).select((chat) => chat.bySeq[seq]));

/// One message of an open chat that waits in the outbox.
@riverpod
OutgoingMessage? outgoingMessage(Ref ref, String topic, String clientId) =>
    ref.watch(
      chatControllerProvider(
        topic,
      ).select((chat) => chat.outgoingById[clientId]),
    );
