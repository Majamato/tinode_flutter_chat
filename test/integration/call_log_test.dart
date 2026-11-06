@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../support/fake_call_media.dart';
import 'account_test.dart' show signUp;
import 'call_test.dart' show User, config, eventually;

/// One device: its stores stay when the user logs out.
final class Device {
  Device(String name, this.password) : login = name {
    container = createTinodeContainer(
      config: config,
      credentials: TinodeCredentials.password(name, password),
      callMedia: media.call,
      storeOpener: stores,
    );
    addTearDown(container.dispose);
    container
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(callControllerProvider, (_, _) {})
      ..listen(callHistoryControllerProvider, (_, _) {});
  }

  final String login;
  final String password;
  final stores = MemoryChatStoreOpener();
  final media = FakeCallMediaFactory();
  late final ProviderContainer container;

  Future<void> ready() async {
    await container.read(sessionControllerProvider.future);
  }

  String get id => container.read(currentUserIdProvider)!;

  SessionController get session =>
      container.read(sessionControllerProvider.notifier);

  Future<void> logOut() async {
    await session.logout();
    await container.read(sessionControllerProvider.future);
  }

  Future<void> logIn() async {
    await session.login(TinodeCredentials.password(login, password));
  }

  bool shows(String topic, int seq) =>
      container.read(callHistoryEntryProvider(topic, seq)) != null;

  CallState? state(String topic, int seq) =>
      container.read(callHistoryEntryProvider(topic, seq))?.call.state;
}

/// The call log against the real server (`../tinode-tests`): what a fake
/// can only assume. Its wire formats, its delete log, its chat list.
void main() {
  final server = config.server;

  /// Alice calls [callee], who declines; the seq of the call.
  Future<int> declinedCall(User alice, User callee) async {
    await alice.calls.start(callee.id, audioOnly: true);
    final seq = alice.call!.seq!;
    await eventually('it rings', () => callee.stage == CallStage.incoming);
    callee.calls.decline();
    await eventually('alice sees it', () => alice.stage == CallStage.ended);
    return seq;
  }

  test("a call reaches the log with the server's last word on it", () async {
    final alice = await User.login('alice');
    final device = Device('bob', 'bob123');
    await device.ready();
    final bob = await User.login('bob');
    final seq = await declinedCall(alice, bob);

    final session = device.container.read(activeSessionProvider)!;
    await session.chatList();
    await eventually(
      'the call is in the log',
      () => device.state(alice.id, seq) == CallState.declined,
    );

    final call = (await session.storedCalls(
      topic: alice.id,
    )).firstWhere((c) => c.message.seq == seq);
    expect(call.message.topic, alice.id);
    expect(call.message.head?.callState, CallState.started);
    expect(call.message.head?.audioOnly, isTrue);
    expect(call.updates, isNotEmpty);
    expect(call.updates.last.head?.replaces, ':$seq');
    expect(call.updates.last.head?.callState, CallState.declined);
  });

  test('logging out and in shows the calls again, at once', () async {
    final alice = await User.login('alice');
    final device = Device('bob', 'bob123');
    await device.ready();
    final bob = await User.login('bob');
    final seq = await declinedCall(alice, bob);
    await device.container.read(activeSessionProvider)!.chatList();
    await eventually(
      'the call shows',
      () => device.state(alice.id, seq) == CallState.declined,
    );

    final user = device.id;
    await device.logOut();
    expect(device.shows(alice.id, seq), isFalse);
    final log = await device.stores.openCallLog(server, user);
    expect((await log.calls()).map((c) => c.message.seq), contains(seq));

    await device.logIn();

    await eventually('the call shows', () => device.shows(alice.id, seq));
    expect(device.state(alice.id, seq), CallState.declined);
  });

  // Not "for everyone": a direct chat gives its members no `D`, so a peer's
  // hard delete stays their own. The user's other device is what can.
  test('a call deleted on another device while away is gone after', () async {
    final alice = await User.login('alice');
    final device = Device('bob', 'bob123');
    await device.ready();
    final bob = await User.login('bob');
    final seq = await declinedCall(alice, bob);
    await device.container.read(activeSessionProvider)!.chatList();
    await eventually(
      'the call shows',
      () => device.state(alice.id, seq) == CallState.declined,
    );

    await device.logOut();
    final other = bob.container.read(activeSessionProvider)!;
    await other.attach(alice.id);
    await other.deleteMessages(alice.id, [SeqRange.single(seq)], hard: false);
    await other.detach(alice.id);

    await device.logIn();

    await eventually(
      'the deletion reached the log',
      () =>
          device.container.read(callHistoryControllerProvider).loaded &&
          !device.shows(alice.id, seq),
    );
  });

  test('a chat deleted while away takes its calls', () async {
    final (first, _, firstId) = await signUp('LogProbeOne');
    final (second, secondLogin, secondId) = await signUp('LogProbeTwo');
    // Another chat, or the list would come back empty, which proves nothing.
    final alice = await User.login('alice');
    final keeper = second.read(activeSessionProvider)!;
    await keeper.attach(alice.id);
    await keeper.publish(alice.id, const PlainText('hi'));
    await keeper.detach(alice.id);
    final device = Device(secondLogin, 'secret1');
    await device.ready();

    final caller = first.read(activeSessionProvider)!;
    await caller.attach(secondId);
    await caller.startCall(secondId, audioOnly: true);
    await device.container.read(activeSessionProvider)!.chatList();
    await eventually(
      'the call shows',
      () => device.container
          .read(callHistoryControllerProvider)
          .ids
          .any((id) => id.topic == firstId),
    );

    await device.logOut();
    await second.read(activeSessionProvider)!.deleteChat(firstId);

    await device.logIn();

    await eventually(
      'the chat is gone',
      () => device.container.read(callHistoryControllerProvider).loaded,
    );
    await eventually(
      'its calls are gone',
      () => !device.container
          .read(callHistoryControllerProvider)
          .ids
          .any((id) => id.topic == firstId),
    );
  });

  test('deleting the account deletes the log', () async {
    final (first, _, _) = await signUp('LogProbeThree');
    final (second, secondLogin, secondId) = await signUp('LogProbeFour');
    final device = Device(secondLogin, 'secret1');
    await device.ready();
    final user = device.id;
    final caller = first.read(activeSessionProvider)!;
    await caller.attach(secondId);
    await caller.startCall(secondId, audioOnly: true);
    await device.container.read(activeSessionProvider)!.chatList();
    await eventually(
      'the call shows',
      () => device.container.read(callHistoryControllerProvider).ids.isNotEmpty,
    );

    // The tear down of `signUp` would delete it twice.
    await second.read(sessionControllerProvider.notifier).logout();
    await device.session.deleteAccount();
    await device.container.read(sessionControllerProvider.future);

    final log = await device.stores.openCallLog(server, user);
    expect(await log.calls(), isEmpty);
  });
}
