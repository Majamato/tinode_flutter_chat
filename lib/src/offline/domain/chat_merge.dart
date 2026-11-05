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

/// [chat] with news that arrived live: a new message, a read or received
/// marker, or the peer going offline at [seen]. Also raises a member's
/// counters. Nothing moves back.
Subscription advanceChat(
  Subscription chat, {
  int? lastSeq,
  int? read,
  int? received,
  DateTime? lastMessageAt,
  DateTime? seen,
}) => Subscription(
  topic: chat.topic,
  userId: chat.userId,
  updated: chat.updated,
  lastMessageAt: _later(chat.lastMessageAt, lastMessageAt),
  access: chat.access,
  online: chat.online,
  lastSeq: max(chat.lastSeq, lastSeq ?? 0),
  read: max(chat.read, read ?? 0),
  received: max(chat.received, received ?? 0),
  lastDeleteId: chat.lastDeleteId,
  public: chat.public,
  private: chat.private,
  seen: switch ((chat.seen, seen)) {
    (final stored, null) => stored,
    (final stored?, final time?)
        when stored.when != null && !time.isAfter(stored.when!) =>
      stored,
    (final stored, final time?) => LastSeen(
      when: time,
      userAgent: stored?.userAgent,
    ),
  },
);

/// [chat] with its presence set to [online].
Subscription withPresence(Subscription chat, {required bool online}) =>
    chat.online == online
    ? chat
    : Subscription(
        topic: chat.topic,
        userId: chat.userId,
        updated: chat.updated,
        lastMessageAt: chat.lastMessageAt,
        access: chat.access,
        online: online,
        lastSeq: chat.lastSeq,
        read: chat.read,
        received: chat.received,
        lastDeleteId: chat.lastDeleteId,
        public: chat.public,
        private: chat.private,
        seen: chat.seen,
      );

/// [chat] without presence: offline, and no last seen.
Subscription withoutPresence(Subscription chat) =>
    !chat.online && chat.seen == null
    ? chat
    : Subscription(
        topic: chat.topic,
        userId: chat.userId,
        updated: chat.updated,
        deleted: chat.deleted,
        lastMessageAt: chat.lastMessageAt,
        access: chat.access,
        lastSeq: chat.lastSeq,
        read: chat.read,
        received: chat.received,
        lastDeleteId: chat.lastDeleteId,
        public: chat.public,
        private: chat.private,
      );

/// [description] without the peer's last seen.
TopicDescription descriptionWithoutPresence(TopicDescription description) =>
    description.seen == null
    ? description
    : TopicDescription(
        created: description.created,
        updated: description.updated,
        lastMessageAt: description.lastMessageAt,
        defaultAccess: description.defaultAccess,
        access: description.access,
        lastSeq: description.lastSeq,
        read: description.read,
        received: description.received,
        lastDeleteId: description.lastDeleteId,
        public: description.public,
        private: description.private,
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
