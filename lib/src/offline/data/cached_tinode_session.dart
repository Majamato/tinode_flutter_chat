import 'dart:async';
import 'dart:developer';
import 'dart:math' show max, min;

import 'package:clock/clock.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/chat_merge.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/history_page.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_retry.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// Messages fetched per page while looking for a message whose fate a drop
/// left unknown.
const _reconcilePage = 64;

/// How many delete-log pages one sync reads at most.
const _maxDeleteLogPages = 20;

/// A [ChatSession] over a remote [TinodeSession] and a [ChatStore].
///
/// What the server sends is written to the store in arrival order; reads
/// wait for those writes, so they see everything that arrived before.
final class CachedTinodeSession implements ChatSession {
  CachedTinodeSession(this._remote, this._store, {required this.userId}) {
    _subscriptions = [
      _remote.messages.listen(_onMessage),
      _remote.presence.listen(_onPresence),
      _remote.statusChanges.listen(_onStatus),
    ];
    if (_remote.status is Connected) {
      scheduleMicrotask(_kick);
    }
  }

  final TinodeSession _remote;
  final ChatStore _store;
  late final List<StreamSubscription<Object>> _subscriptions;

  @override
  final String userId;

  final _outbox = StreamController<OutboxEvent>.broadcast(sync: true);
  final _deletions = StreamController<TopicDeletion>.broadcast(sync: true);

  /// The tail of the writes queued by arriving events.
  Future<void> _writes = Future.value();
  Future<List<Subscription>>? _chatListSync;
  var _closed = false;

  // Outbox drain state.
  var _draining = false;
  var _drainAgain = false;
  String? _sending;
  Timer? _retry;
  var _retryRound = 0;

  // Passed through.

  @override
  Stream<DataMessage> get messages => _remote.messages;

  @override
  Stream<PresMessage> get presence => _remote.presence;

  @override
  Stream<InfoMessage> get info => _remote.info;

  @override
  ConnectionStatus get status => _remote.status;

  @override
  Stream<ConnectionStatus> get statusChanges => _remote.statusChanges;

  @override
  ServerInfo get serverInfo => _remote.serverInfo;

  @override
  Future<LoginResult> loginBasic(String login, String password) =>
      _remote.loginBasic(login, password);

  @override
  Future<LoginResult> loginToken(String token) => _remote.loginToken(token);

  @override
  Future<String> attach(String topic) => _remote.attach(topic);

  @override
  Future<void> detach(String topic) => _remote.detach(topic);

  @override
  void sendTyping(String topic) => _remote.sendTyping(topic);

  @override
  Future<PublishResult> publish(
    String topic,
    MessageContent content, {
    Json? head,
  }) => _remote.publish(topic, content, head: head);

