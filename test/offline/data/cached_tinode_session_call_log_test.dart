import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';

import '../../support/cached_calls_oracle.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/faulty_database.dart';
import '../../support/fixtures.dart';

/// What the session does for the call log. What the log itself does is in
/// `call_log_test.dart`; that the cache's behaviour didn't change, in
/// `cached_tinode_session_test.dart`, `call_log_model_test.dart` and the
/// oracle here.
void main() {
  late FakeTinodeSession remote;
  late ChatDatabase cache;
  late ChatStore store;
  late CallLogDatabase logDb;
  late CallLog log;
  late DatabaseFault logFault;
  late DatabaseFault cacheFault;
  late CachedTinodeSession session;

  /// [chat]s for the topics, each with [lastSeq] 0: nothing for the latest
  /// catch-up to fetch unless a test asks.
  List<Subscription> quiet(List<String> topics) => [
    for (final topic in topics) chat(topic, name: topic),
  ];

  /// The same data on a new link, for a session after the first.
  FakeTinodeSession relinked() {
    final next = FakeTinodeSession(
      chats: remote.chats,
      histories: remote.histories,
    );
    next.deleteLogs.addAll(remote.deleteLogs);
    return remote = next;
  }

  CachedTinodeSession open({TinodeCacheLimits? limits}) =>
      session = CachedTinodeSession(
        remote,
        store,
        userId: alice,
        calls: log,
        limits: limits ?? const TinodeCacheLimits(),
        latestDelay: Duration.zero,
      );

  setUp(() {
    remote = FakeTinodeSession(
      chats: quiet([bob, carol, friends]),
      histories: {
        bob: [
          callMessage(bob, 1),
          callUpdate(bob, 2, 1, CallState.finished),
          message(bob, 3),
          callMessage(bob, 4, from: alice),
        ],
        carol: [message(carol, 1), callMessage(carol, 2)],
        friends: [callMessage(friends, 1)],
      },
    );
    cacheFault = DatabaseFault();
    logFault = DatabaseFault();
    cache = ChatDatabase(NativeDatabase.memory().interceptWith(cacheFault));
    store = ChatStore(cache, ownsDatabase: false);
    logDb = CallLogDatabase(NativeDatabase.memory().interceptWith(logFault));
    log = CallLog(logDb, ownsDatabase: false);
    open();
    addTearDown(() async {
      cacheFault
        ..failing = false
        ..failingWrites = false;
      logFault
        ..failing = false
        ..failingWrites = false
        ..failingClose = false;
      await session.close();
      await cache.close();
      await logDb.close();
    });
  });

  String shape(CachedCall call) =>
      '${call.message.topic} ${call.message.seq} '
      '${[for (final update in call.updates) update.seq]}';

  Future<List<String>> stored({String? topic}) async => [
    for (final call in await session.storedCalls(topic: topic)) shape(call),
  ];

  /// Lets queued work (the outbox, the catch-up) finish.
  Future<void> idle() => pumpEventQueue(times: 200);

  group('what reaches the log', () {
    test('a live call and its updates', () async {
      remote
        ..emitMessage(callMessage(bob, 9))
        ..emitMessage(callUpdate(bob, 10, 9, CallState.accepted))
        ..emitMessage(callUpdate(bob, 11, 9, CallState.finished));

      expect(await stored(), ['$bob 9 [10, 11]']);
    });

    test('a page of history', () async {
      await session.history(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('an older page, as scrolling asks for it', () async {
      await session.history(bob, limit: 1);
      expect(await stored(), ['$bob 4 []']);

      await session.olderPage(bob, before: 4, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('a catch-up', () async {
      await session.catchUp(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('the latest catch-up, for a chat not open', () async {
      remote.chats
        ..clear()
        ..add(chat(bob, lastSeq: 4, lastMessageAt: at(4)));

      await session.chatList();
      await idle();

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('a call found while reconciling a lost message', () async {
      remote
        ..chats.clear()
        ..chats.add(chat(bob, lastSeq: 4, lastMessageAt: at(4)))
        // No echo either: only a look at the server can tell it arrived.
        ..echo = false
        ..loseNextAck = const ConnectionClosedException('gone');

      await session.send(bob, const PlainText('hi'));
      await idle();
      remote.histories[bob]!.add(callMessage(bob, 6));
      remote
        ..emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero))
        ..emitStatus(const Connected());
      await idle();

      expect(await stored(topic: bob), contains('$bob 6 []'));
    });

    test('no plain message, nothing of a group', () async {
      remote
        ..emitMessage(message(bob, 9))
        ..emitMessage(callMessage(friends, 9));
      await session.history(friends, limit: 10);

      expect(await stored(), isEmpty);
    });

    test('and it says so, naming the chat', () async {
      final changes = <String>[];
      final listening = session.storedChanges.listen(changes.add);
      addTearDown(listening.cancel);

      remote.emitMessage(callMessage(carol, 9));
      await session.storedCalls();
      await idle();

      expect(changes, contains(carol));
    });

    test('reads wait for what arrived before', () async {
      remote.emitMessage(callMessage(bob, 9));

      expect(await stored(), ['$bob 9 []']);
    });
  });

  group('matches what the cache held before the log', () {
    Future<void> expectOracle() async {
      expect(
        [for (final call in await session.storedCalls()) shape(call)],
        [for (final call in await cachedCallsOracle(cache)) shape(call)],
      );
      for (final topic in [bob, carol]) {
        expect(await stored(topic: topic), [
          for (final call in await cachedCallsOracle(cache, topic: topic))
            shape(call),
        ]);
      }
    }

    test('after pages and live calls', () async {
      await session.history(bob, limit: 10);
      await session.history(carol, limit: 10);
      remote
        ..emitMessage(callUpdate(bob, 5, 4, CallState.declined, from: alice))
        ..emitMessage(callMessage(carol, 3));

      await session.storedCalls();
      await expectOracle();
      expect(await stored(), hasLength(4));
    });

    test('after an update whose call is not here', () async {
      remote.emitMessage(callUpdate(bob, 9, 8, CallState.missed));

      await session.storedCalls();
      await expectOracle();
      expect(await stored(), isEmpty);
    });

    test('field by field', () async {
      await session.history(bob, limit: 10);

      final logged = await session.storedCalls();
      final cached = await cachedCallsOracle(cache);
      expect(logged, cached);
    });

    test('after deletions', () async {
      await session.history(bob, limit: 10);
      await session.delete(bob, [const SeqRange.single(2)], forEveryone: false);
      await idle();

      await expectOracle();
      expect(await stored(), ['$bob 1 []', '$bob 4 []']);
    });
  });

  group('pruning', () {
    test('drops messages, not calls', () async {
      await session.chatList();
      await session.history(bob, limit: 10);
      await session.close();
      relinked();
      open(limits: const TinodeCacheLimits(messagesPerChat: 1));

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
      expect(await cachedCallsOracle(cache), hasLength(1));
    });
  });

  group('the first start with the log', () {
    /// Fills the cache as a version without the log left it. The chats
    /// are listed, or the pruning would drop their messages.
    Future<void> fillCache() async {
      await store.replaceChats(quiet([bob, friends]));
      await store.putMessages(bob, covering: const SeqRange(1, 6), [
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.finished),
        message(bob, 3),
        callMessage(bob, 4),
        callMessage(bob, 5),
      ]);
      await store.putMessages(friends, [callMessage(friends, 6)]);
    }

    /// A session on the same data: the app started again.
    Future<void> restart({TinodeCacheLimits? limits}) async {
      await session.close();
      relinked();
      open(limits: limits);
    }

    test('starts from the calls in the cache', () async {
      await fillCache();

      await restart();

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []', '$bob 5 []']);
    });

    test('gets them before pruning can drop them', () async {
      await fillCache();

      await restart(limits: const TinodeCacheLimits(messagesPerChat: 1));

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []', '$bob 5 []']);
      expect(
        await store.messagesIn(bob, from: 1, before: 99, limit: 99),
        hasLength(1),
      );
    });

    test('happens once: a log with calls is left alone', () async {
      await log.put([callMessage(carol, 7)]);
      await fillCache();

      await restart();

      expect(await stored(), ['$carol 7 []']);
    });

    test('does not bring back a call deleted since', () async {
      await fillCache();
      await restart();
      await session.storedCalls();
      await log.deleteRanges(bob, [const SeqRange.single(5)]);

      await restart();

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('that fails leaves nothing and tries again next start', () async {
      await fillCache();
      logFault.failingAfterBatch = true;
      await restart();
      await session.storedPage(bob, limit: 1);
      logFault.failingAfterBatch = false;
      expect(await log.isEmpty, isTrue);

      await restart();

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []', '$bob 5 []']);
    });

    test('that fails does not stop the chat', () async {
      await fillCache();
      logFault.failing = true;
      await restart();

      expect((await session.storedPage(bob, limit: 1)).messages, isNotEmpty);
    });

    test('keeps a call that arrives while it runs', () async {
      await fillCache();
      await session.close();
      relinked();
      logFault.holdBatches = Completer();
      open();
      remote.emitMessage(callMessage(bob, 9));
      await logFault.batchHeld.future;

      logFault.holdBatches!.complete();
      logFault.holdBatches = null;

      expect(await stored(), [
        '$bob 1 [2]',
        '$bob 4 []',
        '$bob 5 []',
        '$bob 9 []',
      ]);
    });
  });

  group('deletions', () {
    setUp(() => session.history(bob, limit: 10));

    test('by the user, right away', () async {
      await session.delete(bob, [const SeqRange.single(4)], forEveryone: false);

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('by the user, offline', () async {
      remote.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));

      await session.delete(bob, [const SeqRange.single(4)], forEveryone: true);

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('of nothing leaves everything', () async {
      await session.delete(bob, const [], forEveryone: true);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('by someone else, as they happen', () async {
      remote.emitPresence(
        const PresMessage(
          topic: bob,
          event: PresenceEvent.deleted,
          lastDeleteId: 1,
          deletedRanges: [SeqRange(1, 3)],
        ),
      );

      expect(await stored(), ['$bob 4 []']);
    });

    test('found in the delete log at a catch-up', () async {
      remote.recordDeletion(bob, [const SeqRange.single(4)]);

      await session.catchUp(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('refused by the server: the call comes back with its page', () async {
      remote.failDelete = const ServerException(403, 'denied');
      await session.delete(bob, [const SeqRange.single(4)], forEveryone: true);
      await idle();
      expect(await stored(), ['$bob 1 [2]']);

      await session.olderPage(bob, before: 5, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });
  });

  group('a chat that goes', () {
    setUp(() async {
      await session.history(bob, limit: 10);
      await session.history(carol, limit: 10);
    });

    final ways = <String, Future<void> Function()>{
      'deleted': () => session.deleteChat(bob),
      'left': () => session.leaveChat(bob),
      'gone from the server': () async => remote.emitPresence(
        const PresMessage(topic: 'me', event: PresenceEvent.gone, source: bob),
      ),
    };

    for (final MapEntry(key: way, value: go) in ways.entries) {
      test('$way takes its calls, no others, and says so', () async {
        final changes = <String>[];
        final listening = session.storedChanges.listen(changes.add);
        addTearDown(listening.cancel);

        await go();
        await idle();

        expect(await stored(), ['$carol 2 []']);
        expect(changes, contains(bob));
      });
    }

    test('whose page was on its way stays gone', () async {
      remote.holdHistory = Completer();
      final fetching = session.history(bob, limit: 10);
      await session.deleteChat(bob);

      remote.holdHistory!.complete();
      remote.holdHistory = null;
      await fetching;

      expect(await stored(), ['$carol 2 []']);
    });

    test('and comes back logs again', () async {
      await session.deleteChat(bob);

      remote.emitMessage(callMessage(bob, 9));
      await session.history(bob, limit: 10);

      expect(await stored(), [
        '$bob 1 [2]',
        '$bob 4 []',
        '$bob 9 []',
        '$carol 2 []',
      ]);
    });

    test('not the one asked for leaves a page in flight alone', () async {
      remote.histories[carol]!.add(callMessage(carol, 3));
      remote.holdHistory = Completer();
      final fetching = session.history(carol, limit: 10);
      await session.deleteChat(bob);

      remote.holdHistory!.complete();
      remote.holdHistory = null;
      await fetching;

      expect(await stored(), ['$carol 2 []', '$carol 3 []']);
    });
  });

  group('a full chat list', () {
    setUp(() async {
      await log.put([callMessage(bob, 1), callMessage(carol, 2)]);
    });

    test('drops the calls of chats no longer in it, and says so', () async {
      remote.chats.removeWhere((c) => c.topic == bob);
      final changes = <String>[];
      final listening = session.storedChanges.listen(changes.add);
      addTearDown(listening.cancel);

      await session.chatList();

      expect(await stored(), ['$carol 2 []']);
      expect(changes, contains(bob));
    });

    test('keeps the calls of the chats in it', () async {
      await session.chatList();

      expect(await stored(), ['$bob 1 []', '$carol 2 []']);
    });

    test('that is empty proves nothing', () async {
      remote.chats.clear();

      await session.chatList();

      expect(await stored(), ['$bob 1 []', '$carol 2 []']);
    });

    test('that fails drops nothing', () async {
      remote
        ..chats.clear()
        ..failChatList = const ServerException(500, 'oops');

      await expectLater(session.chatList(), throwsA(anything));

      expect(await stored(), ['$bob 1 []', '$carol 2 []']);
    });

    test('never touches a call that landed while it was fetched', () async {
      remote.chats.removeWhere((c) => c.topic == carol);
      await log.deleteChat(carol);
      remote.holdChatList = Completer();
      final syncing = session.chatList();
      await idle();

      remote.emitMessage(callMessage(carol, 9));
      await session.storedCalls();
      remote.holdChatList!.complete();
      remote.holdChatList = null;
      await syncing;

      expect(await stored(), ['$bob 1 []', '$carol 9 []']);
    });

    test('since a change only says what changed: nothing goes', () async {
      await session.chatList();
      expect(remote.lastChatListSince, isNull);
      await store.advanceChat(bob, lastMessageAt: at(1));

      remote.chats.removeWhere((c) => c.topic == carol);
      await session.chatList();

      expect(remote.lastChatListSince, isNotNull);
      expect(await stored(), ['$bob 1 []', '$carol 2 []']);
    });
  });

  group('a catch-up with nothing cached', () {
    test('applies the deletions missed, for a chat with calls', () async {
      await log.put([
        callMessage(bob, 1),
        callUpdate(bob, 2, 1, CallState.finished),
        callMessage(bob, 4),
      ]);
      remote.recordDeletion(bob, [const SeqRange.single(4)]);

      await session.catchUp(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]']);
      expect(remote.calls, contains('deleteLog $bob since 1'));
      expect(await store.syncedDeleteId(bob), 1);
    });

    test('deletes a call that is not in the page either', () async {
      remote.histories[bob] = [
        for (var seq = 50; seq < 60; seq++) message(bob, seq),
      ];
      await log.put([callMessage(bob, 4)]);
      remote.recordDeletion(bob, [const SeqRange.single(4)]);

      await session.catchUp(bob, limit: 3);

      expect(await stored(), isEmpty);
    });

    test('asks nothing more for a chat without calls', () async {
      await store.replaceChats([
        const Subscription(topic: bob, lastDeleteId: 7),
      ]);
      remote.recordDeletion(bob, [const SeqRange.single(3)]);

      await session.catchUp(bob, limit: 10);

      expect(remote.calls.where((c) => c.startsWith('deleteLog')), isEmpty);
      expect(await store.syncedDeleteId(bob), 7);
    });

    test('does not count the calls of its own page', () async {
      await session.catchUp(bob, limit: 10);

      expect(remote.calls.where((c) => c.startsWith('deleteLog')), isEmpty);
    });

    test('whose read fails tries again at the next catch-up', () async {
      await log.put([callMessage(bob, 1), callMessage(bob, 4)]);
      remote
        ..recordDeletion(bob, [const SeqRange.single(4)])
        ..failDeleteLog = const ServerException(500, 'oops');

      await session.catchUp(bob, limit: 10);
      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);

      await session.catchUp(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('also finds a call again when the server still has it', () async {
      await log.put([callMessage(bob, 1)]);

      await session.catchUp(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });
  });

  group('races', () {
    test('a deletion right behind a page wins', () async {
      cacheFault.holdBatches = Completer();
      final fetching = session.history(bob, limit: 10);
      await cacheFault.batchHeld.future;

      final deleting = session.delete(bob, [
        const SeqRange.single(4),
      ], forEveryone: false);
      cacheFault.holdBatches!.complete();
      cacheFault.holdBatches = null;
      await fetching;
      await deleting;

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('closing with writes queued loses none and throws none', () async {
      remote
        ..emitMessage(callMessage(bob, 9))
        ..emitMessage(callMessage(carol, 9));

      await session.close();

      expect(
        [for (final call in await log.calls()) shape(call)],
        ['$bob 9 []', '$carol 9 []'],
      );
    });

    test('closing during a fetch throws nothing at the app', () async {
      remote.holdHistory = Completer();
      final fetching = session
          .history(bob, limit: 10)
          .then<Object?>((page) => page, onError: (Object e) => e);

      await session.close();
      remote.holdHistory!.complete();
      remote.holdHistory = null;

      expect(await fetching, isA<ConnectionClosedException>());
    });

    test('the same call live and in a page is one call', () async {
      remote
        ..histories[bob]!.add(callMessage(bob, 5))
        ..emitMessage(callMessage(bob, 5));
      await session.history(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []', '$bob 5 []']);
    });
  });

  group('when the log fails, the chat goes on', () {
    setUp(() => logFault.failing = true);

    test('live messages are stored and announced', () async {
      final changes = <String>[];
      final listening = session.storedChanges.listen(changes.add);
      addTearDown(listening.cancel);

      remote
        ..emitMessage(callMessage(bob, 9))
        ..emitMessage(message(bob, 10));
      final latest = await session.storedLatestMessages(topic: bob);

      expect(latest[bob]?.message?.seq, 10);
      expect(changes, contains(bob));
    });

    test('pages are stored and returned', () async {
      final page = await session.history(bob, limit: 10);

      expect(page, hasLength(4));
      expect((await session.storedPage(bob, limit: 10)).messages, hasLength(4));
    });

    test('messages are sent', () async {
      await session.send(bob, const PlainText('hi'));
      await idle();

      expect(remote.calls, contains('publish $bob hi'));
    });

    test('the chat list syncs', () async {
      expect(await session.chatList(), hasLength(3));
    });

    test('a catch-up with nothing cached works as before', () async {
      await session.catchUp(bob, limit: 10);

      expect(
        await store.messagesIn(bob, from: 1, before: 9, limit: 9),
        hasLength(4),
      );
    });

    test('deleting messages reaches the cache and the server', () async {
      await session.history(bob, limit: 10);

      await session.delete(bob, [const SeqRange.single(3)], forEveryone: false);
      await idle();

      expect(
        await store.messagesIn(bob, from: 1, before: 9, limit: 9),
        hasLength(3),
      );
      expect(remote.calls, contains('delete $bob 3-4'));
    });

    test('deletions from elsewhere reach the cache', () async {
      await session.history(bob, limit: 10);

      remote.emitPresence(
        const PresMessage(
          topic: bob,
          event: PresenceEvent.deleted,
          lastDeleteId: 1,
          deletedRanges: [SeqRange.single(3)],
        ),
      );
      await session.storedPage(bob, limit: 1);

      expect(
        await store.messagesIn(bob, from: 1, before: 9, limit: 9),
        hasLength(3),
      );
    });

    test('a chat can be deleted', () async {
      await session.history(bob, limit: 10);

      await session.deleteChat(bob);

      expect(
        await store.messagesIn(bob, from: 1, before: 9, limit: 9),
        isEmpty,
      );
    });

    test('a full chat list that drops a chat works', () async {
      logFault.failing = false;
      await log.put([callMessage(bob, 1)]);
      remote.chats.removeWhere((c) => c.topic == bob);
      logFault
        ..failing = false
        ..failingWrites = true;

      expect(await session.chatList(), hasLength(2));
    });

    test('closing works, even if the log will not close', () async {
      logFault.failingClose = true;
      final owned = CachedTinodeSession(
        relinked(),
        store,
        userId: alice,
        calls: CallLog(logDb),
      );

      await expectLater(owned.close(), completes);
      expect(remote.isClosed, isTrue);
    });
  });

  group('when the cache fails, the log still gets the call', () {
    setUp(() => cacheFault.failing = true);

    test('live', () async {
      remote.emitMessage(callMessage(bob, 9));

      expect(await stored(), ['$bob 9 []']);
    });

    test('and says so, for the calls history', () async {
      final changes = <String>[];
      final listening = session.storedChanges.listen(changes.add);
      addTearDown(listening.cancel);

      remote.emitMessage(callMessage(bob, 9));
      await session.storedCalls();
      await idle();

      expect(changes, contains(bob));
    });

    test('from a page', () async {
      await session.history(bob, limit: 10);

      expect(await stored(), ['$bob 1 [2]', '$bob 4 []']);
    });

    test('a deletion by the user still reaches it', () async {
      await session.history(bob, limit: 10);

      await session.delete(bob, [const SeqRange.single(4)], forEveryone: false);

      expect(await stored(), ['$bob 1 [2]']);
    });

    test('a deletion from elsewhere still reaches it', () async {
      await session.history(bob, limit: 10);

      remote.emitPresence(
        const PresMessage(
          topic: bob,
          event: PresenceEvent.deleted,
          lastDeleteId: 1,
          deletedRanges: [SeqRange.single(4)],
        ),
      );

      expect(await stored(), ['$bob 1 [2]']);
    });
  });

  test('the echo of a message beating its ack still completes it', () async {
    remote.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));
    final sent = await session.send(bob, const PlainText('hi'));

    remote.emitMessage(
      DataMessage(
        topic: bob,
        seq: 5,
        from: alice,
        time: at(5),
        head: MessageHead.fromJson({clientIdHeadKey: sent.clientId}),
        content: const PlainText('hi'),
      ),
    );
    await session.storedCalls();

    expect(await session.storedOutgoing(bob), isEmpty);
  });

  test('closing closes a log it owns', () async {
    final owned = CallLogDatabase(NativeDatabase.memory());
    await owned.customStatement('SELECT 1');
    final closing = CachedTinodeSession(
      relinked(),
      store,
      userId: alice,
      calls: CallLog(owned),
    );

    await closing.close();

    expect(() => owned.customStatement('SELECT 1'), throwsA(anything));
  });

  test('a session with no log given keeps calls in memory', () async {
    final other = CachedTinodeSession(
      FakeTinodeSession(),
      ChatStore(ChatDatabase(NativeDatabase.memory())),
      userId: alice,
    );
    addTearDown(other.close);

    await other.history(bob, limit: 1);

    expect(await other.storedCalls(), isEmpty);
  });
}
