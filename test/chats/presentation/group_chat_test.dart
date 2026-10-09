import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/sender_avatar.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

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
      member(bob, name: 'Bob', read: 2, received: 2),
      member(carol, name: 'Carol', read: 3, received: 3),
    ];
  });

  Future<void> openFriends(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
  }

  void emitMarker(InfoEvent event, String from, int seq) => session.emitInfo(
    InfoMessage(topic: friends, event: event, from: from, seq: seq),
  );

  testWidgets('names a sender once per run, with the avatar at its end', (
    tester,
  ) async {
    await openFriends(tester);

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);
    // Bob's run and Carol's: an avatar each, beside 'two' and 'three'.
    final avatars = find.descendant(
      of: find.byType(SenderAvatar),
      matching: find.byType(CircleAvatar),
    );
    expect(avatars, findsNWidgets(2));
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('own ticks follow the members, rebuilding only the footer', (
    tester,
  ) async {
    await openFriends(tester);
    expect(find.byIcon(Icons.done), findsOneWidget);

    emitMarker(InfoEvent.received, bob, 4);
    emitMarker(InfoEvent.received, carol, 4);
    await tester.pump();
    expect(find.byIcon(Icons.done_all), findsOneWidget);

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, _) =>
        rebuilt.add(element.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    emitMarker(InfoEvent.read, bob, 4);
    emitMarker(InfoEvent.read, carol, 4);
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
    expect(icon.semanticLabel, 'Read');
    expect(rebuilt, contains('MessageFooter'));
    expect(
      rebuilt.where(
        {'MessageBubble', 'MessageList', 'SenderName', 'SenderAvatar'}.contains,
      ),
      isEmpty,
    );
  });

  testWidgets('read by lists who read and who only received', (tester) async {
    await openFriends(tester);
    emitMarker(InfoEvent.read, carol, 4);
    emitMarker(InfoEvent.received, bob, 4);

    await tester.longPress(find.text('mine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read by'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Read by')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Carol')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Delivered to')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Bob')),
      findsOneWidget,
    );
  });

  testWidgets("others' messages offer no read by", (tester) async {
    await openFriends(tester);
    await tester.longPress(find.text('three'));
    await tester.pumpAndSettle();
    expect(find.text('Read by'), findsNothing);
  });

  testWidgets('says who is typing under the title', (tester) async {
    await openFriends(tester);
    session.emitInfo(
      const InfoMessage(topic: friends, event: InfoEvent.typing, from: bob),
    );
    await tester.pump();
    expect(find.text('Bob is typing…'), findsOneWidget);

    session.emitInfo(
      const InfoMessage(topic: friends, event: InfoEvent.typing, from: carol),
    );
    await tester.pump();
    expect(find.text('Bob and Carol are typing…'), findsOneWidget);

    await tester.pump(typingTimeout);
    expect(find.textContaining('typing'), findsNothing);
  });

  testWidgets('typing in the composer tells the members', (tester) async {
    await openFriends(tester);
    await tester.enterText(find.byType(TextField), 'h');
    expect(session.calls, contains('sendTyping $friends'));
  });
}
