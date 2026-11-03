import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/network_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/test_container.dart';

void main() {
  const reconnecting = Reconnecting(attempt: 1, retryIn: Duration.zero);
  late FakeTinodeSession session;
  late ProviderContainer container;

  bool shown() => container.read(reconnectingNoticeProvider);

  void run(void Function(FakeAsync async) body) => fakeAsync((async) {
    session = FakeTinodeSession();
    unawaited(loggedInContainer(session).then((c) => container = c));
    async.flushMicrotasks();
    container.listen(reconnectingNoticeProvider, (_, _) {});
    body(async);
  });

  test('a dropped link shows only once it stays down', () {
    run((async) {
      expect(shown(), isFalse);

      session.emitStatus(reconnecting);
      async.elapse(networkSettle - const Duration(milliseconds: 1));
      expect(shown(), isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(shown(), isTrue);
    });
  });

  test('a blip that heals within the grace shows nothing', () {
    run((async) {
      session.emitStatus(reconnecting);
      async.elapse(networkSettle ~/ 2);
      session.emitStatus(const Connected());
      async.elapse(networkSettle * 2);
      expect(shown(), isFalse);
    });
  });

  test('more retries do not restart the grace', () {
    run((async) {
      session.emitStatus(reconnecting);
      async.elapse(networkSettle ~/ 2);
      session.emitStatus(
        const Reconnecting(attempt: 2, retryIn: Duration.zero),
      );
      async.elapse(networkSettle ~/ 2);
      expect(shown(), isTrue);
    });
  });

  test('the link coming back hides it at once', () {
    run((async) {
      session.emitStatus(reconnecting);
      async.elapse(networkSettle);
      expect(shown(), isTrue);

      session.emitStatus(const Connected());
      async.flushMicrotasks();
      expect(shown(), isFalse);
    });
  });

  test('the link drops at once for the rest of the chat', () {
    run((async) {
      session.emitStatus(reconnecting);
      async.flushMicrotasks();
      expect(container.read(reconnectingControllerProvider), isTrue);
      expect(shown(), isFalse);
    });
  });

  test('asked for while the link is down, it shows after the grace', () {
    run((async) {
      session.emitStatus(reconnecting);
      async.flushMicrotasks();
      container.invalidate(reconnectingNoticeProvider);
      expect(shown(), isFalse);

      async.elapse(networkSettle);
      expect(shown(), isTrue);
    });
  });
}
