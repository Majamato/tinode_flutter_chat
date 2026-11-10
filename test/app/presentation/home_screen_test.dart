import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_unread_badge.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/calls_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/settings_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 5, read: 2, lastMessageAt: at(5)),
        chat(carol, name: 'Carol', lastSeq: 9, lastMessageAt: at(4)),
        // Muted: its unread messages don't count on the tab.
        chat(
          friends,
          name: 'Friends',
          lastSeq: 7,
          lastMessageAt: at(3),
          want: 'JRWS',
        ),
      ],
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    TinodeChatFeatures features = const TinodeChatFeatures(),
    TinodeChatController? controller,
  }) => pumpTinodeChat(
    tester,
    session,
    credentials: TinodeCredentials.token(session.token),
    tabBar: true,
    features: features,
    controller: controller,
  );

  Finder tab(String label) =>
      find.descendant(of: find.byType(HomeTabBar), matching: find.text(label));

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(tab(label));
    await tester.pumpAndSettle();
  }

  testWidgets('the chats, calls and settings tabs, chats first', (
    tester,
  ) async {
    await pump(tester);

    expect(tab(strings.chatListTitle), findsOneWidget);
    expect(tab(strings.callsTitle), findsOneWidget);
    expect(tab(strings.settingsTitle), findsOneWidget);
    expect(find.byType(ChatListScreen), findsOneWidget);
    // The settings left the header for their tab.
    expect(find.byType(PopupMenuButton<void>), findsNothing);

    await openTab(tester, strings.settingsTitle);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(ChatListScreen, skipOffstage: false), findsOneWidget);
    // Calls was never shown, so it isn't built.
    expect(find.byType(CallsScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('without calls there is no calls tab', (tester) async {
    await pump(
      tester,
      features: const TinodeChatFeatures(voiceCalls: false, videoCalls: false),
    );

    expect(tab(strings.callsTitle), findsNothing);
    expect(tab(strings.settingsTitle), findsOneWidget);
  });

  testWidgets('the chats tab counts unread messages of chats not muted', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.descendant(
        of: find.byType(HomeUnreadBadge),
        matching: find.text('12'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a hidden tab keeps its state, its tickers off', (tester) async {
    await pump(tester);
    final list = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(list).position;

    await openTab(tester, strings.settingsTitle);

    final chats = find.byType(ChatListScreen, skipOffstage: false);
    expect(TickerMode.valuesOf(tester.element(chats)).enabled, isFalse);
    expect(
      TickerMode.valuesOf(tester.element(find.byType(SettingsScreen))).enabled,
      isTrue,
    );

    await openTab(tester, strings.chatListTitle);

    expect(tester.state<ScrollableState>(list).position, same(position));
    expect(TickerMode.valuesOf(tester.element(chats)).enabled, isTrue);
  });

  testWidgets('back goes to the chats first', (tester) async {
    await pump(tester);
    await openTab(tester, strings.settingsTitle);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.byType(ChatListScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('a chat the host opens shows over the chats tab', (tester) async {
    final controller = TinodeChatController();
    await pump(tester, controller: controller);
    await openTab(tester, strings.settingsTitle);

    controller.openChat(bob);
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ChatListScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('the bar floats 16 px from the sides, with no floating button', (
    tester,
  ) async {
    await pump(tester);

    final screen = tester.getRect(find.byType(ChatListScreen));
    final bar = tester.getRect(find.byType(HomeTabBar));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(bar.left - screen.left, 16);
    // No system inset: 12 px from the edge, where the app ends.
    expect(screen.bottom - bar.bottom, 12);
  });

  testWidgets(
    'over an iOS home indicator the bar sits 8 px from the edge',
    (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 102);
      tester.view.viewPadding = const FakeViewPadding(bottom: 102);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await pump(tester);

      final screen = tester.getRect(find.byType(ChatListScreen));
      final bar = tester.getRect(find.byType(HomeTabBar));
      expect(screen.bottom - bar.bottom, 8);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('elsewhere the bar floats 12 px over the system bottom inset', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 144);
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await pump(tester);

    final screen = tester.getRect(find.byType(ChatListScreen));
    final bar = tester.getRect(find.byType(HomeTabBar));
    expect(screen.bottom - bar.bottom, 48 + 12);
  });

  testWidgets('screen readers hear the tabs and which one is current', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    final chats = tester.getSemantics(tab(strings.chatListTitle));
    expect(chats.getSemanticsData().role, SemanticsRole.tab);
    expect(chats.flagsCollection.isSelected, Tristate.isTrue);
    expect(chats.label, contains(strings.unreadCount(12)));
    expect(
      tester
          .getSemantics(tab(strings.settingsTitle))
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    semantics.dispose();
  });

  testWidgets('the lens slides to the picked tab', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
      reduceMotion: false,
    );
    Rect lens() => tester.getRect(
      find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(DecoratedBox),
      ),
    );
    final start = lens();

    await tester.tap(tab(strings.settingsTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final moving = lens();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(moving.left, greaterThan(start.left));
    expect(
      lens().center.dx,
      closeTo(tester.getCenter(tab(strings.settingsTitle)).dx, 1),
    );
  });

  testWidgets('without the tab bar the header keeps the menu', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    expect(find.byType(HomeTabBar), findsNothing);
    expect(find.byType(PopupMenuButton<void>), findsOneWidget);
  });
}
