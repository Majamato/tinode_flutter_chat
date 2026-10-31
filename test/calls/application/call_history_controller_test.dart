import 'dart:async';

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
  CallHistoryController controller() =>
      container.read(callHistoryControllerProvider.notifier);
  Iterable<String> fetched() => session.calls.where(
    (call) => call.startsWith('attach ') && call != 'attach me',
  );

  test('fetches the direct chats behind, never groups', () async {
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
    expect(history().loaded, isTrue);
    expect(history().ids, isEmpty);

    await controller().refresh();
    await later();

    expect(fetched(), unorderedEquals(['attach $bob', 'attach $carol']));
    expect(session.attachCount(bob), 0);
    expect(session.attachCount(carol), 0);
    expect(history().ids, [(topic: carol, seq: 3), (topic: bob, seq: 1)]);
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

  test('fetches a few chats at a time', () async {
    final users = [for (var i = 0; i < 5; i++) 'usr$i'];
    await start(
      [for (final user in users) chat(user, lastSeq: 1, lastMessageAt: at(1))],
      {
        for (final user in users) user: [callMessage(user, 1)],
      },
    );
    final hold = session.holdHistory = Completer<void>();

    final refreshing = controller().refresh();
    await later();
    expect(fetched(), hasLength(CallHistoryController.fetchConcurrency));
    expect(history().refreshing, isTrue);

    hold.complete();
    await refreshing;
    await later();
    expect(fetched(), hasLength(5));
    expect(history().ids, hasLength(5));
    expect(history().refreshing, isFalse);
  });

  test('fetches a chat once per session, unless forced', () async {
    await start(
      [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
      {
        bob: [callMessage(bob, 1)],
      },
    );
    session.failHistory = const ConnectionClosedException('dropped');

    await controller().refresh();
    await later();
    await controller().refresh();
    expect(fetched(), hasLength(1));
    expect(session.attachCount(bob), 0);

    await controller().refresh(force: true);
    await later();
    expect(fetched(), hasLength(2));
    expect(history().ids, [(topic: bob, seq: 1)]);
  });

  test('offline it waits, then fetches once connected', () async {
    await start(
      [chat(bob, lastSeq: 1, lastMessageAt: at(1))],
      {
        bob: [callMessage(bob, 1)],
      },
    );
    session.emitStatus(const Suspended());
    await later();

    await controller().refresh();
    expect(fetched(), isEmpty);

    session.emitStatus(const Connected());
    await later();
    expect(fetched(), ['attach $bob']);
  });
}
