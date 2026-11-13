import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/new_group.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

const bobResult = SearchResult(
  topic: bob,
  kind: TopicKind.direct,
  title: 'Bob',
);
const carolResult = SearchResult(
  topic: carol,
  kind: TopicKind.direct,
  title: 'Carol',
);

void main() {
  late FakeTinodeSession session;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession();
    container = await loggedInContainer(session)
      ..listen(newGroupControllerProvider, (_, _) {})
      ..listen(chatListControllerProvider, (_, _) {});
    await settle();
  });

  NewGroupController controller() =>
      container.read(newGroupControllerProvider.notifier);

  test('creates the group, adds its members and lists it', () async {
    final group = await controller().create(' Hikers ', [
      bobResult,
      carolResult,
    ]);
    await settle();

    expect(group, const NewGroup(topic: 'grpNew1'));
    expect(session.addedMembers['grpNew1'], [bob, carol]);
    expect(session.calls, containsAllInOrder(['createGroup Hikers']));
    // Creating held the group; the chat screen attaches it on its own.
    expect(session.calls, contains('detach grpNew1'));
    expect(session.attachCount('grpNew1'), 0);
    expect(container.read(chatSummaryProvider('grpNew1'))?.title, 'Hikers');
    expect(container.read(newGroupControllerProvider), isA<AsyncData<void>>());
  });

  test('a refused member does not undo the group', () async {
    session.refuseMembers.add(carol);
    final group = await controller().create('Hikers', [bobResult, carolResult]);
    expect(group?.notAdded, ['Carol']);
    expect(session.addedMembers['grpNew1'], [bob]);
  });

  test('a refused group is an error', () async {
    session.failCreateGroup = const ServerException(403, 'denied');
    expect(await controller().create('Hikers', const []), isNull);
    expect(container.read(newGroupControllerProvider), isA<AsyncError<void>>());
  });

  test('a blank name creates nothing', () async {
    expect(await controller().create('  ', [bobResult]), isNull);
    expect(session.calls, isNot(contains(startsWith('createGroup'))));
  });

  test('a photo is uploaded and set on the group', () async {
    final group = await controller().create(
      'Hikers',
      [bobResult],
      photo: pickedFile(
        'hills.jpg',
        [1, 2, 3],
        mimeType: 'image/jpeg',
        isImage: true,
      ),
    );
    await settle();
    expect(group?.topic, 'grpNew1');
    expect(
      session.calls,
      containsAllInOrder(['upload hills.jpg', 'createGroup Hikers']),
    );
    final photo = session.chats.last.public?.photo;
    expect(photo?.type, 'jpeg');
    expect(photo?.ref, startsWith('/v0/file/s/fake'));
    expect(
      container.read(chatSummaryProvider('grpNew1'))?.photo?.ref,
      photo?.ref,
    );
  });

  test('a failed photo upload creates nothing', () async {
    session.failUpload = const ConnectionClosedException('gone');
    final group = await controller().create(
      'Hikers',
      const [],
      photo: pickedFile(
        'hills.jpg',
        [1],
        mimeType: 'image/jpeg',
        isImage: true,
      ),
    );
    expect(group, isNull);
    expect(session.calls, isNot(contains(startsWith('createGroup'))));
    expect(container.read(newGroupControllerProvider), isA<AsyncError<void>>());
  });
}
