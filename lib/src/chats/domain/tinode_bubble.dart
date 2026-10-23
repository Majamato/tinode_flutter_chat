import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// What a message shows, besides its text.
enum TinodeBubbleKind {
  /// Text only.
  text,

  /// Images or files, with an optional caption as [TinodeBubble.text].
  attachment,

  /// A call, with how it went.
  call,
}

/// How far one of the user's own messages got.
enum TinodeBubbleStatus {
  /// In the outbox, waiting for the network or uploading.
  waiting,

  /// Refused by the server; a long press retries or discards it.
  failed,

  /// Taken by the server.
  sent,

  /// Received by every other member.
  delivered,

  /// Read by every other member.
  read,
}

/// A message as `TinodeChat.bubbleBuilder` sees it, to restyle or replace
/// its bubble.
final class TinodeBubble with ValueObject {
  /// Creates the data of one bubble.
  const TinodeBubble({
    required this.topic,
    required this.own,
    required this.text,
    required this.time,
    required this.kind,
    required this.startsRun,
    required this.endsRun,
    this.seq,
    this.senderId,
    this.status,
  });

  /// The chat the message is in.
  final String topic;

  /// The message's number in the chat; null while it waits in the outbox.
  final int? seq;

  /// The user ID of the sender; null in the outbox, where it is the user.
  final String? senderId;

  /// Whether the user sent it.
  final bool own;

  /// The message's plain text, or the caption of its attachments.
  final String text;

  /// When it was sent, or created while in the outbox.
  final DateTime time;

  /// What it shows besides [text].
  final TinodeBubbleKind kind;

  /// The first of a run: messages from one sender in a row, close in time.
  final bool startsRun;

  /// The last of a run; the default bubble has its tail.
  final bool endsRun;

  /// How far it got, for the user's own messages; null for others'.
  final TinodeBubbleStatus? status;

  @override
  List<Object?> get props => [
    topic,
    seq,
    senderId,
    own,
    text,
    time,
    kind,
    startsRun,
    endsRun,
    status,
  ];
}
