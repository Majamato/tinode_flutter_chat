import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_resources.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';

import '../../support/fake_call_media.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession session;
  late CallResources resources;
  late FakeCallMedia media;
  late List<CallLinkState> links;

  setUp(() {
    session = FakeTinodeSession();
    resources = CallResources(session);
    media = FakeCallMedia();
    links = [];
  });

  void useMedia() => resources.useMedia(
    media,
    onCandidate: (_) {},
    onRemoteStream: (_) {},
    onLink: links.add,
  );

  test('release lets go of the topic, the media and the timer', () {
    fakeAsync((async) {
      var timedOut = false;
      unawaited(resources.attach(bob));
      async.flushMicrotasks();
      useMedia();
      resources.startSetupTimer(
        const Duration(seconds: 5),
        () => timedOut = true,
      );
      media.emitLink(CallLinkState.connecting);

      resources.release();
      media.emitLink(CallLinkState.closed);
      async.elapse(const Duration(seconds: 10));

      expect(resources.isReleased, isTrue);
      expect(resources.media, isNull);
      expect(media.isClosed, isTrue);
      expect(session.attachCount(bob), 0);
      expect(timedOut, isFalse);
      expect(links, [CallLinkState.connecting], reason: 'no events after');
    });
  });

  test('an attach that completes after release is undone', () async {
    final attached = resources.attach(bob);
    resources.release();

    expect(await attached, isFalse);
    await settle();
    expect(session.attachCount(bob), 0);
  });

  test("an invite check's attach is the call's to release", () async {
    await session.attach(bob);
    resources.adopt(bob);
    expect(await resources.attached, isTrue);

    resources.release();
    await settle();
    expect(session.attachCount(bob), 0);
  });

  test("the peer's candidates wait for its description", () async {
    useMedia();
    await resources.addPeerCandidate(const IceCandidate(candidate: 'early'));
    expect(media.log, isEmpty);

    await resources.peerDescriptionSet();
    await resources.addPeerCandidate(const IceCandidate(candidate: 'late'));
    expect(media.log, ['candidate early', 'candidate late']);
  });
}
