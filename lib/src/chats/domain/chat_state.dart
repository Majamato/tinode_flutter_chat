import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

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
      loadingOlder = false;

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
    if (bySeq == null &&
        pending == null &&
        first == firstSeq &&
        last == lastSeq) {
      return this;
    }
    return _copy(
      bySeq: bySeq == null ? null : Map.unmodifiable(bySeq),
      seqs: added ? List.unmodifiable(bySeq!.keys.sorted(_ascending)) : seqs,
      pending: pending == null ? null : Map.unmodifiable(pending),
      firstSeq: first,
      lastSeq: last,
    );
  }

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
  );
}
