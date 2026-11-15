import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';
import 'package:tinode_flutter_chat/src/offline/domain/call_page.dart';

/// The calls read so far from the call log, newest first, a page at a
/// time: every call down to [cursor], and none older.
///
/// Because it holds every call down to [cursor], a chat read again from
/// there is all a change needs: its new calls come in, its deleted
/// ones go and its changed ones change.
///
/// Updates keep the same [ids] instance while the order is the same, so a
/// list that selects [ids] doesn't rebuild when only a call changed.
@immutable
final class CallWindow {
  const CallWindow()
    : started = false,
      cursor = null,
      ids = const [],
      _byId = const {};

  const CallWindow._(this.started, this.cursor, this.ids, this._byId);

  /// A page was read.
  final bool started;

  /// The last call read: the next page is read before it, and a changed
  /// chat from it. Null before the first page, and once nothing older is
  /// left, when a changed chat is read whole.
  final CallKey? cursor;

  /// The calls, newest first.
  final List<CallId> ids;

  final Map<CallId, CallHistoryEntry> _byId;

  CallHistoryEntry? operator [](CallId id) => _byId[id];

  /// Nothing older is left to read.
  bool get reachedEnd => started && cursor == null;

  /// The window with [entries], the page read before [cursor], below
  /// what it holds; [next] is where the page after it starts.
  CallWindow withPage(Iterable<CallHistoryEntry> entries, {CallKey? next}) =>
      _with({..._byId, for (final entry in entries) entry.id: entry}, next);

  /// The window with [entries] in place of [topic]'s calls from [from] on
  /// (all of them when null), as read from [cursor]. [topic]'s calls older
  /// than [from] stay: a page may have come in below it since. Before the
  /// first page there is nothing to replace.
  CallWindow withChat(
    String topic,
    Iterable<CallHistoryEntry> entries, {
    CallKey? from,
  }) => !started
      ? this
      : _with({
          for (final MapEntry(:key, :value) in _byId.entries)
            if (key.topic != topic ||
                (from != null && _isOlder(value.key, from)))
              key: value,
          for (final entry in entries) entry.id: entry,
        }, cursor);

  CallWindow _with(Map<CallId, CallHistoryEntry> byId, CallKey? cursor) {
    final entries = byId.values.toList()
      ..sort((a, b) => compareNewestFirst(a.key, b.key));
    final sorted = [for (final entry in entries) entry.id];
    return CallWindow._(
      true,
      cursor,
      const ListEquality<CallId>().equals(sorted, ids)
          ? ids
          : List.unmodifiable(sorted),
      Map.unmodifiable(byId),
    );
  }

  static bool _isOlder(CallKey key, CallKey than) =>
      compareNewestFirst(key, than) > 0;
}

/// The call log's order, newest first: by time, then chat, then seq, each
/// descending.
int compareNewestFirst(CallKey a, CallKey b) =>
    switch (b.time.compareTo(a.time)) {
      0 => switch (b.topic.compareTo(a.topic)) {
        0 => b.seq.compareTo(a.seq),
        final order => order,
      },
      final order => order,
    };
