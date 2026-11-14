import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_search/call_search_screen.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_search_field.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/calls_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/back_button.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob Núñez', lastSeq: 2, read: 2, lastMessageAt: at(2)),
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

  Future<void> openSearch(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.callsTitle),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CallsScreen),
        matching: find.byType(CallSearchField),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CallSearchScreen), findsOneWidget);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(CallSearchScreen),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pumpAndSettle();
  }

  Iterable<String> shown(WidgetTester tester) => tester
      .widgetList<CallHistoryTile>(
        find.descendant(
          of: find.byType(CallSearchScreen),
          matching: find.byType(CallHistoryTile),
        ),
      )
      .map((tile) => tile.id.topic);

  testWidgets('the search pill filters the calls by the chat name', (
    tester,
  ) async {
    await openSearch(tester);
    expect(shown(tester), [carol, bob]);

    await type(tester, 'nunez');
    expect(shown(tester), [bob]);

    await type(tester, 'carl');
    expect(shown(tester), [carol]);

    await type(tester, 'dave');
    expect(shown(tester), isEmpty);
    expect(find.text(strings.noCallsFound), findsOneWidget);
    expect(session.calls.where((c) => c.startsWith('find ')), isEmpty);
  });

  testWidgets('a found call calls back', (tester) async {
    await openSearch(tester);
    await type(tester, 'bob');

    await tester.tap(
      find.descendant(
        of: find.byType(CallSearchScreen),
        matching: find.text('Bob Núñez'),
      ),
    );
    await tester.pump();
    expect(session.calls, contains('startCall $bob audio'));
  });

  testWidgets('back from the call search is the chevron', (tester) async {
    await openSearch(tester);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(CallSearchScreen), findsNothing);
    expect(find.byType(CallsScreen), findsOneWidget);
  });
}
