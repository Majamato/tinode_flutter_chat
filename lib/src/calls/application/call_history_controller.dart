import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_history_controller.g.dart';

/// The calls history, read from the cache like the chat list's previews:
/// all calls first, then a chat's again when its cached messages change
/// (`ChatSession.storedChanges`). Only direct chats have calls.
///
/// It never asks the server: the session's latest catch-up fills the cache
/// with the newest messages of each chat it is behind on, calls included.
@Riverpod(keepAlive: true)
class CallHistoryController extends _$CallHistoryController {
  final _changed = <String>{};

  @override
  CallHistory build() {
    final lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _changed.clear();
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
    ref.onDispose(() => unawaited(changes.cancel()));
    unawaited(_load(session, me, lifetime));
    return const CallHistory();
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
