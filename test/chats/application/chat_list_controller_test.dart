import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 3, read: 1, lastMessageAt: at(3)),
        chat(
          friends,
          name: 'Friends',
          lastSeq: 7,
          read: 7,
          lastMessageAt: at(7),
        ),
      ],
    );
    container = await loggedInContainer(session);
  });

  Future<ChatListState> loadList() async {
    container.listen(chatListControllerProvider, (_, _) {});
    await settle();
    return container.read(chatListControllerProvider);
  }

  test('attaches me and loads the chat list', () async {
    final list = await loadList();

    expect(session.calls, containsAllInOrder(['attach me', 'chatList']));
    expect(list.status, LoadStatus.ready);
    expect(list.order, [friends, bob]);
    expect(container.read(chatSummaryProvider(bob))?.unread, 2);
  });

  test('a reconnect reloads the list', () async {
    await loadList();
    session
      ..calls.clear()
      ..chats.add(chat(carol, name: 'Carol', lastSeq: 1, lastMessageAt: at(9)))
      ..emitStatus(const Connected());
    await settle();

    // Carol's message reached this device while it was away; then the
    // latest catch-up fetches it.
    expect(session.calls.take(2), ['chatList', 'markReceived $carol 1']);
    await settle();
    expect(
      session.calls,
      containsAllInOrder(['attach $carol', 'detach $carol']),
    );
    expect(container.read(chatListControllerProvider).order.first, carol);
  });

  test('a load failure can be retried', () async {
    session.failChatList = const RequestTimeoutException('get', Duration.zero);

    final failed = await loadList();
    expect(failed.status, LoadStatus.failed);
    expect(failed.failure, ChatFailure.timeout);

    container.read(chatListControllerProvider.notifier).reload();
    await settle();
    expect(container.read(chatListControllerProvider).status, LoadStatus.ready);
  });

  test('pres msg on me bumps the unread count and the order', () async {
    await loadList();

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.message,
        source: bob,
        seq: 4,
      ),
    );

    final list = container.read(chatListControllerProvider);
    expect(list.byTopic[bob]!.unread, 3);
    expect(list.order.first, bob);
  });

  test('pres read on me clears what another device read', () async {
    await loadList();

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.read,
        source: bob,
        seq: 3,
      ),
    );

    expect(container.read(chatSummaryProvider(bob))?.unread, 0);
  });

  test('pres acs for an unknown chat reloads the list', () async {
    await loadList();
    session.chats.add(chat(carol, name: 'Hikers', lastMessageAt: at(9)));

    // Someone added the user to a group: no seq yet.
    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.access,
        source: carol,
      ),
    );
    await settle();

    expect(container.read(chatSummaryProvider(carol))?.title, 'Hikers');
    expect(container.read(chatListControllerProvider).order.first, carol);
  });

  test('pres acs for a known chat syncs it, e.g. muted elsewhere', () async {
    await loadList();
    expect(container.read(chatSummaryProvider(bob))?.muted, isFalse);
    session
      ..calls.clear()
      ..chats[0] = chat(bob, name: 'Bob', lastSeq: 3, read: 1, want: 'JRWS')
      ..emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.access,
          source: bob,
        ),
      );
    await settle();

    expect(session.calls, ['chatList']);
    expect(container.read(chatSummaryProvider(bob))?.muted, isTrue);
  });

  test('pres on and off on me set who is online', () async {
    final list = await loadList();
    expect(list.byTopic[bob]!.online, isFalse);

    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.online, source: bob),
    );
    final online = container.read(chatListControllerProvider);
    expect(online.byTopic[bob]!.online, isTrue);
    // Presence doesn't move the chat: the order stays the same instance.
    expect(identical(online.order, list.order), isTrue);

    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.offline, source: bob),
    );
    expect(container.read(chatSummaryProvider(bob))?.online, isFalse);
  });

  test('pres off sets the last seen to now', () async {
    await loadList();
    final before = DateTime.now();

    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.offline, source: bob),
    );

    expect(
      container.read(chatSummaryProvider(bob))?.lastSeen?.isBefore(before),
      isFalse,
    );
  });

  test('the last seen comes from the sync, and only moves forward', () async {
    session.chats[0] = chat(
      bob,
      name: 'Bob',
      lastSeq: 3,
      read: 1,
      lastMessageAt: at(3),
      seen: at(5),
    );
    await loadList();
    expect(container.read(chatSummaryProvider(bob))?.lastSeen, at(5));

    final controller = container.read(chatListControllerProvider.notifier)
      ..markSeen(bob, at(4));
    expect(container.read(chatSummaryProvider(bob))?.lastSeen, at(5));
    controller.markSeen(bob, at(6));
    expect(container.read(chatSummaryProvider(bob))?.lastSeen, at(6));
  });

  test(
    'a peer who hides their presence is never online or last seen',
    () async {
      session.chats[0] = Subscription(
        topic: bob,
        lastSeq: 3,
        read: 1,
        lastMessageAt: at(3),
        online: true,
        seen: LastSeen(when: at(5)),
        public: const Profile(name: 'Bob', raw: {'x-presence': 'hidden'}),
        access: chat(bob).access,
      );
      final list = await loadList();
      final hidden = list.byTopic[bob]!;
      expect(hidden.presenceHidden, isTrue);
      expect(hidden.online, isFalse);
      expect(hidden.lastSeen, isNull);

      session
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
        );
      final after = container.read(chatSummaryProvider(bob))!;
      expect(after.online, isFalse);
      expect(after.lastSeen, isNull);
    },
  );

  test("pres upd syncs the list: a peer's profile changed", () async {
    await loadList();
    session
      ..calls.clear()
      ..chats[0] = Subscription(
        topic: bob,
        lastSeq: 3,
        read: 1,
        lastMessageAt: at(3),
        public: const Profile(name: 'Bob', raw: {'x-presence': 'hidden'}),
        access: chat(bob).access,
      )
      ..emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.updated,
          source: bob,
        ),
      );
    await settle();

    expect(session.calls, ['chatList']);
    expect(container.read(chatSummaryProvider(bob))?.presenceHidden, isTrue);
  });

  test('messages from others are marked received as they arrive', () async {
    await loadList();
    session.calls.clear();
    session
      ..emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.message,
          source: bob,
          seq: 7,
        ),
      )
      ..emitMessage(message(friends, 9, from: carol))
      ..emitMessage(message(friends, 10, from: alice));
    await settle();

    expect(session.calls.where((c) => c.startsWith('markReceived')), [
      'markReceived $bob 7',
      'markReceived $friends 9',
    ]);
  });

  test('refresh syncs and keeps the list shown meanwhile', () async {
    await loadList();
    session
      ..calls.clear()
      ..chats.add(chat(carol, name: 'Carol', lastMessageAt: at(9)));
    container.read(chatListControllerProvider.notifier).refresh();
    expect(container.read(chatListControllerProvider).status, LoadStatus.ready);
    await settle();

    expect(session.calls, ['chatList']);
    expect(container.read(chatListControllerProvider).order.first, carol);
  });

  test('pres msg for an unknown chat reloads the list', () async {
    await loadList();
    session.chats.add(chat(carol, name: 'Carol', lastSeq: 1));

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.message,
        source: carol,
        seq: 1,
      ),
    );
    await settle();

    expect(container.read(chatSummaryProvider(carol))?.unread, 1);
  });

  test('own messages in attached chats count as read', () async {
    await loadList();

    session
      ..emitMessage(message(bob, 4))
      ..emitMessage(message(bob, 5, from: alice));

    final bobChat = container.read(chatListControllerProvider).byTopic[bob]!;
    expect(bobChat.lastSeq, 5);
    expect(bobChat.unread, 0);
  });

  group('messages that update another', () {
    /// How the server numbers what isn't a bubble, e.g. how a call ended.
    DataMessage update(
      int seq,
      int target, {
      CallState state = CallState.missed,
    }) => DataMessage(
      topic: bob,
      seq: seq,
      from: bob,
      time: at(seq),
      head: MessageHead(replaces: ':$target', callState: state),
      content: const PlainText(' '),
    );

    void listed(int seq) => session.emitPresence(
      PresMessage(
        topic: 'me',
        event: PresenceEvent.message,
        source: bob,
        seq: seq,
      ),
    );

    int? unread([ProviderContainer? of]) =>
        (of ?? container).read(chatSummaryProvider(bob))?.unread;

    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(done(), isTrue, reason: 'timed out');
    }

    /// Bob's missed call reaches this device while its chat is closed: two
    /// seqs in the list, one bubble in the cache.
    Future<void> missCall() async {
      await loadList();
      session.histories[bob] = [
        for (var seq = 1; seq <= 4; seq++) message(bob, seq),
        update(5, 4),
      ];
      listed(4);
      listed(5);
      container.read(chatListControllerProvider.notifier).refresh();
    }

    test('a missed call counts as one unread message', () async {
      await missCall();

      await until(() => unread() == 3);
    });

    test('it stays one after the list syncs again', () async {
      await missCall();
      await until(() => unread() == 3);

      container.read(chatListControllerProvider.notifier).refresh();
      await settle();
      await settle();

      expect(unread(), 3);
    });

    test('a live update counts for nothing', () async {
      await loadList();

      session.emitMessage(update(4, 3));

      expect(container.read(chatSummaryProvider(bob))?.lastSeq, 4);
      expect(unread(), 2);
    });

    test('a new message after it still counts', () async {
      await missCall();
      await until(() => unread() == 3);

      listed(6);

      expect(unread(), 4);
    });

    test('a read chat with only an update past the marker is read', () async {
      session.chats
        ..clear()
        ..add(chat(bob, lastSeq: 2, read: 2, lastMessageAt: at(2)));
      await loadList();

      session.emitMessage(update(3, 1));

      expect(unread(), 0);
    });

    test('a call answered here counts for nothing, at once', () async {
      await loadList();

      session.emitMessage(message(bob, 4));
      expect(unread(), 3);
      session.emitMessage(update(5, 4, state: CallState.accepted));
      expect(unread(), 2);
      session.emitMessage(update(6, 4, state: CallState.finished));
      expect(unread(), 2);
    });

    test('a call answered on another device counts for nothing', () async {
      await loadList();
      session.histories[bob] = [
        for (var seq = 1; seq <= 4; seq++) message(bob, seq),
        update(5, 4, state: CallState.accepted),
        update(6, 4, state: CallState.finished),
      ];
      listed(4);
      listed(5);
      listed(6);
      container.read(chatListControllerProvider.notifier).refresh();

      await until(() => unread() == 2);
    });

    test('messages unread before an answered call stay unread', () async {
      await loadList();

      session
        ..emitMessage(message(bob, 4))
        ..emitMessage(update(5, 4, state: CallState.accepted));

      final chat = container.read(chatSummaryProvider(bob))!;
      expect(chat.read, 1);
      expect(chat.unread, 2);
      expect(session.calls, isNot(contains(startsWith('markRead'))));
    });

    test('a declined call counts for nothing, at once', () async {
      await loadList();

      session.emitMessage(message(bob, 4));
      expect(unread(), 3);
      session.emitMessage(update(5, 4, state: CallState.declined));
      expect(unread(), 2);
    });

    test('a call declined on another device counts for nothing', () async {
      await loadList();
      session.histories[bob] = [
        for (var seq = 1; seq <= 4; seq++) message(bob, seq),
        update(5, 4, state: CallState.declined),
      ];
      listed(4);
      listed(5);
      container.read(chatListControllerProvider.notifier).refresh();

      await until(() => unread() == 2);
    });

    test('messages unread before a declined call stay unread', () async {
      await loadList();

      session
        ..emitMessage(message(bob, 4))
        ..emitMessage(update(5, 4, state: CallState.declined));

      expect(container.read(chatSummaryProvider(bob))!.read, 1);
      expect(session.calls, isNot(contains(startsWith('markRead'))));
    });

    test('it stays one when the app starts from the cache', () async {
      final stores = MemoryChatStoreOpener();
      FakeTinodeSession online() => FakeTinodeSession(
        chats: [chat(bob, lastSeq: 5, read: 3, lastMessageAt: at(5))],
        histories: {
          bob: [
            for (var seq = 1; seq <= 4; seq++) message(bob, seq),
            update(5, 4),
          ],
        },
      );
      final first = await loggedInContainer(online(), storeOpener: stores)
        ..listen(chatListControllerProvider, (_, _) {});
      await until(() => unread(first) == 1);
      first.dispose();

      final again = await loggedInContainer(online(), storeOpener: stores)
        ..listen(chatListControllerProvider, (_, _) {});

      await until(() => unread(again) != null);
      await settle();
      await settle();
      expect(unread(again), 1);
    });
  });
}
