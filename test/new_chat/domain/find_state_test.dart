import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_state.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

const bob = SearchResult(topic: 'usrBob', kind: TopicKind.direct, title: 'Bob');

void main() {
  test('a result is titled by its profile name, or by its topic', () {
    expect(
      SearchResult.fromFound(
        const FoundTopic(
          topic: 'usrBob',
          public: Profile(name: ' Bob Smith '),
        ),
      ),
      const SearchResult(
        topic: 'usrBob',
        kind: TopicKind.direct,
        title: 'Bob Smith',
      ),
    );
    final group = SearchResult.fromFound(
      const FoundTopic(topic: 'grpX', memberCount: 3),
    );
    expect(group.title, 'grpX');
    expect(group.isUser, isFalse);
    expect(group.memberCount, 3);
  });

  test('results stay while a newer search runs or fails', () {
    final done = const FindState.idle().searching().done([bob]);
    final searching = done.searching();
    expect(searching.status, FindStatus.searching);
    expect(searching.results, [bob]);
    expect(identical(searching.searching(), searching), isTrue);

    final failed = searching.failed(ChatFailure.connectionLost);
    expect(failed.results, [bob]);
    expect(failed.failure, ChatFailure.connectionLost);
  });

  test('the same results keep their list instance', () {
    final done = const FindState.idle().done([bob]);
    expect(
      identical(done.searching().done([bob]).results, done.results),
      isTrue,
    );
    expect(done.done(const []).results, isEmpty);
  });
}
