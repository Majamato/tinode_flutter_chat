import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// One user's chat list on a server, the live one or `FakeChatServer`, and
/// what others do to it.
abstract interface class ChatListWorld {
  /// The user whose list is read, attached to `me`.
  TinodeSession get viewer;

  /// A new group the viewer is a member of, named [name].
  Future<String> newGroup(String name);

  /// Someone else sends a message to [topic].
  Future<void> post(String topic);

  /// Someone attaches [topic], which goes online for the viewer, or
  /// detaches it.
  Future<void> attachOther(String topic);
  Future<void> detachOther(String topic);

  /// Waits until a change made now gets a later server time than the last.
  Future<void> pause();

  /// Waits until the server unloaded the topics nobody is attached to.
  Future<void> unload();

  /// Polls [check] until it holds, or fails.
  Future<void> eventually(String what, Future<bool> Function() check);
}

/// What the package relies on of the server's chat list (`get sub` on
/// `me`). `test/integration/chat_list_contract_test.dart` runs it on the
/// live server, `test/session/data/chat_list_contract_test.dart` on
/// `FakeChatServer`, so the model the other tests use is the server's.
void chatListContract(Future<ChatListWorld> Function() open) {
  late ChatListWorld world;

  setUp(() async => world = await open());

  /// The chats of [topics] in [list], stubs left out.
  List<Subscription> ours(List<Subscription> list, Set<String> topics) => [
    for (final chat in list)
      if (topics.contains(chat.topic) &&
          (chat.access != null || chat.deleted != null))
        chat,
  ];

  /// The server's `LastModified` of a chat as listed.
  DateTime modified(Subscription chat) => [
    ?chat.updated,
    ?chat.lastMessageAt,
    ?chat.deleted,
  ].reduce((a, b) => a.isAfter(b) ? a : b);

  Future<List<String>> groups(int count) async {
    final topics = <String>[];
    for (var i = 0; i < count; i++) {
      topics.add(await world.newGroup('Contract $i'));
      await world.pause();
    }
    return topics;
  }

  test('without "if modified since": every chat, with its name', () async {
    final topics = await groups(3);

    final listed = ours(await world.viewer.chatList(), {...topics});

    expect(listed.map((c) => c.topic), unorderedEquals(topics));
    expect(
      listed.map((c) => c.public?.name),
      unorderedEquals(['Contract 0', 'Contract 1', 'Contract 2']),
    );
  });

  test('a chat whose profile did not change since comes without it; asked '
      'for alone, it comes with it', () async {
    final [topic] = await groups(1);
    final created = ours(await world.viewer.chatList(), {topic}).single;
    await world.post(topic);

    final changed = ours(
      await world.viewer.chatList(ifModifiedSince: created.updated),
      {topic},
    ).single;
    expect(changed.lastSeq, 1);
    expect(changed.public, isNull);

    final alone = await world.viewer.chat(topic);
    expect(alone?.public?.name, 'Contract 0');
    expect(alone?.lastSeq, 1);
  });

  test('a chat asked for alone that the user does not have is null', () async {
    expect(await world.viewer.chat('grpNoSuchChat0'), isNull);
  });

  test('a chat left after "if modified since" comes as deleted; left '
      'before, it does not come, even when its group moved on', () async {
    final [stays, left] = await groups(2);
    final before = ours(await world.viewer.chatList(), {stays, left});
    final since = before.map(modified).reduce((a, b) => a.isAfter(b) ? a : b);
    await world.pause();
    // The server lets only an attached user leave, as the open chat is.
    await world.viewer.attach(left);
    await world.viewer.leaveChat(left);

    final gone = ours(await world.viewer.chatList(ifModifiedSince: since), {
      left,
    }).single;
    expect(gone.deleted, isNotNull);

    await world.pause();
    await world.post(left);
    await world.post(stays);
    final later = ours(
      await world.viewer.chatList(ifModifiedSince: gone.deleted),
      {stays, left},
    );
    expect(later.map((c) => c.topic), [stays]);
  });

  test('a received marker counts only while attached', () async {
    final [topic] = await groups(1);
    await world.post(topic);
    await world.unload();

    world.viewer.markReceived(topic, 1);
    await world.pause();
    expect((await world.viewer.chat(topic))?.received, 0);

    await world.viewer.attach(topic);
    world.viewer.markReceived(topic, 1);
    await world.eventually(
      'the marker counts',
      () async => (await world.viewer.chat(topic))?.received == 1,
    );
    await world.viewer.detach(topic);
  });

  test('a chat online and unchanged comes as a stub: its topic and online, '
      'no access', () async {
    final [topic] = await groups(1);
    final listed = ours(await world.viewer.chatList(), {topic}).single;
    await world.attachOther(topic);

    await world.eventually('the stub comes', () async {
      final answer = await world.viewer.chatList(
        ifModifiedSince: modified(listed),
      );
      return answer.any(
        (c) => c.topic == topic && c.online && c.access == null,
      );
    });
    await world.detachOther(topic);
  });
}
