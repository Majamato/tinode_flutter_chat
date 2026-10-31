import 'dart:async';
import 'dart:collection';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_history_controller.g.dart';

/// The calls history, read from the cache like the chat list's previews:
/// all calls first, then a chat's again when its cached messages change
/// (`ChatSession.storedChanges`). Only direct chats have calls.
///
/// The cache holds only what this device fetched, so [refresh] fetches the
/// newest messages of the direct chats it is behind on.
@Riverpod(keepAlive: true)
class CallHistoryController extends _$CallHistoryController {
  /// Chats [refresh] fetches at once.
  static const fetchConcurrency = 3;

  /// The most chats one [refresh] fetches, the newest first.
  static const fetchChats = 30;

  /// Messages fetched per chat.
  static const fetchPage = 24;

  final _changed = <String>{};

  /// The `lastSeq` each chat had when this session last fetched it.
  final _fetchedUpTo = <String, int>{};

  Future<void>? _refreshing;
  late BuildLifetime _lifetime;

  /// A refresh asked for while it couldn't run: offline, or before the
  /// chat list loaded. It runs once it can.
  bool? _waiting;

  @override
  CallHistory build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _changed.clear();
    _fetchedUpTo.clear();
    _refreshing = null;
    _waiting = null;
    if (session == null || me == null) {
      return const CallHistory();
    }

    final changes = session.storedChanges.listen((topic) {
      if (TopicKind.of(topic) != TopicKind.direct) {
        return;
      }
      if (_changed.isEmpty) {
        scheduleMicrotask(() => unawaited(_reload(session, me, lifetime)));
      }
      _changed.add(topic);
    });
    final connected = session.statusChanges
        .where((status) => status is Connected)
        .listen((_) => _retry());
    ref
      ..onDispose(() => unawaited(changes.cancel()))
      ..onDispose(() => unawaited(connected.cancel()))
      ..listen(chatListControllerProvider.select((list) => list.status), (
        _,
        status,
      ) {
        if (status == LoadStatus.ready) {
          _retry();
        }
      });
    unawaited(_load(session, me, lifetime));
    return const CallHistory();
  }

  /// Fetches the newest messages of each direct chat whose cache is behind
  /// and that this session hasn't fetched since it was last behind, or
  /// every one behind with [force]; the history then reads them. Waits
  /// while offline or before the chat list is there.
  Future<void> refresh({bool force = false}) {
    if (_refreshing case final running?) {
      return running;
    }
    final session = ref.read(activeSessionProvider);
    if (session == null ||
        session.status is! Connected ||
        ref.read(chatListControllerProvider).status != LoadStatus.ready) {
      _waiting = force || (_waiting ?? false);
      return Future.value();
    }
    _waiting = null;
    return _refreshing = _refresh(
      session,
      _lifetime,
      force: force,
    ).whenComplete(() => _refreshing = null);
  }

  void _retry() {
    if (_waiting case final force?) {
      unawaited(refresh(force: force));
    }
  }

  Future<void> _refresh(
    ChatSession session,
    BuildLifetime lifetime, {
    required bool force,
  }) async {
    final latest = await session.storedLatestMessages();
    if (!lifetime.isActive) {
      return;
    }
    final behind =
        ref
            .read(chatListControllerProvider)
            .byTopic
            .values
            .where(
              (chat) =>
                  chat.kind == TopicKind.direct &&
                  chat.lastSeq > (latest[chat.topic]?.newestSeq ?? 0) &&
                  (force || chat.lastSeq > (_fetchedUpTo[chat.topic] ?? 0)),
            )
            .toList()
          ..sort(
            (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
              a.lastMessageAt ?? DateTime(0),
            ),
          );
    if (behind.isEmpty) {
      return;
    }
    final queue = Queue.of(behind.take(fetchChats));
    for (final chat in queue) {
      _fetchedUpTo[chat.topic] = chat.lastSeq;
    }
    state = state.withRefreshing(refreshing: true);
    Future<void> worker() async {
      while (queue.isNotEmpty && lifetime.isActive) {
        await _fetch(session, queue.removeFirst().topic);
      }
    }

    await Future.wait([for (var i = 0; i < fetchConcurrency; i++) worker()]);
    if (lifetime.isActive) {
      state = state.withRefreshing(refreshing: false);
    }
  }

  /// Attaches [topic] long enough to cache its newest messages.
  static Future<void> _fetch(ChatSession session, String topic) async {
    try {
      await session.attach(topic);
    } on Object {
      // Skipped this time; the chat stays behind.
      return;
    }
    try {
      await session.catchUp(topic, limit: fetchPage);
    } on Object {
      // As above.
    } finally {
      unawaited(session.detach(topic).then((_) {}, onError: (_) {}));
    }
  }

  Future<void> _load(
    ChatSession session,
    String me,
    BuildLifetime lifetime,
  ) async {
    final calls = _byTopic(await session.storedCalls(), me);
    if (lifetime.isActive) {
      // A chat read again meanwhile is newer than this first read.
      state = state.withCalls({...calls, ...state.byTopic}, all: true);
    }
  }

  Future<void> _reload(
    ChatSession session,
    String me,
    BuildLifetime lifetime,
  ) async {
    final topics = Set.of(_changed);
    _changed.clear();
    final calls = <String, List<CallHistoryEntry>>{
      for (final topic in topics) topic: const [],
    };
    for (final topic in topics) {
      calls.addAll(_byTopic(await session.storedCalls(topic: topic), me));
    }
    if (lifetime.isActive) {
      state = state.withCalls(calls);
    }
  }

  static Map<String, List<CallHistoryEntry>> _byTopic(
    Iterable<CachedCall> cached,
    String me,
  ) {
    final calls = <String, List<CallHistoryEntry>>{};
    for (final call in cached) {
      if (TopicKind.of(call.message.topic) == TopicKind.direct) {
        if (CallHistoryEntry.of(call, me: me) case final entry?) {
          calls.putIfAbsent(entry.topic, () => []).add(entry);
        }
      }
    }
    return calls;
  }
}

/// One call of the history, for its row.
@riverpod
CallHistoryEntry? callHistoryEntry(Ref ref, String topic, int seq) => ref.watch(
  callHistoryControllerProvider.select(
    (history) => history[(topic: topic, seq: seq)],
  ),
);
