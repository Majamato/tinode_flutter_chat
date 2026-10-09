@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_members_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

// Runs against ../tinode-tests (sample users alice and bob):
//   flutter test --tags integration --run-skipped --concurrency=1
// Each run creates a new group; earlier runs' groups stay on the server.
final config = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

Future<(ProviderContainer, String)> loginAs(String user) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(user, '${user}123'),
    storeOpener: MemoryChatStoreOpener(),
  );
  addTearDown(container.dispose);
  container
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(chatListControllerProvider, (_, _) {});
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
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test('alice sees who wrote, who types, and when bob read hers', () async {
    final (alice, aliceId) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');

    final session = alice.read(activeSessionProvider)!;
    final group = await session.createGroup(
      public: Profile(name: 'Members ${DateTime.now().toIso8601String()}'),
    );
    await session.addMember(group, bobId);
    await session.detach(group);

    for (final container in [alice, bob]) {
      container
        ..listen(chatControllerProvider(group), (_, _) {})
        ..listen(typingMembersProvider(group), (_, _) {});
    }
    await eventually(
      'both members known on both sides',
      () => [alice, bob].every(
        (c) => c.read(chatMembersControllerProvider(group)).byId.length == 2,
      ),
    );

    await bob.read(sendControllerProvider(group).notifier).send('hello');
    await eventually(
      "bob's message on alice's side",
      () => alice.read(chatControllerProvider(group)).seqs.isNotEmpty,
    );
    final bobsSeq = alice.read(chatControllerProvider(group)).seqs.last;
    final sender = alice.read(messageSenderProvider(group, bobsSeq))!;
    expect(sender.userId, bobId);
    expect(sender.name, isNotEmpty);
    expect(sender.showName, isTrue);

    bob.read(typingControllerProvider(group).notifier).typed();
    await eventually(
      'bob typing',
      () =>
          alice.read(typingMembersProvider(group)).names.contains(sender.name),
    );

    await alice.read(sendControllerProvider(group).notifier).send('hi bob');
    await eventually("alice's own message", () {
      final chat = alice.read(chatControllerProvider(group));
      return chat.bySeq[chat.lastSeq]?.from == aliceId;
    });
    final mine = alice.read(chatControllerProvider(group)).lastSeq!;
    // Bob has the chat open: he reads it as it arrives.
    await eventually(
      'read by bob',
      () =>
          alice.read(messageReceiptProvider(group, mine)) ==
          MessageReceipt.read,
    );
  });
}
