import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';

/// The calls of direct chats the app has seen, kept on the device apart
/// from the cache: pruning doesn't touch them and they outlive a logout.
/// Only deleting the account deletes the log.
///
/// Values go in and come out as the client's own models, stored in their
/// wire form so the client's parsers read them back.
final class CallLog {
  CallLog(this._db, {bool ownsDatabase = true}) : _ownsDb = ownsDatabase;

  final CallLogDatabase _db;
  final bool _ownsDb;

  Future<void> close() async {
    if (_ownsDb) {
      await _db.close();
    }
  }

  /// Keeps the call messages of direct chats among [messages], all or none
  /// of them; a message kept before is replaced. True when any was kept.
  Future<bool> put(Iterable<DataMessage> messages) async {
    final calls = messages.where(_isCall).toList();
    if (calls.isEmpty) {
      return false;
    }
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.callMessages, [
        for (final call in calls)
          CallMessagesCompanion.insert(
            topic: call.topic,
            seq: call.seq,
            replaces: Value(call.head?.replaces),
            json: jsonEncode(call.toJson()),
          ),
      ]),
    );
    return true;
  }

  static bool _isCall(DataMessage message) =>
      message.head?.callState != null &&
      TopicKind.of(message.topic) == TopicKind.direct;

  /// Every call, or only [topic]'s, with its updates, ordered by chat and
  /// seq. Updates whose call isn't kept are left out, until it is. A row
  /// that can't be read is logged and left out too, so it hides only
  /// itself.
  Future<List<CachedCall>> calls({String? topic}) async {
    final rows = await _db
        .customSelect(
          'SELECT b.topic AS topic, b.seq AS seq, b.json AS base, '
          'u.json AS upd FROM call_messages b '
          'LEFT JOIN call_messages u ON u.topic = b.topic '
          "AND u.replaces = ':' || b.seq "
          'WHERE b.replaces IS NULL '
          '${topic == null ? '' : 'AND b.topic = ? '}'
          'ORDER BY b.topic, b.seq, u.seq',
          variables: [if (topic != null) Variable.withString(topic)],
          readsFrom: {_db.callMessages},
        )
        .get();
    final calls = <(String, int), (DataMessage, List<DataMessage>)?>{};
    for (final row in rows) {
      final call = calls.putIfAbsent(
        (row.read<String>('topic'), row.read<int>('seq')),
        () => switch (_decoded(row.read<String>('base'))) {
          final message? => (message, []),
          null => null,
        },
      );
      if ((call, row.readNullable<String>('upd')) case (
        (_, final updates)?,
        final json?,
      )) {
        if (_decoded(json) case final update?) {
          updates.add(update);
        }
      }
    }
    return [
      for (final call in calls.values)
        if (call case (final message, final updates))
          CachedCall(message, updates),
    ];
  }

  static DataMessage? _decoded(String json) {
    try {
      return DataMessage.fromJson(jsonDecode(json) as Json);
    } on Object catch (e, stackTrace) {
      log(
        'Could not read a logged call',
        name: 'tinode_flutter_chat',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Whether nothing is kept at all.
  Future<bool> get isEmpty async {
    final row = await (_db.select(
      _db.callMessages,
    )..limit(1)).getSingleOrNull();
    return row == null;
  }

  /// The chats with anything kept.
  Future<Set<String>> topics() async {
    final query = _db.selectOnly(_db.callMessages, distinct: true)
      ..addColumns([_db.callMessages.topic]);
    return {
      for (final row in await query.get()) row.read(_db.callMessages.topic)!,
    };
  }

  /// Forgets the messages of [topic] in [ranges].
  Future<void> deleteRanges(String topic, List<SeqRange> ranges) =>
      _db.transaction(() async {
        for (final range in ranges) {
          await (_db.delete(_db.callMessages)..where(
                (m) =>
                    m.topic.equals(topic) &
                    m.seq.isBiggerOrEqualValue(range.low) &
                    m.seq.isSmallerThanValue(range.high),
              ))
              .go();
        }
      });

  /// Forgets all of [topic].
  Future<void> deleteChat(String topic) =>
      (_db.delete(_db.callMessages)..where((m) => m.topic.equals(topic))).go();
}
