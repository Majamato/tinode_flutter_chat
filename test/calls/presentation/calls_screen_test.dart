import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/calls_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const icons = TinodeChatIcons();

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2)),
        chat(carol, name: 'Carol', lastSeq: 4, read: 4, lastMessageAt: at(4)),
      ],
      histories: {
        bob: [
          callMessage(bob, 1, audioOnly: true),
          callUpdate(bob, 2, 1, CallState.missed),
        ],
        carol: [
          callMessage(carol, 3, from: alice),
          callUpdate(
            carol,
            4,
            3,
            CallState.finished,
            from: alice,
            duration: const Duration(minutes: 4),
          ),
        ],
      },
    );
  });

  Future<void> openCalls(
    WidgetTester tester, {
    TinodeChatFeatures features = const TinodeChatFeatures(),
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
      features: features,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.callsTitle),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(CallHistoryTile),
  );

  testWidgets('opening the tab fetches the calls, newest first', (
    tester,
  ) async {
    await openCalls(tester);

    expect(session.calls, containsAll(['attach $bob', 'attach $carol']));
    final rows = tester.widgetList<CallHistoryTile>(
      find.byType(CallHistoryTile),
    );
    expect(rows.map((r) => r.id.topic), [carol, bob]);
    expect(
      find.descendant(
        of: row('Bob'),
        matching: find.text('${strings.voiceCall} · ${strings.callMissed}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row('Carol'),
        matching: find.text('${strings.videoCall} · 4:00'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(icons.missedCall), findsOneWidget);
    expect(find.byIcon(icons.outgoingCall), findsOneWidget);
    Color? nameColor(String name) =>
        DefaultTextStyle.of(tester.element(find.text(name))).style.color;
    final missedColor = ThemeData().colorScheme.error;
    expect(nameColor('Bob'), missedColor);
    expect(nameColor('Carol'), isNot(missedColor));
  });

  testWidgets('a tap calls back by the same kind', (tester) async {
    await openCalls(tester);

    await tester.tap(find.text('Bob'));
    await tester.pump();

    expect(session.calls, contains('startCall $bob audio'));
  });

  testWidgets('a kind the host leaves out calls back by the other', (
    tester,
  ) async {
    await openCalls(
      tester,
      features: const TinodeChatFeatures(voiceCalls: false),
    );

    await tester.tap(find.text('Bob'));
    await tester.pump();

    expect(session.calls, contains('startCall $bob video'));
  });

  testWidgets('a call that fails says so above the tab bar', (tester) async {
    await openCalls(tester);
    session.failStartCall = const ConnectionClosedException('dropped');

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    final message = find.descendant(
      of: find.byType(SnackBar).last,
      matching: find.byType(Text),
    );
    expect(message, findsOneWidget);
    expect(
      tester.getRect(message).bottom,
      lessThan(tester.getRect(find.byType(HomeTabBar)).top),
    );
  });

  testWidgets('the chat button opens the chat', (tester) async {
    await openCalls(tester);

    await tester.tap(
      find.descendant(
        of: row('Carol'),
        matching: find.byTooltip(strings.openChat),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('pulling down fetches again what failed', (tester) async {
    // The newest chat is fetched first, and fails.
    session.failHistory = const ConnectionClosedException('dropped');
    await openCalls(tester);
    expect(find.text('Carol'), findsNothing);
    int fetches() => session.calls.where((c) => c == 'attach $carol').length;
    final before = fetches();

    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(fetches(), greaterThan(before));
    expect(find.text('Carol'), findsOneWidget);
  });

  testWidgets('without calls it says so', (tester) async {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    await openCalls(tester);

    expect(find.text(strings.noCalls), findsOneWidget);
  });

  testWidgets('the calls scroll under the app bar, starting below it', (
    tester,
  ) async {
    await openCalls(tester);

    final bar = find.descendant(
      of: find.byType(CallsScreen),
      matching: find.byType(TinodeAppBar),
    );
    expect(
      tester.getTopLeft(find.byType(CallHistoryTile).first).dy,
      tester.getBottomLeft(bar).dy,
    );
    expect(
      tester
          .getTopLeft(
            find.descendant(
              of: find.byType(CallsScreen),
              matching: find.byType(ListView),
            ),
          )
          .dy,
      0,
    );
  });
}
