import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';

/// The calls in the cache, by the query `ChatStore.calls` ran before the
/// call log took over, kept word for word: the behaviour the log must match
/// wherever nothing was logged out or pruned. Don't "improve" it.
Future<List<CachedCall>> cachedCallsOracle(
  ChatDatabase db, {
  String? topic,
}) async {
  final rows = await db
      .customSelect(
        'WITH c AS (SELECT topic, seq, json, '
        r"json_extract(json, '$.head.replace') AS rep FROM messages "
        r"WHERE json_extract(json, '$.head.webrtc') IS NOT NULL "
        '${topic == null ? '' : 'AND topic = ? '}) '
        'SELECT b.topic AS topic, b.seq AS seq, b.json AS base, '
        'u.json AS upd FROM c b '
        "LEFT JOIN c u ON u.topic = b.topic AND u.rep = ':' || b.seq "
        'WHERE b.rep IS NULL ORDER BY b.topic, b.seq, u.seq',
        variables: [if (topic != null) Variable.withString(topic)],
        readsFrom: {db.messages},
      )
      .get();
  final calls = <(String, int), (DataMessage, List<DataMessage>)>{};
  for (final row in rows) {
    final (_, updates) = calls.putIfAbsent(
      (row.read<String>('topic'), row.read<int>('seq')),
      () => (
        DataMessage.fromJson(jsonDecode(row.read<String>('base')) as Json),
        [],
      ),
    );
    if (row.readNullable<String>('upd') case final json?) {
      updates.add(DataMessage.fromJson(jsonDecode(json) as Json));
    }
  }
  return [
    for (final (message, updates) in calls.values) CachedCall(message, updates),
  ];
}
