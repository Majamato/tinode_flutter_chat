import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  Future<void> later() async {
    // The cache writes, then the history reads it back.
    for (var i = 0; i < 8; i++) {
      await settle();
    }
  }

  Future<void> start(
    List<Subscription> chats,
    Map<String, List<DataMessage>> histories,
  ) async {
    session = FakeTinodeSession(chats: chats, histories: histories);
    container = (await loggedInContainer(session))
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(callHistoryControllerProvider, (_, _) {});
    await later();
  }

  CallHistory history() => container.read(callHistoryControllerProvider);

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue, reason: 'timed out');
  }

  test('the latest catch-up fills it, never from groups', () async {
    await start(
      [
        chat(bob, lastSeq: 2, lastMessageAt: at(2)),
        chat(carol, lastSeq: 4, lastMessageAt: at(4)),
        chat(friends, lastSeq: 1, lastMessageAt: at(1)),
      ],
      {
        bob: [callMessage(bob, 1), callUpdate(bob, 2, 1, CallState.missed)],
        carol: [
          callMessage(carol, 3, from: alice, audioOnly: true),
          callUpdate(
            carol,
            4,
            3,
            CallState.finished,
            from: alice,
            duration: const Duration(minutes: 4),
          ),
        ],
        friends: [callMessage(friends, 1)],
      },
    );
    await until(() => history().ids.length == 2);

    expect(history().ids, [(topic: carol, seq: 3), (topic: bob, seq: 1)]);
    expect(session.attachCount(bob), 0);
    expect(session.attachCount(carol), 0);
    final carolCall = history()[(topic: carol, seq: 3)]!;
    expect(carolCall.outgoing, isTrue);
    expect(carolCall.call.duration, const Duration(minutes: 4));
    expect(history()[(topic: bob, seq: 1)]!.missed, isTrue);
  });

  test('a call that arrives live, then its update, shows', () async {
    await start([chat(bob)], {});

    session.emitMessage(callMessage(bob, 1));
    await later();
    expect(history().ids, [(topic: bob, seq: 1)]);

    session.emitMessage(callUpdate(bob, 2, 1, CallState.declined));
    await later();
    expect(history()[(topic: bob, seq: 1)]!.call.state, CallState.declined);
  });

  test(
    'a call in a chat that is not attached shows after its pres msg',
    () async {
      await start(
        [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
        {
          bob: [message(bob, 1)],
        },
      );
      await until(() => session.calls.contains('detach $bob'));
      expect(history().ids, isEmpty);

      session
        ..histories[bob]!.add(callMessage(bob, 2))
        ..emitPresence(
          const PresMessage(
            topic: 'me',
            event: PresenceEvent.message,
            source: bob,
            seq: 2,
          ),
        );

      // After the session's `latestDelay`.
      await until(() => history().ids.isNotEmpty);
      expect(history().ids, [(topic: bob, seq: 2)]);
    },
  );
}
