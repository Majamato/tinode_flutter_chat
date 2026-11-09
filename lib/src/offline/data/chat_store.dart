import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/chat_merge.dart'
    as merge;
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/seq_ranges.dart';
import 'package:tinode_flutter_chat/src/offline/domain/uncounted_seqs.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_message.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_snippet.dart';
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
  Future<void> mergeChats(List<Subscription> changes) =>
      _db.transaction(() async {
        for (final change in changes) {
          final topic = change.topic!;
          if (change.deleted != null) {
            await _forgetChat(topic);
            continue;
          }
          final stored = await chat(topic);
          if (stored == null && change.access == null) {
            // Only the online stub of a chat this cache doesn't hold: a new
            // chat always comes with its `acs`.
            continue;
          }
          await _db
              .into(_db.chats)
              .insertOnConflictUpdate(
                _chatRow(
                  stored == null ? change : merge.mergeChat(stored, change),
                ),
              );
        }
      });

  /// Forgets everything about [topic]: the chat, its members, messages and
  /// outbox. Returns the outbox entries it dropped, whose staged files the
  /// caller deletes.
  Future<List<OutboxEntry>> deleteChat(String topic) => _db.transaction(
    () async {
      final dropped = await outbox(topic: topic);
      await (_db.delete(_db.outbox)..where((o) => o.topic.equals(topic))).go();
      await _forgetChat(topic);
      return dropped;
    },
  );

  /// Deletes the chat's row, members, messages and sync state.
  Future<void> _forgetChat(String topic) async {
    await (_db.delete(_db.chats)..where((c) => c.topic.equals(topic))).go();
    await _deleteMembers(topic);
    await (_db.delete(_db.messages)..where((m) => m.topic.equals(topic))).go();
    await (_db.delete(
      _db.topicSyncs,
    )..where((t) => t.topic.equals(topic))).go();
  }

  /// Raises the counters of a stored chat, and its last seen; unknown
  /// chats are left alone.
  Future<void> advanceChat(
    String topic, {
    int? lastSeq,
    int? read,
    int? received,
    DateTime? lastMessageAt,
    DateTime? seen,
  }) => _db.transaction(() async {
    if (await chat(topic) case final stored?) {
      final updated = merge.advanceChat(
        stored,
        lastSeq: lastSeq,
        read: read,
        received: received,
        lastMessageAt: lastMessageAt,
        seen: seen,
      );
      if (updated != stored) {
        await _db.into(_db.chats).insertOnConflictUpdate(_chatRow(updated));
      }
    }
  });

  /// Drops the last seen of every stored chat, once presence is off.
  Future<void> forgetLastSeen() => _db.transaction(() async {
    for (final stored in await chats()) {
      if (stored.seen != null) {
        await _db
            .into(_db.chats)
            .insertOnConflictUpdate(_chatRow(merge.withoutPresence(stored)));
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

  /// The newest message of each cached chat, or only of [topic], with its
  /// updates (see [LatestMessage]). Chats without cached messages are left
  /// out.
  Future<Map<String, LatestMessage>> latestMessages({String? topic}) async {
    final rows = await _db
        .customSelect(
          'SELECT l.topic AS topic, l.newest AS newest, m.json AS json '
          'FROM (SELECT topic, max(seq) AS newest, max(CASE WHEN '
          r"json_extract(json, '$.head.replace') IS NULL THEN seq END) AS base "
          'FROM messages ${topic == null ? '' : 'WHERE topic = ? '}'
          'GROUP BY topic) l '
          'LEFT JOIN messages m ON m.topic = l.topic AND (m.seq = l.base '
          r"OR json_extract(m.json, '$.head.replace') = ':' || l.base) "
          'ORDER BY l.topic, m.seq',
          variables: [if (topic != null) Variable.withString(topic)],
          readsFrom: {_db.messages},
        )
        .get();
    final found = <String, ({int newest, List<DataMessage> messages})>{};
    for (final row in rows) {
      final entry = found.putIfAbsent(
        row.read<String>('topic'),
        () => (newest: row.read<int>('newest'), messages: []),
      );
      if (row.readNullable<String>('json') case final json?) {
        entry.messages.add(DataMessage.fromJson(jsonDecode(json) as Json));
      }
    }
    return {
      for (final MapEntry(:key, :value) in found.entries)
        key: switch (value.messages) {
          [final message, ...final updates]
              when message.head?.replacesSeq == null =>
            LatestMessage(
              newestSeq: value.newest,
              message: message,
              updates: updates,
            ),
          _ => LatestMessage(newestSeq: value.newest),
        },
    };
  }

  /// The seqs past each chat's read marker that the cached updates show
  /// aren't unread messages (see `uncountedBy`), or only [topic]'s. Chats
  /// without any are left out. An update is past the marker whenever its
  /// target is, so reading the updates finds both.
  Future<Map<String, Set<int>>> uncountedSeqs({String? topic}) async {
    final rows = await _db
        .customSelect(
          'SELECT m.topic AS topic, m.seq AS seq, '
          r"json_extract(m.json, '$.head.replace') AS replace_seq, "
          r"json_extract(m.json, '$.head.webrtc') AS webrtc "
          'FROM chats c JOIN messages m ON m.topic = c.topic '
          r"AND m.seq > coalesce(json_extract(c.json, '$.read'), 0) "
          r"WHERE json_extract(m.json, '$.head.replace') IS NOT NULL "
          '${topic == null ? '' : 'AND c.topic = ?'}',
          variables: [if (topic != null) Variable.withString(topic)],
          readsFrom: {_db.chats, _db.messages},
        )
        .get();
    final uncounted = <String, Set<int>>{};
    for (final row in rows) {
      final head = MessageHead.fromJson({
        'replace': row.read<String>('replace_seq'),
        'webrtc': ?row.readNullable<String>('webrtc'),
      });
      uncounted
          .putIfAbsent(row.read<String>('topic'), () => {})
          .addAll(uncountedBy(row.read<int>('seq'), head));
    }
    return uncounted;
  }

  /// Every cached call message, updates included.
  Future<List<DataMessage>> callMessages() async {
    final rows = await _db
        .customSelect(
          'SELECT json FROM messages '
          r"WHERE json_extract(json, '$.head.webrtc') IS NOT NULL",
          readsFrom: {_db.messages},
        )
        .get();
    return [
      for (final row in rows)
        DataMessage.fromJson(jsonDecode(row.read<String>('json')) as Json),
    ];
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

  /// The stored messages of [topic] in [ranges], or all of them without.
  Future<List<DataMessage>> messagesInRanges(
    String topic, [
    List<SeqRange>? ranges,
  ]) async {
    if (ranges != null && ranges.isEmpty) {
      return const [];
    }
    final rows =
        await (_db.select(_db.messages)..where(
              (m) =>
                  m.topic.equals(topic) &
                  (ranges == null
                      ? const Constant(true)
                      : ranges
                            .map(
                              (range) =>
                                  m.seq.isBiggerOrEqualValue(range.low) &
                                  m.seq.isSmallerThanValue(range.high),
                            )
                            .reduce((a, b) => a | b)),
            ))
            .get();
    return [for (final row in rows) _message(row)];
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

  // Message search.

  /// The stored messages of [topic] matching [match] (a full-text query,
  /// see `messageMatch`), newest first, and before seq [before] when given.
  Future<List<FoundMessage>> searchMessages(
    String topic,
    String match, {
    required int limit,
    int? before,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT m.json AS json, '
          "snippet(message_search, 0, ?, ?, '…', $_snippetTokens) AS snippet "
          'FROM message_search '
          'JOIN messages m ON m.rowid = message_search.rowid '
          'WHERE message_search MATCH ? AND m.topic = ? '
          '${before == null ? '' : 'AND m.seq < ? '}'
          'ORDER BY m.seq DESC '
          'LIMIT ?',
          variables: [
            Variable.withString(snippetMatchStart),
            Variable.withString(snippetMatchEnd),
            Variable.withString(match),
            Variable.withString(topic),
            if (before != null) Variable.withInt(before),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.messageSearch, _db.messages},
        )
        .get();
    return [for (final row in rows) _found(row)];
  }

  // Pruning.

  /// Keeps the cache small: drops the messages of chats no longer in the
  /// list (unless the outbox still has something for them), and in every
  /// chat all but the newest [keepPerChat] messages. What is dropped is
  /// no longer covered, so it loads from the server again when needed.
  Future<void> prune({required int keepPerChat}) => _db.transaction(() async {
    const orphan =
        'topic NOT IN (SELECT topic FROM chats) '
        'AND topic NOT IN (SELECT topic FROM outbox)';
    await _db.customUpdate(
      'DELETE FROM messages WHERE $orphan',
      updates: {_db.messages, _db.messageSearch},
      updateKind: UpdateKind.delete,
    );
    await _db.customUpdate(
      'DELETE FROM topic_syncs WHERE $orphan',
      updates: {_db.topicSyncs},
      updateKind: UpdateKind.delete,
    );

    final crowded = await _db
        .customSelect(
          'SELECT topic, (SELECT seq FROM messages n WHERE n.topic = m.topic '
          'ORDER BY seq DESC LIMIT 1 OFFSET ?) AS cutoff '
          'FROM messages m GROUP BY topic HAVING count(*) > ?',
          variables: [
            Variable.withInt(keepPerChat - 1),
            Variable.withInt(keepPerChat),
          ],
          readsFrom: {_db.messages},
        )
        .get();
    for (final row in crowded) {
      final topic = row.read<String>('topic');
      final cutoff = row.read<int>('cutoff');
      await (_db.delete(_db.messages)..where(
            (m) => m.topic.equals(topic) & m.seq.isSmallerThanValue(cutoff),
          ))
          .go();
      await uncover(topic, [SeqRange(1, cutoff)]);
    }
  });

  // Outbox.

  /// Queues [content] for [topic] under [clientId].
  /// Queues [content]; with [attachment], the image or file to upload
  /// first, whose message [content] stands for until then.
  Future<OutboxEntry> enqueuePublish(
    String topic,
    String clientId,
    MessageContent content,
    DateTime createdAt, {
    OutgoingAttachment? attachment,
  }) async {
    final id = await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            topic: topic,
            kind: OutboxKind.publish,
            clientId: Value(clientId),
            payload: jsonEncode({
              'content': content.toJson(),
              'attachment': ?attachment?.toJson(),
            }),
            createdAt: createdAt,
          ),
        );
    return (await outboxEntry(id))!;
  }

  /// Replaces the attachment of entry [id], e.g. once it is compressed or
  /// uploaded, and the content that stands for it. Does nothing when the
  /// entry is gone.
  Future<void> setOutboxAttachment(int id, OutgoingAttachment attachment) =>
      _db.transaction(() async {
        final entry = await outboxEntry(id);
        if (entry == null) {
          return;
        }
        await (_db.update(_db.outbox)..where((o) => o.id.equals(id))).write(
          OutboxCompanion(
            payload: Value(
              jsonEncode({
                ...entry.payload,
                'content': attachment.content.toJson(),
                'attachment': attachment.toJson(),
              }),
            ),
          ),
        );
      });

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

  /// How many words a snippet shows around the match.
  static const _snippetTokens = 12;

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

  static FoundMessage _found(QueryRow row) {
    final message = DataMessage.fromJson(
      jsonDecode(row.read<String>('json')) as Json,
    );
    return FoundMessage(
      topic: message.topic,
      seq: message.seq,
      time: message.time,
      from: message.from,
      snippet: MessageSnippet.parse(row.read<String>('snippet')),
    );
  }

  static Subscription _chat(ChatRow row) =>
      Subscription.fromJson(jsonDecode(row.json) as Json, 'chat');

  /// Presence is live only: a stored `online` would be stale by the next
  /// start, so it is never kept.
  static ChatsCompanion _chatRow(Subscription chat) => ChatsCompanion.insert(
    topic: chat.topic!,
    json: jsonEncode(chat.toJson()..remove('online')),
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

  /// What a publish sends; with an [attachment], what stands for it until
  /// it is uploaded.
  MessageContent get content => MessageContent.fromJson(payload['content']);

  /// The image or file a publish sends, if any.
  OutgoingAttachment? get attachment => switch (payload['attachment']) {
    final Json json => OutgoingAttachment.fromJson(json),
    _ => null,
  };

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
    attachment: attachment,
  );
}
