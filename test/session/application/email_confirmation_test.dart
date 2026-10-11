import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/confirm_email_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/credentials_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/login_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession()..requireEmails();
    container = createTestContainer(connector: connectTo(session))
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(signUpControllerProvider, (_, _) {})
      ..listen(loginControllerProvider, (_, _) {})
      ..listen(confirmEmailControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
  });

  Future<bool> signUp({String email = 'carol@example.com'}) => container
      .read(signUpControllerProvider.notifier)
      .submit(login: 'carol', password: 'pw', name: 'Carol', email: email);

  SessionState? state() => container.read(sessionControllerProvider).value;

  test('the server says whether sign-up needs an email', () {
    expect(container.read(signUpNeedsEmailProvider), isTrue);
  });

  test('a sign-up with an email waits for its code, then logs in', () async {
    expect(await signUp(), isTrue);
    expect(state(), isA<SessionAwaitingLogin>());
    expect(container.read(signUpFailureProvider), isNull);
    expect(
      session.calls,
      contains('createAccount carol Carol carol@example.com'),
    );

    await container
        .read(confirmEmailControllerProvider.notifier)
        .confirm(login: 'carol', password: 'pw', code: '000000');
    expect(container.read(confirmEmailFailureProvider), ChatFailure.wrongCode);
    expect(state(), isA<SessionAwaitingLogin>());

    await container
        .read(confirmEmailControllerProvider.notifier)
        .confirm(login: 'carol', password: 'pw', code: ' 654321 ');
    expect(state(), isA<SessionLoggedIn>());
    expect(session.calls, contains('loginBasic carol 654321'));
  });

  test('a login of an account still to confirm asks for the code', () async {
    await signUp();

    expect(
      await container
          .read(loginControllerProvider.notifier)
          .submit('carol', 'pw'),
      isTrue,
    );
    expect(container.read(loginFailureProvider), isNull);
  });

  test('a sign-up without the email the server needs is refused', () async {
    expect(await signUp(email: ''), isFalse);
    expect(
      container.read(signUpFailureProvider),
      ChatFailure.credentialsRefused,
    );
  });

  test('a taken or malformed email says so; a taken login too', () async {
    session.emails['taken@example.com'] = 'dave';
    await signUp(email: 'taken@example.com');
    expect(container.read(signUpFailureProvider), ChatFailure.emailTaken);

    await signUp(email: 'nope');
    expect(container.read(signUpFailureProvider), ChatFailure.invalidEmail);

    await container
        .read(signUpControllerProvider.notifier)
        .submit(login: 'alice', password: 'pw', name: 'A', email: 'a@b.c');
    expect(container.read(signUpFailureProvider), ChatFailure.loginTaken);
  });

  test(
    'a session whose email turns out unconfirmed asks for a login',
    () async {
      final loggedIn = createTestContainer(
        connector: connectTo(session),
        credentials: TinodeCredentials.token(session.token),
      )..listen(sessionControllerProvider, (_, _) {});
      await loggedIn.read(sessionControllerProvider.future);

      session.emitStatus(
        const Disconnected(cause: CredentialsRequiredException(['email'])),
      );
      await settle();

      expect(loggedIn.read(credentialsControllerProvider), isNull);
      expect(
        await loggedIn.read(sessionControllerProvider.future),
        isA<SessionAwaitingLogin>(),
      );
    },
  );
}
