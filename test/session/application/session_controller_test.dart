import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() => session = FakeTinodeSession());

  Future<SessionState> connect(ProviderContainer container) {
    container.listen(sessionControllerProvider, (_, _) {});
    return container.read(sessionControllerProvider.future);
  }

  test('without credentials it connects and awaits login', () async {
    final container = createTestContainer(connector: connectTo(session));

    final state = await connect(container);

    expect(state, isA<SessionAwaitingLogin>());
    expect(
      SessionPhase.of(container.read(sessionControllerProvider)),
      SessionPhase.awaitingLogin,
    );
    expect(session.calls, isNot(contains(startsWith('login'))));
  });

  test('with a token it logs in right away', () async {
    final container = createTestContainer(
      connector: connectTo(session),
      credentials: TinodeCredentials.token(session.token),
    );

    final state = await connect(container);

    expect(state, isA<SessionLoggedIn>());
    expect(container.read(currentUserIdProvider), session.userId);
    expect(container.read(activeSessionProvider)?.userId, session.userId);
    expect(container.read(currentLoginProvider)?.token, session.token);
  });

  test('a rejected token falls back to the login screen', () async {
    final container = createTestContainer(
      connector: connectTo(session),
      credentials: const TinodeCredentials.token('expired'),
    );

    final state = await connect(container);

    expect(
      state,
      isA<SessionAwaitingLogin>().having(
        (s) => s.lastFailure,
        'lastFailure',
        ChatFailure.badCredentials,
      ),
    );
    expect(container.read(credentialsControllerProvider), isNull);
  });

  test('a password login remembers the token for reconnects', () async {
    final container = createTestContainer(connector: connectTo(session));
    await connect(container);

    await container
        .read(sessionControllerProvider.notifier)
        .login(const TinodeCredentials.password('alice', 'alice123'));

    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionLoggedIn>(),
    );
    expect(
      container.read(credentialsControllerProvider),
      TinodeCredentials.token(session.token),
    );
  });

  test('a wrong password throws and keeps awaiting login', () async {
    final container = createTestContainer(connector: connectTo(session));
    await connect(container);

    await expectLater(
      container
          .read(sessionControllerProvider.notifier)
          .login(const TinodeCredentials.password('alice', 'nope')),
      throwsA(isA<Object>()),
    );
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionAwaitingLogin>(),
    );
  });

  test('an unreachable server fails, and reconnect recovers', () async {
    var reachable = false;
    final container = createTestContainer(
      connector: (_) async => reachable
          ? session
          : throw const ServerUnreachableException('refused'),
    )..listen(sessionControllerProvider, (_, _) {});

    await expectLater(
      container.read(sessionControllerProvider.future),
      throwsA(isA<ServerUnreachableException>()),
    );
    expect(container.read(sessionFailureProvider), ChatFailure.unreachable);

    reachable = true;
    container.read(sessionControllerProvider.notifier).reconnect();
    expect(
      SessionPhase.of(container.read(sessionControllerProvider)),
      SessionPhase.connecting,
    );
    expect(
      await container.read(sessionControllerProvider.future),
      isA<SessionAwaitingLogin>(),
    );
  });

  test('a dropped connection becomes connectionLost', () async {
    final container = createTestContainer(
      connector: connectTo(session),
      credentials: TinodeCredentials.token(session.token),
    );
    await connect(container);

    session.dropConnection();
    await settle();

    expect(
      SessionPhase.of(container.read(sessionControllerProvider)),
      SessionPhase.failed,
    );
    expect(container.read(sessionFailureProvider), ChatFailure.connectionLost);
  });

  group('after the client reconnects by itself', () {
    late ProviderContainer container;

    setUp(() async {
      container = createTestContainer(
        connector: connectTo(session),
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);
    });

    test('it stays logged in while reconnecting', () async {
      session.emitStatus(
        const Reconnecting(attempt: 1, retryIn: Duration.zero),
      );
      await settle();

      expect(
        SessionPhase.of(container.read(sessionControllerProvider)),
        SessionPhase.loggedIn,
      );
    });

    test('its login replaces the old one and its token is kept', () async {
      const renewed = LoginResult(userId: 'usrAlice', token: 'renewed');
      session.emitStatus(const Connected(login: renewed));
      await settle();

      final state = container.read(sessionControllerProvider).value;
      expect(
        state,
        isA<SessionLoggedIn>().having((s) => s.login, 'login', renewed),
      );
      expect(
        container.read(credentialsControllerProvider),
        const TinodeCredentials.token('renewed'),
      );
    });

    test('a refused token goes back to the login screen', () async {
      session.emitStatus(
        const Disconnected(cause: ServerException(401, 'expired')),
      );
      await settle();
      await container.read(sessionControllerProvider.future);

      expect(container.read(credentialsControllerProvider), isNull);
      expect(
        SessionPhase.of(container.read(sessionControllerProvider)),
        SessionPhase.awaitingLogin,
      );
    });
  });

  test('reconnect closes the old session and restores the user', () async {
    final second = FakeTinodeSession();
    final sessions = [session, second];
    final container = createTestContainer(
      connector: (_) async => sessions.removeAt(0),
    );
    await connect(container);
    await container
        .read(sessionControllerProvider.notifier)
        .login(const TinodeCredentials.password('alice', 'alice123'));

    container.read(sessionControllerProvider.notifier).reconnect();
    final state = await container.read(sessionControllerProvider.future);

    expect(session.isClosed, isTrue);
    expect(state, isA<SessionLoggedIn>());
    // The user is remembered now, so the new session opens their cache at
    // once and logs in with the token in the background.
    expect(second.calls, contains('restore'));
    await settle();
    expect(container.read(currentLoginProvider)?.token, second.token);
  });

  test('disposing the container closes the session', () async {
    final container = createTestContainer(connector: connectTo(session));
    await connect(container);

    container.dispose();

    expect(session.isClosed, isTrue);
    expect(session.calls, contains('close'));
  });

  group('a remembered user', () {
    late MemoryChatStoreOpener stores;

    setUp(() async {
      stores = MemoryChatStoreOpener();
      await stores.rememberUser(testConfig.server, session.userId);
    });

    ProviderContainer restoring({String? token}) => createTestContainer(
      connector: connectTo(session),
      restorer: restoreTo(session),
      storeOpener: stores,
      credentials: TinodeCredentials.token(token ?? session.token),
    );

    test('opens their cache before the server answers', () async {
      session.reachable = false;
      final container = restoring();

      final state = await connect(container);

      expect(
        state,
        isA<SessionLoggedIn>()
            .having((s) => s.userId, 'userId', session.userId)
            .having((s) => s.login, 'login', isNull),
      );
      expect(session.calls, ['restore']);
      expect(container.read(currentUserIdProvider), session.userId);

      session.comeOnline();
      await settle();
      expect(container.read(currentLoginProvider)?.token, session.token);
    });

    test('a refused token goes back to the login screen', () async {
      final container = restoring(token: 'expired');
      await connect(container);

      await settle();
      final state = await container.read(sessionControllerProvider.future);

      expect(state, isA<SessionAwaitingLogin>());
      expect(container.read(credentialsControllerProvider), isNull);
      // The cache stays for when the same user logs in again.
      expect(await stores.lastUser(testConfig.server), session.userId);
    });

    test('a token of another user opens their cache instead', () async {
      await stores.rememberUser(testConfig.server, 'usrSomeoneElse');
      final container = restoring();
      expect(
        (await connect(container) as SessionLoggedIn).userId,
        'usrSomeoneElse',
      );

      await settle();
      await settle();
      final state = await container.read(sessionControllerProvider.future);

      expect((state as SessionLoggedIn).userId, session.userId);
      expect(await stores.lastUser(testConfig.server), session.userId);
    });
  });

  group('logout', () {
    test('wipes the cache and asks for a login', () async {
      final stores = MemoryChatStoreOpener();
      final container = createTestContainer(
        connector: connectTo(session),
        storeOpener: stores,
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);
      expect(await stores.lastUser(testConfig.server), session.userId);

      await container.read(sessionControllerProvider.notifier).logout();
      final state = await container.read(sessionControllerProvider.future);

      expect(state, isA<SessionAwaitingLogin>());
      expect(container.read(credentialsControllerProvider), isNull);
      expect(await stores.lastUser(testConfig.server), isNull);
      expect(session.calls, contains('close'));
    });

    test('removes the push token before closing', () async {
      final container = createTestContainer(
        connector: connectTo(session),
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);

      await container.read(sessionControllerProvider.notifier).logout();

      expect(
        session.calls.indexOf('deviceToken null'),
        allOf(isNonNegative, lessThan(session.calls.indexOf('close'))),
      );
    });

    test('a refused push token removal still logs out', () async {
      final container = createTestContainer(
        connector: connectTo(session),
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);
      session.failDeviceToken = const ConnectionClosedException('gone');

      await container.read(sessionControllerProvider.notifier).logout();

      expect(
        await container.read(sessionControllerProvider.future),
        isA<SessionAwaitingLogin>(),
      );
    });

    test('a deleted user ends like a logout', () async {
      final stores = MemoryChatStoreOpener();
      final container = createTestContainer(
        connector: connectTo(session),
        storeOpener: stores,
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);

      session.emitStatus(
        const Disconnected(cause: ServerException(404, 'user not found')),
      );
      await settle();

      expect(container.read(credentialsControllerProvider), isNull);
      expect(await stores.lastUser(testConfig.server), isNull);
    });
  });

  group('sign up', () {
    test('creates the account and logs in as the new user', () async {
      final container = createTestContainer(connector: connectTo(session));
      await connect(container);

      await container
          .read(sessionControllerProvider.notifier)
          .signUp(login: 'carol', password: 'carol123', name: 'Carol');

      expect(
        container.read(sessionControllerProvider).value,
        isA<SessionLoggedIn>().having(
          (s) => s.login?.token,
          'token',
          session.token,
        ),
      );
      expect(session.calls, contains('createAccount carol Carol'));
      expect(
        container.read(credentialsControllerProvider),
        TinodeCredentials.token(session.token),
      );
    });

    test('a taken login throws and keeps awaiting login', () async {
      final container = createTestContainer(connector: connectTo(session));
      await connect(container);

      await expectLater(
        container
            .read(sessionControllerProvider.notifier)
            .signUp(login: 'alice', password: 'pw', name: 'Alice'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 409)),
      );
      expect(
        container.read(sessionControllerProvider).value,
        isA<SessionAwaitingLogin>(),
      );
    });
  });

  group('deleteAccount', () {
    test('deletes the user and their cache, then asks for a login', () async {
      final stores = MemoryChatStoreOpener();
      final container = createTestContainer(
        connector: connectTo(session),
        storeOpener: stores,
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);
      final phases = <SessionPhase>[];
      container.listen(
        sessionControllerProvider.select(SessionPhase.of),
        (_, phase) => phases.add(phase),
      );

      await container.read(sessionControllerProvider.notifier).deleteAccount();
      final state = await container.read(sessionControllerProvider.future);

      expect(session.accountDeleted, isTrue);
      expect(state, isA<SessionAwaitingLogin>());
      expect(container.read(credentialsControllerProvider), isNull);
      expect(await stores.lastUser(testConfig.server), isNull);
      // Its expected disconnect is no lost connection.
      expect(phases, isNot(contains(SessionPhase.failed)));
      // The server drops the user's push tokens itself.
      expect(session.calls, isNot(contains('deviceToken null')));
    });

    test('a refusal throws and keeps the session', () async {
      final container = createTestContainer(
        connector: connectTo(session),
        credentials: TinodeCredentials.token(session.token),
      );
      await connect(container);
      session.failDeleteAccount = const ServerException(403, 'forbidden');

      await expectLater(
        container.read(sessionControllerProvider.notifier).deleteAccount(),
        throwsA(isA<ServerException>()),
      );
      expect(
        container.read(sessionControllerProvider).value,
        isA<SessionLoggedIn>(),
      );
      session.dropConnection();
      await settle();
      expect(
        SessionPhase.of(container.read(sessionControllerProvider)),
        SessionPhase.failed,
      );
    });
  });
}
