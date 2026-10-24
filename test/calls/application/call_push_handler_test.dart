import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_push_handler.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';

import '../../support/fake_system_calls.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

/// A push as the server sends it for bob's call [seq] to alice.
TinodePush callPush(
  int seq, {
  String state = 'started',
  String? replaces,
  String topic = bob,
  bool audioOnly = false,
  DateTime? sentAt,
}) => TinodePush.tryParse({
  'what': 'msg',
  'topic': topic,
  'xfrom': bob,
  'seq': '$seq',
  'ts': (sentAt ?? epoch).toIso8601String(),
  'webrtc': state,
  'silent': 'true',
  if (audioOnly) 'aonly': 'true',
  'replace': ?replaces,
})!;

void main() {
  late FakeSystemCalls system;
  late MemoryChatStoreOpener opener;

  Future<bool> handle(
    TinodePush push, {
    String? token,
    DateTime? now,
    TinodeChatFeatures features = const TinodeChatFeatures(),
  }) => withClock(
    Clock.fixed(now ?? epoch.add(const Duration(seconds: 2))),
    () => handleCallPush(
      push,
      config: testConfig,
      token: token,
      systemCalls: system,
      storeOpener: opener,
      features: features,
    ),
  );

  setUp(() async {
    system = FakeSystemCalls();
    opener = MemoryChatStoreOpener();
    await opener.rememberUser(testConfig.server, alice);
    final store = await opener.open(testConfig.server, alice);
    await store.replaceChats([chat(bob, name: ' Bob ')]);
  });

  test('a new call rings with the name the cache has', () async {
    expect(await handle(callPush(4, audioOnly: true)), isTrue);

    expect(system.log, ['ring usrBob 4 audio Bob 28s']);
    expect(system.reported.single.hangUpWith, isNull);
  });

  test('a kind of call the host turned off does not ring', () async {
    const noVideo = TinodeChatFeatures(videoCalls: false);

    expect(await handle(callPush(4), features: noVideo), isTrue);
    expect(system.log, isEmpty);

    await handle(callPush(5, audioOnly: true), features: noVideo);
    expect(system.log, ['ring usrBob 5 audio Bob 28s']);
  });

  test('without a cache the caller has no name', () async {
    opener = MemoryChatStoreOpener();

    await handle(callPush(4));

    expect(system.log, ['ring usrBob 4 video null 28s']);
  });

  test('with a token, a decline can reach the caller', () async {
    var registered = 0;
    await withClock(
      Clock.fixed(epoch),
      () => handleCallPush(
        callPush(4),
        config: testConfig,
        token: 'tok',
        systemCalls: system,
        storeOpener: opener,
        registerHangUp: () async => registered++,
      ),
    );

    expect(registered, 1);
    expect(
      system.reported.single.hangUpWith,
      HangUpCredentials(
        server: testConfig.server,
        apiKey: testConfig.apiKey,
        userAgent: testConfig.userAgent,
        token: 'tok',
      ),
    );
  });

  test('a call sent too long ago does not ring', () async {
    expect(await handle(callPush(4), now: epoch.add(callPushLifetime)), isTrue);
    expect(system.log, isEmpty);
  });

  test('group chats and other pushes are no calls here', () async {
    expect(await handle(callPush(4, topic: friends)), isTrue);
    expect(
      await handle(
        TinodePush.tryParse({'what': 'msg', 'topic': bob, 'seq': '5'})!,
      ),
      isFalse,
    );
    expect(
      await handle(TinodePush.tryParse({'what': 'read', 'topic': bob})!),
      isFalse,
    );
    expect(system.log, isEmpty);
  });

  test('taken on another device, it stops ringing', () async {
    await handle(callPush(4));

    await handle(callPush(5, state: 'accepted', replaces: ':4'));

    expect(system.log.last, 'stopRinging usrBob 4');
  });

  test('over before an answer, it is missed', () async {
    await handle(callPush(4));

    await handle(callPush(5, state: 'missed', replaces: ':4'));

    expect(system.log.last, 'stopRinging usrBob 4 missed');
  });

  test('a call accepted here goes on', () async {
    await handle(callPush(4));
    system.ringing.clear();

    expect(
      await handle(callPush(5, state: 'accepted', replaces: ':4')),
      isTrue,
    );

    expect(system.log, hasLength(1));
  });
}
