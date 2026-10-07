import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_view.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/incoming_call_view.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_call_media.dart';
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

  Future<void> pump(WidgetTester tester) => pumpTinodeChat(
    tester,
    session,
    credentials: TinodeCredentials.token(session.token),
    callMedia: media.call,
  );

  Future<void> openChat(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
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

    // Back does not leave the call behind.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CallView), findsOneWidget);

    await tester.tap(find.byTooltip('Hang up'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('group chats and servers without ICE servers offer none', (
    tester,
  ) async {
    await pump(tester);
    await openChat(tester, 'Friends');
    expect(find.byTooltip('Voice call'), findsNothing);
    await tester.pageBack();
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
