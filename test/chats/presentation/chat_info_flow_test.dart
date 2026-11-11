import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_header.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_presence_line.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_info/chat_info_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/confirm_sheet.dart';
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
        chat(bob, name: 'Bob', lastSeq: 1, lastMessageAt: at(1)),
        chat(
          friends,
          name: 'Friends',
          lastSeq: 1,
          lastMessageAt: at(2),
          mode: 'JRWPASDO',
        ),
      ],
      histories: {
        bob: [message(bob, 1)],
        friends: [message(friends, 1)],
      },
    );
    session.memberLists[friends] = [
      member(alice, name: 'Alice', mode: 'JRWPASDO'),
      member(bob, name: 'Bob'),
    ];
  });

  Future<void> openInfo(WidgetTester tester, String title) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(ChatHeader), matching: find.text(title)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatInfoScreen), findsOneWidget);
  }

  Finder inInfo(Finder finder) =>
      find.descendant(of: find.byType(ChatInfoScreen), matching: finder);

  testWidgets('back is the chevron: the chat is named below it', (
    tester,
  ) async {
    await openInfo(tester, 'Friends');
    expect(backText(), findsNothing);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(ChatInfoScreen), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets("a direct chat's info says when the peer was last seen", (
    tester,
  ) async {
    session.chats[0] = chat(
      bob,
      name: 'Bob',
      lastSeq: 1,
      lastMessageAt: at(1),
      seen: DateTime.now().subtract(const Duration(days: 3)),
    );
    await openInfo(tester, 'Bob');

    final lastSeen = inInfo(find.textContaining(strings.lastSeenOn('')));
    expect(lastSeen, findsOneWidget);

    // Online outranks it, as in the header.
    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.online, source: bob),
    );
    await tester.pump();
    expect(inInfo(find.text(strings.online)), findsOneWidget);
    expect(lastSeen, findsNothing);
  });

  testWidgets("a group's info has no presence", (tester) async {
    await openInfo(tester, 'Friends');

    expect(inInfo(find.byType(ChatPresenceLine)), findsOneWidget);
    expect(inInfo(find.text(strings.online)), findsNothing);
    expect(inInfo(find.textContaining(strings.lastSeenOn(''))), findsNothing);
  });

  Future<void> confirm(WidgetTester tester, String action) async {
    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmSheet),
        matching: find.text(action),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('deletes a 1:1 chat and goes back to the list', (tester) async {
    await openInfo(tester, 'Bob');

    await tester.tap(find.text(strings.deleteChat));
    await tester.pumpAndSettle();
    expect(find.text(strings.deleteChatConfirm), findsOneWidget);
    await confirm(tester, strings.deleteChat);

    expect(session.deletedChats, [bob]);
    expect(find.text(strings.chatListTitle), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('the owner sees members, removes one, deletes the group', (
    tester,
  ) async {
    await openInfo(tester, 'Friends');
    expect(find.text(strings.members), findsOneWidget);
    expect(find.text(strings.ownerLabel), findsOneWidget);

    await tester.tap(find.byTooltip(strings.removeMember));
    await tester.pumpAndSettle();
    expect(find.text(strings.removeMemberConfirmTitle('Bob')), findsOneWidget);
    await confirm(tester, strings.removeMember);
    expect(session.removedMembers[friends], [bob]);
    expect(find.byTooltip(strings.removeMember), findsNothing);

    await tester.tap(find.text(strings.deleteGroup));
    await tester.pumpAndSettle();
    await confirm(tester, strings.deleteGroup);
    expect(session.deletedChats, [friends]);
    expect(find.text(strings.chatListTitle), findsOneWidget);
  });

  testWidgets('a refusal shows and keeps the chat', (tester) async {
    session.failDeleteChat = const ServerException(403, 'forbidden');
    await openInfo(tester, 'Bob');

    await tester.tap(find.text(strings.deleteChat));
    await tester.pumpAndSettle();
    await confirm(tester, strings.deleteChat);

    expect(find.byType(ChatInfoScreen), findsOneWidget);
    expect(find.text(strings.rejected), findsOneWidget);
  });

  testWidgets('an open chat that is gone says so, without a composer', (
    tester,
  ) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    session.emitPresence(
      const PresMessage(
        topic: 'me',
        event: PresenceEvent.gone,
        source: friends,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.chatGone), findsOneWidget);
    expect(find.text(strings.retry), findsNothing);
    expect(find.text(strings.messageHint), findsNothing);
  });
}
