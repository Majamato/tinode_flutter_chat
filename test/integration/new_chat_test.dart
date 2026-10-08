@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
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
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test('alice finds bob by his login, and creates a group with him', () async {
    final (alice, _) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');
    alice.listen(chatListControllerProvider, (_, _) {});
    bob.listen(chatListControllerProvider, (_, _) {});
    await eventually(
      'both chat lists',
      () =>
          alice.read(chatListControllerProvider).status == LoadStatus.ready &&
          bob.read(chatListControllerProvider).status == LoadStatus.ready,
    );

    const scope = FindScope.groupMembers;
    alice.listen(findControllerProvider(scope), (_, _) {});
    alice.read(findControllerProvider(scope).notifier).search('bob');
    await eventually(
      'the search',
      () => alice.read(findControllerProvider(scope)).status == FindStatus.done,
    );
    final found = alice.read(findControllerProvider(scope)).results;
    final bobResult = found.singleWhere((r) => r.topic == bobId);
    expect(bobResult.title, isNot(bobId));

    final name = 'Integration ${DateTime.now().toIso8601String()}';
    alice.listen(newGroupControllerProvider, (_, _) {});
    final group = await alice.read(newGroupControllerProvider.notifier).create(
      name,
      [bobResult],
    );
    expect(group, isNotNull);
    expect(group!.notAdded, isEmpty);

    // Alice's list syncs after creating; bob's follows his pres acs.
    await eventually(
      "the group in alice's list",
      () => alice.read(chatSummaryProvider(group.topic))?.title == name,
    );
    await eventually(
      "the group in bob's list",
      () => bob.read(chatSummaryProvider(group.topic))?.title == name,
    );
  });
}
