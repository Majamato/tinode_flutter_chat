import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/older_messages_indicator.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/skeleton_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_skeleton.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_tile.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/presentation/connecting_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../../support/fake_tinode_session.dart';
import '../../../support/fixtures.dart';
import '../../../support/pump_tinode_chat.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [chat(bob, name: 'Bob', lastSeq: 60, read: 60)],
      histories: {
        bob: [for (var seq = 1; seq <= 60; seq++) message(bob, seq)],
      },
    );
  });

  Future<void> pump(WidgetTester tester, {SessionConnector? connector}) =>
      pumpTinodeChat(
        tester,
        session,
        connector: connector,
        credentials: TinodeCredentials.token(session.token),
        theme: TinodeChatTheme.materialTheme(),
      );

  Finder spinner() => find.byType(CircularProgressIndicator);

  testWidgets('connecting shows the chat list skeleton, then the chats', (
    tester,
  ) async {
    final hold = Completer<void>();
    await pump(
      tester,
      connector: (config) async {
        await hold.future;
        return connectTo(session)(config);
      },
    );

    expect(find.byType(ConnectingView), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
    expect(find.byType(ChatListSkeleton), findsOneWidget);
    expect(spinner(), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ConnectingView), findsNothing);
    expect(find.byType(ChatListTile), findsOneWidget);
  });

  testWidgets('the chat list shows its skeleton until the chats come', (
    tester,
  ) async {
    final hold = session.holdChatList = Completer();
    await pump(tester);

    expect(find.byType(ChatListSkeleton), findsOneWidget);
    expect(spinner(), findsNothing);
    // Rows as tall as the chats', starting under the app bar.
    final first = tester.getRect(
      find
          .descendant(
            of: find.byType(ChatListSkeleton),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(first.top, greaterThan(0));

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ChatListSkeleton), findsNothing);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('a chat shows its bubbles as bones until its messages come', (
    tester,
  ) async {
    // Before the list, which would put the newest messages on the device.
    final hold = session.holdHistory = Completer();
    await pump(tester);
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatSkeleton), findsOneWidget);
    expect(spinner(), findsNothing);
    // No wider than a bubble grows.
    final width = tester.getSize(find.byType(ChatSkeleton)).width;
    final bones = find.descendant(
      of: find.byType(SkeletonBubble),
      matching: find.byType(SkeletonBone),
    );
    expect(bones, findsWidgets);
    for (final bone in bones.evaluate()) {
      expect(bone.size!.width, lessThanOrEqualTo(width * 0.78));
    }
    // Both sides, as a conversation.
    final sides = tester
        .widgetList<SkeletonBubble>(find.byType(SkeletonBubble))
        .map((b) => b.own)
        .toSet();
    expect(sides, {true, false});

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ChatSkeleton), findsNothing);
    expect(find.byType(MessageBubble), findsWidgets);
  });

  testWidgets('older messages show bubble bones above the oldest', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    final hold = session.holdHistory = Completer();
    await tester.fling(
      find.byType(MessageBubble).first,
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();
    final older = find.descendant(
      of: find.byType(OlderMessagesIndicator),
      matching: find.byType(SkeletonBubble),
    );
    expect(older, findsNWidgets(3));
    expect(spinner(), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(older, findsNothing);
  });

  testWidgets('people search shows result row bones until it answers', (
    tester,
  ) async {
    session.found['bob,basic:bob'] = [
      const FoundTopic(
        topic: bob,
        public: Profile(name: 'Bob'),
      ),
    ];
    await pump(tester);
    await tester.tap(find.byTooltip(const TinodeChatStrings().newChat));
    await tester.pumpAndSettle();
    final hold = session.holdFind = Completer();
    await tester.enterText(
      find.descendant(
        of: find.byType(FindPeopleScreen),
        matching: find.byType(TextField),
      ),
      'bob',
    );
    await tester.pump(findDebounce);
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultSkeleton), findsOneWidget);
    expect(spinner(), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SearchResultSkeleton), findsNothing);
    expect(find.byType(SearchResultTile), findsOneWidget);
  });
}
