import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_history.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/faulty_store_opener.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

const dave = 'usrDave';
const aliceLogin = TinodeCredentials.password('alice', 'alice123');
const daveLogin = TinodeCredentials.password('dave', 'dave123');

/// How the call log lives through the ways a session ends, and what the
/// Calls tab does when the log fails.
void main() {
  final server = testConfig.server;
  late List<Subscription> chats;
  late Map<String, List<DataMessage>> histories;
  late ChatStoreOpener stores;

  setUp(() {
    stores = MemoryChatStoreOpener();
    chats = [
      chat(bob, name: 'Bob', lastSeq: 2, lastMessageAt: at(2)),
      chat(carol, name: 'Carol', lastSeq: 4, lastMessageAt: at(4)),
    ];
    histories = {
      bob: [callMessage(bob, 1), callUpdate(bob, 2, 1, CallState.missed)],
      carol: [
        callMessage(carol, 3, from: alice),
        callUpdate(carol, 4, 3, CallState.finished, from: alice),
      ],
    };
  });

  const both = [(topic: carol, seq: 3), (topic: bob, seq: 1)];

  /// A link to the server, one per connection.
  FakeTinodeSession link() =>
      FakeTinodeSession(chats: chats, histories: histories);

  /// Dave's link: another user, with a call of his own.
  FakeTinodeSession daveLink() => FakeTinodeSession(
    userId: dave,
    passwords: {'dave': 'dave123'},
    chats: [chat(carol, lastSeq: 9, lastMessageAt: at(9))],
    histories: {
      carol: [callMessage(carol, 9)],
    },
  );

  CallHistory calls(ProviderContainer container) =>
      container.read(callHistoryControllerProvider);

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 400 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue, reason: 'timed out');
  }

  /// A container connecting through [links], in order.
  Future<ProviderContainer> start(
    List<FakeTinodeSession> links, {
    TinodeCredentials credentials = aliceLogin,
  }) async {
    final container =
        createTestContainer(
            connector: (_) async => links.removeAt(0),
            storeOpener: stores,
            credentials: credentials,
          )
          ..listen(sessionControllerProvider, (_, _) {})
          ..listen(chatListControllerProvider, (_, _) {})
          ..listen(callHistoryControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    return container;
  }

  Future<List<int>> logged([String user = alice]) async => [
    for (final call in await (await stores.openCallLog(server, user)).calls())
      call.message.seq,
  ];

  Future<List<String?>> cachedChats([String user = alice]) async => [
    for (final chat in await (await stores.open(server, user)).chats())
      chat.topic,
  ];

  /// Logs in on the link waiting for it and waits for the chat list.
  Future<void> logIn(
    ProviderContainer container, [
    TinodeCredentials credentials = aliceLogin,
  ]) async {
    await container.read(sessionControllerProvider.future);
    await container.read(sessionControllerProvider.notifier).login(credentials);
  }

  SessionController controller(ProviderContainer container) =>
      container.read(sessionControllerProvider.notifier);

  /// Holds the server's history, so whatever shows came from the device.
  FakeTinodeSession silent(FakeTinodeSession link) {
    final hold = Completer<void>();
    addTearDown(hold.complete);
    return link..holdHistory = hold;
  }

  group('after a logout', () {
    test('the cache is gone and the log is not', () async {
      final first = link();
      final container = await start([first, link()]);
      await until(() => calls(container).ids.length == 2);

      await controller(container).logout();
      await container.read(sessionControllerProvider.future);

      expect(await cachedChats(), isEmpty);
      expect(await logged(), [1, 3]);
      expect(calls(container).ids, isEmpty);
      expect(calls(container).loaded, isFalse);
    });

    test('the next login shows the calls with no fetch', () async {
      final container = await start([link(), silent(link())]);
      await until(() => calls(container).ids.length == 2);

      await controller(container).logout();
      await logIn(container);

      await until(() => calls(container).ids.length == 2);
      expect(calls(container).ids, both);
      expect(calls(container)[both.first]!.call.state, CallState.finished);
      expect(calls(container)[both.last]!.missed, isTrue);
    });

    test('calls the server no longer offers stay', () async {
      final container = await start([link(), link()]);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout();
      histories
        ..[bob] = [for (var seq = 3; seq <= 40; seq++) message(bob, seq)]
        ..[carol] = [for (var seq = 5; seq <= 40; seq++) message(carol, seq)];

      await logIn(container);

      await until(() => calls(container).ids.length == 2);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls(container).ids, both);
    });

    test('offline it works the same', () async {
      final first = link();
      final container = await start([first, link()]);
      await until(() => calls(container).ids.length == 2);
      first.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));

      await controller(container).logout();
      await container.read(sessionControllerProvider.future);

      expect(await cachedChats(), isEmpty);
      expect(await logged(), [1, 3]);
    });

    test('twice over, nothing is lost or doubled', () async {
      final container = await start([link(), link(), link()]);
      await until(() => calls(container).ids.length == 2);

      await controller(container).logout();
      await logIn(container);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout();
      await logIn(container);

      await until(() => calls(container).ids.length == 2);
      expect(calls(container).ids, both);
      expect(await logged(), [1, 3]);
    });

    test('a call deleted while away is gone on the next login', () async {
      final second = link();
      final container = await start([link(), second]);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout();
      second.recordDeletion(bob, [const SeqRange(1, 3)]);

      await logIn(container);

      await until(() => calls(container).ids.length == 1);
      expect(calls(container).ids, [(topic: carol, seq: 3)]);
    });

    test('a chat gone while away takes its calls', () async {
      final container = await start([link(), link()]);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout();
      chats.removeWhere((c) => c.topic == bob);

      await logIn(container);

      await until(() => calls(container).ids.length == 1);
      expect(calls(container).ids, [(topic: carol, seq: 3)]);
    });
  });

  group('the account ending takes the log too', () {
    test('deleted by the user', () async {
      final container = await start([link(), link()]);
      await until(() => calls(container).ids.length == 2);

      await controller(container).deleteAccount();
      await container.read(sessionControllerProvider.future);

      expect(await cachedChats(), isEmpty);
      expect(await logged(), isEmpty);
    });

    test('gone from the server', () async {
      final first = link();
      final container = await start([first, link()]);
      await until(() => calls(container).ids.length == 2);

      first.emitStatus(
        const Disconnected(cause: ServerException(404, 'user not found')),
      );
      await until(() => container.read(sessionControllerProvider).hasValue);
      await pumpEventQueue();

      expect(await cachedChats(), isEmpty);
      expect(await logged(), isEmpty);
    });

    test('and a failed deletion keeps everything', () async {
      final first = link();
      final container = await start([first]);
      await until(() => calls(container).ids.length == 2);
      first.failDeleteAccount = const ServerException(403, 'forbidden');

      await expectLater(
        controller(container).deleteAccount(),
        throwsA(isA<ServerException>()),
      );

      expect(await cachedChats(), isNotEmpty);
      expect(await logged(), [1, 3]);
      expect(calls(container).ids, both);
    });
  });

  group('nothing changes for', () {
    test('a token that expired', () async {
      final first = link();
      final container = await start([first, silent(link())]);
      await until(() => calls(container).ids.length == 2);

      first.emitStatus(
        const Disconnected(cause: ServerException(401, 'expired')),
      );
      await until(
        () =>
            container.read(sessionControllerProvider).value
                is SessionAwaitingLogin,
      );

      expect(await cachedChats(), isNotEmpty);
      expect(await logged(), [1, 3]);
      await logIn(container);
      await until(() => calls(container).ids.length == 2);
      expect(calls(container).ids, both);
    });

    test('a reconnect: the log is still good for new calls', () async {
      final second = link();
      final container = await start([link(), second]);
      await until(() => calls(container).ids.length == 2);

      controller(container).reconnect();
      await container.read(sessionControllerProvider.future);
      await until(() => calls(container).ids.length == 2);
      second.emitMessage(callMessage(bob, 8));

      await until(() => calls(container).ids.length == 3);
      expect(await logged(), [1, 8, 3]);
    });

    test('an app restart, offline', () async {
      final first = await start([link()]);
      await until(() => calls(first).ids.length == 2);
      first.dispose();
      await pumpEventQueue();

      final offline = link()..reachable = false;
      final second =
          createTestContainer(
              connector: (_) async => offline,
              storeOpener: stores,
              credentials: TinodeCredentials.token(offline.token),
            )
            ..listen(sessionControllerProvider, (_, _) {})
            ..listen(callHistoryControllerProvider, (_, _) {});
      await second.read(sessionControllerProvider.future);

      await until(() => calls(second).ids.length == 2);
      expect(calls(second).ids, both);
    });
  });

  group('two users on one device', () {
    test("never see each other's calls", () async {
      final container = await start([link(), daveLink(), link()]);
      await until(() => calls(container).ids.length == 2);

      await controller(container).logout();
      await logIn(container, daveLogin);
      await until(() => calls(container).ids.length == 1);
      expect(calls(container).ids, [(topic: carol, seq: 9)]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls(container).ids, hasLength(1));
      expect(await logged(dave), [9]);

      await controller(container).logout();
      await logIn(container);
      await until(() => calls(container).ids.length == 2);
      expect(calls(container).ids, both);
      expect(await logged(), [1, 3]);
    });

    test("a switch by the server keeps the first user's log", () async {
      final first = link();
      final daves = daveLink();
      final container = await start([first, daves]);
      await until(() => calls(container).ids.length == 2);

      first.emitStatus(
        Connected(
          login: LoginResult(userId: dave, token: daves.token),
        ),
      );
      await until(() => calls(container).ids.length == 1);

      expect(calls(container).ids, [(topic: carol, seq: 9)]);
      expect(await logged(), [1, 3]);
    });

    test("deleting one account leaves the other's log", () async {
      final container = await start([link(), daveLink(), link()]);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout();
      await logIn(container, daveLogin);
      await until(() => calls(container).ids.length == 1);

      await controller(container).deleteAccount();
      await container.read(sessionControllerProvider.future);

      expect(await logged(dave), isEmpty);
      expect(await logged(), [1, 3]);
    });
  });

  test('one user on two servers has two logs', () async {
    final other = Uri.parse('wss://other.example.com');
    final here = await stores.openCallLog(server, alice);
    final there = await stores.openCallLog(other, alice);

    await here.put([callMessage(bob, 1)]);

    expect(await there.calls(), isEmpty);
    await stores.deleteCallLog(other, alice);
    expect(await here.calls(), hasLength(1));
  });

  group('when the log fails', () {
    late FaultyStoreOpener faulty;

    setUp(() => stores = faulty = FaultyStoreOpener());

    test('to open, this session keeps its calls in memory', () async {
      faulty.failOpen = true;

      final first = link();
      final container = await start([first]);

      await until(() => calls(container).ids.length == 2);
      first.emitMessage(callMessage(bob, 8));
      await until(() => calls(container).ids.length == 3);
    });

    test('at its first read, the same: a corrupt file', () async {
      faulty.fault.failing = true;

      final first = link();
      final container = await start([first]);

      await until(() => calls(container).ids.length == 2);
      first.emitMessage(callMessage(bob, 8));
      await until(() => calls(container).ids.length == 3);
    });

    test('later on, the tab is empty rather than loading', () async {
      final first = link();
      final container = await start([first]);
      await until(() => calls(container).ids.length == 2);
      await controller(container).logout().catchError((_) {});
      faulty.fault.failing = false;

      // A read that breaks after the log opened.
      final second = await start([link()]);
      faulty.fault.failing = true;
      second.invalidate(callHistoryControllerProvider);
      await until(() => calls(second).loaded);

      expect(calls(second).ids, isEmpty);
    });

    test('while reading a change, what shows stays', () async {
      final first = link();
      final container = await start([first]);
      await until(() => calls(container).ids.length == 2);

      faulty.fault.failing = true;
      first.emitMessage(message(bob, 8));
      await pumpEventQueue();
      expect(calls(container).ids, both);

      // Back: the next change reads the chat again.
      faulty.fault.failing = false;
      first.emitMessage(callMessage(bob, 9));
      await until(() => calls(container).ids.length == 3);
    });
  });

  group('the history and the log at the same moment', () {
    test('a live call during the first read shows', () async {
      final first = link();
      final container = await start([first]);

      first.emitMessage(callMessage(bob, 8));

      await until(() => calls(container).ids.length == 3);
      expect(calls(container).ids.last, (topic: bob, seq: 1));
    });

    test('a burst across chats shows whole, in time order', () async {
      final first = link();
      final container = await start([first]);
      await until(() => calls(container).ids.length == 2);

      first
        ..emitMessage(callMessage(bob, 10))
        ..emitMessage(callMessage(carol, 11))
        ..emitMessage(callMessage(bob, 12));

      await until(() => calls(container).ids.length == 5);
      expect(calls(container).ids.take(3), [
        (topic: bob, seq: 12),
        (topic: carol, seq: 11),
        (topic: bob, seq: 10),
      ]);
    });
  });
}
