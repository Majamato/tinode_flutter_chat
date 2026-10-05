import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One message of a chat, as a bubble shows it.
final class ChatMessage with ValueObject {
  const ChatMessage({
    required this.seq,
    required this.time,
    required this.content,
    required this.isOwn,
    this.from,
  });

  /// [me] is the logged-in user's ID, used to tell own messages apart.
  factory ChatMessage.fromData(DataMessage message, {required String me}) =>
      ChatMessage(
        seq: message.seq,
        time: message.time,
        content: message.content,
        from: message.from,
        isOwn: message.from == me,
      );

  final int seq;
  final DateTime time;
  final MessageContent content;

  /// The sender's user ID; absent in channels and for server messages.
  final String? from;

  /// Sent by the logged-in user.
  final bool isOwn;

  @override
  List<Object?> get props => [seq, time, content, from, isOwn];
}
