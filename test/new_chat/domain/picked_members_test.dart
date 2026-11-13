import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/picked_members.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';

const _bob = SearchResult(
  topic: 'usrBob',
  kind: TopicKind.direct,
  title: 'Bob',
);
const _carol = SearchResult(
  topic: 'usrCarol',
  kind: TopicKind.direct,
  title: 'Carol',
);

void main() {
  test('toggling picks in order and unpicks', () {
    final picked = const PickedMembers().toggled(_bob).toggled(_carol);
    expect(picked.members, [_bob, _carol]);
    expect(picked.has('usrCarol'), isTrue);
    expect(picked.count, 2);

    final unpicked = picked.toggled(_bob);
    expect(unpicked.members, [_carol]);
    expect(unpicked.has('usrBob'), isFalse);
  });

  test('compares by value', () {
    expect(
      const PickedMembers().toggled(_bob),
      const PickedMembers().toggled(_bob),
    );
  });
}
