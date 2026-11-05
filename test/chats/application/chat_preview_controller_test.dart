import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_preview_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_preview.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 3, read: 3, lastMessageAt: at(3)),
      ],
    );
    container = (await loggedInContainer(session))
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(chatPreviewControllerProvider, (_, _) {});
    await settle();
  });

  Future<void> later() async {
    // The cache writes, then the preview reads it back.
    for (var i = 0; i < 5; i++) {
      await settle();
    }
  }

  ChatPreview? bobPreview() => container.read(chatPreviewProvider(bob));
  bool bobBehind() => container.read(chatPreviewBehindProvider(bob));

  test('with nothing cached, the previews come from the server', () async {
    final server = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1)),
        chat(friends, name: 'Friends', lastSeq: 2, lastMessageAt: at(2)),
      ],
      histories: {
        bob: [message(bob, 1, text: 'hi there')],
        friends: [message(friends, 2, from: carol, text: 'hello all')],
      },
    );
    server.memberLists[friends] = [member(carol, name: 'Carol')];
    final fresh = (await loggedInContainer(server))
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(chatPreviewControllerProvider, (_, _) {});
    ChatPreview? preview(String topic) =>
        fresh.read(chatPreviewProvider(topic));

    for (var i = 0; i < 200 && preview(friends)?.senderName == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(preview(bob)?.text, 'hi there');
    expect(preview(friends)?.text, 'hello all');
    expect(preview(friends)?.senderName, 'Carol');
    expect(fresh.read(chatPreviewBehindProvider(bob)), isFalse);
    expect(fresh.read(chatPreviewBehindProvider(friends)), isFalse);
  });

  test('nothing cached: no preview, behind once the chat has messages', () {
    expect(bobPreview(), isNull);
    expect(bobBehind(), isTrue);
  });

  test('a message that arrives is the preview, and stays cached', () async {
    session.emitMessage(message(bob, 4, text: 'hello'));
    await later();

    expect(bobPreview()?.text, 'hello');
    expect(bobPreview()?.kind, ChatPreviewKind.text);
    expect(bobBehind(), isFalse);

    container
      ..invalidate(chatPreviewControllerProvider)
      ..listen(chatPreviewControllerProvider, (_, _) {});
    await later();
    expect(bobPreview()?.text, 'hello');
  });

  test(
    'pres msg puts the preview behind until the message is cached',
    () async {
      session.emitMessage(message(bob, 4, text: 'hello'));
      await later();

      session.emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.message,
          source: bob,
          seq: 5,
        ),
      );
      await later();
      expect(bobBehind(), isTrue);
      expect(bobPreview()?.text, 'hello');

      session.emitMessage(message(bob, 5, text: 'again'));
      await later();
      expect(bobBehind(), isFalse);
      expect(bobPreview()?.text, 'again');
    },
  );
}
