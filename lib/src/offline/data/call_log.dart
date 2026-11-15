import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/offline/domain/call_page.dart';

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
            time: Value(call.time.millisecondsSinceEpoch),
            json: jsonEncode(call.toJson()),
          ),
      ]),
    );
    return true;
  }

  static bool _isCall(DataMessage message) =>
      message.head?.callState != null &&
      TopicKind.of(message.topic) == TopicKind.direct;

  /// The calls, newest first, each with its updates: of [topics] only
  /// when given, older than [before], no older than [from], at most
  /// [limit]. Updates whose call isn't kept are left out, until it is. A
  /// row that can't be read is logged and left out too, so it hides only
  /// itself.
  Future<CallPage> page({
    Set<String>? topics,
    CallKey? before,
    CallKey? from,
    int? limit,
  }) async {
    if (topics != null && topics.isEmpty) {
      return const CallPage([]);
    }
    final rows = await _db
        .customSelect(
          'SELECT b.topic AS topic, b.seq AS seq, b.time AS time, '
          'b.json AS base, u.json AS upd FROM ( '
          'SELECT topic, seq, time, json FROM call_messages '
          'WHERE replaces IS NULL '
          '${topics == null ? '' : 'AND topic IN (${_marks(topics.length)}) '}'
          '${before == null ? '' : 'AND (time, topic, seq) < (?, ?, ?) '}'
          '${from == null ? '' : 'AND (time, topic, seq) >= (?, ?, ?) '}'
          'ORDER BY time DESC, topic DESC, seq DESC'
          '${limit == null ? '' : ' LIMIT ?'}'
          ') b '
          'LEFT JOIN call_messages u ON u.topic = b.topic '
          "AND u.replaces = ':' || b.seq "
          'ORDER BY b.time DESC, b.topic DESC, b.seq DESC, u.seq',
          variables: [
            for (final topic in topics ?? const <String>{})
              Variable.withString(topic),
            ...?_key(before),
            ...?_key(from),
            if (limit != null) Variable.withInt(limit),
          ],
          readsFrom: {_db.callMessages},
        )
        .get();
    final calls = <CallKey, (DataMessage, List<DataMessage>)?>{};
    for (final row in rows) {
      final key = (
        time: row.read<int>('time'),
        topic: row.read<String>('topic'),
        seq: row.read<int>('seq'),
      );
      final call = calls.putIfAbsent(
        key,
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
    return CallPage([
      for (final call in calls.values)
        if (call case (final message, final updates))
          CachedCall(message, updates),
    ], next: limit != null && calls.length >= limit ? calls.keys.last : null);
  }

  static String _marks(int count) => List.filled(count, '?').join(', ');

  static List<Variable<Object>>? _key(CallKey? key) => key == null
      ? null
      : [
          Variable.withInt(key.time),
          Variable.withString(key.topic),
          Variable.withInt(key.seq),
        ];

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
