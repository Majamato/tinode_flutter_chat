import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_match.dart';

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

    test('keeps no presence: online is what the last sync fetched', () async {
      remote.chats
        ..clear()
        ..add(
          chat(
            bob,
            name: 'Bob',
            lastSeq: 100,
            lastMessageAt: at(100),
            online: true,
          ),
        );
      expect((await session.chatList()).single.online, isTrue);
      expect((await session.storedChatList()).single.online, isFalse);

      // Unchanged and online: the server sends a stub, its `acs` empty.
      remote.chats
        ..clear()
        ..add(const Subscription(topic: bob, online: true));
      final stub = (await session.chatList()).single;
      expect(stub.online, isTrue);
      expect(stub.public?.name, 'Bob');
      expect(stub.access?.mode.has(Permission.write), isTrue);

      // Unchanged and offline: left out.
      remote.chats.clear();
      expect((await session.chatList()).single.online, isFalse);
    });

    test('an online stub of a chat not cached is ignored', () async {
      await session.chatList();
      remote.chats
        ..clear()
        ..add(const Subscription(topic: carol, online: true));

      expect((await session.chatList()).map((c) => c.topic), [bob]);
    });

    test('a chat removed since is dropped', () async {
      await session.chatList();
      remote.chats
        ..clear()
        ..add(Subscription(topic: bob, deleted: at(200)));

      expect(await session.chatList(), isEmpty);
    });
  });

  group('presence', () {
    final seenAt = DateTime.utc(2026, 3, 3, 14, 5);

    void serveBob({bool online = false, DateTime? seen}) => remote.chats
      ..clear()
      ..add(
        chat(
          bob,
          name: 'Bob',
          lastSeq: 100,
          lastMessageAt: at(100),
          online: online,
          seen: seen,
        ),
      );

    test('keeps the last seen the server sends', () async {
      serveBob(seen: seenAt);
      expect((await session.chatList()).single.seen?.when, seenAt);
      expect((await session.storedChatList()).single.seen?.when, seenAt);
    });

    test('pres off on me stores now as the last seen', () async {
      serveBob(seen: seenAt);
      await session.chatList();
      final before = DateTime.now().toUtc();

      remote.emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.offline,
          source: bob,
        ),
      );
      final seen = (await session.storedChatList()).single.seen;

      expect(seen?.when?.isBefore(before), isFalse);
      expect(seen?.userAgent, 'test');
    });

    group('while the host turns it off', () {
      setUp(() async {
        await session.close();
        remote = FakeTinodeSession(chats: []);
        store = ChatStore(ChatDatabase(NativeDatabase.memory()));
        session = CachedTinodeSession(
          remote,
          store,
          userId: alice,
          keepsPresence: false,
        );
        addTearDown(session.close);
      });

      test('no online or last seen comes through', () async {
        serveBob(online: true, seen: seenAt);
        final events = <PresenceEvent>[];
        session.presence.listen((p) => events.add(p.event));

        final chats = await session.chatList();
        expect(chats.single.online, isFalse);
        expect(chats.single.seen, isNull);
        expect((await store.chats()).single.seen, isNull);

        remote
          ..emitPresence(
            const PresMessage(
              topic: 'me',
              event: PresenceEvent.online,
              source: bob,
            ),
          )
          ..emitPresence(
            const PresMessage(
              topic: 'me',
              event: PresenceEvent.offline,
              source: bob,
            ),
          )
          ..emitPresence(
            const PresMessage(
              topic: 'me',
              event: PresenceEvent.read,
              source: bob,
            ),
          );
        await settle();

        expect(events, [PresenceEvent.read]);
        expect((await store.chats()).single.seen, isNull);
      });

      test('a description has no last seen', () async {
        remote.descriptions[bob] = TopicDescription(
          lastSeq: 100,
          seen: LastSeen(when: seenAt),
        );
        final description = await session.description(bob);
        expect(description?.seen, isNull);
        expect(description?.lastSeq, 100);
      });

      test('forgetLastSeen drops what the cache held before', () async {
        await store.replaceChats([chat(bob, name: 'Bob', seen: seenAt)]);
        expect((await session.storedChatList()).single.seen, isNull);

        session.forgetLastSeen();
        // Synced again: the merge would keep a stored `seen`.
        serveBob();
        await session.chatList();

        expect((await store.chats()).single.seen, isNull);
      });
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

  group('members', () {
    setUp(() {
      remote.memberLists[friends] = [
        member(alice, name: 'Alice'),
        member(bob, name: 'Bob', read: 2),
      ];
    });

    test('a fetch keeps them; one member is put, or removed', () async {
      expect(await session.members(friends), hasLength(2));
      expect(await session.storedMembers(friends), hasLength(2));

      remote.memberLists[friends]!.add(member(carol, name: 'Carol'));
      final [carolNow] = await session.members(friends, userId: carol);
      expect(carolNow.public?.name, 'Carol');
      expect(await session.storedMembers(friends), hasLength(3));

      remote.memberLists[friends]!.removeWhere((m) => m.userId == bob);
      expect(await session.members(friends, userId: bob), isEmpty);
      expect(
        (await session.storedMembers(friends)).map((m) => m.userId),
        unorderedEquals([alice, carol]),
      );
    });

    test('markers and messages from members raise their counters', () async {
      await session.members(friends);
      remote
        ..emitInfo(
          const InfoMessage(
            topic: friends,
            event: InfoEvent.received,
            from: bob,
            seq: 6,
          ),
        )
        ..emitInfo(
          const InfoMessage(
            topic: friends,
            event: InfoEvent.read,
            from: bob,
            seq: 4,
          ),
        )
        ..emitMessage(message(friends, 3, from: alice));

      final stored = {
        for (final m in await session.storedMembers(friends)) m.userId: m,
      };
      expect((stored[bob]!.read, stored[bob]!.received), (4, 6));
      expect((stored[alice]!.read, stored[alice]!.received), (3, 3));
    });
  });

  group('received markers', () {
    test('go out only while connected, and raise the chat', () async {
      await session.chatList();
      remote.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
      );
      session.markReceived(bob, 99);
      remote.emitStatus(const Connected());
      session.markReceived(bob, 100);
      await settle();

      expect(remote.calls.where((c) => c.startsWith('markReceived')), [
        'markReceived $bob 100',
      ]);
      expect((await session.storedChatList()).single.received, 100);
    });
  });

  test('closing closes the remote session', () async {
    await session.close();
    expect(remote.isClosed, isTrue);
  });

  group('pruning', () {
    test('a new session prunes the cache before it serves it', () async {
      await session.chatList();
      await session.history(bob, limit: 40);
      final files = MemoryFileStore();
      final big = Uri.parse('https://example.com/big.bin');
      await files.cache(big, Stream.value(List.filled(2048, 0)));

      final pruned = CachedTinodeSession(
        remote,
        store,
        userId: alice,
        files: files,
        limits: const TinodeCacheLimits(
          messagesPerChat: 10,
          fileCacheBytes: 1024,
        ),
      );
      final page = await pruned.storedPage(bob, limit: 32);

      expect(page.messages.map((m) => m.seq), [
        for (var seq = 91; seq <= 100; seq++) seq,
      ]);
      await pumpEventQueue();
      expect(files.isCached(big), isFalse);

      // The pruned messages load from the server again.
      remote.calls.clear();
      final older = await pruned.olderPage(bob, before: 91, limit: 5);
      expect(older.messages.map((m) => m.seq), [86, 87, 88, 89, 90]);
      expect(requests(), ['history $bob before 91']);
    });

    test('message search waits for what arrived before', () async {
      await session.chatList();
      remote.emitMessage(message(bob, 101, text: 'see you at noon'));

      final found = await session.searchMessages(
        bob,
        messageMatch('noon')!,
        limit: 5,
      );
      expect(found.single.seq, 101);
    });
  });

  group('latest catch-up', () {
    /// A session over [remote] with an empty cache, catching up a
    /// `pres msg` at once.
    CachedTinodeSession open(FakeTinodeSession remote) {
      final opened = CachedTinodeSession(
        remote,
        ChatStore(ChatDatabase(NativeDatabase.memory())),
        userId: alice,
        latestDelay: Duration.zero,
      );
      addTearDown(opened.close);
      return opened;
    }

    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(done(), isTrue, reason: 'timed out');
    }

    /// Long enough for a catch-up that would run to have run.
    Future<void> quiet() =>
        Future<void>.delayed(const Duration(milliseconds: 100));

    Iterable<String> attaches(FakeTinodeSession remote, String topic) =>
        remote.calls.where((c) => c == 'attach $topic');

    test('after a sync, caches the newest message of each chat', () async {
      final remote = FakeTinodeSession(
        chats: [
          chat(bob, lastSeq: 3, lastMessageAt: at(3)),
          chat(carol, lastMessageAt: at(1)),
        ],
        histories: {
          bob: [message(bob, 1), message(bob, 2), message(bob, 3)],
        },
      );
      final cached = open(remote);

      await cached.chatList();
      await until(() => remote.calls.contains('detach $bob'));

      final latest = await cached.storedLatestMessages();
      expect(latest[bob]?.message?.seq, 3);
      expect(remote.attachCount(bob), 0);
      // Without messages, nothing to fetch.
      expect(attaches(remote, carol), isEmpty);
    });

    test('a chat the cache already covers is not attached', () async {
      final remote = FakeTinodeSession(
        chats: [chat(bob, lastSeq: 2, lastMessageAt: at(2))],
        histories: {
          bob: [message(bob, 1), message(bob, 2)],
        },
      );
      final cached = open(remote);
      await cached.history(bob, limit: 32);

      await cached.chatList();
      await quiet();

      expect(attaches(remote, bob), isEmpty);
    });

    test('fetches four chats at a time, the newest first', () async {
      final users = [for (var i = 0; i < 6; i++) 'usr$i'];
      final remote = FakeTinodeSession(
        chats: [
          for (final (i, user) in users.indexed)
            chat(user, lastSeq: 1, lastMessageAt: at(i)),
        ],
        histories: {
          for (final user in users) user: [message(user, 1)],
        },
      );
      final hold = remote.holdHistory = Completer<void>();
      final cached = open(remote);

      await cached.chatList();
      await until(
        () => remote.calls.where((c) => c.startsWith('history')).length == 4,
      );
      await quiet();

      bool attached(String call) => call.startsWith('attach usr');
      expect(remote.calls.where(attached), [
        'attach usr5',
        'attach usr4',
        'attach usr3',
        'attach usr2',
      ]);

      hold.complete();
      await until(() => remote.calls.where(attached).length == 6);
      await until(() => remote.calls.contains('detach usr0'));
    });

    test('a group fetches its members first, to name the sender', () async {
      final remote = FakeTinodeSession(
        chats: [chat(friends, lastSeq: 2, lastMessageAt: at(2))],
        histories: {
          friends: [message(friends, 1, from: carol), message(friends, 2)],
        },
      );
      remote.memberLists[friends] = [
        member(bob, name: 'Bob'),
        member(carol, name: 'Carol'),
      ];
      final cached = open(remote);

      await cached.chatList();
      await until(() => remote.calls.contains('detach $friends'));

      final membersAt = remote.calls.indexOf('members $friends');
      expect(membersAt, isNonNegative);
      expect(membersAt, lessThan(remote.calls.indexOf('history $friends')));
      // The sender was known: no second fetch.
      expect(remote.calls.where((c) => c == 'members $friends'), hasLength(1));
      final stored = await cached.storedMembers(friends);
      expect(stored.map((m) => m.userId), contains(bob));
    });

    test("the user's own newest message fetches the members, for its "
        'receipt', () async {
      final remote = FakeTinodeSession(
        chats: [
          chat(bob, lastSeq: 1, lastMessageAt: at(2)),
          chat(carol, lastSeq: 1, lastMessageAt: at(1)),
        ],
        histories: {
          bob: [message(bob, 1, from: alice)],
          carol: [message(carol, 1, from: carol)],
        },
      );
      remote.memberLists[bob] = [member(alice), member(bob, read: 1)];
      final cached = open(remote);

      await cached.chatList();
      await until(
        () =>
            remote.calls.contains('detach $bob') &&
            remote.calls.contains('detach $carol'),
      );

      expect(remote.calls, contains('members $bob'));
      expect(remote.calls, isNot(contains('members $carol')));
    });

    test('a pres msg fetches its chat, once for a burst', () async {
      final remote = FakeTinodeSession(
        chats: [chat(friends, lastSeq: 1, lastMessageAt: at(1))],
        histories: {
          friends: [message(friends, 1)],
        },
      );
      remote.memberLists[friends] = [member(bob, name: 'Bob')];
      final cached = open(remote);
      await cached.chatList();
      await until(() => remote.calls.contains('detach $friends'));
      remote
        ..calls.clear()
        ..histories[friends]!.addAll([
          message(friends, 2),
          message(friends, 3),
        ]);

      for (final seq in [2, 3]) {
        remote.emitPresence(
          PresMessage(
            topic: 'me',
            event: PresenceEvent.message,
            source: friends,
            seq: seq,
          ),
        );
      }
      await until(() => remote.calls.contains('detach $friends'));
      await quiet();

      expect(attaches(remote, friends), hasLength(1));
      final latest = await cached.storedLatestMessages(topic: friends);
      expect(latest[friends]?.message?.seq, 3);
    });

    test('a chat the app holds catches itself up', () async {
      final remote = FakeTinodeSession(
        chats: [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
        histories: {
          bob: [message(bob, 1)],
        },
      );
      final cached = open(remote);
      await cached.attach(bob);

      await cached.chatList();
      await quiet();

      expect(attaches(remote, bob), hasLength(1));
      expect(remote.calls, isNot(contains('history $bob')));
      expect(remote.attachCount(bob), 1);
    });

    test('offline, it waits for the link', () async {
      final remote = FakeTinodeSession(
        chats: [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
        histories: {
          bob: [message(bob, 1)],
        },
      );
      final cached = open(remote);
      await cached.chatList();
      await until(() => remote.calls.contains('detach $bob'));
      remote
        ..emitStatus(
          const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
        )
        ..calls.clear()
        ..histories[bob]!.add(message(bob, 2))
        ..emitPresence(
          const PresMessage(
            topic: 'me',
            event: PresenceEvent.message,
            source: bob,
            seq: 2,
          ),
        );
      await quiet();
      expect(attaches(remote, bob), isEmpty);

      remote.emitStatus(const Connected());
      await until(() => remote.calls.contains('detach $bob'));

      final latest = await cached.storedLatestMessages(topic: bob);
      expect(latest[bob]?.message?.seq, 2);
    });

    test('a refused chat is skipped until it has news', () async {
      final remote = FakeTinodeSession(
        chats: [
          chat(bob, lastSeq: 1, lastMessageAt: at(2)),
          chat(carol, lastSeq: 1, lastMessageAt: at(1)),
        ],
        histories: {
          bob: [message(bob, 1)],
          carol: [message(carol, 1, from: carol)],
        },
      );
      remote.refuseAttach.add(bob);
      final cached = open(remote);

      await cached.chatList();
      await until(() => remote.calls.contains('detach $carol'));
      final latest = await cached.storedLatestMessages();
      expect(latest.keys, [carol]);

      remote.calls.clear();
      await cached.chatList();
      await quiet();
      expect(attaches(remote, bob), isEmpty);

      remote.emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.message,
          source: bob,
          seq: 2,
        ),
      );
      await until(() => attaches(remote, bob).isNotEmpty);
    });

    test('a chat whose newest messages were deleted is fetched once', () async {
      final remote = FakeTinodeSession(
        chats: [chat(bob, lastSeq: 3, lastMessageAt: at(3))],
        histories: {
          bob: [message(bob, 1), message(bob, 2)],
        },
      );
      final cached = open(remote);
      await cached.chatList();
      await until(() => remote.calls.contains('detach $bob'));

      remote.calls.clear();
      await cached.chatList();
      await quiet();

      expect(attaches(remote, bob), isEmpty);
    });
  });
}
