import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One entry of the chat list, as the list tile shows it.
final class ChatSummary with ValueObject {
  const ChatSummary({
    required this.topic,
    required this.kind,
    required this.title,
    this.lastMessageAt,
    this.lastSeq = 0,
    this.read = 0,
    this.canWrite = true,
    this.canDeleteForEveryone = false,
  });

  factory ChatSummary.fromSubscription(Subscription subscription) {
    final topic = subscription.topic!;
    final name = subscription.public?.name?.trim();
    return ChatSummary(
      topic: topic,
      kind: TopicKind.of(topic),
      title: name == null || name.isEmpty ? topic : name,
      lastMessageAt: subscription.lastMessageAt,
      lastSeq: subscription.lastSeq,
      read: subscription.read,
      canWrite: subscription.access?.mode.has(Permission.write) ?? true,
      canDeleteForEveryone:
          subscription.access?.mode.has(Permission.delete) ?? false,
    );
  }

  final String topic;
  final TopicKind kind;

  /// The profile name, or the topic name when there is none.
  final String title;
  final DateTime? lastMessageAt;
  final int lastSeq;

  /// Highest seq this user has read.
  final int read;

  /// False for channel followers, who can only read.
  final bool canWrite;

  /// The user may delete messages for everyone (`D`), e.g. a group's
  /// owner. Others can delete only for themselves.
  final bool canDeleteForEveryone;

  int get unread => lastSeq > read ? lastSeq - read : 0;

  /// Up to two letters for the avatar: the first letters of the first two
  /// words of [title].
  String get initials => title
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
      .join();

  /// A new message [seq] arrived at [time]. Older news changes nothing.
  ChatSummary withMessage(int seq, DateTime time) => seq <= lastSeq
      ? this
      : _copy(
          lastSeq: seq,
          lastMessageAt: lastMessageAt == null || time.isAfter(lastMessageAt!)
              ? time
              : lastMessageAt,
        );

  /// The user read up to [seq]. A read marker never moves back.
  ChatSummary withRead(int seq) => seq <= read ? this : _copy(read: seq);

  ChatSummary _copy({int? lastSeq, DateTime? lastMessageAt, int? read}) =>
      ChatSummary(
        topic: topic,
        kind: kind,
        title: title,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastSeq: lastSeq ?? this.lastSeq,
        read: read ?? this.read,
        canWrite: canWrite,
        canDeleteForEveryone: canDeleteForEveryone,
      );

  @override
  List<Object?> get props => [
    topic,
    kind,
    title,
    lastMessageAt,
    lastSeq,
    read,
    canWrite,
    canDeleteForEveryone,
  ];
}
