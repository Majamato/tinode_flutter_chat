import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/search/application/message_search_controller.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_search_state.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

/// Waits out the debounce and lets the search settle.
Future<void> settled() async {
  await Future<void>.delayed(
    messageSearchDebounce + const Duration(milliseconds: 20),
  );
  await settle();
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    final session = FakeTinodeSession(
      chats: [chat(bob, lastSeq: 40), chat(friends, lastSeq: 2)],
      histories: {
        bob: [
          for (var seq = 1; seq <= 40; seq++)
            message(bob, seq, text: 'lunch number $seq'),
        ],
        friends: [
          message(friends, 1, text: 'hiking on Sunday', time: at(100)),
          message(friends, 2, text: 'lunch after the hike', time: at(101)),
        ],
      },
    );
    container = await loggedInContainer(session);
    // Fill the cache, as opening the chats would.
    final cached = container.read(activeSessionProvider)!;
    await cached.chatList();
    await cached.history(bob, limit: 40);
    await cached.history(friends, limit: 40);
  });

  MessageSearchController controller(String topic) {
    container.listen(messageSearchControllerProvider(topic), (_, _) {});
    return container.read(messageSearchControllerProvider(topic).notifier);
  }

  MessageSearchState state(String topic) =>
      container.read(messageSearchControllerProvider(topic));

  List<int> found(String topic) => [
    for (final f in state(topic).results) f.seq,
  ];

  test('searches the chat once the input settles, newest first', () async {
    controller(friends)
      ..search('h')
      ..search('hik');
    expect(state(friends).status, MessageSearchStatus.searching);
    await settled();

    expect(state(friends).status, MessageSearchStatus.done);
    expect(found(friends), [2, 1]);
    expect(state(friends).results.first.snippet.text, 'lunch after the hike');
  });

  test('finds only messages of its own chat', () async {
    controller(friends).search('lunch');
    await settled();

    expect(found(friends), [2]);
  });

  test('short input clears the results; old answers are dropped', () async {
    controller(friends).search('hik');
    await settled();
    controller(friends)
      ..search('x')
      ..search('');
    expect(state(friends).status, MessageSearchStatus.idle);
    expect(state(friends).results, isEmpty);

    controller(friends)
      ..search('hiking')
      ..search('sunday hik');
    await settled();
    expect(found(friends), [1]);
  });

  test('loads the next page', () async {
    controller(bob).search('lunch');
    await settled();

    expect(state(bob).results, hasLength(messageSearchPageSize));
    expect(state(bob).hasMore, isTrue);
    expect(found(bob).first, 40);

    await controller(bob).loadMore();
    expect(state(bob).results, hasLength(40));
    expect(state(bob).hasMore, isFalse);
    expect(found(bob).last, 1);
  });
}
