import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  BackgroundPolicy policy() =>
      container.read(backgroundPolicyProvider.notifier);

  void run(void Function(FakeAsync async) body) => fakeAsync((async) {
    session = FakeTinodeSession();
    unawaited(loggedInContainer(session).then((c) => container = c));
    async.flushMicrotasks();
    body(async);
  });

  test('hidden, the session is suspended after the grace', () {
    run((async) {
      policy().hidden();
      async.elapse(backgroundGrace);
      expect(session.calls, contains('suspend'));
    });
  });

  test('a call keeps the session open in the background', () {
    run((async) {
      policy()
        ..keepOpen(inCall: true)
        ..hidden();
      async.elapse(backgroundGrace * 4);
      expect(session.calls, isNot(contains('suspend')));

      policy().keepOpen(inCall: false);
      async.elapse(backgroundGrace);
      expect(session.calls, contains('suspend'));
    });
  });

  test('a call starting in the background stops the countdown', () {
    run((async) {
      policy().hidden();
      async.elapse(backgroundGrace ~/ 2);
      policy().keepOpen(inCall: true);
      async.elapse(backgroundGrace);
      expect(session.calls, isNot(contains('suspend')));
    });
  });

  test('a call ending in the foreground starts no countdown', () {
    run((async) {
      policy()
        ..keepOpen(inCall: true)
        ..keepOpen(inCall: false);
      async.elapse(backgroundGrace * 2);
      expect(session.calls, isNot(contains('suspend')));
    });
  });
}
