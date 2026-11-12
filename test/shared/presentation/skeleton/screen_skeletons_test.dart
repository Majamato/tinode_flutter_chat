import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_skeleton.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_skeleton.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_skeleton.dart';
import 'package:tinode_flutter_chat/src/search/presentation/found_message_skeleton.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  Future<void> pumpSkeleton(
    WidgetTester tester,
    Widget skeleton, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TinodeChatTheme.materialTheme(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(body: skeleton),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The height of each row of [skeleton]'s list.
  double? rowHeightOf(WidgetTester tester, Type skeleton) => tester
      .widget<ListView>(
        find.descendant(
          of: find.byType(skeleton),
          matching: find.byType(ListView),
        ),
      )
      .itemExtent;

  for (final brightness in Brightness.values) {
    group('in ${brightness.name} mode', () {
      for (final (name, skeleton) in [
        ('chat list', const ChatListSkeleton()),
        ('chat', const ChatSkeleton()),
        ('calls history', const CallHistorySkeleton()),
        ('profile', const ProfileSkeleton()),
        ('people search', const SearchResultSkeleton()),
        ('message search', const FoundMessageSkeleton()),
      ]) {
        testWidgets('the $name skeleton lays out at phone width', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 640) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await pumpSkeleton(tester, skeleton, brightness: brightness);

          expect(tester.takeException(), isNull);
          expect(find.byType(SkeletonBone), findsWidgets);
        });
      }
    });
  }

  testWidgets('chat list rows are as tall as the chats', (tester) async {
    await pumpSkeleton(tester, const ChatListSkeleton());

    expect(rowHeightOf(tester, ChatListSkeleton), ChatListTile.height);
    // A screenful of them.
    expect(
      find.byWidgetPredicate((w) => w is SkeletonBone && w.width == 56),
      findsAtLeastNWidgets(5),
    );
  });

  testWidgets('calls history rows are as tall as the calls', (tester) async {
    await pumpSkeleton(tester, const CallHistorySkeleton());

    expect(rowHeightOf(tester, CallHistorySkeleton), CallHistoryTile.height);
    expect(
      find.byWidgetPredicate((w) => w is SkeletonBone && w.width == 48),
      findsAtLeastNWidgets(5),
    );
  });

  testWidgets('the profile skeleton has the photo, the field and the button', (
    tester,
  ) async {
    await pumpSkeleton(tester, const ProfileSkeleton());

    final sizes = tester
        .widgetList<SkeletonBone>(find.byType(SkeletonBone))
        .map((b) => (b.circle, b.width, b.height));
    expect(sizes, [
      (true, 96.0, 96.0),
      (false, null, 56.0),
      (false, null, 54.0),
    ]);
  });

  testWidgets('one message search row while more load', (tester) async {
    await pumpSkeleton(
      tester,
      const Column(children: [FoundMessageSkeleton(rows: 1), Text('below')]),
    );

    expect(
      find.descendant(
        of: find.byType(FoundMessageSkeleton),
        matching: find.byType(ListTile),
      ),
      findsOneWidget,
    );
    // Shrink-wrapped, so what follows it sits right under it.
    expect(
      tester.getTopLeft(find.text('below')).dy,
      tester.getBottomLeft(find.byType(FoundMessageSkeleton)).dy,
    );
  });
}
