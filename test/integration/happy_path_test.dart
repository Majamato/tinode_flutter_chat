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
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

// Runs against ../tinode-tests (sample users alice and bob):
//   (cd ../tinode-tests && docker compose up -d)
//   flutter test --tags integration --run-skipped
final config = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

Future<(ProviderContainer, String)> loginAs(String user) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(user, '${user}123'),
  );
  addTearDown(container.dispose);
  container.listen(sessionControllerProvider, (_, _) {});
  final state = await container.read(sessionControllerProvider.future);
  expect(state, isA<SessionLoggedIn>());
  return (container, container.read(currentUserIdProvider)!);
}

/// Polls [condition] until it holds, failing after [timeout].
Future<void> eventually(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting: $what');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test('alice and bob chat through the package providers', () async {
    final (alice, aliceId) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');

    alice.listen(chatListControllerProvider, (_, _) {});
    bob.listen(chatListControllerProvider, (_, _) {});
    await eventually(
      'chat list',
      () => alice.read(chatListControllerProvider).status == LoadStatus.ready,
    );
    expect(alice.read(chatListControllerProvider).order, contains(bobId));

    // In P2P each side names the topic after the peer.
    alice.listen(chatControllerProvider(bobId), (_, _) {});
    bob.listen(chatControllerProvider(aliceId), (_, _) {});
    alice.listen(sendControllerProvider(bobId), (_, _) {});
    await eventually(
      'both chats loaded',
      () =>
          alice.read(chatControllerProvider(bobId)).status ==
              LoadStatus.ready &&
          bob.read(chatControllerProvider(aliceId)).status == LoadStatus.ready,
    );

    final text = 'integration ${DateTime.now().toIso8601String()}';
    final sent = await alice
        .read(sendControllerProvider(bobId).notifier)
        .send(text);
    expect(sent, isTrue);

    final aliceChat = alice.read(chatControllerProvider(bobId));
    final seq = aliceChat.lastSeq!;
    expect(aliceChat.bySeq[seq]!.content.text, text);
    expect(aliceChat.bySeq[seq]!.isOwn, isTrue);

    // Bob has the chat open: he receives it live and reads it.
    await eventually(
      'bob receives the message',
      () => bob.read(chatMessageProvider(aliceId, seq))?.content.text == text,
    );
    expect(bob.read(chatMessageProvider(aliceId, seq))!.isOwn, isFalse);
    await eventually(
      "bob's chat list catches up",
      () => bob.read(chatSummaryProvider(aliceId))?.lastSeq == seq,
    );
    expect(bob.read(chatSummaryProvider(aliceId))!.unread, 0);
    expect(alice.read(chatSummaryProvider(bobId))!.unread, 0);
  });

  test('a wrong password leaves the session awaiting login', () async {
    final container = createTinodeContainer(
      config: config,
      credentials: const TinodeCredentials.password('alice', 'nope'),
    );
    addTearDown(container.dispose);
    container.listen(sessionControllerProvider, (_, _) {});

    final state = await container.read(sessionControllerProvider.future);

    expect(state, isA<SessionAwaitingLogin>());
  });
}
