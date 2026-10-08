import 'dart:math';

import 'package:tinode_dart_client/tinode_dart_client.dart';

/// [stored] updated by [patch], a chat from a `get sub` with "if modified
/// since": a `public` or `private` left out is unchanged, and counters never
/// move back.
Subscription mergeChat(Subscription stored, Subscription patch) => Subscription(
  topic: patch.topic ?? stored.topic,
  userId: patch.userId ?? stored.userId,
  updated: _later(stored.updated, patch.updated),
  lastMessageAt: _later(stored.lastMessageAt, patch.lastMessageAt),
  access: patch.access ?? stored.access,
  online: patch.online,
  lastSeq: max(stored.lastSeq, patch.lastSeq),
  read: max(stored.read, patch.read),
  received: max(stored.received, patch.received),
  lastDeleteId: max(stored.lastDeleteId, patch.lastDeleteId),
  public: patch.public ?? stored.public,
  private: patch.private ?? stored.private,
  seen: patch.seen ?? stored.seen,
);

/// [chat] with news that arrived live: a new message, or a read marker.
Subscription advanceChat(
  Subscription chat, {
  int? lastSeq,
  int? read,
  DateTime? lastMessageAt,
}) => Subscription(
  topic: chat.topic,
  userId: chat.userId,
  updated: chat.updated,
  lastMessageAt: _later(chat.lastMessageAt, lastMessageAt),
  access: chat.access,
  online: chat.online,
  lastSeq: max(chat.lastSeq, lastSeq ?? 0),
  read: max(chat.read, read ?? 0),
  received: chat.received,
  lastDeleteId: chat.lastDeleteId,
  public: chat.public,
  private: chat.private,
  seen: chat.seen,
);

/// The "if modified since" for the next chat list sync: the newest change
/// the stored list has seen, less a millisecond, since the server only
/// returns what changed strictly after it.
DateTime? chatListWatermark(Iterable<Subscription> chats) {
  DateTime? newest;
  for (final chat in chats) {
    for (final time in [chat.updated, chat.lastMessageAt, chat.deleted]) {
      newest = _later(newest, time);
    }
  }
  return newest?.subtract(const Duration(milliseconds: 1));
}

DateTime? _later(DateTime? a, DateTime? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return b.isAfter(a) ? b : a;
}
