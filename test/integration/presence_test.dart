@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/profile/application/presence_visibility_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import 'account_test.dart' show signUp;
import 'happy_path_test.dart' show config, eventually;

// Runs against ../tinode-tests (sample users alice and bob):
//   (cd ../tinode-tests && docker compose up -d)
//   flutter test --tags integration --run-skipped --concurrency=1
Future<(ProviderContainer, String)> loginAs(
  String user, {
  TinodeChatFeatures features = const TinodeChatFeatures(),
}) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(user, '${user}123'),
    storeOpener: MemoryChatStoreOpener(),
    features: features,
  );
  addTearDown(container.dispose);
  container
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(chatListControllerProvider, (_, _) {});
  await container.read(sessionControllerProvider.future);
  await eventually(
    'chat list',
    () => container.read(chatListControllerProvider).status == LoadStatus.ready,
  );
  return (container, container.read(currentUserIdProvider)!);
}

void main() {
  test('alice sees bob come online, then when he was last seen', () async {
    final (alice, _) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');

    await eventually(
      'bob online',
      () => alice.read(chatSummaryProvider(bobId))?.online ?? false,
    );

    // The server says `off` a few seconds after the link goes.
    final left = DateTime.now();
    bob.dispose();
    await eventually(
      'bob offline',
      () => !(alice.read(chatSummaryProvider(bobId))?.online ?? true),
      timeout: const Duration(seconds: 15),
    );
    final lastSeen = alice.read(chatSummaryProvider(bobId))!.lastSeen!;
    expect(lastSeen.difference(left).inSeconds.abs(), lessThan(15));
  });

  test('with presence off, alice never sees bob online or last seen', () async {
    final (alice, _) = await loginAs(
      'alice',
      features: const TinodeChatFeatures(presence: false),
    );
    final (bob, bobId) = await loginAs('bob');

    // Long enough for `pres on`, and for `off` once bob leaves.
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(alice.read(chatSummaryProvider(bobId))!.online, isFalse);
    bob.dispose();
    await Future<void>.delayed(const Duration(seconds: 7));

    final summary = alice.read(chatSummaryProvider(bobId))!;
    expect(summary.online, isFalse);
    expect(summary.lastSeen, isNull);
    final stored = await alice.read(activeSessionProvider)!.storedChatList();
    expect(stored.every((chat) => chat.seen == null && !chat.online), isTrue);
  });

  test('a user who hides their status shows no online or last seen to '
      'others, as soon as they change it', () async {
    final (hider, _, hiderId) = await signUp('Hider');
    final (watcher, _, _) = await signUp('Watcher');

    // A direct chat between them: the watcher writes first.
    final session = watcher.read(activeSessionProvider)!;
    await session.attach(hiderId);
    await session.publish(hiderId, const PlainText('hi'));
    await session.detach(hiderId);
    watcher.read(chatListControllerProvider.notifier).refresh();
    await eventually(
      'the hider online for the watcher',
      () => watcher.read(chatSummaryProvider(hiderId))?.online ?? false,
    );

    hider.listen(profileControllerProvider, (_, _) {});
    await hider.read(profileControllerProvider.future);
    expect(
      await hider
          .read(presenceVisibilityControllerProvider.notifier)
          .set(shown: false),
      isTrue,
    );

    // `pres upd` makes the watcher sync: the flag hides them while online.
    await eventually(
      'the hider hidden',
      () => watcher.read(chatSummaryProvider(hiderId))?.presenceHidden ?? false,
    );
    final hidden = watcher.read(chatSummaryProvider(hiderId))!;
    expect(hidden.online, isFalse);
    expect(hidden.lastSeen, isNull);

    // Shown again: the server merges `public`, so this must overwrite the
    // flag, not leave it out.
    expect(
      await hider
          .read(presenceVisibilityControllerProvider.notifier)
          .set(shown: true),
      isTrue,
    );
    await eventually(
      'the hider online again for the watcher',
      () => switch (watcher.read(chatSummaryProvider(hiderId))) {
        final chat? => !chat.presenceHidden && chat.online,
        null => false,
      },
    );
  });
}
