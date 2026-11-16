import 'dart:math';

import 'package:tinode_dart_client/tinode_dart_client.dart';

/// What a Tinode server (v0.25) answers about one user's chat list, for
/// `FakeTinodeSession(server:)`. `chat_list_contract.dart` holds it to the
/// live server's behaviour.
///
/// - Without "if modified since" the list is any [maxResults] chats, in no
///   order, each with its profile.
/// - With it, the chats changed after it, the one changed the longest ago
///   first, at most [maxResults]. A chat's profile comes only when the
///   profile itself changed after it. A chat left after it comes as
///   `deleted`; one left before it doesn't come at all, even when its
///   group moved on since and so took a place in the cut. Each chat that
///   is [online] and isn't in the answer comes as a stub: its topic and
///   `online`, nothing else.
/// - A received marker counts only from a session attached to the chat.
///
/// Every change takes the time of [now], then moves it on by [step].
final class FakeChatServer {
  FakeChatServer({
    this.maxResults = 1024,
    DateTime? start,
    this.step = const Duration(seconds: 1),
  }) : _now = start ?? DateTime.utc(2026, 10, 4, 9);

  final int maxResults;
  final Duration step;
  DateTime _now;

  /// The time the next change takes.
  DateTime get now => _now;

  /// The chats, in the order they were added.
  final _rows = <String, _Row>{};

  /// The chats someone is attached to, as the user's `me` sees them.
  final online = <String>{};

  /// The chats the user has, left ones too.
  Iterable<String> get topics => _rows.keys;

  /// Moves the clock on by [by].
  void tick([Duration by = const Duration(seconds: 1)]) => _now = _now.add(by);

  DateTime _stamp() {
    final at = _now;
    _now = _now.add(step);
    return at;
  }

  /// Adds [chat], new now; its `lastSeq` messages were sent now too.
  void add(Subscription chat) {
    final at = _stamp();
    _rows[chat.topic!] = _Row(
      chat,
      updated: at,
      touched: chat.lastSeq > 0 ? at : null,
    );
  }

  /// Adds every one of [chats], each a step after the one before.
  void addAll(Iterable<Subscription> chats) => chats.forEach(add);

  /// Someone sent a message to [topic]; it counts as unread.
  int post(String topic) {
    final row = _rows[topic]!;
    row
      ..chat = _with(row.chat, lastSeq: row.chat.lastSeq + 1)
      ..touched = _stamp();
    return row.chat.lastSeq;
  }

  /// The chat's profile changed.
  void rename(String topic, Profile public) {
    final row = _rows[topic]!;
    row
      ..chat = _with(row.chat, public: public)
      ..updated = _stamp();
  }

  /// The user's access to [topic] changed, e.g. muted on another device.
  void changeAccess(String topic, Access access) {
    final row = _rows[topic]!;
    row
      ..chat = _with(row.chat, access: access)
      ..updated = _stamp();
  }

  /// The user read [topic] up to [seq], maybe on another device.
  void read(String topic, int seq) {
    final row = _rows[topic]!;
    row
      ..chat = _with(row.chat, read: max(row.chat.read, seq))
      ..updated = _stamp();
  }

  /// A received marker from a session attached to [topic].
  void receive(String topic, int seq) {
    final row = _rows[topic];
    if (row == null || seq <= row.chat.received) {
      return;
    }
    row
      ..chat = _with(row.chat, received: seq)
      ..updated = _stamp();
  }

  /// The user left [topic], or was removed from it.
  void leave(String topic) {
    final row = _rows[topic];
    if (row == null || row.deleted != null) {
      return;
    }
    final at = _stamp();
    row
      ..deleted = at
      ..updated = at;
  }

  /// The list, as `get sub` on `me` answers it.
  List<Subscription> list({DateTime? ifModifiedSince, int? limit}) {
    final cap = limit == null || limit <= 0 || limit > maxResults
        ? maxResults
        : limit;
    if (ifModifiedSince == null) {
      return [
        for (final row in _rows.values.where((r) => r.deleted == null))
          row.wire(public: true, online: _isOnline(row.chat.topic!)),
      ].take(cap).toList();
    }
    final cut =
        (_rows.values.where((r) => r.modified.isAfter(ifModifiedSince)).toList()
              ..sort((a, b) => a.modified.compareTo(b.modified)))
            .take(cap);
    final answer = <Subscription>[
      for (final row in cut)
        if (row.deleted case final deleted?)
          if (deleted.isAfter(ifModifiedSince))
            Subscription(topic: row.chat.topic, deleted: deleted)
          else
            ...const <Subscription>[]
        else
          row.wire(
            public: row.updated.isAfter(ifModifiedSince),
            online: _isOnline(row.chat.topic!),
          ),
    ];
    final listed = {for (final chat in answer) chat.topic};
    return [
      ...answer,
      for (final topic in online)
        if (!listed.contains(topic) && _rows[topic]?.deleted == null)
          Subscription(topic: topic, online: true),
    ];
  }

  /// One chat, as `get sub` on `me` with its topic answers it.
  Subscription? one(String topic) => switch (_rows[topic]) {
    final row? when row.deleted == null => row.wire(
      public: true,
      online: _isOnline(topic),
    ),
    _ => null,
  };

  bool _isOnline(String topic) => online.contains(topic);

  static Subscription _with(
    Subscription chat, {
    int? lastSeq,
    int? read,
    int? received,
    Profile? public,
    Access? access,
  }) => Subscription(
    topic: chat.topic,
    lastSeq: lastSeq ?? chat.lastSeq,
    read: read ?? chat.read,
    received: received ?? chat.received,
    public: public ?? chat.public,
    private: chat.private,
    access: access ?? chat.access,
    lastDeleteId: chat.lastDeleteId,
    seen: chat.seen,
  );
}

final class _Row {
  _Row(this.chat, {required this.updated, this.touched});

  Subscription chat;
  DateTime updated;
  DateTime? touched;
  DateTime? deleted;

  /// The server's `LastModified`: the later of `updated` and `touched`.
  DateTime get modified => switch (touched) {
    final touched? when touched.isAfter(updated) => touched,
    _ => updated,
  };

  Subscription wire({required bool public, required bool online}) =>
      Subscription(
        topic: chat.topic,
        online: online,
        updated: updated,
        lastMessageAt: touched,
        access: chat.access,
        lastSeq: chat.lastSeq,
        read: chat.read,
        received: chat.received,
        lastDeleteId: chat.lastDeleteId,
        public: public ? chat.public : null,
        private: public ? chat.private : null,
        seen: chat.seen,
      );
}
