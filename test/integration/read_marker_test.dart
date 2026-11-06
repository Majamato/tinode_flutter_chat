@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import 'account_test.dart' show signUp;
import 'call_test.dart' show User;
import 'group_chat_test.dart' show config, eventually;

// Runs against ../tinode-tests:
//   flutter test --tags integration --run-skipped --concurrency=1
// Each test signs up its own users and deletes them at the end.

/// [login] on a device with an empty cache, as after a log out or a
/// reinstall: the chat list shows the server's read markers.
Future<ProviderContainer> loginAfresh(String login) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(login, 'secret1'),
    storeOpener: MemoryChatStoreOpener(),
  );
  addTearDown(container.dispose);
  container
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(chatListControllerProvider, (_, _) {});
  expect(
    await container.read(sessionControllerProvider.future),
    isA<SessionLoggedIn>(),
  );
  await eventually(
    'the chat list',
    () => container.read(chatListControllerProvider).status == LoadStatus.ready,
  );
  return container;
}

/// Sends [text] from an open chat and returns its seq.
Future<int> sendFrom(ProviderContainer user, String topic, String text) async {
  await user.read(sendControllerProvider(topic).notifier).send(text);
  await eventually(
    'the message to be sent',
    () => user.read(chatControllerProvider(topic)).outgoingIds.isEmpty,
  );
  return user.read(chatControllerProvider(topic)).lastSeq!;
}

/// Opens [topic] until its unread messages are gone, then closes it.
Future<void> readChat(ProviderContainer user, String topic) async {
  final open = user.listen(chatControllerProvider(topic), (_, _) {});
  await eventually(
    'the chat to be read',
    () =>
        user.read(chatControllerProvider(topic)).status == LoadStatus.ready &&
        user.read(chatSummaryProvider(topic))?.unread == 0,
  );
  // The marker may still be on its way through the outbox.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  open.close();
}

void main() {
  test('a chat opened from the cache stays read on a fresh login', () async {
    final (sender, _, senderId) = await signUp('Sender');
    final (reader, readerLogin, readerId) = await signUp('Reader');
    sender
      ..listen(chatControllerProvider(readerId), (_, _) {})
      ..listen(sendControllerProvider(readerId), (_, _) {});
    await eventually(
      'the chat to be ready',
      () =>
          sender.read(chatControllerProvider(readerId)).status ==
          LoadStatus.ready,
    );

    await sendFrom(sender, readerId, 'Hello');
    await eventually(
      'the message to be unread',
      () => reader.read(chatSummaryProvider(senderId))?.unread == 1,
    );
    // The latest catch-up fetches it before the user opens the chat.
    final session = reader.read(activeSessionProvider)!;
    await eventuallyAsync(
      'the message to be cached',
      () async =>
          (await session.storedPage(senderId, limit: 1)).messages.isNotEmpty,
    );

    await readChat(reader, senderId);

    final again = await loginAfresh(readerLogin);
    expect(again.read(chatSummaryProvider(senderId))?.unread, 0);
  });

  test(
    'a message deleted before it was read stays read on a fresh login',
    () async {
      final (sender, _, senderId) = await signUp('Sender');
      final (reader, readerLogin, readerId) = await signUp('Reader');
      sender
        ..listen(chatControllerProvider(readerId), (_, _) {})
        ..listen(sendControllerProvider(readerId), (_, _) {});
      await eventually(
        'the chat to be ready',
        () =>
            sender.read(chatControllerProvider(readerId)).status ==
            LoadStatus.ready,
      );

      await sendFrom(sender, readerId, 'Stays');
      await eventually(
        'the first message to be unread',
        () => reader.read(chatSummaryProvider(senderId))?.unread == 1,
      );
      await readChat(reader, senderId);

      final deleted = await sendFrom(sender, readerId, 'Taken back');
      await eventually(
        'the second message to be unread',
        () => reader.read(chatSummaryProvider(senderId))?.unread == 1,
      );
      await sender.read(chatControllerProvider(readerId).notifier).delete({
        deleted,
      }, forEveryone: true);

      await readChat(reader, senderId);

      final again = await loginAfresh(readerLogin);
      expect(again.read(chatSummaryProvider(senderId))?.lastSeq, deleted);
      expect(again.read(chatSummaryProvider(senderId))?.unread, 0);
    },
  );

  test('a missed call that took two seqs counts as one', () async {
    final alice = await User.login('alice');
    final bob = await User.login('bob');
    await readChat(bob.container, alice.id);
    final before = bob.container.read(chatSummaryProvider(alice.id))!.lastSeq;

    await alice.calls.start(bob.id, audioOnly: true);
    await eventually('it rings', () => bob.stage == CallStage.incoming);
    alice.calls.hangUp();

    await eventually(
      'the call and how it ended in the list',
      () =>
          bob.container.read(chatSummaryProvider(alice.id))!.lastSeq ==
          before + 2,
    );
    await eventually(
      'the call to count once',
      () => bob.container.read(chatSummaryProvider(alice.id))!.unread == 1,
    );
  });

  test('a declined call leaves nothing unread, on a fresh login too', () async {
    final alice = await User.login('alice');
    final bob = await User.login('bob');
    await readChat(bob.container, alice.id);
    final before = bob.container.read(chatSummaryProvider(alice.id))!.lastSeq;

    await alice.calls.start(bob.id, audioOnly: true);
    await eventually('it rings', () => bob.stage == CallStage.incoming);
    bob.calls.decline();
    await eventually('alice sees it', () => alice.stage == CallStage.ended);

    await eventually(
      'the call and how it ended in the list',
      () =>
          bob.container.read(chatSummaryProvider(alice.id))!.lastSeq ==
          before + 2,
    );
    await eventually(
      'nothing to be unread',
      () => bob.container.read(chatSummaryProvider(alice.id))!.unread == 0,
    );

    final again = await User.login('bob');
    await eventually(
      'nothing to be unread on a fresh login',
      () => again.container.read(chatSummaryProvider(alice.id))!.unread == 0,
    );
  });

  test(
    'an answered call leaves nothing unread, on a fresh login too',
    () async {
      final alice = await User.login('alice');
      final bob = await User.login('bob');
      await readChat(bob.container, alice.id);
      final before = bob.container.read(chatSummaryProvider(alice.id))!.lastSeq;

      await alice.calls.start(bob.id, audioOnly: true);
      await eventually('it rings', () => bob.stage == CallStage.incoming);
      await bob.calls.accept();
      await eventually(
        'the call to be answered',
        () =>
            bob.container.read(chatSummaryProvider(alice.id))!.lastSeq >
            before + 1,
      );
      bob.calls.hangUp();
      await eventually('alice sees it', () => alice.stage == CallStage.ended);

      await eventually(
        'nothing to be unread',
        () => bob.container.read(chatSummaryProvider(alice.id))!.unread == 0,
      );

      final again = await User.login('bob');
      await eventually(
        'nothing to be unread on a fresh login',
        () => again.container.read(chatSummaryProvider(alice.id))!.unread == 0,
      );
    },
  );
}

/// Polls the async [condition] until it holds, failing after ten seconds.
Future<void> eventuallyAsync(
  String what,
  Future<bool> Function() condition,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
