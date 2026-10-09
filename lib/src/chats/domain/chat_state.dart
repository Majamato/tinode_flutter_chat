import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// The longest pause between two messages of one run.
const runGap = Duration(minutes: 5);

/// The messages of one open chat, by seq, plus loading flags.
///
/// History pages, live messages and publish acks all merge through
/// [withMessages], which dedups by seq. Updates return `this` when nothing
/// changed and keep the same [seqs] instance unless a seq was added, so the
/// message list only rebuilds when a bubble appears.
///
/// A message that updates another (`replace`, as the server does for calls)
/// changes that bubble instead of adding one. If its target is not loaded
/// yet, it waits in [pending] until the target arrives with an older page.
///
/// Messages still in the outbox have no seq yet: they are [outgoingIds],
/// shown after the numbered ones until the server numbers them.
@immutable
final class ChatState {
  const ChatState.loading()
    : status = LoadStatus.loading,
      failure = null,
      bySeq = const {},
      seqs = const [],
      pending = const {},
      firstSeq = null,
      lastSeq = null,
      hasOlder = false,
      loadingOlder = false,
      outgoingIds = const [],
      outgoingById = const {};

  const ChatState._({
    required this.status,
    required this.failure,
    required this.bySeq,
    required this.seqs,
    required this.pending,
    required this.firstSeq,
    required this.lastSeq,
    required this.hasOlder,
    required this.loadingOlder,
    required this.outgoingIds,
    required this.outgoingById,
  });

  final LoadStatus status;

  /// Why the first load failed; set when [status] is [LoadStatus.failed].
  final ChatFailure? failure;
  final Map<int, ChatMessage> bySeq;

  /// Every seq in [bySeq], ascending.
  final List<int> seqs;

  /// The newest update of each message that is not loaded yet, by the seq
  /// of that message.
  final Map<int, ChatMessage> pending;

  /// The lowest and highest seq seen, updates included: the bounds for
  /// fetching older and newer messages.
  final int? firstSeq;
  final int? lastSeq;

  /// The server may have messages before [firstSeq].
  final bool hasOlder;
  final bool loadingOlder;

  /// The client IDs of the messages in the outbox, oldest first. The same
  /// instance until one is added or removed.
  final List<String> outgoingIds;
  final Map<String, OutgoingMessage> outgoingById;

  ChatState withMessages(Iterable<ChatMessage> messages) {
    Map<int, ChatMessage>? bySeq;
    Map<int, ChatMessage>? pending;
    var added = false;
    var first = firstSeq;
    var last = lastSeq;
    for (final message in messages) {
      first = min(first ?? message.seq, message.seq);
      last = max(last ?? message.seq, message.seq);

      if (message.replaces case final target?) {
        if ((bySeq ?? this.bySeq)[target] case final current?) {
          final updated = current.updatedBy(message);
          if (updated != current) {
            (bySeq ??= Map.of(this.bySeq))[target] = updated;
          }
        } else if (message.seq >
            ((pending ?? this.pending)[target]?.seq ?? 0)) {
          (pending ??= Map.of(this.pending))[target] = message;
        }
        continue;
      }

      var incoming = message;
      if ((pending ?? this.pending)[message.seq] case final update?) {
        incoming = message.updatedBy(update);
        (pending ??= Map.of(this.pending)).remove(message.seq);
      }
      final existing = (bySeq ?? this.bySeq)[message.seq];
      // A plain copy of an updated message, e.g. from a later history
      // fetch, must not undo the update.
      if (existing == incoming ||
          (existing != null && existing.revision > incoming.revision)) {
        continue;
      }
      (bySeq ??= Map.of(this.bySeq))[message.seq] = incoming;
      added |= existing == null;
    }
    // A numbered copy of an outbox message replaces it, whether the
    // server's echo or the outbox's own ack came first.
    final sent = {
      for (final message in messages)
        if (outgoingById.containsKey(message.clientId)) message.clientId!,
    };
    if (bySeq == null &&
        pending == null &&
        sent.isEmpty &&
        first == firstSeq &&
        last == lastSeq) {
      return this;
    }
    return _withoutOutgoing(sent)._copy(
      bySeq: bySeq == null ? null : Map.unmodifiable(bySeq),
      seqs: added ? List.unmodifiable(bySeq!.keys.sorted(_ascending)) : seqs,
      pending: pending == null ? null : Map.unmodifiable(pending),
      firstSeq: first,
      lastSeq: last,
    );
  }

