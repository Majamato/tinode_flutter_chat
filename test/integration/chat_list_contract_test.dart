@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

import '../support/chat_list_contract.dart';
import 'account_test.dart' show uniqueLogin;
import 'group_chat_test.dart' show config;

/// The chat list contract on the live server (../tinode-tests), with two
/// throwaway users deleted afterwards: the viewer, whose list is read, and
/// the owner of its groups. The same tests run on `FakeChatServer` in
/// `test/session/data/chat_list_contract_test.dart`.
void main() {
  chatListContract(() async {
    final owner = await _signUp('Owner');
    final viewer = await _signUp('Viewer');
    await viewer.session.attach('me');
    return _LiveWorld(owner: owner.session, user: viewer);
  });
}

typedef _User = ({TinodeSession session, String userId});

Future<_User> _signUp(String name) async {
  final session = await ClientTinodeSession.connect(config);
  final login = await session.createAccount(
    login: uniqueLogin(name.toLowerCase()),
    password: 'secret1',
    public: Profile(name: name),
  );
  addTearDown(() async {
    try {
      await session.deleteAccount();
    } on Object {
      await session.close();
    }
  });
  return (session: session, userId: login.userId);
}

final class _LiveWorld implements ChatListWorld {
  _LiveWorld({required this.owner, required this.user});

  final TinodeSession owner;
  final _User user;

  @override
  TinodeSession get viewer => user.session;

  @override
  Future<String> newGroup(String name) async {
    final topic = await owner.createGroup(public: Profile(name: name));
    await owner.addMember(topic, user.userId);
    await owner.detach(topic);
    return topic;
  }

  @override
  Future<void> post(String topic) async {
    await owner.attach(topic);
    await owner.publish(topic, const PlainText('contract'));
    await owner.detach(topic);
  }

  @override
  Future<void> attachOther(String topic) => owner.attach(topic);

  @override
  Future<void> detachOther(String topic) => owner.detach(topic);

  @override
  Future<void> pause() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  /// The server unloads a topic 4 s after its last session left.
  @override
  Future<void> unload() => Future<void>.delayed(const Duration(seconds: 6));

  @override
  Future<void> eventually(String what, Future<bool> Function() check) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!await check()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out: $what');
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}
