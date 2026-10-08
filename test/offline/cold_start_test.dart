import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../support/fake_tinode_session.dart';
import '../support/fixtures.dart';
import '../support/test_container.dart';

/// A day with the app: online first, then reopened without a network.
void main() {
  late MemoryChatStoreOpener stores;

  FakeTinodeSession server() => FakeTinodeSession(
    chats: [chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2))],
    histories: {
      bob: [message(bob, 1), message(bob, 2)],
    },
  );

  Future<ProviderContainer> open(FakeTinodeSession session) async {
    final container =
        createTestContainer(
            connector: connectTo(session),
            restorer: restoreTo(session),
            storeOpener: stores,
            credentials: TinodeCredentials.token(session.token),
          )
          ..listen(sessionControllerProvider, (_, _) {})
          ..listen(chatListControllerProvider, (_, _) {})
          ..listen(reconnectingControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    await settle();
    return container;
  }

  setUp(() async {
    stores = MemoryChatStoreOpener();
    // Online: the chat list and Bob's chat land in the cache.
    final first = await open(server());
    final chat = first.listen(chatControllerProvider(bob), (_, _) {});
    await settle();
    chat.close();
    first.dispose();
    await settle();
  });

  test('the chats and their messages show without a server', () async {
    final offline = server()..reachable = false;
    final container = await open(offline);

    expect(offline.calls.first, 'restore');
    expect(offline.calls, isNot(contains(startsWith('history'))));
    expect(container.read(reconnectingControllerProvider), isTrue);
    final list = container.read(chatListControllerProvider);
    expect(list.status, LoadStatus.ready);
    expect(list.order, [bob]);

    container.listen(chatControllerProvider(bob), (_, _) {});
    await settle();
    final chat = container.read(chatControllerProvider(bob));
    expect(chat.status, LoadStatus.ready);
    expect(chat.seqs, [1, 2]);
  });

  test(
    'what the user wrote offline goes out once the server answers',
    () async {
      final offline = server()..reachable = false;
      final container = await open(offline);
      container
        ..listen(chatControllerProvider(bob), (_, _) {})
        ..listen(sendControllerProvider(bob), (_, _) {});
      await settle();

      await container.read(sendControllerProvider(bob).notifier).send('back');
      await settle();
      expect(
        container.read(chatControllerProvider(bob)).outgoingIds,
        hasLength(1),
      );
      expect(offline.calls, isNot(contains('publish $bob back')));

      offline.histories[bob]!.add(message(bob, 3, text: 'meanwhile'));
      offline.comeOnline();
      await settle();
      await settle();
      await settle();

      expect(
        offline.calls.where((c) => c == 'publish $bob back'),
        hasLength(1),
      );
      final chat = container.read(chatControllerProvider(bob));
      expect(chat.outgoingIds, isEmpty);
      expect(
        [for (final seq in chat.seqs) chat.bySeq[seq]!.content.text],
        ['message 1', 'message 2', 'meanwhile', 'back'],
      );
      expect(container.read(reconnectingControllerProvider), isFalse);
    },
  );
}
