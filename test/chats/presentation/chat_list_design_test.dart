import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_online_dot.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_unread_badge.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const icons = TinodeChatIcons();

void main() {
  const strings = TinodeChatStrings();
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(
          bob,
          name: 'Bob',
          lastSeq: 2,
          read: 2,
          lastMessageAt: at(2),
          online: true,
        ),
        chat(
          friends,
          name: 'Friends',
          lastSeq: 5,
          read: 1,
          lastMessageAt: at(1),
          want: 'JRWS',
        ),
      ],
    );
  });

  Future<void> pumpList(WidgetTester tester) => pumpTinodeChat(
    tester,
    session,
    credentials: TinodeCredentials.token(session.token),
    theme: TinodeChatTheme.materialTheme(),
  );

  Finder dotOf(String topic) => find.descendant(
    of: find.byWidgetPredicate((w) => w is ChatOnlineDot && w.topic == topic),
    matching: find.byType(Container),
  );

  testWidgets('a direct chat online has the dot, until pres off', (
    tester,
  ) async {
    await pumpList(tester);
    expect(dotOf(bob), findsOneWidget);
    expect(dotOf(friends), findsNothing);

    session.emitPresence(
      const PresMessage(topic: 'me', event: PresenceEvent.offline, source: bob),
    );
    await tester.pump();
    expect(dotOf(bob), findsNothing);
  });

  testWidgets('a muted chat has the icon and a grey badge', (tester) async {
    await pumpList(tester);

    expect(find.byIcon(icons.muted), findsOneWidget);
    final badge = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChatUnreadBadge),
        matching: find.byType(Container),
      ),
    );
    final context = tester.element(find.byType(ChatUnreadBadge).first);
    expect(
      (badge.decoration! as ShapeDecoration).color,
      TinodeChatTheme.of(context).mutedBadgeColor,
    );
    // Unread but not cached here.
    expect(find.text(strings.newMessageArrived), findsOneWidget);
  });

  testWidgets('the newest message is the preview: text, then a missed call', (
    tester,
  ) async {
    await pumpList(tester);

    session.emitMessage(message(bob, 3, text: 'see you'));
    await tester.pumpAndSettle();
    expect(find.text('see you'), findsOneWidget);

    session.emitMessage(
      DataMessage(
        topic: bob,
        seq: 4,
        from: bob,
        time: at(4),
        head: const MessageHead(callState: CallState.missed, audioOnly: true),
        content: DraftyContent(Drafty.videoCall(audioOnly: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('see you'), findsNothing);
    expect(find.text(strings.missedVoiceCall), findsOneWidget);
  });

  testWidgets('the search field opens the people search', (tester) async {
    await pumpList(tester);

    await tester.tap(find.text(strings.searchChats));
    await tester.pumpAndSettle();
    expect(find.byType(FindPeopleScreen), findsOneWidget);
  });

  testWidgets('the chats scroll under the app bar, starting below it', (
    tester,
  ) async {
    await pumpList(tester);

    expect(
      tester.getTopLeft(find.byType(ChatListTile).first).dy,
      tester.getBottomLeft(find.byType(ChatListHeader)).dy,
    );
    expect(
      tester
          .getTopLeft(
            find.descendant(
              of: find.byType(ChatListScreen),
              matching: find.byType(ListView),
            ),
          )
          .dy,
      0,
    );
  });

  testWidgets('a link down for a second turns "Chats" into reconnecting, '
      'with the bar and the list where they were', (tester) async {
    await pumpList(tester);
    final header = tester.getRect(find.byType(ChatListHeader));
    final screen = tester.getRect(find.byType(ChatListScreen));

    session.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(strings.reconnecting), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    final title = find.descendant(
      of: find.byType(ChatListHeader),
      matching: find.text(strings.reconnecting),
    );
    expect(title, findsOneWidget);
    expect(find.text(strings.chatListTitle), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ChatListHeader),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.getRect(find.byType(ChatListHeader)), header);
    expect(tester.getRect(find.byType(ChatListScreen)), screen);

    session.emitStatus(const Connected());
    await tester.pumpAndSettle();
    expect(find.text(strings.reconnecting), findsNothing);
    expect(find.text(strings.chatListTitle), findsOneWidget);
  });
}
