import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';

import '../../support/fake_call_media.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

/// Bob's call [seq] to alice, as alice's session sees it.
DataMessage invite(int seq, {String topic = bob, bool audioOnly = false}) =>
    DataMessage(
      topic: topic,
      seq: seq,
      from: topic,
      time: at(seq),
      head: MessageHead(callState: CallState.started, audioOnly: audioOnly),
      content: DraftyContent(Drafty.videoCall(audioOnly: audioOnly)),
    );

/// The server's update [seq] to call [target] in bob's chat.
DataMessage update(int seq, int target, CallState state, {String? from}) =>
    DataMessage(
      topic: bob,
      seq: seq,
      from: from ?? bob,
      time: at(seq),
      head: MessageHead(replaces: ':$target', callState: state),
      content: DraftyContent(Drafty.videoCall()),
    );

InfoMessage callInfo(CallEvent event, int seq, {Json? payload}) => InfoMessage(
  topic: bob,
  event: InfoEvent.call,
  from: bob,
  seq: seq,
  callEvent: event,
  payload: payload,
);

void main() {
  late FakeTinodeSession session;
  late FakeCallMediaFactory media;
  late ProviderContainer container;

  ActiveCall? call() => container.read(callControllerProvider);
  CallController controller() =>
      container.read(callControllerProvider.notifier);

  Future<void> setUpCalls() async {
    container = await loggedInContainer(session, callMedia: media.call)
      ..listen(callControllerProvider, (_, _) {});
  }

  setUp(() async {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    media = FakeCallMediaFactory();
    await setUpCalls();
  });

  group('an outgoing call', () {
    test('rings, connects through offer and answer, and hangs up', () async {
      await controller().start(bob, audioOnly: false);
      expect(
        session.calls,
        containsAllInOrder(['attach usrBob', 'startCall usrBob video']),
      );
      expect(call()!.stage, CallStage.calling);
      expect(call()!.seq, 1);
      expect(call()!.localStream, media.last.local);
      expect(media.last.iceServers, session.serverInfo.iceServers);

      session.emitInfo(callInfo(CallEvent.ringing, 1));
      expect(call()!.stage, CallStage.ringing);

      session.emitInfo(callInfo(CallEvent.accept, 1));
      await settle();
      expect(call()!.stage, CallStage.connecting);
      expect(session.calls.last, 'call usrBob 1 offer');
      expect(session.callPayloads.last, {
        'type': 'offer',
        'sdp': 'local offer',
      });

      // The peer's paths wait for its answer.
      session.emitInfo(
        callInfo(
          CallEvent.iceCandidate,
          1,
          payload: const IceCandidate(candidate: 'early').toJson(),
        ),
      );
      await settle();
      expect(media.last.log, isNot(contains('candidate early')));
      session.emitInfo(
        callInfo(
          CallEvent.answer,
          1,
          payload: const CallDescription(
            type: 'answer',
            sdp: 'peer answer',
          ).toJson(),
        ),
      );
      await settle();
      expect(
        media.last.log,
        containsAllInOrder(['acceptAnswer peer answer', 'candidate early']),
      );

      media.last.emitCandidate('mine');
      expect(session.calls.last, 'call usrBob 1 iceCandidate');
      expect(session.callPayloads.last?['candidate'], 'mine');

      media.last
        ..emitRemote()
        ..emitLink(CallLinkState.connected);
      await settle();
      expect(call()!.stage, CallStage.connected);
      expect(call()!.remoteStream, media.last.remote);
      expect(call()!.speakerOn, isTrue, reason: 'video plays aloud');

      controller().hangUp();
      await settle();
      expect(session.calls, contains('call usrBob 1 hangUp'));
      expect(call()!.stage, CallStage.ended);
      expect(call()!.failure, isNull);
      expect(media.last.isClosed, isTrue);
      expect(session.attachCount(bob), 0);
    });

    test('a refused microphone ends it before it reaches the peer', () async {
      media.failOpen = const CallMediaException(permissionDenied: true);

      await controller().start(bob, audioOnly: true);

      expect(call()!.failure, CallFailure.permissionDenied);
      expect(session.calls, isNot(contains(startsWith('startCall'))));
      expect(session.attachCount(bob), 0);
    });

    test('a chat already in a call is busy', () async {
      session.failStartCall = const ServerException(486, 'busy here');

      await controller().start(bob, audioOnly: true);
      await settle();

      expect(call()!.failure, CallFailure.busy);
      expect(session.attachCount(bob), 0);
    });

    test("ends on the server's hang-up, which has no sender", () async {
      await controller().start(bob, audioOnly: true);

      session.emitInfo(
        const InfoMessage(
          topic: bob,
          event: InfoEvent.call,
          seq: 1,
          callEvent: CallEvent.hangUp,
        ),
      );

      expect(call()!.stage, CallStage.ended);
      expect(session.calls, isNot(contains('call usrBob 1 hangUp')));
    });

    test('ends when the server records the call as over', () async {
      await controller().start(bob, audioOnly: true);

      session.emitMessage(update(2, 1, CallState.missed, from: alice));

      expect(call()!.stage, CallStage.ended);
    });

    test('a hang-up while publishing still reaches the peer', () async {
      session.holdStartCall = Completer();
      final publishing = controller().start(bob, audioOnly: true);
      await settle();
      controller().hangUp();
      session.holdStartCall!.complete();
      await publishing;

      expect(session.calls, contains('call usrBob 1 hangUp'));
      expect(call()!.stage, CallStage.ended);
    });

    test('a failed link hangs up', () async {
      await controller().start(bob, audioOnly: false);
      session.emitInfo(callInfo(CallEvent.accept, 1));
      await settle();

      media.last.emitLink(CallLinkState.failed);

      expect(call()!.failure, CallFailure.mediaFailed);
      expect(session.calls, contains('call usrBob 1 hangUp'));
    });

    test('the controls reach the media', () async {
      await controller().start(bob, audioOnly: false);

      controller()
        ..toggleMicrophone()
        ..toggleCamera();
      await controller().switchCamera();
      await controller().toggleSpeaker();

      expect(
        media.last.log,
        containsAllInOrder([
          'mic off',
          'camera off',
          'switchCamera',
          'speaker on',
        ]),
      );
      expect(call()!.micOn, isFalse);
      expect(call()!.cameraOn, isFalse);
      expect(call()!.frontCamera, isFalse);
      expect(call()!.speakerOn, isTrue);
    });
  });

  group('an incoming call', () {
    test('rings when it arrives in an attached chat', () async {
      session.emitMessage(invite(4, audioOnly: true));
      await settle();

      expect(
        call(),
        isA<ActiveCall>()
            .having((c) => c.stage, 'stage', CallStage.incoming)
            .having((c) => c.seq, 'seq', 4)
            .having((c) => c.audioOnly, 'audioOnly', isTrue),
      );
      expect(
        session.calls,
        containsAllInOrder(['attach usrBob', 'call usrBob 4 ringing']),
      );
      expect(session.attachCount(bob), 1);
    });

    test('rings from another chat after checking its new message', () async {
      session.histories[bob] = [invite(4)];

      session.emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.message,
          source: bob,
          seq: 4,
        ),
      );
      await settle();

      expect(call()!.stage, CallStage.incoming);
      expect(
        session.calls,
        containsAllInOrder([
          'attach usrBob',
          'history usrBob since 4',
          'call usrBob 4 ringing',
        ]),
      );
      expect(session.attachCount(bob), 1);
    });

    test('a call that already ended does not ring', () async {
      session.histories[bob] = [invite(4), update(5, 4, CallState.missed)];

      session.emitPresence(
        const PresMessage(
          topic: 'me',
          event: PresenceEvent.message,
          source: bob,
          seq: 4,
        ),
      );
      await settle();

      expect(call(), isNull);
      expect(session.attachCount(bob), 0);
    });

    test('accepting opens the media and answers the offer', () async {
      session.emitMessage(invite(4));
      await settle();

      await controller().accept();
      expect(media.last.log, ['open video']);
      expect(session.calls.last, 'call usrBob 4 accept');
      expect(call()!.acceptedHere, isTrue);

      session.emitInfo(
        callInfo(
          CallEvent.offer,
          4,
          payload: const CallDescription(
            type: 'offer',
            sdp: 'peer offer',
          ).toJson(),
        ),
      );
      await settle();
      expect(media.last.log, contains('answer peer offer'));
      expect(session.calls.last, 'call usrBob 4 answer');
      expect(session.callPayloads.last, {
        'type': 'answer',
        'sdp': 'local answer',
      });
    });

    test('declining hangs up and lets the chat go', () async {
      session.emitMessage(invite(4));
      await settle();

      controller().decline();
      await settle();

      expect(session.calls.last, 'detach usrBob');
      expect(session.calls, contains('call usrBob 4 hangUp'));
      expect(session.attachCount(bob), 0);
    });

    test('stops ringing when another device takes it', () async {
      session.emitMessage(invite(4));
      await settle();

      session.emitInfo(
        const InfoMessage(
          topic: 'me',
          event: InfoEvent.call,
          from: alice,
          source: bob,
          seq: 4,
          callEvent: CallEvent.accept,
        ),
      );
      await settle();

      expect(call(), isNull);
      expect(session.attachCount(bob), 0);
    });

    test('stops ringing when the update says it was accepted', () async {
      session.emitMessage(invite(4));
      await settle();

      session.emitMessage(update(5, 4, CallState.accepted));

      expect(call(), isNull);
    });

    test('a second call while in one is declined', () async {
      await controller().start(bob, audioOnly: true);

      session.emitMessage(invite(7, topic: carol));

      expect(session.calls.last, 'call usrCarol 7 hangUp');
      expect(call()!.topic, bob);
    });

    test('the same call seen twice rings once', () async {
      session
        ..emitMessage(invite(4))
        ..emitMessage(invite(4));
      await settle();

      expect(session.calls.where((c) => c.endsWith('ringing')), hasLength(1));
    });
  });

  test('a dropped connection ends the call', () async {
    await controller().start(bob, audioOnly: true);

    session.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));

    expect(call()!.failure, CallFailure.connectionLost);
  });

  group('timers', () {
    test('an unanswered call gives up after the call timeout', () {
      fakeAsync((async) {
        session = FakeTinodeSession(chats: [chat(bob)]);
        unawaited(setUpCalls());
        async.flushMicrotasks();
        unawaited(controller().start(bob, audioOnly: true));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 34));
        expect(call()!.stage, CallStage.calling);

        async.elapse(const Duration(seconds: 2));
        expect(call()!.stage, CallStage.ended);
        expect(session.calls, contains('call usrBob 1 hangUp'));

        async.elapse(callEndedLinger);
        expect(call(), isNull);
      });
    });

    test('a connected call has no timeout', () {
      fakeAsync((async) {
        session = FakeTinodeSession(chats: [chat(bob)]);
        unawaited(setUpCalls());
        async.flushMicrotasks();
        unawaited(controller().start(bob, audioOnly: true));
        async.flushMicrotasks();
        media.last.emitLink(CallLinkState.connected);

        async.elapse(const Duration(minutes: 5));
        expect(call()!.stage, CallStage.connected);
      });
    });
  });
}
