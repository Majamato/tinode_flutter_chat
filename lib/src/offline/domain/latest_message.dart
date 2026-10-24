import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What the cache holds of a chat's end, for the chat list's preview: the
/// newest message that is a bubble of its own, the updates of it
/// (`head.replace`, e.g. a call's later state), and the newest seq cached,
/// updates included.
final class LatestMessage with ValueObject {
  const LatestMessage({
    required this.newestSeq,
    this.message,
    this.updates = const [],
  });

  /// Null when the cache holds only updates of older messages.
  final DataMessage? message;

  /// The updates of [message], oldest first.
  final List<DataMessage> updates;

  /// The newest seq cached for the chat. A chat whose `lastSeq` is past it
  /// has messages the cache doesn't hold.
  final int newestSeq;

  @override
  List<Object?> get props => [message, updates, newestSeq];
}
