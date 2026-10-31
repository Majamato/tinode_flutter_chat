import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history_entry.dart';

/// Names one call of the history: its chat and the seq that started it.
typedef CallId = ({String topic, int seq});

/// The calls history: the calls the cache holds in direct chats, by chat,
/// and the newest [limit] of them, newest first.
///
/// Updates keep the same [ids] instance while the order is the same, so a
/// list that selects [ids] doesn't rebuild when only a call changed.
@immutable
final class CallHistory {
  const CallHistory()
    : loaded = false,
      refreshing = false,
      byTopic = const {},
      ids = const [],
      _byId = const {};

  const CallHistory._(
    this.loaded,
    this.refreshing,
    this.byTopic,
    this.ids,
    this._byId,
  );

  /// The most calls the history shows.
  static const limit = 200;

  /// The cache was read.
  final bool loaded;

  /// Chats behind in the cache are being fetched.
  final bool refreshing;

  final Map<String, List<CallHistoryEntry>> byTopic;

  /// The calls shown, newest first.
  final List<CallId> ids;

  final Map<CallId, CallHistoryEntry> _byId;

  CallHistoryEntry? operator [](CallId id) => _byId[id];

  /// The history with [calls] in place of what it held of their chats;
  /// with [all], of every chat.
  CallHistory withCalls(
    Map<String, List<CallHistoryEntry>> calls, {
    bool all = false,
  }) {
    final byTopic = Map<String, List<CallHistoryEntry>>.unmodifiable(
      <String, List<CallHistoryEntry>>{if (!all) ...this.byTopic, ...calls}
        ..removeWhere((_, entries) => entries.isEmpty),
    );
    final newest = [for (final entries in byTopic.values) ...entries]
      ..sort(
        (a, b) => switch (b.time.compareTo(a.time)) {
          0 => b.seq.compareTo(a.seq),
          final order => order,
        },
      );
    final shown = newest.take(limit).toList();
    final ids = [
      for (final entry in shown) (topic: entry.topic, seq: entry.seq),
    ];
    return CallHistory._(
      true,
      refreshing,
      byTopic,
      const ListEquality<CallId>().equals(ids, this.ids)
          ? this.ids
          : List.unmodifiable(ids),
      {for (final entry in shown) (topic: entry.topic, seq: entry.seq): entry},
    );
  }

  CallHistory withRefreshing({required bool refreshing}) =>
      refreshing == this.refreshing
      ? this
      : CallHistory._(loaded, refreshing, byTopic, ids, _byId);
}
