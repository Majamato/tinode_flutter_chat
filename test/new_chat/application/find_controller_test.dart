import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

const bobFound = FoundTopic(
  topic: bob,
  public: Profile(name: 'Bob'),
);
const carolFound = FoundTopic(
  topic: carol,
  public: Profile(name: 'Carol'),
);
const hikers = FoundTopic(
  topic: friends,
  public: Profile(name: 'Hikers'),
);

/// Waits out the debounce and lets the search settle.
Future<void> settled() async {
  await Future<void>.delayed(findDebounce + const Duration(milliseconds: 20));
  await settle();
}

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession();
    session.found['bob,basic:bob'] = [bobFound];
    session.found['carol,basic:carol'] = [carolFound];
    container = await loggedInContainer(session);
  });

  FindController controller([FindScope scope = FindScope.newChat]) {
    container.listen(findControllerProvider(scope), (_, _) {});
    return container.read(findControllerProvider(scope).notifier);
  }

  FindState state([FindScope scope = FindScope.newChat]) =>
      container.read(findControllerProvider(scope));

  test('searches once the input settles', () async {
    controller()
      ..search('b')
      ..search('bo')
      ..search('bob');
    expect(state().status, FindStatus.searching);
    await settled();

    expect(session.calls.where((c) => c.startsWith('find')), [
      'find bob,basic:bob',
    ]);
    expect(state().status, FindStatus.done);
    expect(state().results.single.title, 'Bob');
  });

  test('input too short clears the results without searching', () async {
    controller().search('bob');
    await settled();
    controller().search('b');
    expect(state().status, FindStatus.idle);
    expect(state().results, isEmpty);
    await settled();
    expect(session.calls.where((c) => c.startsWith('find')), hasLength(1));
  });

  test('an answer to older input is dropped', () async {
    final hold = session.holdFind = Completer();
    controller().search('bob');
    await settled(); // The search for bob waits for the server.
    controller().search('carol');
    await settled();
    hold.complete();
    await settle();

    expect(state().results.single.topic, carol);
  });

  test('leaves out the user, and groups when picking members', () async {
    session.found['all,basic:all'] = [
      const FoundTopic(topic: alice),
      bobFound,
      hikers,
    ];
    controller().search('all');
    controller(FindScope.groupMembers).search('all');
    await settled();

    expect(state().results.map((r) => r.topic), [bob, friends]);
    expect(state(FindScope.groupMembers).results.map((r) => r.topic), [bob]);
  });

  test('each scope keeps its own search', () async {
    controller().search('bob');
    controller(FindScope.groupMembers).search('carol');
    await settled();
    expect(state().results.single.topic, bob);
    expect(state(FindScope.groupMembers).results.single.topic, carol);
  });

  test('offline it fails, and searches again once connected', () async {
    session.emitStatus(
      const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
    );
    controller().search('bob');
    await settled();
    expect(state().status, FindStatus.failed);
    expect(state().failure, ChatFailure.connectionLost);

    session.emitStatus(const Connected());
    await settle();
    expect(state().status, FindStatus.done);
    expect(state().results.single.topic, bob);
  });

  test('a refused search can be retried', () async {
    session.failFind = const ServerException(500, 'internal error');
    controller().search('bob');
    await settled();
    expect(state().failure, ChatFailure.rejected);

    controller().retry();
    await settle();
    expect(state().results.single.topic, bob);
  });
}
