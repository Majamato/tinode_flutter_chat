import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/chat_merge.dart'
    as merge;
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/seq_ranges.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// One user's cache: the chat list, the messages fetched so far and the
/// outbox. Values go in and come out as the client's own models, stored in
/// their wire form so the client's parsers read them back.
final class ChatStore {
  ChatStore(this._db, {bool ownsDatabase = true}) : _ownsDb = ownsDatabase;

  final ChatDatabase _db;
  final bool _ownsDb;

  Future<void> close() async {
    if (_ownsDb) {
      await _db.close();
    }
  }

  // Chat list.

  Future<List<Subscription>> chats() async => [
    for (final row in await _db.select(_db.chats).get()) _chat(row),
  ];

  Future<Subscription?> chat(String topic) async {
    final row = await (_db.select(
      _db.chats,
    )..where((c) => c.topic.equals(topic))).getSingleOrNull();
    return row == null ? null : _chat(row);
  }

  /// Replaces the whole list, after a sync without "if modified since".
  /// The members of chats no longer in it go too.
  Future<void> replaceChats(List<Subscription> chats) => _db.transaction(
    () async {
      await _db.delete(_db.chats).go();
      await _db.batch(
        (b) =>
            b.insertAll(_db.chats, [for (final chat in chats) _chatRow(chat)]),
      );
      await (_db.delete(_db.members)..where(
            (m) => m.topic.isNotIn([for (final chat in chats) chat.topic!]),
          ))
          .go();
    },
  );

  /// Merges the chats changed since the last sync; removed ones go.
  Future<void> mergeChats(
    List<Subscription> changes,
  ) => _db.transaction(() async {
    for (final change in changes) {
      final topic = change.topic!;
      if (change.deleted != null) {
        await (_db.delete(_db.chats)..where((c) => c.topic.equals(topic))).go();
        await _deleteMembers(topic);
        continue;
      }
      final stored = await chat(topic);
      await _db
          .into(_db.chats)
          .insertOnConflictUpdate(
            _chatRow(stored == null ? change : merge.mergeChat(stored, change)),
          );
    }
  });

  /// Raises the counters of a stored chat; unknown chats are left alone.
  Future<void> advanceChat(
    String topic, {
    int? lastSeq,
    int? read,
    int? received,
    DateTime? lastMessageAt,
  }) => _db.transaction(() async {
    if (await chat(topic) case final stored?) {
      final updated = merge.advanceChat(
        stored,
        lastSeq: lastSeq,
        read: read,
        received: received,
        lastMessageAt: lastMessageAt,
      );
      if (updated != stored) {
        await _db.into(_db.chats).insertOnConflictUpdate(_chatRow(updated));
      }
    }
  });

  // Members.

  Future<List<Subscription>> members(String topic) async => [
    for (final row in await (_db.select(
      _db.members,
    )..where((m) => m.topic.equals(topic))).get())
      _member(row),
  ];

  Future<Subscription?> member(String topic, String userId) async {
    final row =
        await (_db.select(_db.members)
              ..where((m) => m.topic.equals(topic) & m.userId.equals(userId)))
            .getSingleOrNull();
    return row == null ? null : _member(row);
  }

  /// The members from a full `get sub`: whoever it leaves out goes, the
  /// others merge as chats do (a left-out `public` is unchanged, counters
  /// never move back).
  Future<void> replaceMembers(String topic, List<Subscription> members) =>
      _db.transaction(() async {
        final stored = {for (final m in await this.members(topic)) m.userId: m};
        await _deleteMembers(topic);
        await _db.batch(
          (b) => b.insertAll(_db.members, [
            for (final m in members)
              _memberRow(topic, _mergedMember(stored[m.userId], m)),
          ]),
        );
      });

  /// One member, joined or read again.
  Future<void> putMember(String topic, Subscription member) =>
      _db.transaction(() async {
        final stored = await this.member(topic, member.userId!);
        await _db
            .into(_db.members)
            .insertOnConflictUpdate(
              _memberRow(topic, _mergedMember(stored, member)),
            );
      });

