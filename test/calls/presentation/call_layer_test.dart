import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_local_preview.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/incoming_call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/video_call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/voice_call_view.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_call_media.dart';
import '../../support/fake_network_monitor.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

DataMessage invite(int seq, {bool audioOnly = false}) => DataMessage(
  topic: bob,
  seq: seq,
  from: bob,
  time: at(seq),
  head: MessageHead(callState: CallState.started, audioOnly: audioOnly),
  content: DraftyContent(Drafty.videoCall(audioOnly: audioOnly)),
);

void main() {
  late FakeTinodeSession session;
  late FakeCallMediaFactory media;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, read: 1, lastMessageAt: at(1)),
        chat(friends, name: 'Friends'),
        chat(channel, name: 'News', mode: 'JRP'),
      ],
      histories: {
        bob: [message(bob, 1, text: 'Hi Alice')],
      },
    );
    media = FakeCallMediaFactory();
  });

  Future<void> pump(
    WidgetTester tester, {
    TinodeChatFeatures features = const TinodeChatFeatures(),
    bool reduceMotion = true,
    FakeNetworkMonitor? network,
  }) => pumpTinodeChat(
    tester,
    session,
    credentials: TinodeCredentials.token(session.token),
    callMedia: media.call,
    features: features,
    reduceMotion: reduceMotion,
    network: network,
  );

  Future<void> openChat(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  /// Places a call to Bob from his chat; [video] for a video call.
  Future<void> callBob(WidgetTester tester, {bool video = false}) async {
    await openChat(tester, 'Bob');
    await tester.tap(find.byTooltip(video ? 'Video call' : 'Voice call'));
    await tester.pumpAndSettle();
  }

  /// Bob calls, and the user takes it; the link comes up.
  Future<void> acceptBob(WidgetTester tester, {bool video = false}) async {
    await openChat(tester, 'Bob');
    session.emitMessage(invite(2, audioOnly: !video));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    media.last.emitLink(CallLinkState.connected);
    await tester.pump();
  }

  testWidgets('a call rings over the chat list and can be declined', (
    tester,
  ) async {
    await pump(tester);
    session.histories[bob]!.add(invite(2, audioOnly: true));

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.message,
        source: bob,
        seq: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IncomingCallView), findsOneWidget);
    expect(find.text('Incoming voice call'), findsOneWidget);

    await tester.tap(find.text('Decline'));
    await tester.pump();
    expect(session.calls, contains('call usrBob 2 hangUp'));
    expect(find.byType(IncomingCallView), findsNothing);
    expect(find.text('Call ended'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CallView), findsNothing);
  });

  testWidgets('accepting turns the ringing screen into the call', (
    tester,
  ) async {
    await pump(tester);
    await openChat(tester, 'Bob');

    session.emitMessage(invite(2, audioOnly: true));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallView), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
    expect(session.calls.last, 'call usrBob 2 accept');

    media.last.emitLink(CallLinkState.connected);
    await tester.pump();
    expect(find.text('0:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:01'), findsOneWidget);

    await tester.tap(find.byTooltip('Mute'));
    await tester.pump();
    expect(media.last.log, contains('mic off'));
    expect(find.byTooltip('Unmute'), findsOneWidget);

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CallView), findsNothing);
    expect(find.text('Hi Alice'), findsOneWidget, reason: 'back in the chat');
  });

  testWidgets('a 1:1 chat offers voice and video calls', (tester) async {
    await pump(tester);
    await openChat(tester, 'Bob');

    expect(find.byTooltip('Voice call'), findsOneWidget);
    expect(find.byTooltip('Video call'), findsOneWidget);

    await tester.tap(find.byTooltip('Voice call'));
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsOneWidget);
    expect(find.text('Calling…'), findsOneWidget);
    expect(session.calls, contains('startCall usrBob audio'));

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Back minimizes the call to the call bar, which brings it back', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await callBob(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsNothing);
    expect(find.text('Hi Alice'), findsOneWidget, reason: 'the chat shows');
    expect(find.bySemanticsLabel(RegExp('^Return to call')), findsOneWidget);
    expect(find.text('Calling…'), findsOneWidget, reason: 'in the bar');

    await tester.tap(find.text('Calling…'));
    await tester.pumpAndSettle();
    expect(find.byType(VoiceCallView), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Return to call')), findsNothing);

    // The chevron minimizes too; then Back leaves the chat as usual.
    await tester.tap(find.byTooltip('Back to chat'));
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Hi Alice'), findsNothing, reason: 'back on the list');
    expect(find.bySemanticsLabel(RegExp('^Return to call')), findsOneWidget);

    // The bar shows how the call ended, then goes.
    media.last.emitLink(CallLinkState.failed);
    await tester.pump();
    expect(find.text('The call could not be connected.'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    expect(find.bySemanticsLabel(RegExp('^Return to call')), findsNothing);
    semantics.dispose();
  });

  testWidgets('a call that rings closes the keyboard, for good', (
    tester,
  ) async {
    await pump(tester);
    await openChat(tester, 'Bob');
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    session.emitMessage(invite(2, audioOnly: true));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallView), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(IncomingCallView), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a minimized call closes the keyboard when it comes back', (
    tester,
  ) async {
    await pump(tester);
    await callBob(tester);
    await tester.tap(find.byTooltip('Back to chat'));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Calling…'));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceCallView), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a ringing call ignores Back', (tester) async {
    await pump(tester);
    await openChat(tester, 'Bob');
    session.emitMessage(invite(2, audioOnly: true));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallView), findsOneWidget);

    await tester.tap(find.text('Decline'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the voice call has Speaker, Mute and End, with their state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await acceptBob(tester);

    expect(find.byType(VoiceCallView), findsOneWidget);
    for (final label in ['Speaker', 'Mute', 'End']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(VoiceCallView),
        matching: find.byTooltip('Video call'),
      ),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Mute')),
      isSemantics(hasToggledState: true, isToggled: false),
    );

    await tester.tap(find.text('Mute'));
    await tester.tap(find.text('Speaker'));
    await tester.pumpAndSettle();
    expect(media.last.log, containsAll(['mic off', 'speaker on']));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Unmute')),
      isSemantics(hasToggledState: true, isToggled: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Turn speaker off')),
      isSemantics(hasToggledState: true, isToggled: true),
    );

    await tester.tap(find.text('End'));
    await tester.pump(const Duration(seconds: 3));
    semantics.dispose();
  });

  testWidgets('a dropped link shows as reconnecting until it comes back', (
    tester,
  ) async {
    await pump(tester);
    await acceptBob(tester);
    expect(find.text('Reconnecting…'), findsNothing);

    media.last.emitLink(CallLinkState.disconnected);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting…'), findsOneWidget, reason: 'the pill');
    expect(find.text('0:00'), findsOneWidget, reason: 'the timer stays');

    // Minimized, the bar says so instead of the timer.
    await tester.tap(find.byTooltip('Back to chat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting…'), findsOneWidget);

    media.last.emitLink(CallLinkState.connected);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting…'), findsNothing);
    expect(find.text('0:00'), findsOneWidget, reason: 'the same call');

    await tester.tap(find.text('0:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a link that stays down ends the call, which can be redialled', (
    tester,
  ) async {
    await pump(tester);
    await acceptBob(tester);

    media.last.emitLink(CallLinkState.disconnected);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reconnecting…'), findsOneWidget);

    await tester.pump(callReconnectTimeout);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('The connection dropped. The call ended.'), findsWidgets);
    expect(session.calls, contains('call usrBob 2 hangUp'));
    expect(find.text('End'), findsNothing, reason: 'no controls');

    await tester.tap(find.text('Call again'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('startCall usrBob audio'));
    expect(find.text('Calling…'), findsOneWidget);

    await tester.tap(find.text('End'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('offline, the ended call waits for the server to call again', (
    tester,
  ) async {
    await pump(tester);
    await acceptBob(tester);

    session.emitStatus(
      const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You're offline. The call ended."), findsWidgets);
    final callAgain = find.ancestor(
      of: find.text('Call again'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.widget<GestureDetector>(callAgain.first).onTap, isNull);

    session.emitStatus(const Connected());
    await tester.pump();
    expect(tester.widget<GestureDetector>(callAgain.first).onTap, isNotNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsNothing);
    expect(find.text('Hi Alice'), findsOneWidget);
  });

  testWidgets('during a call, a network change probes the link gently', (
    tester,
  ) async {
    final network = FakeNetworkMonitor();
    await pump(tester, network: network);
    List<String> probes() =>
        session.calls.where((c) => c.startsWith('resume')).toList();

    network.report(available: true);
    await tester.pump(const Duration(seconds: 2));
    expect(probes(), ['resume probe 4s']);

    await acceptBob(tester);
    network.report(available: true);
    await tester.pump(const Duration(seconds: 2));
    expect(probes().last, 'resume probe 10s');

    await tester.tap(find.text('End'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a tap on the video hides the controls and lifts the self-view', (
    tester,
  ) async {
    await pump(tester);
    await callBob(tester, video: true);
    expect(find.byType(VideoCallView), findsOneWidget);

    double opacityOf(Finder control) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: control, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
    final pipTop = tester.getTopLeft(find.byType(CallLocalPreview)).dy;
    expect(opacityOf(find.byTooltip('Hang up')), 1);

    await tester.tapAt(tester.getCenter(find.byType(VideoCallView)));
    await tester.pumpAndSettle();
    expect(opacityOf(find.byTooltip('Hang up')), 0);
    expect(
      tester.getTopLeft(find.byType(CallLocalPreview)).dy,
      lessThan(pipTop),
    );

    await tester.tapAt(tester.getCenter(find.byType(VideoCallView)));
    await tester.pumpAndSettle();
    expect(opacityOf(find.byTooltip('Hang up')), 1);
    expect(tester.getTopLeft(find.byType(CallLocalPreview)).dy, pipTop);

    // While the cameras swap, the button ignores taps; the self-view stays
    // blurred until the new camera's frames come, or for at most
    // newCameraWait (no renderer reports frames in tests).
    bool blurred() => tester
        .widget<ImageFiltered>(
          find.descendant(
            of: find.byType(CallLocalPreview),
            matching: find.byType(ImageFiltered),
          ),
        )
        .enabled;
    expect(blurred(), isFalse);
    final hold = media.last.holdSwitch = Completer<void>();
    await tester.tap(find.byTooltip('Switch camera'));
    await tester.pump();
    expect(blurred(), isTrue);
    await tester.tap(find.byTooltip('Switch camera'));
    hold.complete();
    await tester.pumpAndSettle();
    expect(media.last.log.where((l) => l == 'switchCamera'), hasLength(1));
    expect(blurred(), isTrue, reason: 'no new frames yet');
    await tester.pump(CallLocalPreview.newCameraWait);
    await tester.pumpAndSettle();
    expect(blurred(), isFalse);

    await tester.tap(find.byTooltip('Turn camera off'));
    await tester.pumpAndSettle();
    expect(media.last.log, contains('camera off'));
    expect(find.text('Camera off'), findsOneWidget);

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the self-view turns away while the cameras swap', (
    tester,
  ) async {
    await pump(tester, reduceMotion: false);
    await openChat(tester, 'Bob');
    await tester.tap(find.byTooltip('Video call'));
    await tester.pump(const Duration(seconds: 1));
    double facing() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(CallLocalPreview),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .entry(0, 0);
    expect(facing(), 1);

    // Edge-on until the media answers, then back.
    final hold = media.last.holdSwitch = Completer<void>();
    await tester.tap(find.byTooltip('Switch camera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(facing(), closeTo(0, 0.01), reason: 'edge-on');

    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(facing(), closeTo(1, 0.01), reason: 'facing again');
    await tester.pump(CallLocalPreview.newCameraWait);

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a host without video calls neither offers nor rings them', (
    tester,
  ) async {
    await pump(tester, features: const TinodeChatFeatures(videoCalls: false));
    await openChat(tester, 'Bob');
    expect(find.byTooltip('Video call'), findsNothing);
    expect(find.byTooltip('Voice call'), findsOneWidget);

    session.emitMessage(invite(2));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallView), findsNothing);
    expect(session.calls, isNot(contains('call usrBob 2 ringing')));
    expect(session.calls, isNot(contains('call usrBob 2 hangUp')));
  });

  testWidgets('the call screen moves, unless Reduce motion is on', (
    tester,
  ) async {
    await pump(tester, reduceMotion: false);
    await openChat(tester, 'Bob');
    await tester.tap(find.byTooltip('Voice call'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'blobs, rings');
    expect(find.text('Calling'), findsOneWidget, reason: 'pulsing dots');

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('group chats and servers without ICE servers offer none', (
    tester,
  ) async {
    await pump(tester);
    await openChat(tester, 'Friends');
    expect(find.byTooltip('Voice call'), findsNothing);
    await tester.tap(find.byTooltip('Back to chats'));
    await tester.pumpAndSettle();

    session.serverInfo = const ServerInfo(version: '0.25');
    await openChat(tester, 'Bob');
    expect(find.byTooltip('Voice call'), findsNothing);
  });

  testWidgets('a refused microphone is explained', (tester) async {
    media.failOpen = const CallMediaException(permissionDenied: true);
    await pump(tester);
    await openChat(tester, 'Bob');

    await tester.tap(find.byTooltip('Voice call'));
    await tester.pumpAndSettle();

    expect(
      find.text('Allow access to the microphone and camera to make calls.'),
      findsWidgets,
    );
    await tester.pump(const Duration(seconds: 3));
  });
}
