import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_window.dart';
import 'package:tinode_flutter_chat/src/offline/domain/call_page.dart';

/// The calls history: the calls of the call log read so far, newest first,
/// a page at a time as the tab scrolls; see [CallWindow].
@immutable
final class CallHistory {
  const CallHistory()
    : loaded = false,
      loadingMore = false,
      window = const CallWindow();

  const CallHistory._(this.loaded, this.loadingMore, this.window);

  /// The first page was read, or the log couldn't be.
  final bool loaded;

  /// The next page is being read.
  final bool loadingMore;

  final CallWindow window;

  /// The calls shown, newest first; see [CallWindow.ids].
  List<CallId> get ids => window.ids;

  CallHistoryEntry? operator [](CallId id) => window[id];

  /// Older calls are left to read.
  bool get hasMore => loaded && !window.reachedEnd;

  /// The history with [entries], the next page, below what it shows.
  CallHistory withPage(Iterable<CallHistoryEntry> entries, {CallKey? next}) =>
      CallHistory._(true, false, window.withPage(entries, next: next));

  /// The history with [entries] in place of [topic]'s calls from [from]
  /// on; see [CallWindow.withChat].
  CallHistory withChat(
    String topic,
    Iterable<CallHistoryEntry> entries, {
    CallKey? from,
  }) => CallHistory._(
    loaded,
    loadingMore,
    window.withChat(topic, entries, from: from),
  );

  CallHistory withLoadingMore({required bool loading}) =>
      CallHistory._(loaded, loading, window);
}
