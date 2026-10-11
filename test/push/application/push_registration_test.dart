import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/push/application/push_registration.dart';
import 'package:tinode_flutter_chat/src/push/application/push_token_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() => session = FakeTinodeSession());

  Iterable<String> tokenCalls() =>
      session.calls.where((c) => c.startsWith('deviceToken'));

  void setToken(ProviderContainer container, String? token) =>
      container.read(pushTokenControllerProvider.notifier).set(token);

  test('a token given before login is registered once logged in', () async {
    final container = createTestContainer(connector: connectTo(session))
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(pushRegistrationProvider, (_, _) {});
    setToken(container, 'fcm1');
    await container.read(sessionControllerProvider.future);
    await settle();
    expect(tokenCalls(), isEmpty);

    await container
        .read(sessionControllerProvider.notifier)
        .login(TinodeCredentials.token(session.token));
    await settle();

    expect(session.deviceToken, 'fcm1');
  });

  test('a renewed token replaces the old one, null removes it', () async {
    final container = await loggedInContainer(session)
      ..listen(pushRegistrationProvider, (_, _) {});
    setToken(container, 'fcm1');
    await settle();
    setToken(container, 'fcm2');
    await settle();
    setToken(container, null);
    await settle();

    expect(tokenCalls(), [
      'deviceToken null',
      'deviceToken fcm1',
      'deviceToken fcm2',
      'deviceToken null',
    ]);
  });

  test('a refused token leaves the chat logged in', () async {
    final container = await loggedInContainer(session)
      ..listen(pushRegistrationProvider, (_, _) {});
    session.failDeviceToken = const ServerException(500, 'internal error');
    setToken(container, 'fcm1');
    await settle();

    expect(container.read(sessionControllerProvider).hasError, isFalse);
  });

  test('the next user to log in gets the token after a logout', () async {
    final container = await loggedInContainer(session)
      ..listen(pushRegistrationProvider, (_, _) {});
    setToken(container, 'fcm1');
    await settle();

    await container.read(sessionControllerProvider.notifier).logout();
    await container.read(sessionControllerProvider.future);
    expect(session.deviceToken, isNull);
    expect(container.read(pushTokenControllerProvider), 'fcm1');

    await container
        .read(sessionControllerProvider.notifier)
        .login(TinodeCredentials.token(session.token));
    await settle();
    expect(session.deviceToken, 'fcm1');
  });
}
