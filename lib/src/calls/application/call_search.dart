import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_log_reader.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_matches.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_search_state.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_window.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_matches.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/name_match.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_search.g.dart';

/// The call search as the user types ([search]): the calls of the chats
/// whose name matches (see [CallMatches]) in the whole call log, exact
/// matches first, newest first among each. It reads them a page of
/// [callPageSize] at a time, the next ones as the results scroll
/// ([loadMore]), and a changed chat again as the calls history does. It
/// never asks the server, and opens on every call.
@riverpod
class CallSearchController extends _$CallSearchController {
  final _changed = <String>{};
  CallLogReader? _reader;
  late BuildLifetime _lifetime;
  var _input = '';

  /// The chats the log had calls of when the search last matched names.
  var _known = const <String>{};

  /// Counts the searches; an answer counts only for the latest.
  var _runs = 0;

  @override
  CallSearchState build() {
    final lifetime = _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _changed.clear();
    _reader = null;
    if (session == null || me == null) {
      return const CallSearchState();
    }

    final reader = _reader = CallLogReader(session, me);
    watchCallsWhileShown(ref, session);
    final changes = session.storedChanges.listen((topic) {
      if (TopicKind.of(topic) != TopicKind.direct) {
        return;
      }
      if (_changed.isEmpty) {
        scheduleMicrotask(() => unawaited(_reload(reader, lifetime)));
      }
      _changed.add(topic);
    });
    ref
      ..onDispose(() => unawaited(changes.cancel()))
      ..listen(chatListControllerProvider.select(ChatMatches.fromChatList), (
        _,
        chats,
      ) {
        // A chat renamed into or out of the search.
        if (state.loaded &&
            !matchesEveryone(_input) &&
            CallMatches.of(_known, _titles(chats), _input) != state.matches) {
          unawaited(_run(reader, lifetime));
        }
      });
    unawaited(_run(reader, lifetime));
    return const CallSearchState();
  }

  /// The user typed [input]: searches it, showing what was found before
  /// until the first page of it is read.
  void search(String input) {
    if (input == _input) {
      return;
    }
    _input = input;
    if (_reader case final reader?) {
      unawaited(_run(reader, _lifetime));
    }
  }

  /// Reads the calls after the ones shown, unless they are being read or
  /// there are none.
  Future<void> loadMore() async {
    final reader = _reader;
    if (reader == null || !state.hasMore || state.loadingMore) {
      return;
    }
    final run = _runs;
    final lifetime = _lifetime;
    bool isCurrent() => lifetime.isActive && run == _runs;
    state = state.withLoadingMore(loading: true);
    await reader.queued(() async {
      if (!isCurrent()) {
        return;
      }
      final read = await _read(reader, state.matches, state.exact, state.typos);
      if (isCurrent()) {
        state = switch (read) {
          (final exact, final typos) => state.withWindows(exact, typos),
          null => state,
        }.withLoadingMore(loading: false);
      }
    });
  }

  Future<void> _run(CallLogReader reader, BuildLifetime lifetime) {
    final run = ++_runs;
    final input = _input;
    bool isCurrent() => lifetime.isActive && run == _runs;
    return reader.queued(() async {
      if (!isCurrent()) {
        return;
      }
      final CallMatches matches;
      if (matchesEveryone(input)) {
        matches = const CallMatches.everyChat();
      } else {
        _known = await reader.topics() ?? const {};
        matches = CallMatches.of(
          _known,
          _titles(
            ChatMatches.fromChatList(ref.read(chatListControllerProvider)),
          ),
          input,
        );
      }
      const none = CallWindow();
      final read = isCurrent()
          ? await _read(reader, matches, none, none)
          : null;
      if (isCurrent()) {
        // When the log can't be read, nothing is found.
        final (exact, typos) =
            read ?? (none.withPage(const []), none.withPage(const []));
        state = state.found(matches, exact, typos);
      }
    });
  }

  /// [exact] and [typos] read further by [callPageSize] calls in all: the
  /// calls of [CallMatches.exact] first, then, once those reached their
  /// end, of [CallMatches.typos]. Null when the log can't be read.
  static Future<(CallWindow, CallWindow)?> _read(
    CallLogReader reader,
    CallMatches matches,
    CallWindow exact,
    CallWindow typos,
  ) async {
    var read = exact;
    var room = callPageSize;
    if (!read.reachedEnd) {
      final page = await reader.read(
        topics: matches.exact,
        before: read.cursor,
        limit: room,
      );
      if (page == null) {
        return null;
      }
      read = read.withPage(page.entries, next: page.next);
      room -= page.entries.length;
    }
    if (!read.reachedEnd || room <= 0 || typos.reachedEnd) {
      return (read, typos);
    }
    final page = await reader.read(
      topics: matches.typos,
      before: typos.cursor,
      limit: room,
    );
    return page == null
        ? null
        : (read, typos.withPage(page.entries, next: page.next));
  }

  /// Reads the chats changed since the last time again, in whichever of
  /// the search's windows holds them, down to the last call it read. A
  /// chat the search didn't know may have its first call now: when that
  /// changes which chats match, it searches again. Any other message of a
  /// chat changes nothing.
  Future<void> _reload(CallLogReader reader, BuildLifetime lifetime) =>
      reader.queued(() async {
        final topics = Set.of(_changed);
        _changed.clear();
        if (!lifetime.isActive || !state.loaded) {
          return;
        }
        if (!matchesEveryone(_input) && !_known.containsAll(topics)) {
          final known = await reader.topics();
          if (!lifetime.isActive) {
            return;
          }
          if (known != null) {
            _known = known;
            final chats = ChatMatches.fromChatList(
              ref.read(chatListControllerProvider),
            );
            if (CallMatches.of(known, _titles(chats), _input) !=
                state.matches) {
              unawaited(_run(reader, lifetime));
              return;
            }
          }
        }
        for (final topic in topics) {
          final matches = state.matches;
          final inExact = matches.exact?.contains(topic) ?? true;
          if (!inExact && !matches.typos.contains(topic)) {
            continue;
          }
          final window = inExact ? state.exact : state.typos;
          if (!window.started) {
            continue;
          }
          final from = window.cursor;
          final calls = await reader.read(topics: {topic}, from: from);
          if (!lifetime.isActive || state.matches != matches) {
            return;
          }
          if (calls != null) {
            state = inExact
                ? state.withWindows(
                    state.exact.withChat(topic, calls.entries, from: from),
                    state.typos,
                  )
                : state.withWindows(
                    state.exact,
                    state.typos.withChat(topic, calls.entries, from: from),
                  );
          }
        }
      });

  static Map<String, String> _titles(ChatMatches chats) => {
    for (final chat in chats.chats) chat.topic: chat.title,
  };
}

/// One call the call search found, for its row.
@riverpod
CallHistoryEntry? callSearchEntry(Ref ref, String topic, int seq) => ref.watch(
  callSearchControllerProvider.select(
    (search) => search[(topic: topic, seq: seq)],
  ),
);
