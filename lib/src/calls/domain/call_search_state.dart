import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_matches.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_window.dart';

/// What the call search shows: the calls of the chats that match exactly,
/// newest first, then those of the chats a letter off, read from the call
/// log a page at a time; see [CallWindow].
///
/// Updates keep the same [ids] instance while the order is the same, so a
/// list that selects [ids] doesn't rebuild when only a call changed.
@immutable
final class CallSearchState {
  const CallSearchState()
    : matches = const CallMatches.everyChat(),
      exact = const CallWindow(),
      typos = const CallWindow(),
      loaded = false,
      loadingMore = false,
      ids = const [];

  const CallSearchState._(
    this.matches,
    this.exact,
    this.typos,
    this.ids, {
    required this.loaded,
    required this.loadingMore,
  });

  /// The chats whose calls show.
  final CallMatches matches;

  /// The calls of [CallMatches.exact].
  final CallWindow exact;

  /// The calls of [CallMatches.typos], read once [exact] reached its end.
  final CallWindow typos;

  /// The first page of the search was read.
  final bool loaded;

  /// The next page is being read.
  final bool loadingMore;

  /// The calls shown, best first: those of [exact], then of [typos].
  final List<CallId> ids;

  CallHistoryEntry? operator [](CallId id) => exact[id] ?? typos[id];

  bool get isEmpty => ids.isEmpty;

  /// Older calls are left to read.
  bool get hasMore => loaded && !(exact.reachedEnd && typos.reachedEnd);

  /// A search for [matches], whose first page is in [exact] and [typos].
  CallSearchState found(
    CallMatches matches,
    CallWindow exact,
    CallWindow typos,
  ) => _with(matches, exact, typos, loaded: true, loadingMore: false);

  /// The search with [exact] and [typos] read further or again.
  CallSearchState withWindows(CallWindow exact, CallWindow typos) =>
      _with(matches, exact, typos, loaded: loaded, loadingMore: loadingMore);

  CallSearchState withLoadingMore({required bool loading}) =>
      _with(matches, exact, typos, loaded: loaded, loadingMore: loading);

  CallSearchState _with(
    CallMatches matches,
    CallWindow exact,
    CallWindow typos, {
    required bool loaded,
    required bool loadingMore,
  }) {
    final shown = [...exact.ids, ...typos.ids];
    return CallSearchState._(
      matches,
      exact,
      typos,
      const ListEquality<CallId>().equals(shown, ids)
          ? ids
          : List.unmodifiable(shown),
      loaded: loaded,
      loadingMore: loadingMore,
    );
  }
}
