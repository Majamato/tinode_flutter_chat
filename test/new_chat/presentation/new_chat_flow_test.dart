import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_group_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [chat(carol, name: 'Carol', lastSeq: 1, lastMessageAt: at(1))],
    );
    session.found['bob,basic:bob'] = [
      const FoundTopic(
        topic: bob,
        public: Profile(name: 'Bob'),
      ),
      const FoundTopic(
        topic: friends,
        public: Profile(name: 'Bob fans'),
        memberCount: 4,
      ),
    ];
  });

  Future<void> openSearch(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.byTooltip(strings.newChat));
    await tester.pumpAndSettle();
    expect(find.byType(FindPeopleScreen), findsOneWidget);
  }

  Future<void> search(WidgetTester tester, Finder field, String text) async {
    await tester.enterText(field, text);
    await tester.pump(findDebounce);
    await tester.pumpAndSettle();
  }

  testWidgets('finds someone and opens the 1:1 chat with them', (tester) async {
    await openSearch(tester);
    expect(find.text(strings.findHint), findsWidgets);

    await search(tester, find.byType(TextField), 'bob');
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Bob fans'), findsOneWidget);
    expect(find.text(strings.groupLabel), findsOneWidget);

    // The server makes the chat when it is first attached.
    session.chats.add(chat(bob, name: 'Bob', lastMessageAt: at(5)));
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(FindPeopleScreen), findsNothing);
    expect(session.calls, contains('attach $bob'));

    // Back goes straight to the chat list, which now has the chat.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(strings.chatListTitle), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('a search that finds no one says so', (tester) async {
    await openSearch(tester);
    await search(tester, find.byType(TextField), 'nobody');
    expect(find.text(strings.nobodyFound), findsOneWidget);
  });

  testWidgets('offline the search fails and can be retried', (tester) async {
    await openSearch(tester);
    session.failFind = const ConnectionClosedException('gone');
    await search(tester, find.byType(TextField), 'bob');
    expect(find.text(strings.connectionLost), findsOneWidget);

    await tester.tap(find.text(strings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('creates a group with a member and opens it', (tester) async {
    await openSearch(tester);
    await tester.tap(find.text(strings.newGroup));
    await tester.pumpAndSettle();
    expect(find.byType(NewGroupScreen), findsOneWidget);

    final create = find.widgetWithText(TextButton, strings.createGroup);
    expect(tester.widget<TextButton>(create).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'Hikers');
    await tester.pump();
    expect(tester.widget<TextButton>(create).onPressed, isNotNull);

    await search(tester, find.byType(TextField).last, 'bob');
    // Only people can be members.
    expect(find.text('Bob fans'), findsNothing);
    await tester.tap(find.text('Bob'));
    await tester.pump();
    expect(find.byType(InputChip), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(session.calls, containsAllInOrder(['createGroup Hikers']));
    expect(session.members['grpNew1'], [bob]);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Hikers'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(strings.chatListTitle), findsOneWidget);
    expect(find.text('Hikers'), findsOneWidget);
  });

  testWidgets('a member the server refuses is reported', (tester) async {
    session.refuseMembers.add(bob);
    await openSearch(tester);
    await tester.tap(find.text(strings.newGroup));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hikers');
    await search(tester, find.byType(TextField).last, 'bob');
    await tester.tap(find.text('Bob'));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, strings.createGroup));
    await tester.pumpAndSettle();
    expect(find.text(strings.membersNotAdded), findsOneWidget);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('a group the server refuses stays on the screen', (tester) async {
    session.failCreateGroup = const ServerException(403, 'denied');
    await openSearch(tester);
    await tester.tap(find.text(strings.newGroup));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hikers');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, strings.createGroup));
    await tester.pumpAndSettle();
    expect(find.text(strings.rejected), findsOneWidget);
    expect(find.byType(NewGroupScreen), findsOneWidget);
  });
}
