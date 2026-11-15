import 'package:collection/collection.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';

import 'fixtures.dart';
import 'test_container.dart';

/// An opener whose call log of [user] on the test server already holds
/// [calls]: more than the 32 messages a catch-up fetches per chat, so more
/// than `histories` can give. The chats list must name their chats, or
/// the first full chat list drops them.
Future<MemoryChatStoreOpener> storesWithCalls(
  Iterable<DataMessage> calls, {
  String user = alice,
}) async {
  final stores = MemoryChatStoreOpener();
  final log = await stores.openCallLog(testConfig.server, user);
  await log.put(calls);
  await log.close();
  return stores;
}

/// Every call of the log, or only a topic's, by chat and then seq: the
/// order the log read them in before it paged, which the tests compare.
extension CallLogCalls on CallLog {
  Future<List<CachedCall>> calls({String? topic}) async =>
      _byChat((await page(topics: topic == null ? null : {topic})).calls);
}

/// [CallLogCalls.calls], through the session.
extension StoredCalls on ChatSession {
  Future<List<CachedCall>> storedCalls({String? topic}) async => _byChat(
    (await storedCallPage(topics: topic == null ? null : {topic})).calls,
  );
}

List<CachedCall> _byChat(List<CachedCall> calls) => calls.sorted(
  (a, b) => switch (a.message.topic.compareTo(b.message.topic)) {
    0 => a.message.seq.compareTo(b.message.seq),
    final order => order,
  },
);
