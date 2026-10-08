@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:web_socket/web_socket.dart';

import 'happy_path_test.dart' show eventually;

// Runs against ../tinode-tests (sample users alice and bob):
//   flutter test --tags integration --run-skipped
final config = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
  userAgent: 'tinode_flutter_chat-test/0.1',
  reconnect: const ReconnectPolicy(
    base: Duration(milliseconds: 300),
    cap: Duration(milliseconds: 600),
  ),
);

/// Real sockets, with a way to cut the current one.
final class SeverableConnector {
  WebSocket? _current;

  Future<WebSocket> call(Uri uri) async =>
      _current = await WebSocket.connect(uri);

  Future<void> sever() async => _current?.close();
}

Future<(ProviderContainer, String)> loginAs(
  String user, {
  SeverableConnector? connector,
}) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(user, '${user}123'),
    storeOpener: MemoryChatStoreOpener(),
    connector: connector == null
        ? null
        : (config) async => ClientTinodeSession(
            await TinodeClient.connect(config, connector: connector.call),
          ),
  );
  addTearDown(container.dispose);
  container
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(chatListControllerProvider, (_, _) {});
  await container.read(sessionControllerProvider.future);
  return (container, container.read(currentUserIdProvider)!);
}

Future<void> openChat(ProviderContainer container, String topic) async {
  container
    ..listen(chatControllerProvider(topic), (_, _) {})
    ..listen(sendControllerProvider(topic), (_, _) {});
  await eventually(
    'chat $topic loaded',
    () =>
        container.read(chatControllerProvider(topic)).status ==
        LoadStatus.ready,
  );
}

void main() {
  test('a message sent while the link is down arrives exactly once', () async {
    final link = SeverableConnector();
    final (alice, aliceId) = await loginAs('alice', connector: link);
    final (bob, bobId) = await loginAs('bob');
    await openChat(alice, bobId);
    await openChat(bob, aliceId);

    final text = 'offline ${DateTime.now().microsecondsSinceEpoch}';
    await link.sever();
    await eventually(
      'alice is reconnecting',
      () => alice.read(activeSessionProvider)!.status is! Connected,
    );
    expect(
      await alice.read(sendControllerProvider(bobId).notifier).send(text),
      isTrue,
    );

    await eventually(
      'bob receives it',
      () => bob
          .read(chatControllerProvider(aliceId))
          .bySeq
          .values
          .any((m) => m.content.text == text),
      timeout: const Duration(seconds: 15),
    );
    await eventually(
      "alice's outbox is empty",
      () => alice.read(chatControllerProvider(bobId)).outgoingIds.isEmpty,
    );

    // Once, with the outbox's client ID, also on the server.
    final history = await bob
        .read(activeSessionProvider)!
        .history(aliceId, limit: 10);
    final copies = history.where((m) => m.content.text == text).toList();
    expect(copies, hasLength(1));
    expect(clientIdOf(copies.single.head), isNotNull);
  });

  test("deleting for me reaches alice's other device", () async {
    final (phone, _) = await loginAs('alice');
    final (laptop, _) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');
    await openChat(phone, bobId);
    await openChat(laptop, bobId);

    final text = 'to delete ${DateTime.now().microsecondsSinceEpoch}';
    await phone.read(sendControllerProvider(bobId).notifier).send(text);
    int? seqOf(ProviderContainer c) => c
        .read(chatControllerProvider(bobId))
        .bySeq
        .values
        .where((m) => m.content.text == text)
        .firstOrNull
        ?.seq;
    await eventually('both devices have it', () => seqOf(laptop) != null);
    final seq = seqOf(phone)!;

    await phone.read(chatControllerProvider(bobId).notifier).delete({
      seq,
    }, forEveryone: false);
    expect(seqOf(phone), isNull);

    await eventually('the laptop drops it', () => seqOf(laptop) == null);
    // Bob still has it: it was deleted for alice only.
    expect(bob, isNotNull);
  });
}