  /// Adds an outbox message, or updates its status.
  ChatState withOutgoing(OutgoingMessage message) {
    final id = message.clientId;
    if (outgoingById[id] == message) {
      return this;
    }
    return _copy(
      outgoingIds: outgoingById.containsKey(id)
          ? outgoingIds
          : List.unmodifiable([...outgoingIds, id]),
      outgoingById: Map.unmodifiable({...outgoingById, id: message}),
    );
  }

  /// Drops an outbox message, e.g. one the user discarded.
  ChatState withoutOutgoing(String clientId) => _withoutOutgoing({clientId});

  /// Drops the messages in [ranges], e.g. deleted ones. The seq bounds stay,
  /// so catching up and paging go on from where they were.
  ChatState withoutSeqs(Iterable<SeqRange> ranges) {
    bool deleted(int seq) => ranges.any((r) => r.contains(seq));
    if (!seqs.any(deleted) && !pending.keys.any(deleted)) {
      return this;
    }
    return _copy(
      bySeq: Map.unmodifiable({
        for (final MapEntry(:key, :value) in bySeq.entries)
          if (!deleted(key)) key: value,
      }),
      seqs: List.unmodifiable(seqs.where((seq) => !deleted(seq))),
      pending: Map.unmodifiable({
        for (final MapEntry(:key, :value) in pending.entries)
          if (!deleted(key)) key: value,
      }),
    );
  }

  /// Starts over from [messages], keeping the outbox: after a gap too wide
  /// to fill at once, older pages load from there.
  ChatState restartedWith(Iterable<ChatMessage> messages) {
    var restarted = const ChatState.loading();
    for (final id in outgoingIds) {
      restarted = restarted.withOutgoing(outgoingById[id]!);
    }
    return restarted.withMessages(messages)._copy(status: status);
  }

  ChatState _withoutOutgoing(Set<String> ids) {
    if (!ids.any(outgoingById.containsKey)) {
      return this;
    }
    return _copy(
      outgoingIds: List.unmodifiable(
        outgoingIds.where((id) => !ids.contains(id)),
      ),
      outgoingById: Map.unmodifiable({
        for (final MapEntry(:key, :value) in outgoingById.entries)
          if (!ids.contains(key)) key: value,
      }),
    );
  }

  /// Message [seq] is the first of a **run**: messages from one sender in
  /// a row, each within [runGap] of the one before. Its bubble names the
  /// sender.
  bool startsRun(int seq) {
    final index = binarySearch(seqs, seq);
    if (index < 0) {
      return false;
    }
    return index == 0 || !_sameRun(bySeq[seqs[index - 1]]!, bySeq[seq]!);
  }

  /// Message [seq] is the last of a run. Its bubble shows the sender's
  /// avatar.
  bool endsRun(int seq) {
    final index = binarySearch(seqs, seq);
    if (index < 0) {
      return false;
    }
    return index == seqs.length - 1 ||
        !_sameRun(bySeq[seq]!, bySeq[seqs[index + 1]]!);
  }

  static bool _sameRun(ChatMessage earlier, ChatMessage later) =>
      earlier.from == later.from &&
      later.time.difference(earlier.time) <= runGap;

  ChatState ready({required bool hasOlder}) =>
      _copy(status: LoadStatus.ready, hasOlder: hasOlder);

  ChatState failed(ChatFailure failure) =>
      _copy(status: LoadStatus.failed, failure: failure);

  ChatState withLoadingOlder({required bool loading, bool? hasOlder}) =>
      loading == loadingOlder && (hasOlder ?? this.hasOlder) == this.hasOlder
      ? this
      : _copy(loadingOlder: loading, hasOlder: hasOlder);

  static int _ascending(int a, int b) => a.compareTo(b);

  ChatState _copy({
    LoadStatus? status,
    ChatFailure? failure,
    Map<int, ChatMessage>? bySeq,
    List<int>? seqs,
    Map<int, ChatMessage>? pending,
    int? firstSeq,
    int? lastSeq,
    bool? hasOlder,
    bool? loadingOlder,
    List<String>? outgoingIds,
    Map<String, OutgoingMessage>? outgoingById,
  }) => ChatState._(
    status: status ?? this.status,
    failure: failure ?? this.failure,
    bySeq: bySeq ?? this.bySeq,
    seqs: seqs ?? this.seqs,
    pending: pending ?? this.pending,
    firstSeq: firstSeq ?? this.firstSeq,
    lastSeq: lastSeq ?? this.lastSeq,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    outgoingIds: outgoingIds ?? this.outgoingIds,
    outgoingById: outgoingById ?? this.outgoingById,
  );
}
