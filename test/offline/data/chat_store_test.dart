import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/seq_ranges.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fixtures.dart';

void main() {
  late ChatStore store;

  setUp(() {
    store = ChatStore(ChatDatabase(NativeDatabase.memory()));
    addTearDown(store.close);
  });

  group('members', () {
    test('a full list replaces the members, merged', () async {
      await store.replaceMembers(friends, [
        member(bob, name: 'Bob', read: 4, received: 6),
        member(carol, name: 'Carol'),
      ]);
      // A member entry without a profile, older counters, and carol gone.
      await store.replaceMembers(friends, [member(bob, read: 2)]);

      final [bobNow] = await store.members(friends);
      expect(bobNow.userId, bob);
      expect(bobNow.public?.name, 'Bob');
      expect((bobNow.read, bobNow.received), (4, 6));
    });

    test('one member is put, advanced and removed', () async {
      await store.putMember(friends, member(bob, name: 'Bob'));
      await store.advanceMember(friends, bob, read: 5);
      await store.advanceMember(friends, bob, received: 7);
      await store.advanceMember(friends, carol, read: 9);

      final bobNow = (await store.member(friends, bob))!;
      expect((bobNow.read, bobNow.received), (5, 7));
      expect(await store.member(friends, carol), isNull);

      await store.removeMember(friends, bob);
      expect(await store.members(friends), isEmpty);
    });

    test('members go with their chat', () async {
      await store.replaceChats([chat(friends), chat(bob)]);
      await store.putMember(friends, member(carol));
      await store.putMember(bob, member(bob));

      await store.mergeChats([Subscription(topic: friends, deleted: at(1))]);
      expect(await store.members(friends), isEmpty);

      await store.replaceChats([]);
      expect(await store.members(bob), isEmpty);
    });
  });

  group('chats', () {
    test('a full sync replaces the list', () async {
      await store.replaceChats([chat(bob, name: 'Bob'), chat(friends)]);
      await store.replaceChats([chat(bob, name: 'Bob')]);
      expect((await store.chats()).map((c) => c.topic), [bob]);
      expect((await store.chat(bob))?.public?.name, 'Bob');
    });

    test('a partial sync merges and drops removed chats', () async {
      await store.replaceChats([
        chat(bob, name: 'Bob', lastSeq: 3),
        chat(friends),
      ]);
      await store.mergeChats([
        const Subscription(topic: bob, lastSeq: 5),
        Subscription(topic: friends, deleted: at(1)),
        chat(carol, name: 'Carol'),
      ]);

      final chats = {for (final c in await store.chats()) c.topic: c};
      expect(chats.keys, unorderedEquals([bob, carol]));
      expect(chats[bob]!.lastSeq, 5);
      expect(chats[bob]!.public?.name, 'Bob');
    });

    test('advanceChat raises counters of known chats only', () async {
      await store.replaceChats([chat(bob, lastSeq: 3, read: 1)]);
      await store.advanceChat(bob, lastSeq: 4, read: 4, lastMessageAt: at(4));
      await store.advanceChat(carol, lastSeq: 9);

      final stored = (await store.chat(bob))!;
      expect(stored.lastSeq, 4);
      expect(stored.read, 4);
      expect(stored.lastMessageAt, at(4));
      expect(await store.chat(carol), isNull);
    });
  });

  group('messages', () {
    test('a page is stored with what it covered', () async {
      await store.putMessages(bob, [
        message(bob, 2),
        message(bob, 3),
      ], covering: const SeqRange(1, 4));

      expect(await store.coverage(bob), SeqRanges(const [SeqRange(1, 4)]));
      expect(
        (await store.messagesIn(
          bob,
          from: 1,
          before: 10,
          limit: 1,
        )).map((m) => m.seq),
        [3],
      );
      expect(await store.messagesIn(bob, from: 1, before: 10, limit: 5), [
        message(bob, 2),
        message(bob, 3),
      ]);
    });

    test('a live message extends only a coverage it follows', () async {
      await store.putMessages(bob, [
        message(bob, 1),
      ], covering: const SeqRange(1, 2));
      await store.putLive(message(bob, 2));
      await store.putLive(message(bob, 5));

      expect(await store.coverage(bob), SeqRanges(const [SeqRange(1, 3)]));
      expect(
        (await store.messagesIn(
          bob,
          from: 1,
          before: 9,
          limit: 9,
        )).map((m) => m.seq),
        [1, 2, 5],
      );
    });

    test('deleted messages go but stay covered; uncover forgets', () async {
      await store.putMessages(bob, [
        message(bob, 1),
        message(bob, 2),
      ], covering: const SeqRange(1, 3));

      await store.deleteMessages(bob, const [SeqRange.single(1)]);
      expect(
        (await store.messagesIn(
          bob,
          from: 1,
          before: 9,
          limit: 9,
        )).map((m) => m.seq),
        [2],
      );
      expect((await store.coverage(bob)).covers(1), isTrue);

      await store.uncover(bob, const [SeqRange.single(1)]);
      expect((await store.coverage(bob)).covers(1), isFalse);
    });

    test('messages are found by client ID', () async {
      final sent = DataMessage(
        topic: bob,
        seq: 7,
        time: at(7),
        from: alice,
        head: MessageHead.fromJson(const {clientIdHeadKey: 'cid'}),
        content: const PlainText('mine'),
      );
      await store.putLive(sent);
      expect(await store.messageWithClientId(bob, 'cid'), sent);
    });

    test('the synced delete ID never moves back', () async {
      await store.setSyncedDeleteId(bob, 3);
      await store.setSyncedDeleteId(bob, 2);
      expect(await store.syncedDeleteId(bob), 3);
    });
  });

  group('outbox', () {
    test('keeps entries in order with their payloads', () async {
      final publish = await store.enqueuePublish(
        bob,
        'cid',
        const DraftyContent(Drafty(text: 'bold')),
        at(1),
      );
      await store.enqueueDelete(
        bob,
        const [SeqRange(1, 3)],
        hard: true,
        createdAt: at(2),
      );

      final entries = await store.outbox();
      expect(entries.map((e) => e.kind), [
        OutboxKind.publish,
        OutboxKind.delete,
      ]);
      expect(entries.first.content, const DraftyContent(Drafty(text: 'bold')));
      expect(entries.last.ranges, const [SeqRange(1, 3)]);
      expect(entries.last.hard, isTrue);
      expect((await store.outboxByClientId('cid'))?.id, publish.id);
    });

    test('read markers keep only the newest', () async {
      await store.enqueueRead(bob, 3, at(1));
      await store.enqueueRead(bob, 5, at(2));
      await store.enqueueRead(bob, 4, at(3));

      final reads = await store.outbox(topic: bob);
      expect(reads.map((e) => e.seq), [5]);
    });

    test('a failure is kept and cleared', () async {
      final entry = await store.enqueuePublish(
        bob,
        'cid',
        const PlainText('x'),
        at(1),
      );
      await store.updateOutbox(entry.id, failure: ChatFailure.rejected);
      expect(
        (await store.outboxEntry(entry.id))?.failure,
        ChatFailure.rejected,
      );

      await store.updateOutbox(entry.id, clearFailure: true);
      expect((await store.outboxEntry(entry.id))?.failed, isFalse);
    });

    test('a publish completes once', () async {
      final entry = await store.enqueuePublish(
        bob,
        'cid',
        const PlainText('x'),
        at(1),
      );
      final sent = message(bob, 1, from: alice, text: 'x');

      expect(await store.completePublish(entry, sent), isTrue);
      expect(await store.completePublish(entry, sent), isFalse);
      expect(await store.outbox(), isEmpty);
      expect((await store.coverage(bob)).covers(1), isTrue);
    });
  });
}