  @override
  Future<int> deleteMessages(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
  }) => _remote.deleteMessages(topic, ranges, hard: hard);

  @override
  Future<DeleteLog> deleteLog(String topic, {int? since, int? limit}) =>
      _remote.deleteLog(topic, since: since, limit: limit);

  @override
  Future<PublishResult> startCall(String topic, {required bool audioOnly}) =>
      _remote.startCall(topic, audioOnly: audioOnly);

  @override
  void sendCallEvent(String topic, int seq, CallEvent event, {Json? payload}) =>
      _remote.sendCallEvent(topic, seq, event, payload: payload);

  @override
  void suspend() => _remote.suspend();

  @override
  void resume({Duration? probeTimeout}) =>
      _remote.resume(probeTimeout: probeTimeout);

  @override
  Stream<OutboxEvent> get outbox => _outbox.stream;

  @override
  Stream<TopicDeletion> get deletions => _deletions.stream;

  // Chat list.

  @override
  Future<List<Subscription>> storedChatList() async {
    await _writes;
    return _store.chats();
  }

  /// Syncs the cached list with the server ("if modified since" the newest
  /// change it holds) and returns it. Overlapping calls share one sync.
  @override
  Future<List<Subscription>> chatList({DateTime? ifModifiedSince}) =>
      _chatListSync ??= _syncChatList().whenComplete(
        () => _chatListSync = null,
      );

  Future<List<Subscription>> _syncChatList() async {
    await _writes;
    final since = chatListWatermark(await _store.chats());
    final fetched = await _remote.chatList(ifModifiedSince: since);
    if (since == null) {
      await _store.replaceChats(fetched);
    } else {
      await _store.mergeChats(fetched);
    }
    return _store.chats();
  }

  // History.

  /// Fetches from the server and keeps what came back, with the seqs the
  /// request covered.
  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  }) async {
    final page = await _remote.history(
      topic,
      limit: limit,
      since: since,
      before: before,
    );
    await _write(
      () => _store.putMessages(
        topic,
        page,
        covering: _covered(page, since: since, before: before, limit: limit),
      ),
    );
    return page;
  }

  @override
  Future<HistoryPage> storedPage(String topic, {required int limit}) async {
    await _writes;
    final top = (await _store.coverage(topic)).top;
    if (top == null) {
      return const HistoryPage([], reachedStart: false);
    }
    final messages = await _store.messagesIn(
      topic,
      from: top.low,
      before: top.high,
      limit: limit,
    );
    return HistoryPage(
      messages,
      reachedStart: top.low <= 1 && messages.length < limit,
    );
  }

  @override
  Future<HistoryPage> olderPage(
    String topic, {
    required int before,
    required int limit,
  }) async {
    await _writes;
    var result = <DataMessage>[];
    var cursor = before;
    var reachedStart = false;
    // Each round either serves a covered range or fills the gap below it.
    for (var round = 0; round < 16 && result.length < limit; round++) {
      if (cursor <= 1) {
        reachedStart = true;
        break;
      }
      final covered = await _store.coverage(topic);
      final want = limit - result.length;
      if (covered.rangeContaining(cursor - 1) case final range?) {
        final cached = await _store.messagesIn(
          topic,
          from: range.low,
          before: cursor,
          limit: want,
        );
        result = [...cached, ...result];
        if (cached.length >= want) {
          break;
        }
        cursor = range.low;
        continue;
      }

      if (_remote.status is! Connected) {
        break;
      }
      final since = covered.highestBelow(cursor);
      final List<DataMessage> fetched;
      try {
        fetched = await history(
          topic,
          since: since,
          before: cursor,
          limit: want,
        );
      } on ConnectionClosedException {
        break;
      }
      result = [...fetched, ...result];
      if (fetched.length >= want) {
        break;
      }
      cursor = since ?? 1;
    }
    return HistoryPage(result, reachedStart: reachedStart);
  }

  @override
  Future<CatchUp> catchUp(String topic, {required int limit}) async {
    await _writes;
    final top = (await _store.coverage(topic)).top;
    if (top == null) {
      final page = await history(topic, limit: limit);
      // Nothing cached to delete: deletions so far are already applied.
      final chat = await _store.chat(topic);
      await _store.setSyncedDeleteId(topic, chat?.lastDeleteId ?? 0);
      return CatchUp(page, gap: true);
    }
    final page = await history(topic, since: top.high, limit: limit);
    await _syncDeletes(topic);
    return CatchUp(page, gap: page.length >= limit);
  }

  /// Applies the deletions made since the last one this cache applied.
  Future<void> _syncDeletes(String topic) async {
    try {
      var synced = await _store.syncedDeleteId(topic);
      for (var page = 0; page < _maxDeleteLogPages; page++) {
        final log = await _remote.deleteLog(topic, since: synced + 1);
        if (log.ranges.isEmpty || log.lastDeleteId <= synced) {
          return;
        }
        await _applyDeletion(topic, log.ranges);
        synced = log.lastDeleteId;
        await _store.setSyncedDeleteId(topic, synced);
      }
    } on Object catch (e, stackTrace) {
      // The next catch-up tries again; the messages stay meanwhile.
      _log('Could not sync deletions of $topic', e, stackTrace);
    }
  }

  Future<void> _applyDeletion(String topic, List<SeqRange> ranges) async {
    await _store.deleteMessages(topic, ranges);
    if (!_closed) {
      _deletions.add(TopicDeletion(topic, ranges));
    }
  }

  // Outbox.

  @override
  Future<List<OutgoingMessage>> storedOutgoing(String topic) async => [
    for (final entry in await _store.outbox(topic: topic))
      if (entry.kind == OutboxKind.publish)
        entry.toOutgoing(sending: entry.clientId == _sending),
  ];

  @override
  Future<OutgoingMessage> send(String topic, MessageContent content) async {
    final entry = await _store.enqueuePublish(
      topic,
      newClientId(),
      content,
      clock.now().toUtc(),
    );
    final message = entry.toOutgoing();
    _emit(OutgoingChanged(message));
    _kick();
    return message;
  }

  @override
  Future<void> retry(String clientId) async {
    final entry = await _store.outboxByClientId(clientId);
    if (entry == null || !entry.failed) {
      return;
    }
    await _store.updateOutbox(entry.id, attempts: 0, clearFailure: true);
    _emit(
      OutgoingChanged(entry.toOutgoing().withStatus(OutgoingStatus.queued)),
    );
    _kick();
  }

  @override
  Future<void> discard(String clientId) async {
    if (clientId == _sending) {
      throw StateError('The message is being sent.');
    }
    final entry = await _store.outboxByClientId(clientId);
    if (entry != null && await _store.removeOutbox(entry.id)) {
      _emit(OutgoingDiscarded(entry.topic, clientId));
    }
  }

  @override
  Future<void> delete(
    String topic,
    List<SeqRange> ranges, {
    required bool forEveryone,
  }) async {
    if (ranges.isEmpty) {
      return;
    }
    await _write(() async {
      await _store.deleteMessages(topic, ranges);
      await _store.enqueueDelete(
        topic,
        ranges,
        hard: forEveryone,
        createdAt: clock.now().toUtc(),
      );
    });
    if (!_closed) {
      _deletions.add(TopicDeletion(topic, ranges));
    }
    _kick();
  }

  /// Read markers reach the server now, or from the outbox once online.
  @override
  void markRead(String topic, int seq) {
    unawaited(_write(() => _store.advanceChat(topic, read: seq)));
    if (_remote.status is Connected) {
      _remote.markRead(topic, seq);
    } else {
      unawaited(
        _write(() => _store.enqueueRead(topic, seq, clock.now().toUtc())),
      );
    }
  }

  /// Starts a drain unless one is running, in which case it runs again.
  void _kick() => unawaited(_drain());

  Future<void> _drain() async {
    if (_closed) {
      return;
    }
    if (_draining) {
      _drainAgain = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainAgain = false;
        if (_remote.status is! Connected) {
          return;
        }
        await _writes;
        final pending = [
          for (final entry in await _store.outbox())
            if (!entry.failed) entry,
        ];
        final topics = {for (final entry in pending) entry.topic};
        for (final topic in topics) {
          final entries = [
            for (final entry in pending)
              if (entry.topic == topic) entry,
          ];
          if (!await _drainTopic(topic, entries)) {
            return;
          }
        }
      } while (_drainAgain && !_closed);
    } on Object catch (e, stackTrace) {
      _log('The outbox stopped', e, stackTrace);
    } finally {
      _draining = false;
    }
  }

  /// Sends one topic's entries in order. False when the link went down.
  Future<bool> _drainTopic(String topic, List<OutboxEntry> entries) async {
    try {
      await _remote.attach(topic);
    } on Object catch (e) {
      switch (retryDecisionFor(e)) {
        case RetryDecision.waitForConnection:
          return false;
        case RetryDecision.retryLater || RetryDecision.reconcile:
          _scheduleRetry();
          return true;
        case RetryDecision.fail:
          // The topic is gone or closed to this user: nothing will go.
          for (final entry in entries) {
            await _giveUp(entry, ChatFailure.of(e));
          }
          return true;
      }
    }
    try {
      await _reconcile(topic, entries.where((e) => e.inFlight).toList());
      for (final entry in entries) {
        if (_closed) {
          return false;
        }
        // Reconciling may have completed it.
        final current = await _store.outboxEntry(entry.id);
        if (current == null || current.failed) {
          continue;
        }
        try {
          await _send(current);
          _retryRound = 0;
        } on Object catch (e) {
          switch (retryDecisionFor(e)) {
            case RetryDecision.waitForConnection:
              return false;
            case RetryDecision.reconcile:
              _scheduleRetry();
              return true;
            case RetryDecision.retryLater:
              final attempts = current.attempts + 1;
              if (attempts >= maxSendAttempts) {
                await _giveUp(current, ChatFailure.of(e));
                continue;
              }
              await _store.updateOutbox(
                current.id,
                attempts: attempts,
                inFlight: false,
              );
              _scheduleRetry();
              return true;
            case RetryDecision.fail:
              await _giveUp(current, ChatFailure.of(e));
          }
        }
      }
      return true;
    } on ConnectionClosedException {
      return false;
    } finally {
      unawaited(_remote.detach(topic).then((_) {}, onError: (_) {}));
    }
  }

  Future<void> _send(OutboxEntry entry) async {
    switch (entry.kind) {
      case OutboxKind.publish:
        final clientId = entry.clientId!;
        await _store.updateOutbox(
          entry.id,
          inFlight: true,
          sentAfterSeq: await _newestSeq(entry.topic),
        );
        _sending = clientId;
        _emit(OutgoingChanged(entry.toOutgoing(sending: true)));
        try {
          final ack = await _remote.publish(
            entry.topic,
            entry.content,
            head: {clientIdHeadKey: clientId},
          );
          await _complete(
            entry,
            DataMessage(
              topic: entry.topic,
              seq: ack.seq,
              time: ack.time,
              from: userId,
              head: MessageHead.fromJson({
                if (entry.content is DraftyContent)
                  'mime': MessageHead.draftyMime,
                clientIdHeadKey: clientId,
              }),
              content: entry.content,
            ),
          );
        } finally {
          _sending = null;
        }
      case OutboxKind.delete:
        final deleteId = await _remote.deleteMessages(
          entry.topic,
          entry.ranges,
          hard: entry.hard,
        );
        // Only the next delete ID can be recorded: anything between would
        // be deletions this cache has not applied yet.
        if (deleteId == await _store.syncedDeleteId(entry.topic) + 1) {
          await _store.setSyncedDeleteId(entry.topic, deleteId);
        }
        await _store.removeOutbox(entry.id);
      case OutboxKind.read:
        _remote.markRead(entry.topic, entry.seq!);
        await _store.removeOutbox(entry.id);
    }
  }

  /// Entries sent before a drop may have reached the server: look for
  /// their client IDs there before sending any again.
  Future<void> _reconcile(String topic, List<OutboxEntry> inFlight) async {
    final publishes = inFlight
        .where((e) => e.kind == OutboxKind.publish)
        .toList();
    if (publishes.isEmpty) {
      return;
    }
    final found = <String, DataMessage>{};
    var since = publishes.map((e) => e.sentAfterSeq).reduce(min) + 1;
    for (var page = 0; page < 10; page++) {
      final fetched = await history(topic, since: since, limit: _reconcilePage);
      for (final message in fetched) {
        if (clientIdOf(message.head) case final id?
            when message.from == userId) {
          found[id] = message;
        }
      }
      if (fetched.length < _reconcilePage) {
        break;
      }
      since = fetched.last.seq + 1;
    }
    for (final entry in publishes) {
      if (found[entry.clientId] case final message?) {
        await _complete(entry, message);
      } else {
        // Not on the server: safe to send again.
        await _store.updateOutbox(entry.id, inFlight: false);
      }
    }
    // Deletes and read markers are safe to repeat.
  }

  /// The server has [entry] as [message].
  Future<void> _complete(OutboxEntry entry, DataMessage message) async {
    final first = await _store.completePublish(entry, message);
    await _store.advanceChat(
      message.topic,
      lastSeq: message.seq,
      read: message.seq,
      lastMessageAt: message.time,
    );
    if (first) {
      _emit(OutgoingSent(entry.clientId!, message));
    }
  }

  Future<void> _giveUp(OutboxEntry entry, ChatFailure failure) async {
    switch (entry.kind) {
      case OutboxKind.publish:
        await _store.updateOutbox(entry.id, failure: failure, inFlight: false);
        _emit(
          OutgoingChanged(
            entry.toOutgoing().withStatus(
              OutgoingStatus.failed,
              failure: failure,
            ),
          ),
        );
      case OutboxKind.delete:
        // The messages are still there: fetch them again.
        await _store.removeOutbox(entry.id);
        await _store.uncover(entry.topic, entry.ranges);
        if (!_closed) {
          _deletions.add(
            TopicDeletion(entry.topic, entry.ranges, restored: true),
          );
        }
      case OutboxKind.read:
        await _store.removeOutbox(entry.id);
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(retryDelay(++_retryRound), _kick);
  }

  Future<int> _newestSeq(String topic) async {
    final chat = await _store.chat(topic);
    final top = (await _store.coverage(topic)).top;
    return max(chat?.lastSeq ?? 0, (top?.high ?? 1) - 1);
  }

  // Arriving events.

  void _onMessage(DataMessage message) => unawaited(
    _write(() async {
      await _store.putLive(message);
      final own = message.from == userId;
      await _store.advanceChat(
        message.topic,
        lastSeq: message.seq,
        read: own ? message.seq : null,
        lastMessageAt: message.time,
      );
      // The echo of an outbox message may beat the server's ack.
      if (clientIdOf(message.head) case final id? when own) {
        if (await _store.outboxByClientId(id) case final entry?) {
          await _complete(entry, message);
        }
      }
    }),
  );

  void _onPresence(PresMessage presence) {
    final source = presence.source;
    switch (presence) {
      case PresMessage(topic: 'me', event: PresenceEvent.message, :final seq?)
          when source != null:
        unawaited(
          _write(
            () => _store.advanceChat(
              source,
              lastSeq: seq,
              lastMessageAt: clock.now().toUtc(),
            ),
          ),
        );
      case PresMessage(topic: 'me', event: PresenceEvent.read, :final seq?)
          when source != null:
        unawaited(_write(() => _store.advanceChat(source, read: seq)));
      case PresMessage(
            :final topic,
            event: PresenceEvent.deleted,
            :final deletedRanges,
          )
          when topic != 'me' && deletedRanges.isNotEmpty:
        unawaited(_write(() => _onDeleted(presence)));
      case _:
        break;
    }
  }

  Future<void> _onDeleted(PresMessage presence) async {
    final topic = presence.topic;
    await _applyDeletion(topic, presence.deletedRanges);
    final deleteId = presence.lastDeleteId;
    if (deleteId != null &&
        deleteId == await _store.syncedDeleteId(topic) + 1) {
      await _store.setSyncedDeleteId(topic, deleteId);
    } else {
      // Deletions came in between: read them from the log.
      unawaited(_syncDeletes(topic));
    }
  }

  void _onStatus(ConnectionStatus status) {
    if (status is Connected) {
      _retryRound = 0;
      _kick();
    }
  }

  // Plumbing.

  /// Queues a store write behind the earlier ones. A failed write is
  /// logged: the cache misses it, the chat goes on.
  Future<void> _write(Future<void> Function() write) => _writes = _writes
      .then((_) => write())
      .catchError(
        (Object e, StackTrace stackTrace) =>
            _log('A cache write failed', e, stackTrace),
      );

  void _emit(OutboxEvent event) {
    if (!_closed) {
      _outbox.add(event);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _retry?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    await _remote.close();
    await _writes;
    await _store.close();
    unawaited(_outbox.close());
    unawaited(_deletions.close());
  }

  /// The seqs a history request answered for: `since <= seq < before`, cut
  /// at the oldest message when the page was full.
  static SeqRange? _covered(
    List<DataMessage> page, {
    required int? since,
    required int? before,
    required int limit,
  }) {
    final low = page.length >= limit ? page.first.seq : (since ?? 1);
    final high = before ?? (page.isEmpty ? null : page.last.seq + 1);
    return high != null && high > low ? SeqRange(low, high) : null;
  }

  static void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );
}
