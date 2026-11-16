@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/push/application/message_push_handler.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

import 'account_test.dart' show signUp;
import 'group_chat_test.dart' show config;
import 'read_marker_test.dart' show sendFrom;

// Runs against ../tinode-tests:
//   flutter test --tags integration --run-skipped --concurrency=1

/// Opens [session] again, as the app does when it is shown, for the
/// account to be deleted at the end.
Future<void> wake(TinodeSession session) async {
  final connected = session.statusChanges.firstWhere((s) => s is Connected);
  session.resume();
  await connected.timeout(const Duration(seconds: 10));
}

void main() {
  test('a push fetched while the app is closed caches the message, and the '
      'sender sees it delivered', () async {
    final (alice, _, aliceId) = await signUp('Alice');
    final (bob, _, bobId) = await signUp('Bob');
    final token = switch (alice.read(sessionControllerProvider).value) {
      SessionLoggedIn(:final login?) => login.token,
      _ => fail('Alice is not logged in'),
    };
    // Alice's app is closed: no session of hers hears the message.
    final aliceApp = alice.read(activeSessionProvider)!..suspend();
    addTearDown(() => wake(aliceApp));
    // Her device remembers her, with nothing cached yet.
    final device = MemoryChatStoreOpener();
    await device.rememberUser(config.server, aliceId);

    bob
      ..listen(chatControllerProvider(aliceId), (_, _) {})
      ..listen(sendControllerProvider(aliceId), (_, _) {});
    final seq = await sendFrom(bob, aliceId, 'hello from bob');

    final names = await handleMessagePush(
      MessagePush(topic: bobId, seq: seq, from: bobId),
      config: config,
      token: token,
      storeOpener: device,
      connect: ClientTinodeSession.connect,
      portNames: MemoryPortNames(),
    );

    expect(names?.chat, 'Bob');
    final cache = await device.open(config.server, aliceId);
    final latest = await cache.latestMessages(topic: bobId);
    expect(latest[bobId]?.message?.seq, seq);
    expect(latest[bobId]?.message?.content.text, 'hello from bob');
    expect((await cache.chat(bobId))?.received, seq);

    // Bob's open chat hears Alice's received marker.
    final bobSession = bob.read(activeSessionProvider)!;
    Future<bool> delivered() async => (await bobSession.storedMembers(
      aliceId,
    )).any((m) => m.userId == aliceId && m.received >= seq);
    for (var i = 0; i < 100 && !await delivered(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(await delivered(), isTrue, reason: 'Bob sees it delivered');
  });

  test('a burst fetches once: later pushes find it marked received', () async {
    final (alice, _, aliceId) = await signUp('Alice');
    final (bob, _, bobId) = await signUp('Bob');
    final token = switch (alice.read(sessionControllerProvider).value) {
      SessionLoggedIn(:final login?) => login.token,
      _ => fail('Alice is not logged in'),
    };
    final aliceApp = alice.read(activeSessionProvider)!..suspend();
    addTearDown(() => wake(aliceApp));
    final device = MemoryChatStoreOpener();
    await device.rememberUser(config.server, aliceId);
    bob
      ..listen(chatControllerProvider(aliceId), (_, _) {})
      ..listen(sendControllerProvider(aliceId), (_, _) {});
    final first = await sendFrom(bob, aliceId, 'one');
    final last = await sendFrom(bob, aliceId, 'two');

    var connects = 0;
    Future<TinodeSession> connect(TinodeConfig config) {
      connects++;
      return ClientTinodeSession.connect(config);
    }

    for (final seq in [last, first, last]) {
      await handleMessagePush(
        MessagePush(topic: bobId, seq: seq, from: bobId),
        config: config,
        token: token,
        storeOpener: device,
        connect: connect,
        portNames: MemoryPortNames(),
      );
    }

    expect(connects, 1);
    final cache = await device.open(config.server, aliceId);
    expect((await cache.chat(bobId))?.received, last);
  });
}
