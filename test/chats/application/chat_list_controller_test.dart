import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_list_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
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

    expect(session.calls, ['chatList']);
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
}
