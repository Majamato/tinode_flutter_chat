import 'dart:async';
import 'dart:developer';

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

/// The calls history, read from the call log like the chat list's previews
/// from the cache: all calls first, then a chat's again when its stored
/// messages change (`ChatSession.storedChanges`). Only direct chats have
/// calls.
///
/// It never asks the server: every call the session sees reaches the log,
/// and its latest catch-up fetches the newest messages of each chat it is
/// behind on, calls included. When the log can't be read the history is
/// empty rather than loading forever, and what it shows stays.
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
    final calls = _byTopic(await _stored(session) ?? const [], me);
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
      final stored = await _stored(session, topic: topic);
      if (stored == null) {
        return;
      }
      calls.addAll(_byTopic(stored, me));
    }
    if (lifetime.isActive) {
      state = state.withCalls(calls);
    }
  }

  /// The stored calls; null when the log can't be read.
  static Future<List<CachedCall>?> _stored(
    ChatSession session, {
    String? topic,
  }) async {
    try {
      return await session.storedCalls(topic: topic);
    } on Object catch (e, stackTrace) {
      log(
        'Could not read the calls',
        name: 'tinode_flutter_chat',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
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
