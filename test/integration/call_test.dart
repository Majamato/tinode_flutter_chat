@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../support/fake_call_media.dart';

// Runs against ../tinode-tests, which must have ICE servers configured
// (ICE_SERVERS_FILE). The media are fakes: the server passes the WebRTC
// setup on unread, so the call flow is real while no audio flows.
final config = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

/// A logged-in user with the chat list loaded, as the app has it.
final class User {
  User._(this.container, this.id, this.media);

  static Future<User> login(String name) async {
    final media = FakeCallMediaFactory();
    final container = createTinodeContainer(
      config: config,
      credentials: TinodeCredentials.password(name, '${name}123'),
      callMedia: media.call,
    );
    addTearDown(container.dispose);
    container
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(chatListControllerProvider, (_, _) {})
      ..listen(callControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    final user = User._(
      container,
      container.read(currentUserIdProvider)!,
      media,
    );
    await eventually(
      '$name chat list',
      () =>
          container.read(chatListControllerProvider).status == LoadStatus.ready,
    );
    return user;
  }

  final ProviderContainer container;
  final String id;
  final FakeCallMediaFactory media;

  ActiveCall? get call => container.read(callControllerProvider);
  CallStage? get stage => call?.stage;
  CallController get calls => container.read(callControllerProvider.notifier);
}

/// Polls [condition] until it holds, failing after [timeout].
Future<void> eventually(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  late User alice;
  late User bob;

  setUp(() async {
    alice = await User.login('alice');
    bob = await User.login('bob');
  });

  test('alice calls bob, who is on his chat list, and they talk', () async {
    await alice.calls.start(bob.id, audioOnly: true);
    expect(alice.stage, CallStage.calling);
    final seq = alice.call!.seq!;

    // Bob's session is not in the chat: the invite check finds the call.
    await eventually('bob rings', () => bob.stage == CallStage.incoming);
    expect(bob.call!.seq, seq);
    expect(bob.call!.audioOnly, isTrue);
    await eventually(
      'alice hears it ring',
      () => alice.stage == CallStage.ringing,
    );

    await bob.calls.accept();
    await eventually(
      'offer and answer cross',
      () =>
          bob.media.last.log.contains('answer local offer') &&
          alice.media.last.log.contains('acceptAnswer local answer'),
    );

    alice.media.last.emitCandidate('candidate:alice');
    bob.media.last.emitCandidate('candidate:bob');
    await eventually(
      'paths cross',
      () =>
          bob.media.last.log.contains('candidate candidate:alice') &&
          alice.media.last.log.contains('candidate candidate:bob'),
    );

    alice.media.last.emitLink(CallLinkState.connected);
    bob.media.last.emitLink(CallLinkState.connected);
    expect(alice.stage, CallStage.connected);
    expect(bob.stage, CallStage.connected);

    alice.calls.hangUp();
    await eventually('bob sees the end', () => bob.stage == CallStage.ended);
    expect(bob.call!.failure, isNull);

    // The chat shows one call bubble, updated by the server.
    bob.container.listen(chatControllerProvider(alice.id), (_, _) {});
    await eventually(
      'bob sees the finished call',
      () =>
          bob.container.read(chatMessageProvider(alice.id, seq))?.call?.state ==
          CallState.finished,
    );
    final record = bob.container.read(chatMessageProvider(alice.id, seq))!;
    expect(record.call!.duration, isNotNull);
    expect(record.call!.audioOnly, isTrue);
    expect(record.isOwn, isFalse);
    final bobChat = bob.container.read(chatControllerProvider(alice.id));
    expect(
      bobChat.seqs.where((s) => s > seq),
      isEmpty,
      reason: 'no bubbles for updates',
    );
    expect(bobChat.lastSeq, greaterThan(seq));

    await eventually(
      'the call screens go away',
      () => alice.call == null && bob.call == null,
    );
  });

  test('bob declines, and alice sees it', () async {
    await alice.calls.start(bob.id, audioOnly: false);
    final seq = alice.call!.seq!;
    await eventually('bob rings', () => bob.stage == CallStage.incoming);

    bob.calls.decline();

    await eventually(
      'alice sees the end',
      () => alice.stage == CallStage.ended,
    );
    alice.container.listen(chatControllerProvider(bob.id), (_, _) {});
    await eventually(
      'the call is recorded as declined',
      () =>
          alice.container.read(chatMessageProvider(bob.id, seq))?.call?.state ==
          CallState.declined,
    );
  });
}
