import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

import '../../support/chat_list_contract.dart';
import '../../support/fake_chat_server.dart';
import '../../support/fake_tinode_session.dart';

/// The chat list contract on `FakeChatServer`; the same tests run on the
/// live server in `test/integration/chat_list_contract_test.dart`.
void main() {
  chatListContract(() async {
    final world = _ModelWorld();
    await world.viewer.attach('me');
    return world;
  });
}

final class _ModelWorld implements ChatListWorld {
  final server = FakeChatServer(step: const Duration(milliseconds: 10));
  late final FakeTinodeSession _viewer = FakeTinodeSession(server: server);
  var _groups = 0;

  @override
  TinodeSession get viewer => _viewer;

  @override
  Future<String> newGroup(String name) async {
    final topic = 'grpContract${_groups++}';
    server.add(
      Subscription(
        topic: topic,
        public: Profile(name: name),
        access: Access(
          want: AccessMode.parse('JRWPS'),
          given: AccessMode.parse('JRWPS'),
          mode: AccessMode.parse('JRWPS'),
        ),
      ),
    );
    return topic;
  }

  @override
  Future<void> post(String topic) async => server.post(topic);

  @override
  Future<void> attachOther(String topic) async => server.online.add(topic);

  @override
  Future<void> detachOther(String topic) async => server.online.remove(topic);

  @override
  Future<void> pause() async => server.tick(const Duration(milliseconds: 1));

  @override
  Future<void> unload() async {}

  @override
  Future<void> eventually(String what, Future<bool> Function() check) async =>
      expect(await check(), isTrue, reason: what);
}
