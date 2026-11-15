import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_log_reader.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_history_controller.g.dart';

/// The calls the calls history and the call search read from the call log
/// at a time.
const callPageSize = 50;

/// The calls history, read from the call log a page at a time: the newest
/// [callPageSize] first, the next ones as the tab scrolls ([loadMore]).
/// When a chat's stored messages change (`ChatSession.storedChanges`), it
/// reads that chat's calls again down to the last one read. Only direct
/// chats have calls.
///
/// It never asks the server: every call the session sees reaches the log,
/// and its latest catch-up fetches the newest messages of each chat it is
/// behind on, calls included. When the log can't be read the history is
/// empty rather than loading forever, and what it shows stays.
@Riverpod(keepAlive: true)
class CallHistoryController extends _$CallHistoryController {
  final _changed = <String>{};
  CallLogReader? _reader;
  late BuildLifetime _lifetime;

  @override
  CallHistory build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _changed.clear();
    _reader = null;
    if (session == null || me == null) {
      return const CallHistory();
    }

    final reader = _reader = CallLogReader(session, me);
    final changes = session.storedChanges.listen((topic) {
      if (TopicKind.of(topic) != TopicKind.direct) {
        return;
      }
      if (_changed.isEmpty) {
        scheduleMicrotask(() => unawaited(_reload(reader, lifetime)));
      }
      _changed.add(topic);
    });
    ref.onDispose(() => unawaited(changes.cancel()));
    unawaited(
      reader.queued(() async {
        final page = await reader.read(limit: callPageSize);
        if (lifetime.isActive) {
          state = state.withPage(page?.entries ?? const [], next: page?.next);
        }
      }),
    );
    return const CallHistory();
  }

  /// Reads the calls after the ones shown, unless they are being read or
  /// there are none.
  Future<void> loadMore() async {
    final reader = _reader;
    if (reader == null || !state.hasMore || state.loadingMore) {
      return;
    }
    final lifetime = _lifetime;
    state = state.withLoadingMore(loading: true);
    await reader.queued(() async {
      final page = await reader.read(
        before: state.window.cursor,
        limit: callPageSize,
      );
      if (lifetime.isActive) {
        state = page == null
            ? state.withLoadingMore(loading: false)
            : state.withPage(page.entries, next: page.next);
      }
    });
  }

  /// Reads the chats changed since the last time again, down to the last
  /// call read; a chat that can't be read keeps what it shows.
  Future<void> _reload(CallLogReader reader, BuildLifetime lifetime) =>
      reader.queued(() async {
        final topics = Set.of(_changed);
        _changed.clear();
        for (final topic in topics) {
          if (!lifetime.isActive || !state.window.started) {
            return;
          }
          final from = state.window.cursor;
          final calls = await reader.read(topics: {topic}, from: from);
          if (calls != null && lifetime.isActive) {
            state = state.withChat(topic, calls.entries, from: from);
          }
        }
      });
}

/// One call of the history, for its row.
@riverpod
CallHistoryEntry? callHistoryEntry(Ref ref, String topic, int seq) => ref.watch(
  callHistoryControllerProvider.select(
    (history) => history[(topic: topic, seq: seq)],
  ),
);
