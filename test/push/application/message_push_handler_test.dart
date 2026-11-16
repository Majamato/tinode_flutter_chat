import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/push/application/message_push_handler.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';
import 'package:tinode_flutter_chat/src/push/data/push_relay_port.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  final server = testConfig.server;
  late MemoryChatStoreOpener stores;
  late MemoryPortNames ports;
  late FakeTinodeSession remote;
  late int connects;

  setUp(() async {
    stores = MemoryChatStoreOpener();
    ports = MemoryPortNames();
    await stores.rememberUser(server, alice);
    remote = FakeTinodeSession(
      chats: [chat(bob, name: 'Bob', lastSeq: 3, lastMessageAt: at(3))],
      histories: {
        bob: [message(bob, 1), message(bob, 2), message(bob, 3)],
        friends: [message(friends, 1, from: carol)],
      },
    )..memberLists[friends] = [member(carol, name: 'Carol')];
    connects = 0;
  });

  Future<ChatStore> store() => stores.open(server, alice);

  /// The cache holds [chats], as the app last synced them.
  Future<void> cached(List<Subscription> chats) async =>
      (await store()).mergeChats(chats);

  /// A push as the push service hands it over.
  TinodePush push(Map<String, Object?> data) => TinodePush.tryParse(data)!;

  TinodePush newMessage(String topic, int seq, {String from = bob}) =>
      push({'what': 'msg', 'topic': topic, 'seq': '$seq', 'xfrom': from});

  Future<TinodePushNames?> handle(
    TinodePush push, {
    String? token = 'token-$alice',
    Duration timeout = backgroundPushTimeout,
    SessionConnector? connect,
  }) => handleMessagePush(
    push,
    config: testConfig,
    token: token,
    storeOpener: stores,
    connect:
        connect ??
        (_) async {
          connects++;
          return remote;
        },
    portNames: ports,
    timeout: timeout,
  );

  test('a new message is fetched, and marked received while its chat is '
      'attached', () async {
    await cached([chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1))]);

    final names = await handle(newMessage(bob, 3));

    expect(
      remote.calls,
      containsAllInOrder([
        'loginToken',
        'attach $bob',
        'history $bob',
        'markReceived $bob 3',
        'detach $bob',
        'close',
      ]),
    );
    final latest = await (await store()).latestMessages(topic: bob);
    expect(latest[bob]?.message?.seq, 3);
    expect((await (await store()).coverage(bob)).top?.high, 4);
    expect((await (await store()).chat(bob))?.received, 3);
    expect(names, const TinodePushNames(chat: 'Bob'));
  });

  test('a chat the cache lacks is fetched first', () async {
    final names = await handle(newMessage(bob, 3));

    expect(
      remote.calls,
      containsAllInOrder(['chat $bob', 'attach $bob', 'markReceived $bob 3']),
    );
    expect(names?.chat, 'Bob');
  });

  test('a message already marked received needs no connection', () async {
    await cached([chat(bob, name: 'Bob', lastSeq: 3, lastMessageAt: at(3))]);
    await (await store()).advanceChat(bob, received: 3);

    final names = await handle(newMessage(bob, 3));

    expect(connects, 0);
    expect(names?.chat, 'Bob');
  });

  test('what the user wrote offline is never sent from here', () async {
    await cached([chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1))]);
    await (await store()).enqueuePublish(
      bob,
      'client-1',
      const PlainText('sent later, by the app'),
      at(5),
    );

    await handle(newMessage(bob, 3));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(remote.calls, isNot(contains(startsWith('publish'))));
    expect(await (await store()).outbox(topic: bob), hasLength(1));
  });

  test('a group names the sender, fetched when the cache lacks them', () async {
    await cached([chat(friends, name: 'Friends', lastMessageAt: at(0))]);

    final names = await handle(newMessage(friends, 1, from: carol));

    expect(remote.calls, contains('members $friends $carol'));
    expect(names, const TinodePushNames(chat: 'Friends', sender: 'Carol'));
  });

  test('a read marker is kept, with no connection', () async {
    await cached([chat(bob, lastSeq: 3, read: 1, lastMessageAt: at(3))]);

    await handle(push({'what': 'read', 'topic': bob, 'seq': '3'}));

    expect(connects, 0);
    expect((await (await store()).chat(bob))?.read, 3);
  });

  test('a new chat is fetched, with its name', () async {
    final names = await handle(
      push({'what': 'sub', 'topic': bob, 'xfrom': bob}),
    );

    expect(remote.calls, contains('chat $bob'));
    expect((await (await store()).chat(bob))?.public?.name, 'Bob');
    expect(names?.chat, 'Bob');
  });

  test('a call push is left to TinodeCalls', () async {
    final call = push({
      'what': 'msg',
      'topic': bob,
      'seq': '4',
      'webrtc': 'started',
    });

    expect(await handle(call), isNull);
    expect(connects, 0);
  });

  test('without a token, or a user on the device, nothing happens', () async {
    expect(await handle(newMessage(bob, 3), token: null), isNull);

    await stores.forgetUser(server);
    expect(await handle(newMessage(bob, 3)), isNull);
    expect(connects, 0);
  });

  test('a server that never answers gives up within the time, and the '
      'cached names still come', () async {
    await cached([chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1))]);
    final never = Completer<FakeTinodeSession>();

    final watch = Stopwatch()..start();
    final names = await handle(
      newMessage(bob, 3),
      timeout: const Duration(milliseconds: 50),
      connect: (_) => never.future,
    );

    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(names?.chat, 'Bob');
  });

  test('a refused token gives up, and the cached names still come', () async {
    await cached([chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1))]);

    final names = await handle(newMessage(bob, 3), token: 'expired');

    expect(remote.calls, isNot(contains('attach $bob')));
    expect(remote.calls, contains('close'));
    expect(names?.chat, 'Bob');
  });

  test('the cached names come at once, without the server', () async {
    await cached([chat(friends, name: 'Friends', lastMessageAt: at(0))]);
    await (await store()).putMember(friends, member(carol, name: 'Carol'));

    final names = await cachedPushNames(
      newMessage(friends, 1, from: carol),
      server: server,
      storeOpener: stores,
    );

    expect(names, const TinodePushNames(chat: 'Friends', sender: 'Carol'));
    expect(connects, 0);
  });

  test('no cached names without a user on the device', () async {
    await stores.forgetUser(server);

    expect(
      await cachedPushNames(
        newMessage(bob, 1),
        server: server,
        storeOpener: stores,
      ),
      isNull,
    );
  });

  group('while the app lives', () {
    final name = pushRelayName(server);

    test("the app's session takes the push, and nothing connects", () async {
      final taken = <TinodePush>[];
      final app = AppPushPort.open(ports, server, (push) async {
        taken.add(push);
        return const TinodePushNames(chat: 'Bob, as the app has it');
      });
      addTearDown(app.close);

      final names = await handle(newMessage(bob, 3));

      expect(taken.single, isA<MessagePush>());
      expect(names, const TinodePushNames(chat: 'Bob, as the app has it'));
      expect(connects, 0);
    });

    test('a port left by an app that is gone is dropped, and the push is '
        'fetched here', () async {
      final gone = ReceivePort();
      addTearDown(gone.close);
      ports.register(gone.sendPort, name);
      await cached([chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1))]);

      await handle(newMessage(bob, 3));

      expect(connects, 1);
      expect(remote.calls, contains('markReceived $bob 3'));
      expect(ports.lookup(name), isNull);
    });
  });
}
