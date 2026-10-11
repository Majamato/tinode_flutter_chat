import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_snippet.dart';

import '../../support/fixtures.dart';

void main() {
  late ChatStore store;

  setUp(() async {
    store = ChatStore(ChatDatabase(NativeDatabase.memory()));
    addTearDown(store.close);
    await store.replaceChats([chat(bob), chat(friends)]);
  });

  Future<List<int>> search(String input, {String topic = bob}) async => [
    for (final found in await store.searchMessages(
      topic,
      messageMatch(input)!,
      limit: 20,
    ))
      found.seq,
  ];

  test('finds words by their start, all of them, ignoring accents', () async {
    await store.putMessages(bob, [
      message(bob, 1, text: 'Hello, world'),
      message(bob, 2, text: 'Un café con leche'),
      message(bob, 3, text: 'hello there'),
    ]);

    expect(await search('hel wor'), [1]);
    expect(await search('cafe'), [2]);
    expect(await search('CAFÉ'), [2]);
    expect(await search('nothing'), isEmpty);
  });

  test('marks the matches in the snippet', () async {
    await store.putLive(message(bob, 1, text: 'see you at the café'));

    final [found] = await store.searchMessages(
      bob,
      messageMatch('cafe')!,
      limit: 5,
    );
    expect(found.snippet.parts, const [
      SnippetPart('see you at the '),
      SnippetPart('café', match: true),
    ]);
    expect((found.from, found.time), (bob, at(1)));
  });

  test('reads Drafty text and leaves out updates of other messages', () async {
    await store.putMessages(bob, [
      DataMessage(
        topic: bob,
        seq: 1,
        from: bob,
        time: at(1),
        content: const DraftyContent(Drafty(text: 'holiday photos')),
      ),
      DataMessage(
        topic: bob,
        seq: 2,
        from: bob,
        time: at(2),
        head: const MessageHead(replaces: ':1'),
        content: const PlainText('holiday plans'),
      ),
    ]);

    expect(await search('holiday'), [1]);
  });

  test('newest first, in one chat only, page after page', () async {
    await store.putMessages(bob, [
      message(bob, 1, text: 'lunch?'),
      message(bob, 2, text: 'no'),
      message(bob, 3, text: 'lunch at one'),
    ]);
    await store.putMessages(friends, [
      message(friends, 7, text: 'lunch tomorrow'),
    ]);

    expect(await search('lunch'), [3, 1]);
    expect(await search('lunch', topic: friends), [7]);

    final first = await store.searchMessages(
      bob,
      messageMatch('lunch')!,
      limit: 1,
    );
    final rest = await store.searchMessages(
      bob,
      messageMatch('lunch')!,
      limit: 1,
      before: first.last.seq,
    );
    expect([for (final f in rest) f.seq], [1]);
  });

  test('deleted and replaced messages are found as they are now', () async {
    await store.putMessages(bob, [
      message(bob, 1, text: 'secret plan'),
      message(bob, 2, text: 'first draft'),
    ]);
    await store.deleteMessages(bob, [const SeqRange.single(1)]);
    await store.putLive(message(bob, 2, text: 'final version'));

    expect(await search('secret'), isEmpty);
    expect(await search('draft'), isEmpty);
    expect(await search('final'), [2]);
  });

  test('a forgotten chat takes its messages out of the search', () async {
    await store.putMessages(bob, [message(bob, 1, text: 'see you')]);
    expect(await search('see'), [1]);

    await store.deleteChat(bob);
    expect(await search('see'), isEmpty);
  });
}
