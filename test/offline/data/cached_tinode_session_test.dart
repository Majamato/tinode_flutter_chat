import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession remote;
  late ChatStore store;
  late CachedTinodeSession session;

  setUp(() {
    remote = FakeTinodeSession(
      chats: [chat(bob, name: 'Bob', lastSeq: 100, lastMessageAt: at(100))],
      histories: {
        bob: [for (var seq = 1; seq <= 100; seq++) message(bob, seq)],
      },
    );
    store = ChatStore(ChatDatabase(NativeDatabase.memory()));
    session = CachedTinodeSession(remote, store, userId: alice);
    addTearDown(session.close);
  });

  List<String> requests() =>
      remote.calls.where((c) => c.startsWith('history')).toList();

  group('chat list', () {
    test('syncs fully first, then only what changed since', () async {
      expect(await session.chatList(), hasLength(1));
      expect(remote.lastChatListSince, isNull);

      remote.chats
        ..clear()
        ..add(const Subscription(topic: bob, lastSeq: 101));
      final chats = await session.chatList();

      expect(remote.lastChatListSince, isNotNull);
      expect(chats.single.lastSeq, 101);
      expect(chats.single.public?.name, 'Bob');
      expect(await session.storedChatList(), chats);
    });

    test('a chat removed since is dropped', () async {
      await session.chatList();
      remote.chats
        ..clear()
        ..add(Subscription(topic: bob, deleted: at(200)));

      expect(await session.chatList(), isEmpty);
    });
  });

  group('history', () {
    test('older pages come from the cache and only gaps are fetched', () async {
      // The newest page, and an older page fetched separately: 1-32 and
      // 69-100 are cached, 33-68 is a gap.
      await session.history(bob, limit: 32);
      await session.history(bob, before: 33, limit: 32);
      remote.calls.clear();

      final page = await session.olderPage(bob, before: 69, limit: 32);

      expect(page.messages.map((m) => m.seq), [
        for (var seq = 37; seq <= 68; seq++) seq,
      ]);
      expect(requests(), ['history $bob since 33 before 69']);

      // That page was full, so 33-36 is still a gap: only it is fetched,
      // the rest comes from the cache.
      remote.calls.clear();
      final rest = await session.olderPage(bob, before: 37, limit: 32);
      expect(rest.messages.first.seq, 5);
      expect(rest.messages, hasLength(32));
      expect(requests(), ['history $bob since 33 before 37']);

      remote.calls.clear();
      final first = await session.olderPage(bob, before: 5, limit: 32);
      expect(first.messages.map((m) => m.seq), [1, 2, 3, 4]);
      expect(first.reachedStart, isTrue);
      expect(requests(), isEmpty);
    });

    test('the stored page is the newest cached range', () async {
      await session.history(bob, limit: 10);
      final stored = await session.storedPage(bob, limit: 32);
      expect(stored.messages.map((m) => m.seq), [
        for (var seq = 91; seq <= 100; seq++) seq,
      ]);
      expect(stored.reachedStart, isFalse);
    });

    test('offline, an older page gives what is cached', () async {
      await session.history(bob, limit: 10);
      remote.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
      );

      final page = await session.olderPage(bob, before: 91, limit: 32);
      expect(page.messages, isEmpty);
      expect(page.reachedStart, isFalse);
    });

    test('catching up fetches after the cache and applies deletions', () async {
      await session.history(bob, limit: 10);
      remote.histories[bob]!.add(message(bob, 101));
      remote.recordDeletion(bob, const [SeqRange.single(95)]);
      final deletions = <TopicDeletion>[];
      session.deletions.listen(deletions.add);

      final caughtUp = await session.catchUp(bob, limit: 32);

      expect(caughtUp.messages.map((m) => m.seq), [101]);
      expect(caughtUp.gap, isFalse);
      expect(deletions.single.ranges, const [SeqRange.single(95)]);
      final stored = await session.storedPage(bob, limit: 32);
      expect(stored.messages.map((m) => m.seq), isNot(contains(95)));
      expect(stored.messages.last.seq, 101);
    });
  });

  group('read markers', () {
    test('offline, only the newest is sent once connected', () async {
      remote.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
      );
      session
        ..markRead(bob, 3)
        ..markRead(bob, 5);
      await settle();
      expect(remote.calls, isNot(contains(startsWith('markRead'))));

      remote.emitStatus(const Connected());
      await settle();
      await settle();

      expect(remote.calls.where((c) => c.startsWith('markRead')), [
        'markRead $bob 5',
      ]);
    });
  });

  test('closing closes the remote session', () async {
    await session.close();
    expect(remote.isClosed, isTrue);
  });
}
