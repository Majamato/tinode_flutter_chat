import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_tail.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/date_chip.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_bubble.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const icons = TinodeChatIcons();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(
          friends,
          name: 'Friends',
          lastSeq: 4,
          read: 4,
          lastMessageAt: at(4),
        ),
      ],
      histories: {
        friends: [
          message(friends, 1, text: 'one'),
          message(friends, 2, text: 'two'),
          message(friends, 3, from: carol, text: 'three'),
          message(friends, 4, from: alice, text: 'mine'),
        ],
      },
    );
    session.memberLists[friends] = [
      member(alice, name: 'Alice', read: 4, received: 4),
      member(bob, name: 'Bob', read: 4, received: 4),
      member(carol, name: 'Carol', read: 4, received: 4),
    ];
  });

  Future<void> openFriends(
    WidgetTester tester, {
    TinodeBubbleBuilder? bubbleBuilder,
    TinodeChatFeatures features = const TinodeChatFeatures(),
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      theme: TinodeChatTheme.materialTheme(),
      bubbleBuilder: bubbleBuilder,
      features: features,
    );
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
  }

  testWidgets('only the last bubble of a run has a tail', (tester) async {
    await openFriends(tester);

    // Bob's run ends at 'two'; Carol's 'three' and Alice's 'mine' are runs
    // of their own.
    expect(find.byType(BubbleTail), findsNWidgets(3));
    for (final text in ['two', 'three', 'mine']) {
      expect(
        find.ancestor(
          of: find.text(text),
          matching: find.byWidgetPredicate(
            (w) => w is Stack && w.children.any(_holdsTail),
          ),
        ),
        findsOneWidget,
        reason: text,
      );
    }
  });

  testWidgets('a date shows above the first message of the day', (
    tester,
  ) async {
    await openFriends(tester);
    expect(find.byType(DateChip), findsOneWidget);
  });

  testWidgets('the bubble builder gets the data and replaces the bubble', (
    tester,
  ) async {
    final seen = <TinodeBubble>[];
    await openFriends(
      tester,
      bubbleBuilder: (context, bubble, defaultBubble) {
        seen.add(bubble);
        return bubble.own ? Text('custom ${bubble.text}') : defaultBubble;
      },
    );

    expect(find.text('custom mine'), findsOneWidget);
    expect(find.text('mine'), findsNothing);
    expect(find.text('two'), findsOneWidget);
    final mine = seen.lastWhere((b) => b.own);
    expect(mine.seq, 4);
    expect(mine.kind, TinodeBubbleKind.text);
    expect(mine.status, TinodeBubbleStatus.read);
    expect(mine.endsRun, isTrue);
    final one = seen.lastWhere((b) => b.text == 'one');
    expect((one.startsRun, one.endsRun, one.senderId), (true, false, bob));
  });

  testWidgets('a blank field offers the mic, text the send arrow', (
    tester,
  ) async {
    await openFriends(tester);
    expect(find.byTooltip('Record voice message'), findsOneWidget);
    expect(find.byIcon(icons.microphone), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send'), findsOneWidget);
    expect(find.byIcon(icons.send), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Record voice message'), findsOneWidget);
  });

  testWidgets('without voice messages, send is disabled while the field is '
      'blank', (tester) async {
    await openFriends(
      tester,
      features: const TinodeChatFeatures(voiceMessages: false),
    );
    expect(find.byTooltip('Record voice message'), findsNothing);
    IconButton send() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Send'),
        matching: find.byType(IconButton),
      ),
    );

    expect(send().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(send().onPressed, isNotNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(send().onPressed, isNull);
  });

  testWidgets('a typing bubble shows while someone types, rebuilding no '
      'message', (tester) async {
    await openFriends(tester);
    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, _) =>
        rebuilt.add(element.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    session.emitInfo(
      const InfoMessage(topic: friends, event: InfoEvent.typing, from: bob),
    );
    await tester.pump();
    expect(find.byType(TypingBubble), findsOneWidget);

    await tester.pump(typingTimeout);
    await tester.pump();
    expect(find.byType(TypingBubble), findsNothing);
    expect(rebuilt, isNot(contains('$MessageBubble')));
  });

  testWidgets('the header says online, and typing over it', (tester) async {
    const strings = TinodeChatStrings();
    session.chats.add(
      chat(bob, name: 'Bob', lastSeq: 1, read: 1, online: true),
    );
    session.histories[bob] = [message(bob, 1, text: 'hi')];
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text(strings.online), findsOneWidget);

    session.emitInfo(
      const InfoMessage(topic: bob, event: InfoEvent.typing, from: bob),
    );
    await tester.pump();
    expect(find.text(strings.typingDirect), findsOneWidget);
    expect(find.text(strings.online), findsNothing);

    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.offline, source: bob),
    );
    await tester.pump(typingTimeout);
    await tester.pump();
    expect(find.text(strings.typingDirect), findsNothing);
    expect(find.text(strings.online), findsNothing);
  });

  group('dayLabel', () {
    const strings = TinodeChatStrings();
    const localizations = DefaultMaterialLocalizations();
    final now = DateTime(2026, 10, 23, 9);

    test('says today and yesterday, else the date', () {
      String label(DateTime time) =>
          dayLabel(strings, localizations, time, now: now);
      expect(label(DateTime(2026, 10, 23, 0, 5)), 'Today');
      expect(label(DateTime(2026, 10, 22, 23, 55)), 'Yesterday');
      expect(label(DateTime(2026, 10, 20)), 'Tue, Oct 20');
      expect(label(DateTime(2025, 12, 31)), 'Wednesday, December 31, 2025');
    });
  });
}

bool _holdsTail(Widget widget) =>
    widget is PositionedDirectional && widget.child is BubbleTail;
