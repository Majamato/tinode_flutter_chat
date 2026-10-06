import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 3, read: 1, lastMessageAt: at(3)),
      ],
      histories: {
        bob: [message(bob, 1), message(bob, 2, from: alice), message(bob, 3)],
      },
    );
    container = await loggedInContainer(session)
      ..listen(chatListControllerProvider, (_, _) {});
    await settle();
  });

  ProviderSubscription<ChatState> openChat([String topic = bob]) =>
      container.listen(chatControllerProvider(topic), (_, _) {});

  ChatState chatState([String topic = bob]) =>
      container.read(chatControllerProvider(topic));

  test('attaches, loads history and marks it read', () async {
    openChat();
    expect(chatState().status, LoadStatus.loading);
    await settle();

    expect(chatState().status, LoadStatus.ready);
    expect(chatState().seqs, [1, 2, 3]);
    expect(chatState().bySeq[2]!.isOwn, isTrue);
    expect(chatState().hasOlder, isFalse);
    expect(
      session.calls,
      containsAllInOrder(['attach $bob', 'history $bob', 'markRead $bob 3']),
    );
    expect(container.read(chatSummaryProvider(bob))?.unread, 0);
  });

  group('after a reconnect', () {
    setUp(() async {
      openChat();
      await settle();
      session.calls.clear();
    });

    test('fetches what it missed by seq and marks it read', () async {
      session.histories[bob]!.addAll([message(bob, 4), message(bob, 5)]);

      session.emitStatus(const Connected());
      await settle();

      expect(session.calls.where((c) => c.contains(bob)), [
        'history $bob since 4',
        'markRead $bob 5',
      ]);
      expect(chatState().seqs, [1, 2, 3, 4, 5]);
    });

    test('a full page of missed messages reloads the chat', () async {
      session.histories[bob]!.addAll([
        for (var seq = 4; seq < 4 + historyPageSize; seq++) message(bob, seq),
      ]);

      session.emitStatus(const Connected());
      await settle();
      await settle();

      expect(
        session.calls,
        containsAllInOrder(['detach $bob', 'attach $bob', 'history $bob']),
      );
      expect(chatState().seqs.last, 3 + historyPageSize);
      expect(chatState().seqs, hasLength(historyPageSize));
    });
  });

  test('a message arriving during the load is kept', () async {
    final hold = session.holdHistory = Completer<void>();
    openChat();
    await settle();

    session.emitMessage(message(bob, 4));
    hold.complete();
    await settle();

    expect(chatState().seqs, [1, 2, 3, 4]);
  });

  test('live messages merge and are marked read', () async {
    openChat();
    await settle();

    session.emitMessage(message(bob, 4, text: 'live'));

    expect(chatState().bySeq[4]!.content.text, 'live');
    expect(session.calls.last, 'markRead $bob 4');
  });

  test('messages of other chats are ignored', () async {
    openChat();
    await settle();

    session.emitMessage(message(friends, 9));

    expect(chatState().seqs, [1, 2, 3]);
  });

  test('a history failure can be retried', () async {
    session.failHistory = const ServerException(403, 'denied');
    openChat();
    await settle();

    expect(chatState().status, LoadStatus.failed);
    expect(chatState().failure, ChatFailure.rejected);

    container.read(chatControllerProvider(bob).notifier).reload();
    await settle();
    expect(chatState().status, LoadStatus.ready);
  });

  test('loads older pages before the first message', () async {
    session.histories[bob] = [
      for (var seq = 1; seq <= historyPageSize + 5; seq++) message(bob, seq),
    ];
    openChat();
    await settle();
    expect(chatState().hasOlder, isTrue);
    expect(chatState().firstSeq, 6);

    await container.read(chatControllerProvider(bob).notifier).loadOlder();

    expect(chatState().firstSeq, 1);
    expect(chatState().hasOlder, isFalse);
    expect(chatState().loadingOlder, isFalse);
    expect(session.calls, contains('history $bob before 6'));
  });

  test('detaches when the chat closes', () async {
    final chat = openChat();
    await settle();

    chat.close();
    await container.pump();
    await settle();

    expect(session.calls, contains('detach $bob'));
  });

  group('send', () {
    test('publishes, shows the message and dedups the echo', () async {
      openChat();
      container.listen(sendControllerProvider(bob), (_, _) {});
      await settle();

      final sent = await container
          .read(sendControllerProvider(bob).notifier)
          .send('  hello  ');
      await settle();

      expect(sent, isTrue);
      expect(session.calls, contains('publish $bob hello'));
      expect(chatState().seqs, [1, 2, 3, 4]);
      expect(chatState().bySeq[4]!.isOwn, isTrue);
      expect(chatState().bySeq[4]!.content.text, 'hello');
      expect(container.read(sendControllerProvider(bob)).hasError, isFalse);
    });

    test('blank text is not sent', () async {
      openChat();
      await settle();

      final sent = await container
          .read(sendControllerProvider(bob).notifier)
          .send('   ');

      expect(sent, isFalse);
      expect(session.calls, isNot(contains(startsWith('publish'))));
    });

    test('a failure is reported and nothing is added', () async {
      openChat();
      container.listen(sendControllerProvider(bob), (_, _) {});
      await settle();
      session.failPublish = const ServerException(403, 'denied');

      final sent = await container
          .read(sendControllerProvider(bob).notifier)
          .send('hello');

      expect(sent, isFalse);
      expect(container.read(sendControllerProvider(bob)).hasError, isTrue);
      expect(chatState().seqs, [1, 2, 3]);
    });
  });
}
