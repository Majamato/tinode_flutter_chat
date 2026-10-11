import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_actions_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_exit.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
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
        chat(bob, name: 'Bob', lastMessageAt: at(1)),
        chat(friends, name: 'Friends', lastMessageAt: at(2), mode: 'JRWPASDO'),
        chat(channel, name: 'News', lastMessageAt: at(3), mode: 'JRP'),
      ],
    );
    session.memberLists[friends] = [
      member(alice, name: 'Alice', mode: 'JRWPASDO'),
      member(bob, name: 'Bob'),
      member(carol, name: 'Carol'),
    ];
    container = await loggedInContainer(session)
      ..listen(chatListControllerProvider, (_, _) {});
    await settle();
  });

  ProviderSubscription<Object?> open(String topic) =>
      container.listen(chatControllerProvider(topic), (_, _) {});

  test('how each chat is left', () {
    expect(container.read(chatExitProvider(bob)), ChatExit.deleteChat);
    expect(container.read(chatExitProvider(friends)), ChatExit.deleteGroup);
    expect(container.read(chatExitProvider(channel)), ChatExit.leaveGroup);
  });

  test('deleting a chat drops it from the list and the cache', () async {
    final done = await container
        .read(chatActionsControllerProvider(bob).notifier)
        .exit(ChatExit.deleteChat);

    expect(done, isTrue);
    expect(session.deletedChats, [bob]);
    expect(container.read(chatListControllerProvider).contains(bob), isFalse);
    final stored = await container
        .read(activeSessionProvider)!
        .storedChatList();
    expect(stored.map((c) => c.topic), isNot(contains(bob)));
  });

  test('leaving a group unsubscribes from it', () async {
    await container
        .read(chatActionsControllerProvider(channel).notifier)
        .exit(ChatExit.leaveGroup);

    expect(session.leftChats, [channel]);
    expect(
      container.read(chatListControllerProvider).contains(channel),
      isFalse,
    );
  });

  test('a refusal keeps the chat and says why', () async {
    session.failDeleteChat = const ServerException(403, 'forbidden');

    final done = await container
        .read(chatActionsControllerProvider(bob).notifier)
        .exit(ChatExit.deleteChat);

    expect(done, isFalse);
    expect(container.read(chatListControllerProvider).contains(bob), isTrue);
    expect(
      container.read(chatActionFailureProvider(bob)),
      ChatFailure.rejected,
    );
  });

  test('members are listed owner first; only others can be removed', () async {
    open(friends);
    await settle();

    expect(container.read(chatMemberIdsProvider(friends)), [alice, bob, carol]);
    expect(container.read(memberRemovableProvider(friends, alice)), isFalse);
    expect(container.read(memberRemovableProvider(friends, bob)), isTrue);
  });

  test('without A nobody can be removed', () async {
    session.chats[1] = chat(friends, name: 'Friends', lastMessageAt: at(2));
    container.read(chatListControllerProvider.notifier).refresh();
    open(friends);
    await settle();

    expect(container.read(memberRemovableProvider(friends, bob)), isFalse);
  });

  test('a removed member leaves the list', () async {
    open(friends);
    await settle();

    await container
        .read(chatActionsControllerProvider(friends).notifier)
        .removeMember(bob);

    expect(session.removedMembers[friends], [bob]);
    expect(container.read(chatMembersControllerProvider(friends))[bob], isNull);
  });

  test('a chat gone elsewhere leaves the list and fails when open', () async {
    open(friends);
    await settle();

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.gone,
        source: friends,
      ),
    );
    await settle();

    expect(
      container.read(chatListControllerProvider).contains(friends),
      isFalse,
    );
    expect(
      container.read(chatControllerProvider(friends)).failure,
      ChatFailure.gone,
    );
    final stored = await container
        .read(activeSessionProvider)!
        .storedChatList();
    expect(stored.map((c) => c.topic), isNot(contains(friends)));
  });
}
