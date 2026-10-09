import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_members.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

const dave = 'usrDave';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(friends, name: 'Friends', lastSeq: 4, read: 4),
        chat(bob, name: 'Bob', lastSeq: 1, read: 1),
        chat(channel, name: 'News', lastSeq: 1, read: 1, mode: 'JRP'),
      ],
      histories: {
        friends: [
          message(friends, 1),
          message(friends, 2),
          message(friends, 3, from: carol),
          message(friends, 4, from: alice),
        ],
        bob: [message(bob, 1, from: alice)],
        channel: [message(channel, 1, from: null)],
      },
    );
    session.memberLists[friends] = [
      member(alice, name: 'Alice', read: 4, received: 4),
      member(bob, name: 'Bob', read: 2, received: 2),
      member(carol, name: 'Carol', read: 3, received: 3),
    ];
    session.memberLists[bob] = [
      member(alice, read: 1, received: 1),
      member(bob),
    ];
    container = await loggedInContainer(session)
      ..listen(chatListControllerProvider, (_, _) {});
    await settle();
  });

  ProviderSubscription<Object?> openChat(String topic) =>
      container.listen(chatControllerProvider(topic), (_, _) {});

  ChatMembers members([String topic = friends]) =>
      container.read(chatMembersControllerProvider(topic));

  MessageReceipt? receipt(int seq, [String topic = friends]) =>
      container.read(messageReceiptProvider(topic, seq));

  void emitMarker(InfoEvent event, String from, int seq) => session.emitInfo(
    InfoMessage(topic: friends, event: event, from: from, seq: seq),
  );

  test('the chat syncs its members once attached', () async {
    openChat(friends);
    await settle();

    expect(
      session.calls,
      containsAllInOrder(['attach $friends', 'members $friends']),
    );
    expect(members().byId.keys, unorderedEquals([alice, bob, carol]));
    expect(members()[bob]?.name, 'Bob');
  });

  test(
    'a reopened chat shows the cached members; a failed sync keeps them',
    () async {
      final open = openChat(friends);
      await settle();
      open.close();
      await settle();

      session
        ..memberLists[friends] = []
        ..failMembers = const RequestTimeoutException('get', Duration.zero);
      openChat(friends);
      await settle();

      expect(members().byId.keys, unorderedEquals([alice, bob, carol]));
    },
  );

  test("ticks follow the other members' markers", () async {
    openChat(friends);
    await settle();
    expect(receipt(4), MessageReceipt.sent);
    expect(receipt(3), isNull);

    emitMarker(InfoEvent.received, bob, 4);
    expect(receipt(4), MessageReceipt.sent);
    emitMarker(InfoEvent.received, carol, 4);
    expect(receipt(4), MessageReceipt.delivered);

    emitMarker(InfoEvent.read, bob, 4);
    emitMarker(InfoEvent.read, carol, 4);
    expect(receipt(4), MessageReceipt.read);
  });

  test("a message raises its sender's counters", () async {
    openChat(friends);
    await settle();
    session.emitMessage(message(friends, 5, from: carol));
    expect(members()[carol]?.read, 5);
  });

  test(
    'someone who joins, leaves or writes unknown is fetched alone',
    () async {
      openChat(friends);
      await settle();
      session.calls.clear();

      session.memberLists[friends]!.add(member(dave, name: 'Dave'));
      session.emitPresence(
        const PresMessage(
          topic: friends,
          event: PresenceEvent.access,
          source: dave,
        ),
      );
      await settle();
      expect(session.calls, ['members $friends $dave']);
      expect(members()[dave]?.name, 'Dave');

      session.memberLists[friends]!.removeWhere((m) => m.userId == dave);
      session.emitPresence(
        const PresMessage(
          topic: friends,
          event: PresenceEvent.access,
          source: dave,
        ),
      );
      await settle();
      expect(members()[dave], isNull);

      session.memberLists[friends]!.add(member(dave, name: 'Dave'));
      session.emitMessage(message(friends, 5, from: dave));
      await settle();
      expect(members()[dave]?.name, 'Dave');
    },
  );

  test('group bubbles name the sender at the start of a run and show the '
      'avatar at its end', () async {
    openChat(friends);
    await settle();

    final first = container.read(messageSenderProvider(friends, 1))!;
    expect(
      (first.name, first.showName, first.showAvatar),
      ('Bob', true, false),
    );
    final second = container.read(messageSenderProvider(friends, 2))!;
    expect((second.showName, second.showAvatar), (false, true));
    final carols = container.read(messageSenderProvider(friends, 3))!;
    expect(
      (carols.name, carols.showName, carols.showAvatar),
      ('Carol', true, true),
    );
    expect(container.read(messageSenderProvider(friends, 4)), isNull);
  });

  test(
    'a direct chat has receipts from the peer but no sender labels',
    () async {
      openChat(bob);
      await settle();
      expect(container.read(messageSenderProvider(bob, 1)), isNull);
      expect(receipt(1, bob), MessageReceipt.sent);

      session.emitInfo(
        const InfoMessage(topic: bob, event: InfoEvent.read, from: bob, seq: 1),
      );
      expect(receipt(1, bob), MessageReceipt.read);
    },
  );

  test('a channel fetches no members', () async {
    openChat(channel);
    await settle();
    expect(session.calls, isNot(contains('members $channel')));
  });

  test("read by is offered on the user's own group messages", () async {
    openChat(friends);
    await settle();
    emitMarker(InfoEvent.read, carol, 4);
    emitMarker(InfoEvent.received, bob, 4);

    expect(container.read(showsReadByProvider(friends, 4)), isTrue);
    expect(container.read(showsReadByProvider(friends, 3)), isFalse);
    final (:read, :delivered) = container.read(
      messageReadByProvider(friends, 4),
    );
    expect(read.map((m) => m.name), ['Carol']);
    expect(delivered.map((m) => m.name), ['Bob']);
  });
}
