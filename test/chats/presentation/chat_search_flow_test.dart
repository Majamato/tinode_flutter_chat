import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_search/chat_search_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_tile.dart';
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
        chat(bob, name: 'Bob Núñez', lastSeq: 1, lastMessageAt: at(1)),
        chat(carol, name: 'Carol', lastSeq: 1, lastMessageAt: at(3)),
        chat(friends, name: 'Bob fans', lastSeq: 1, lastMessageAt: at(2)),
      ],
    );
  });

  Future<void> openSearch(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text(strings.searchChats));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsOneWidget);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(ChatSearchScreen),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pumpAndSettle();
  }

  Iterable<String> shown(WidgetTester tester) => tester
      .widgetList<SearchResultTile>(find.byType(SearchResultTile))
      .map((tile) => tile.result.topic);

  testWidgets('the search pill finds the chats, not new people', (
    tester,
  ) async {
    await openSearch(tester);
    expect(find.byType(FindPeopleScreen), findsNothing);
    expect(find.text(strings.newGroup), findsNothing);
    expect(shown(tester), [carol, friends, bob]);

    await type(tester, 'bob');
    expect(shown(tester), [friends, bob]);

    await type(tester, 'nunez');
    expect(shown(tester), [bob]);

    await type(tester, 'dave');
    expect(find.byType(SearchResultTile), findsNothing);
    expect(find.text(strings.noChatsFound), findsOneWidget);
    expect(session.calls.where((c) => c.startsWith('find ')), isEmpty);
  });

  testWidgets('tapping a chat opens it', (tester) async {
    await openSearch(tester);
    await type(tester, 'fans');

    await tester.tap(find.byType(SearchResultTile));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('back from the chat search is the chevron', (tester) async {
    await openSearch(tester);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchScreen), findsNothing);
    expect(find.text(strings.searchChats), findsOneWidget);
  });
}
