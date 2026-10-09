import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/typing_members.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  /// Runs [body] with the group open and its members loaded.
  void run(void Function(FakeAsync async) body) => fakeAsync((async) {
    session = FakeTinodeSession(
      chats: [
        chat(friends, name: 'Friends'),
        chat(bob, name: 'Bob'),
      ],
    );
    session.memberLists[friends] = [
      member(alice, name: 'Alice'),
      member(bob, name: 'Bob'),
      member(carol, name: 'Carol'),
    ];
    unawaited(loggedInContainer(session).then((c) => container = c));
    async.flushMicrotasks();
    for (final topic in [friends, bob]) {
      container
        ..listen(chatControllerProvider(topic), (_, _) {})
        ..listen(typingMembersProvider(topic), (_, _) {});
    }
    async.flushMicrotasks();
    body(async);
  });

  TypingMembers typing([String topic = friends]) =>
      container.read(typingMembersProvider(topic));

  void keyPress(String from, [String topic = friends]) => session.emitInfo(
    InfoMessage(topic: topic, event: InfoEvent.typing, from: from),
  );

  test('members type, first to start first, until they pause', () {
    run((async) {
      keyPress(bob);
      async.elapse(const Duration(seconds: 2));
      keyPress(carol);
      expect(typing().names, ['Bob', 'Carol']);

      async.elapse(typingTimeout - const Duration(seconds: 1));
      expect(typing().names, ['Carol']);
      async.elapse(const Duration(seconds: 2));
      expect(typing().isEmpty, isTrue);
    });
  });

  test('a key press restarts the wait; a message ends it', () {
    run((async) {
      keyPress(bob);
      async.elapse(typingTimeout - const Duration(seconds: 1));
      keyPress(bob);
      async.elapse(const Duration(seconds: 2));
      expect(typing().names, ['Bob']);

      session.emitMessage(message(friends, 1));
      expect(typing().isEmpty, isTrue);
    });
  });

  test("the user's own key presses from another device don't count", () {
    run((async) {
      keyPress(alice);
      expect(typing().isEmpty, isTrue);
    });
  });

  test('in a direct chat the peer types without a name', () {
    run((async) {
      keyPress(bob, bob);
      expect(typing(bob), const TypingMembers(names: [null], direct: true));
    });
  });

  test("the user's typing goes out at most once per throttle", () {
    run((async) {
      final typingNotes = container.read(
        typingControllerProvider(friends).notifier,
      )..typed();
      async.elapse(const Duration(seconds: 1));
      typingNotes.typed();
      async.elapse(typingThrottle);
      typingNotes.typed();

      expect(
        session.calls.where((c) => c == 'sendTyping $friends'),
        hasLength(2),
      );
    });
  });
}
