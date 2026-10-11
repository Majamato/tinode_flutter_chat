import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/password_reset_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/password_reset_state.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession();
    container = createTestContainer(connector: connectTo(session))
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(passwordResetControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
  });

  PasswordResetController controller() =>
      container.read(passwordResetControllerProvider.notifier);

  PasswordResetState state() => container.read(passwordResetControllerProvider);

  test('a code by email, then the new password with it', () async {
    await controller().request(' alice@example.com ');
    expect(state().codeSent, isTrue);
    expect(state().email, 'alice@example.com');

    await controller().reset(code: '123456', password: 'new-pw');

    expect(state().done, isTrue);
    expect(session.passwords['alice'], 'new-pw');
    expect(session.calls, isNot(contains(startsWith('login'))));
  });

  test('a wrong code says so and lets the user try again', () async {
    await controller().request('alice@example.com');

    await controller().reset(code: '000000', password: 'new-pw');
    expect(state().failure, ChatFailure.wrongCode);
    expect(state().done, isFalse);

    await controller().reset(code: '123456', password: 'new-pw');
    expect(state().done, isTrue);
  });

  test('a code still valid from before counts as sent', () async {
    session.resetCodes['alice@example.com'] = '123456';

    await controller().request('alice@example.com');

    expect(state().codeSent, isTrue);
    expect(state().failure, isNull);
    await controller().reset(code: '123456', password: 'new-pw');
    expect(state().done, isTrue);
  });

  test('offline it fails with a lost connection', () async {
    session.dropConnection();

    await controller().request('alice@example.com');

    expect(state().failure, ChatFailure.connectionLost);
    expect(state().codeSent, isFalse);
  });
}
