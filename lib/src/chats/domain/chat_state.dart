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
@immutable
final class ChatState {
  const ChatState.loading()
    : status = LoadStatus.loading,
      failure = null,
      bySeq = const {},
      seqs = const [],
      hasOlder = false,
      loadingOlder = false;

  const ChatState._({
    required this.status,
    required this.failure,
    required this.bySeq,
    required this.seqs,
    required this.hasOlder,
    required this.loadingOlder,
  });

  final LoadStatus status;

  /// Why the first load failed; set when [status] is [LoadStatus.failed].
  final ChatFailure? failure;
  final Map<int, ChatMessage> bySeq;

  /// Every seq in [bySeq], ascending.
  final List<int> seqs;

  /// The server may have messages before the first of [seqs].
  final bool hasOlder;
  final bool loadingOlder;

  int? get firstSeq => seqs.firstOrNull;

  int? get lastSeq => seqs.lastOrNull;

  ChatState withMessages(Iterable<ChatMessage> messages) {
    Map<int, ChatMessage>? bySeq;
    var added = false;
    for (final message in messages) {
      final existing = (bySeq ?? this.bySeq)[message.seq];
      if (existing == message) {
        continue;
      }
      bySeq ??= Map.of(this.bySeq);
      bySeq[message.seq] = message;
      added |= existing == null;
    }
    if (bySeq == null) {
      return this;
    }
    return _copy(
      bySeq: Map.unmodifiable(bySeq),
      seqs: added ? List.unmodifiable(bySeq.keys.sorted(_ascending)) : seqs,
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
    bool? hasOlder,
    bool? loadingOlder,
  }) => ChatState._(
    status: status ?? this.status,
    failure: failure ?? this.failure,
    bySeq: bySeq ?? this.bySeq,
    seqs: seqs ?? this.seqs,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}
