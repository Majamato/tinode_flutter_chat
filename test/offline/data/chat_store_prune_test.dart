import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/seq_ranges.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';

import '../../support/fixtures.dart';

void main() {
  late ChatStore store;

  setUp(() async {
    store = ChatStore(ChatDatabase(NativeDatabase.memory()));
    addTearDown(store.close);
    await store.replaceChats([chat(bob), chat(friends)]);
  });

  Future<List<int>> seqsOf(String topic) async => [
    for (final m in await store.messagesIn(
      topic,
      from: 1,
      before: 1000,
      limit: 1000,
    ))
      m.seq,
  ];

  test('keeps the newest messages of each chat, uncovers the rest', () async {
    await store.putMessages(bob, [
      for (var seq = 1; seq <= 10; seq++) message(bob, seq),
    ], covering: const SeqRange(1, 11));
    await store.putMessages(friends, [
      message(friends, 1),
      message(friends, 2),
    ], covering: const SeqRange(1, 3));

    await store.prune(keepPerChat: 3);

    expect(await seqsOf(bob), [8, 9, 10]);
    expect(await store.coverage(bob), SeqRanges([const SeqRange(8, 11)]));
    expect(await seqsOf(friends), [1, 2]);
    expect(await store.coverage(friends), SeqRanges([const SeqRange(1, 3)]));
  });

  test('counts stored messages, not seqs, across gaps', () async {
    await store.putMessages(bob, [
      message(bob, 1),
      message(bob, 2),
    ], covering: const SeqRange(1, 3));
    await store.putMessages(bob, [
      message(bob, 50),
      message(bob, 51),
    ], covering: const SeqRange(50, 52));

    await store.prune(keepPerChat: 3);

    expect(await seqsOf(bob), [2, 50, 51]);
    expect(
      await store.coverage(bob),
      SeqRanges([const SeqRange(2, 3), const SeqRange(50, 52)]),
    );
  });

  test('drops the messages of chats no longer in the list', () async {
    await store.putMessages(carol, [
      message(carol, 1, text: 'old news'),
    ], covering: const SeqRange(1, 2));
    await store.putMessages(channel, [message(channel, 1)]);
    // Something still waits to go to the channel: its messages stay.
    await store.enqueueRead(channel, 1, at(5));

    await store.prune(keepPerChat: 100);

    expect(await seqsOf(carol), isEmpty);
    expect(await store.coverage(carol), SeqRanges.empty);
    expect(await seqsOf(channel), [1]);
  });

  test('pruned messages leave message search too', () async {
    await store.putMessages(bob, [
      message(bob, 1, text: 'ancient history'),
      message(bob, 2, text: 'recent history'),
    ]);

    await store.prune(keepPerChat: 1);

    final found = await store.searchMessages(
      bob,
      messageMatch('history')!,
      limit: 5,
    );
    expect([for (final f in found) f.seq], [2]);
  });
}
