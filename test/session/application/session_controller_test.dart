import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
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
    expect(container.read(activeSessionProvider), same(session));
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

  test('reconnect closes the old session and reuses the token', () async {
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
    expect(state.session, same(second));
    expect(second.calls, contains('loginToken'));
  });

  test('disposing the container closes the session', () async {
    final container = createTestContainer(connector: connectTo(session));
    await connect(container);

    container.dispose();

    expect(session.isClosed, isTrue);
    expect(session.calls, contains('close'));
  });
}
