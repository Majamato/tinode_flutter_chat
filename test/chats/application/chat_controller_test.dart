import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
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
        'members $bob',
        'history $bob since 4',
        'deleteLog $bob since 1',
        'markRead $bob 5',
      ]);
      expect(chatState().seqs, [1, 2, 3, 4, 5]);
    });

    test('a full page of missed messages starts over from it', () async {
      session.histories[bob]!.addAll([
        for (var seq = 4; seq < 4 + historyPageSize; seq++) message(bob, seq),
      ]);

      session.emitStatus(const Connected());
      await settle();

      expect(session.calls, isNot(contains('detach $bob')));
      expect(chatState().seqs.first, 4);
      expect(chatState().seqs.last, 3 + historyPageSize);
      expect(chatState().hasOlder, isTrue);

      // The older page comes from the cache: no request for it.
      session.calls.clear();
      await container.read(chatControllerProvider(bob).notifier).loadOlder();
      expect(chatState().seqs.first, 1);
      expect(chatState().hasOlder, isFalse);
      expect(session.calls.where((c) => c.startsWith('history')), isEmpty);
    });

    test('deletions made meanwhile are applied', () async {
      session
        ..recordDeletion(bob, const [SeqRange.single(2)])
        ..emitStatus(const Connected());
      await settle();

      expect(chatState().seqs, [1, 3]);
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

  test('opening a chat the list lacks syncs the list', () async {
    // The server makes the 1:1 chat on attach; its creator gets no pres.
    session.chats.add(chat(carol, name: 'Carol', lastMessageAt: at(9)));
    session.calls.clear();
    openChat(carol);
    await settle();

    expect(session.calls, containsAllInOrder(['attach $carol', 'chatList']));
    expect(container.read(chatSummaryProvider(carol))?.title, 'Carol');
  });

  test('opening a listed chat does not sync the list', () async {
    session.calls.clear();
    openChat();
    await settle();
    expect(session.calls, isNot(contains('chatList')));
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

    test('a refused message is marked failed and can be retried', () async {
      openChat();
      container.listen(sendControllerProvider(bob), (_, _) {});
      await settle();
      session.failPublish = const ServerException(403, 'denied');

      final sent = await container
          .read(sendControllerProvider(bob).notifier)
          .send('hello');
      await settle();

      expect(sent, isTrue);
      expect(chatState().seqs, [1, 2, 3]);
      final id = chatState().outgoingIds.single;
      expect(chatState().outgoingById[id]!.status, OutgoingStatus.failed);
      expect(chatState().outgoingById[id]!.failure, ChatFailure.rejected);

      await container.read(chatControllerProvider(bob).notifier).retry(id);
      await settle();

      expect(chatState().outgoingIds, isEmpty);
      expect(chatState().bySeq[4]!.content.text, 'hello');
      expect(chatState().bySeq[4]!.clientId, id);
    });

    test('a failed message can be discarded', () async {
      openChat();
      await settle();
      session.failPublish = const ServerException(403, 'denied');
      await container.read(sendControllerProvider(bob).notifier).send('hi');
      await settle();

      final id = chatState().outgoingIds.single;
      await container.read(chatControllerProvider(bob).notifier).discard(id);

      expect(chatState().outgoingIds, isEmpty);
      expect(session.calls.where((c) => c.startsWith('publish')), hasLength(1));
    });

    test('offline it waits in the outbox and goes out on connect', () async {
      openChat();
      await settle();
      session.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
      );

      final sent = await container
          .read(sendControllerProvider(bob).notifier)
          .send('later');
      await settle();

      expect(sent, isTrue);
      final id = chatState().outgoingIds.single;
      expect(chatState().outgoingById[id]!.status, OutgoingStatus.queued);
      expect(session.calls, isNot(contains('publish $bob later')));

      session.emitStatus(const Connected());
      await settle();
      await settle();

      expect(
        session.calls.where((c) => c == 'publish $bob later'),
        hasLength(1),
      );
      expect(session.publishHeads.last, {clientIdHeadKey: id});
      expect(chatState().outgoingIds, isEmpty);
      expect(chatState().bySeq[4]!.content.text, 'later');
    });

    test('a lost ack is found on the server, not sent twice', () async {
      openChat();
      await settle();
      // No echo either: only a look at the server can tell it arrived.
      session
        ..echo = false
        ..loseNextAck = const ConnectionClosedException('dropped');

      await container.read(sendControllerProvider(bob).notifier).send('once');
      await settle();
      expect(chatState().outgoingIds, hasLength(1));

      session.emitStatus(const Connected());
      await settle();
      await settle();

      expect(
        session.calls.where((c) => c == 'publish $bob once'),
        hasLength(1),
      );
      expect(session.calls, contains('history $bob since 4'));
      expect(chatState().outgoingIds, isEmpty);
      expect(chatState().bySeq[4]!.content.text, 'once');
    });
  });

  group('delete', () {
    test('hides the messages at once and tells the server', () async {
      openChat();
      await settle();

      await container.read(chatControllerProvider(bob).notifier).delete({
        1,
        2,
      }, forEveryone: false);
      expect(chatState().seqs, [3]);
      await settle();

      expect(session.calls, contains('delete $bob 1-3'));
    });

    test('for everyone asks for a hard delete', () async {
      openChat();
      await settle();

      await container.read(chatControllerProvider(bob).notifier).delete({
        3,
      }, forEveryone: true);
      await settle();

      expect(session.calls, contains('delete $bob 3-4 hard'));
    });

    test('a refused delete brings the messages back', () async {
      openChat();
      await settle();
      session.failDelete = const ServerException(403, 'denied');

      await container.read(chatControllerProvider(bob).notifier).delete({
        3,
      }, forEveryone: true);
      expect(chatState().seqs, [1, 2]);
      await settle();
      await settle();

      expect(chatState().seqs, [1, 2, 3]);
    });

    test('pres del from another session is applied', () async {
      openChat();
      await settle();

      session.emitPresence(
        const PresMessage(
          topic: bob,
          event: PresenceEvent.deleted,
          lastDeleteId: 1,
          deletedRanges: [SeqRange.single(1)],
        ),
      );
      await settle();

      expect(chatState().seqs, [2, 3]);
    });
  });

  group('from the cache', () {
    test('a reopened chat shows before the server answers', () async {
      final first = openChat();
      await settle();
      first.close();
      await settle();

      final hold = session.holdHistory = Completer<void>();
      session.histories[bob]!.add(message(bob, 4));
      openChat();
      await settle();

      expect(chatState().status, LoadStatus.ready);
      expect(chatState().seqs, [1, 2, 3]);

      hold.complete();
      await settle();
      expect(chatState().seqs, [1, 2, 3, 4]);
    });

    test('offline, a cached chat stays ready', () async {
      final first = openChat();
      await settle();
      first.close();
      await settle();

      session.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
      );
      openChat();
      await settle();

      expect(chatState().status, LoadStatus.ready);
      expect(chatState().seqs, [1, 2, 3]);
    });
  });
}
