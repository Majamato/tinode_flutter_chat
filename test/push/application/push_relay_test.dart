import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/push/application/push_relay.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';
import 'package:tinode_flutter_chat/src/push/data/push_relay_port.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  final server = testConfig.server;
  late FakeTinodeSession session;
  late ProviderContainer container;
  late MemoryPortNames ports;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1)),
        chat(friends, name: 'Friends', lastSeq: 1, lastMessageAt: at(1)),
      ],
      histories: {
        bob: [message(bob, 1), message(bob, 2)],
        friends: [message(friends, 1), message(friends, 2, from: carol)],
      },
    )..memberLists[friends] = [member(carol, name: 'Carol')];
    ports = MemoryPortNames();
    container = (await loggedInContainer(session, portNames: ports))
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(pushRelayProvider, (_, _) {});
    await settle();
  });

  TinodePush push(Map<String, Object?> data) => TinodePush.tryParse(data)!;

  Future<TinodePushNames?> relay(TinodePush push) =>
      relayToApp(ports, server, push, timeout: const Duration(seconds: 5));

  test("a new message is fetched by the app's session, and named", () async {
    session.calls.clear();

    final names = await relay(
      push({'what': 'msg', 'topic': friends, 'seq': '2', 'xfrom': carol}),
    );

    expect(
      session.calls,
      containsAllInOrder([
        'attach $friends',
        'history $friends',
        'members $friends $carol',
        'markReceived $friends 2',
        'detach $friends',
      ]),
    );
    expect(names, const TinodePushNames(chat: 'Friends', sender: 'Carol'));
  });

  test('a suspended session wakes to fetch', () async {
    session
      ..emitStatus(const Suspended())
      ..calls.clear();

    final fetched = relay(
      push({'what': 'msg', 'topic': bob, 'seq': '2', 'xfrom': bob}),
    );
    await settle();
    expect(session.calls, contains('resume'));
    session.emitStatus(const Connected());

    expect((await fetched)?.chat, 'Bob');
    expect(session.calls, contains('markReceived $bob 2'));
  });

  test('a read push marks the chat read in the list', () async {
    session.chats[0] = chat(bob, name: 'Bob', lastSeq: 3, lastMessageAt: at(3));
    container.read(chatListControllerProvider.notifier).refresh();
    await settle();
    expect(container.read(chatSummaryProvider(bob))?.unread, 3);

    await relay(push({'what': 'read', 'topic': bob, 'seq': '3'}));

    expect(container.read(chatSummaryProvider(bob))?.unread, 0);
    expect(session.calls, isNot(contains(startsWith('markRead'))));
  });

  test('logged out, the app takes no pushes', () async {
    expect(ports.lookup(pushRelayName(server)), isNotNull);

    container.dispose();

    expect(ports.lookup(pushRelayName(server)), isNull);
    expect(
      await relay(push({'what': 'msg', 'topic': bob, 'seq': '2'})),
      isNull,
    );
  });
}
