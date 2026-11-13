import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/member_search.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob Builder', lastMessageAt: at(1)),
        chat(friends, name: 'Bob fans', lastMessageAt: at(2)),
      ],
    );
    session.found['bo,basic:bo'] = [
      const FoundTopic(
        topic: bob,
        public: Profile(name: 'Bob Builder'),
      ),
      const FoundTopic(
        topic: carol,
        public: Profile(name: 'Bobby Carol'),
      ),
    ];
    container = await loggedInContainer(session)
      ..listen(memberSuggestionsProvider, (_, _) {})
      ..listen(memberSearchProvider, (_, _) {});
    await settle();
  });

  void type(String input) {
    container
        .read(findControllerProvider(FindScope.groupMembers).notifier)
        .search(input);
    container.read(memberFilterProvider.notifier).change(input);
  }

  test('suggests the direct chats, filtered as the user types', () async {
    expect(
      container.read(memberSuggestionsProvider).people.map((p) => p.topic),
      [bob],
    );
    type('x');
    expect(container.read(memberSuggestionsProvider).isEmpty, isTrue);
  });

  test('the server search leaves out who is suggested', () async {
    type('bo');
    await Future<void>.delayed(findDebounce);
    await settle();
    final search = container.read(memberSearchProvider);
    expect(search.status, FindStatus.done);
    expect(search.found.map((r) => r.topic), [carol]);
  });
}
