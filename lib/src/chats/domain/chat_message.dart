import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One message of a chat, as a bubble shows it.
final class ChatMessage with ValueObject {
  const ChatMessage({
    required this.seq,
    required this.time,
    required this.content,
    required this.isOwn,
    this.from,
    this.call,
    this.replaces,
    this.clientId,
    int? revision,
  }) : revision = revision ?? seq;

  /// [me] is the logged-in user's ID, used to tell own messages apart.
  factory ChatMessage.fromData(DataMessage message, {required String me}) =>
      ChatMessage(
        seq: message.seq,
        time: message.time,
        content: message.content,
        from: message.from,
        isOwn: message.from == me,
        call: CallRecord.fromHead(message.head),
        replaces: message.head?.replacesSeq,
        clientId: clientIdOf(message.head),
      );

  final int seq;
  final DateTime time;
  final MessageContent content;

  /// The sender's user ID; absent in channels and for server messages.
  final String? from;

  /// Sent by the logged-in user.
  final bool isOwn;

  /// Set when the message stands for a call.
  final CallRecord? call;

  /// The seq of the message this one updates. Such a message is no bubble
  /// of its own: it changes that one, see [updatedBy].
  final int? replaces;

  /// Set on messages this package sent: the outbox entry it was.
  final String? clientId;

  /// The seq of the newest update applied, or [seq] when there is none.
  final int revision;

  /// This message as its update [later] changes it: new content and call
  /// state, same place in the chat. Older updates, and updates from anyone
  /// but the sender, are ignored.
  ChatMessage updatedBy(ChatMessage later) {
    if (later.seq <= revision || later.from != from) {
      return this;
    }
    return ChatMessage(
      seq: seq,
      time: time,
      content: later.content,
      isOwn: isOwn,
      from: from,
      call: switch ((call, later.call)) {
        (final call?, final update?) => call.updatedBy(update),
        (_, final update) => update,
      },
      replaces: replaces,
      clientId: clientId,
      revision: later.seq,
    );
  }

  @override
  List<Object?> get props => [
    seq,
    time,
    content,
    from,
    isOwn,
    call,
    replaces,
    clientId,
    revision,
  ];
}
