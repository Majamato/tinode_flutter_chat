import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_search_state.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'message_search_controller.g.dart';

/// How long the input must stay unchanged before it is searched.
const messageSearchDebounce = Duration(milliseconds: 300);

/// Found messages fetched per page.
const messageSearchPageSize = 30;

/// A message search as the user types, over the messages of the chat named
/// [topic] kept on this device. It waits for the input to settle and drops
/// answers to older input. It needs no network: the server has no message
/// search.
@riverpod
class MessageSearchController extends _$MessageSearchController {
  late BuildLifetime _lifetime;
  Timer? _debounce;
  String? _match;

  /// Counts the searches; an answer counts only for the latest.
  var _runs = 0;

  @override
  MessageSearchState build(String topic) {
    _lifetime = BuildLifetime(ref);
    _match = null;
    ref
      ..watch(activeSessionProvider)
      ..onDispose(() => _debounce?.cancel());
    return const MessageSearchState.idle();
  }

  /// The user typed [input]: searches it once it stays unchanged for
  /// [messageSearchDebounce]. Input too short to search clears the results.
  void search(String input) {
    final match = messageMatch(input);
    if (match == _match) {
      return;
    }
    _match = match;
    _debounce?.cancel();
    // An answer to the previous input no longer counts.
    _runs++;
    if (match == null) {
      state = const MessageSearchState.idle();
      return;
    }
    state = state.searching();
    _debounce = Timer(messageSearchDebounce, () => unawaited(_run()));
  }

  /// Searches the current input again at once, e.g. after a failure.
  void retry() {
    _debounce?.cancel();
    unawaited(_run());
  }

  /// Loads the results after the ones shown.
  Future<void> loadMore() async {
    final match = _match;
    if (match == null ||
        state.status != MessageSearchStatus.done ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    final run = _runs;
    final lifetime = _lifetime;
    bool isCurrent() => lifetime.isActive && run == _runs;
    state = state.withLoadingMore(loading: true);
    try {
      final more = await _session().searchMessages(
        topic,
        match,
        before: state.results.last.seq,
        limit: messageSearchPageSize,
      );
      if (isCurrent()) {
        state = state.withMore(
          more,
          hasMore: more.length >= messageSearchPageSize,
        );
      }
    } on Object {
      if (isCurrent()) {
        state = state.withLoadingMore(loading: false);
      }
    }
  }

  Future<void> _run() async {
    final match = _match;
    if (match == null) {
      return;
    }
    final run = ++_runs;
    final lifetime = _lifetime;
    bool isCurrent() => lifetime.isActive && run == _runs;
    state = state.searching();
    try {
      final found = await _session().searchMessages(
        topic,
        match,
        limit: messageSearchPageSize,
      );
      if (isCurrent()) {
        state = state.done(
          found,
          hasMore: found.length >= messageSearchPageSize,
        );
      }
    } on Object catch (e) {
      if (isCurrent()) {
        state = state.failed(ChatFailure.of(e));
      }
    }
  }

  ChatSession _session() =>
      ref.read(activeSessionProvider) ??
      (throw const ConnectionLostException());
}