  Future<void> removeMember(String topic, String userId) => (_db.delete(
    _db.members,
  )..where((m) => m.topic.equals(topic) & m.userId.equals(userId))).go();

  /// Raises a stored member's counters; unknown members are left alone.
  Future<void> advanceMember(
    String topic,
    String userId, {
    int? read,
    int? received,
  }) => _db.transaction(() async {
    if (await member(topic, userId) case final stored?) {
      final updated = merge.advanceChat(stored, read: read, received: received);
      if (updated != stored) {
        await _db
            .into(_db.members)
            .insertOnConflictUpdate(_memberRow(topic, updated));
      }
    }
  });

  Future<void> _deleteMembers(String topic) =>
      (_db.delete(_db.members)..where((m) => m.topic.equals(topic))).go();

  static Subscription _mergedMember(
    Subscription? stored,
    Subscription fetched,
  ) => stored == null ? fetched : merge.mergeChat(stored, fetched);

  // Messages.

  Future<SeqRanges> coverage(String topic) async =>
      (await _sync(topic))?.$1 ?? SeqRanges.empty;

  /// Stores [messages] and marks [covering] as fetched.
  Future<void> putMessages(
    String topic,
    List<DataMessage> messages, {
    SeqRange? covering,
  }) => _db.transaction(() async {
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.messages, [
        for (final m in messages) _messageRow(m),
      ]),
    );
    if (covering != null) {
      await _setCoverage(topic, (await coverage(topic)).add(covering));
    }
  });

  /// Stores a message that arrived live. It extends the coverage only when
  /// it follows a covered seq: otherwise the seqs before it may be missing.
  Future<void> putLive(DataMessage message) => _db.transaction(() async {
    await _db.into(_db.messages).insertOnConflictUpdate(_messageRow(message));
    final covered = await coverage(message.topic);
    if (message.seq == 1 || covered.covers(message.seq - 1)) {
      await _setCoverage(
        message.topic,
        covered.add(SeqRange.single(message.seq)),
      );
    }
  });

  /// The newest [limit] stored messages with `from <= seq < before`,
  /// oldest first.
  Future<List<DataMessage>> messagesIn(
    String topic, {
    required int from,
    required int before,
    required int limit,
  }) async {
    final rows =
        await (_db.select(_db.messages)
              ..where(
                (m) =>
                    m.topic.equals(topic) &
                    m.seq.isBiggerOrEqualValue(from) &
                    m.seq.isSmallerThanValue(before),
              )
              ..orderBy([(m) => OrderingTerm.desc(m.seq)])
              ..limit(limit))
            .get();
    return [for (final row in rows.reversed) _message(row)];
  }

  Future<DataMessage?> messageWithClientId(
    String topic,
    String clientId,
  ) async {
    final row =
        await (_db.select(_db.messages)
              ..where(
                (m) => m.topic.equals(topic) & m.clientId.equals(clientId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _message(row);
  }

  /// Deletes the stored messages in [ranges]. They stay covered: the
  /// server has nothing there either.
  Future<void> deleteMessages(String topic, List<SeqRange> ranges) =>
      _db.transaction(() async {
        for (final range in ranges) {
          await (_db.delete(_db.messages)..where(
                (m) =>
                    m.topic.equals(topic) &
                    m.seq.isBiggerOrEqualValue(range.low) &
                    m.seq.isSmallerThanValue(range.high),
              ))
              .go();
        }
      });

  /// Forgets that [ranges] were fetched, so they load from the server again.
  Future<void> uncover(String topic, List<SeqRange> ranges) =>
      _db.transaction(() async {
        var covered = await coverage(topic);
        for (final range in ranges) {
          covered = covered.remove(range);
        }
        await _setCoverage(topic, covered);
      });

  Future<int> syncedDeleteId(String topic) async =>
      (await _sync(topic))?.$2 ?? 0;

  /// Records that deletions up to [id] are applied; it never moves back.
  Future<void> setSyncedDeleteId(String topic, int id) =>
      _db.transaction(() async {
        if (id > await syncedDeleteId(topic)) {
          await _db
              .into(_db.topicSyncs)
              .insert(
                TopicSyncsCompanion.insert(
                  topic: topic,
                  syncedDeleteId: Value(id),
                ),
                onConflict: DoUpdate(
                  (_) => TopicSyncsCompanion(syncedDeleteId: Value(id)),
                ),
              );
        }
      });

  // Outbox.

  /// Queues [content] for [topic] under [clientId].
  Future<OutboxEntry> enqueuePublish(
    String topic,
    String clientId,
    MessageContent content,
    DateTime createdAt,
  ) async {
    final id = await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            topic: topic,
            kind: OutboxKind.publish,
            clientId: Value(clientId),
            payload: jsonEncode({'content': content.toJson()}),
            createdAt: createdAt,
          ),
        );
    return (await outboxEntry(id))!;
  }

  Future<OutboxEntry> enqueueDelete(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
    required DateTime createdAt,
  }) async {
    final id = await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            topic: topic,
            kind: OutboxKind.delete,
            payload: jsonEncode({
              'ranges': [for (final r in ranges) r.toJson()],
              'hard': hard,
            }),
            createdAt: createdAt,
          ),
        );
    return (await outboxEntry(id))!;
  }

  /// Queues a read marker; a newer one replaces an older, unsent one.
  Future<void> enqueueRead(String topic, int seq, DateTime createdAt) =>
      _db.transaction(() async {
        final queued =
            await (_db.select(_db.outbox)..where(
                  (o) =>
                      o.topic.equals(topic) &
                      o.kind.equalsValue(OutboxKind.read),
                ))
                .get();
        final newest = queued.fold(0, (max, row) {
          final seq = OutboxEntry._fromRow(row).seq ?? 0;
          return seq > max ? seq : max;
        });
        if (seq <= newest) {
          return;
        }
        await (_db.delete(_db.outbox)..where(
              (o) =>
                  o.topic.equals(topic) & o.kind.equalsValue(OutboxKind.read),
            ))
            .go();
        await _db
            .into(_db.outbox)
            .insert(
              OutboxCompanion.insert(
                topic: topic,
                kind: OutboxKind.read,
                payload: jsonEncode({'seq': seq}),
                createdAt: createdAt,
              ),
            );
      });

  /// The outbox in order, of one [topic] or of all.
  Future<List<OutboxEntry>> outbox({String? topic}) async {
    final query = _db.select(_db.outbox)
      ..orderBy([(o) => OrderingTerm.asc(o.id)]);
    if (topic != null) {
      query.where((o) => o.topic.equals(topic));
    }
    return [for (final row in await query.get()) OutboxEntry._fromRow(row)];
  }

  Future<OutboxEntry?> outboxEntry(int id) async {
    final row = await (_db.select(
      _db.outbox,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    return row == null ? null : OutboxEntry._fromRow(row);
  }

  Future<OutboxEntry?> outboxByClientId(String clientId) async {
    final row = await (_db.select(
      _db.outbox,
    )..where((o) => o.clientId.equals(clientId))).getSingleOrNull();
    return row == null ? null : OutboxEntry._fromRow(row);
  }

  /// Removes an entry; false when it was gone already.
  Future<bool> removeOutbox(int id) async =>
      await (_db.delete(_db.outbox)..where((o) => o.id.equals(id))).go() > 0;

  /// The server took publish [entry] as [message]: stores the message and
  /// drops the entry in one step. False when another path did it first.
  Future<bool> completePublish(OutboxEntry entry, DataMessage message) =>
      _db.transaction(() async {
        final removed = await removeOutbox(entry.id);
        final covered = await coverage(message.topic);
        await _db
            .into(_db.messages)
            .insertOnConflictUpdate(_messageRow(message));
        if (message.seq == 1 || covered.covers(message.seq - 1)) {
          await _setCoverage(
            message.topic,
            covered.add(SeqRange.single(message.seq)),
          );
        }
        return removed;
      });

  Future<void> updateOutbox(
    int id, {
    bool? inFlight,
    int? sentAfterSeq,
    int? attempts,
    ChatFailure? failure,
    bool clearFailure = false,
  }) => (_db.update(_db.outbox)..where((o) => o.id.equals(id))).write(
    OutboxCompanion(
      inFlight: Value.absentIfNull(inFlight),
      sentAfterSeq: Value.absentIfNull(sentAfterSeq),
      attempts: Value.absentIfNull(attempts),
      failure: clearFailure
          ? const Value(null)
          : Value.absentIfNull(failure?.name),
    ),
  );

  // Rows.

  Future<(SeqRanges, int)?> _sync(String topic) async {
    final row = await (_db.select(
      _db.topicSyncs,
    )..where((t) => t.topic.equals(topic))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      SeqRanges.fromJson(jsonDecode(row.covered) as List<Object?>),
      row.syncedDeleteId,
    );
  }

  Future<void> _setCoverage(String topic, SeqRanges covered) => _db
      .into(_db.topicSyncs)
      .insert(
        TopicSyncsCompanion.insert(
          topic: topic,
          covered: Value(jsonEncode(covered.toJson())),
        ),
        onConflict: DoUpdate(
          (_) =>
              TopicSyncsCompanion(covered: Value(jsonEncode(covered.toJson()))),
        ),
      );

  static Subscription _chat(ChatRow row) =>
      Subscription.fromJson(jsonDecode(row.json) as Json, 'chat');

  static ChatsCompanion _chatRow(Subscription chat) => ChatsCompanion.insert(
    topic: chat.topic!,
    json: jsonEncode(chat.toJson()),
  );

  static Subscription _member(MemberRow row) =>
      Subscription.fromJson(jsonDecode(row.json) as Json, 'member');

  static MembersCompanion _memberRow(String topic, Subscription member) =>
      MembersCompanion.insert(
        topic: topic,
        userId: member.userId!,
        json: jsonEncode(member.toJson()),
      );

  static DataMessage _message(MessageRow row) =>
      DataMessage.fromJson(jsonDecode(row.json) as Json);

  static MessagesCompanion _messageRow(DataMessage message) =>
      MessagesCompanion.insert(
        topic: message.topic,
        seq: message.seq,
        json: jsonEncode(message.toJson()),
        clientId: Value(clientIdOf(message.head)),
      );
}

/// One request waiting in the outbox.
final class OutboxEntry {
  OutboxEntry._({
    required this.id,
    required this.topic,
    required this.kind,
    required this.payload,
    required this.createdAt,
    required this.inFlight,
    required this.sentAfterSeq,
    required this.attempts,
    this.clientId,
    this.failure,
  });

  factory OutboxEntry._fromRow(OutboxRow row) => OutboxEntry._(
    id: row.id,
    topic: row.topic,
    kind: row.kind,
    payload: jsonDecode(row.payload) as Json,
    createdAt: row.createdAt,
    inFlight: row.inFlight,
    sentAfterSeq: row.sentAfterSeq,
    attempts: row.attempts,
    clientId: row.clientId,
    failure: ChatFailure.values.asNameMap()[row.failure],
  );

  final int id;
  final String topic;
  final OutboxKind kind;
  final Json payload;
  final DateTime createdAt;
  final bool inFlight;
  final int sentAfterSeq;
  final int attempts;
  final String? clientId;
  final ChatFailure? failure;

  bool get failed => failure != null;

  /// What a publish sends.
  MessageContent get content => MessageContent.fromJson(payload['content']);

  /// What a delete deletes.
  List<SeqRange> get ranges => [
    for (final range in payload['ranges']! as List<Object?>)
      SeqRange.fromJson(range! as Json, 'outbox.ranges'),
  ];

  bool get hard => payload['hard'] == true;

  /// What a read marker marks.
  int? get seq => payload['seq'] as int?;

  /// A publish as the chat shows it while it waits.
  OutgoingMessage toOutgoing({bool sending = false}) => OutgoingMessage(
    clientId: clientId!,
    topic: topic,
    content: content,
    createdAt: createdAt,
    status: failed
        ? OutgoingStatus.failed
        : (sending ? OutgoingStatus.sending : OutgoingStatus.queued),
    failure: failure,
  );
}
