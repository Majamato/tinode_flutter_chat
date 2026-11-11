import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart' show Subscription;
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_back_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_header.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/composer_dock.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_header.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/edge_fade.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/recording_panel.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

/// The glass app bar and composer float over the content: the [Scaffold]
/// hands their heights to the content as padding, whatever bar the host
/// brings, and all the glass of a screen shares one backdrop.
void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2)),
      ],
      histories: {
        bob: [
          message(bob, 1, text: 'hi'),
          message(bob, 2, from: alice, text: 'hello'),
        ],
      },
    );
  });

  Future<void> openBob(
    WidgetTester tester, {
    TinodeAppBarBuilder? appBarBuilder,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      theme: TinodeChatTheme.materialTheme(),
      appBarBuilder: appBarBuilder,
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
  }

  /// The padding the messages scroll within.
  EdgeInsets listPadding(WidgetTester tester) =>
      tester.widget<SuperListView>(find.byType(SuperListView)).padding!
          as EdgeInsets;

  testWidgets('the messages run under both bars, padded by their heights', (
    tester,
  ) async {
    await openBob(tester);

    expect(tester.getTopLeft(find.byType(SuperListView)).dy, 0);
    expect(
      tester.getBottomLeft(find.byType(SuperListView)).dy,
      tester.getBottomLeft(find.byType(ComposerDock)).dy,
    );
    expect(
      listPadding(tester).top,
      tester.getSize(find.byType(ChatHeader)).height + 4,
    );
    expect(
      listPadding(tester).bottom,
      tester.getSize(find.byType(ComposerDock)).height + 12,
    );
  });

  testWidgets('the composer rises with the keyboard, and the messages '
      'with it', (tester) async {
    await openBob(tester);
    final before = tester.getSize(find.byType(ComposerDock)).height;

    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final dock = tester.getSize(find.byType(ComposerDock)).height;
    // 8 px above the keyboard instead of 8 px above the screen's edge.
    expect(dock, before + 300);
    expect(listPadding(tester).bottom, dock + 12);
    expect(tester.getBottomLeft(find.byType(ComposerDock)).dy, 600);
  });

  testWidgets('the messages make room for the recording panel in the same '
      'frame', (tester) async {
    await openBob(tester);
    final before = tester.getSize(find.byType(ComposerDock)).height;

    await tester.tap(find.byTooltip('Record voice message'));
    await tester.pump();

    expect(find.byType(RecordingPanel), findsOneWidget);
    final dock = tester.getSize(find.byType(ComposerDock)).height;
    expect(dock, greaterThan(before));
    expect(listPadding(tester).bottom, dock + 12);
  });

  testWidgets("all of a screen's glass shares its backdrop group", (
    tester,
  ) async {
    await openBob(tester);

    final group = tester.widget<BackdropGroup>(find.byType(BackdropGroup));
    final filters = tester
        .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
        .toList();
    // Back, title, the search and calls island, attach, field, send.
    expect(filters.length, greaterThanOrEqualTo(6));
    for (final filter in filters) {
      expect(filter.backdropKey, same(group.backdropKey));
    }
  });

  testWidgets("a host's bar replaces the chat's, and the messages start "
      'below it', (tester) async {
    final screens = <TinodeScreen>[];
    await openBob(
      tester,
      appBarBuilder: (context, screen, defaultAppBar) {
        screens.add(screen);
        return switch (screen) {
          TinodeChatScreen() => PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: Text('Host bar')),
            ),
          ),
          _ => defaultAppBar,
        };
      },
    );

    expect(screens, contains(const TinodeChatScreen(bob)));
    expect(screens, contains(const TinodeChatListScreen()));
    expect(find.text('Host bar'), findsOneWidget);
    expect(find.byType(ChatHeader), findsNothing);
    expect(listPadding(tester).top, 100 + 4);
  });

  testWidgets('a host may wrap the default bar', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      appBarBuilder: (context, screen, defaultAppBar) => PreferredSize(
        preferredSize: defaultAppBar.preferredSize,
        child: KeyedSubtree(
          key: const ValueKey('wrapped'),
          child: defaultAppBar,
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('wrapped')),
        matching: find.byType(ChatListHeader),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a tap on the app bar between its buttons never reaches what '
      'scrolled under it', (tester) async {
    session = FakeTinodeSession(
      chats: [
        for (var i = 0; i < 20; i++)
          chat('grp$i', name: 'Chat $i', lastMessageAt: at(100 - i)),
      ],
    );
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Between the title and the compose button, over a chat's row.
    final bar = tester.getRect(find.byType(ChatListHeader));
    final point = Offset(bar.right - 80, bar.top + 28);
    final under = find
        .byType(ChatListTile)
        .evaluate()
        .where(
          (row) => tester.getRect(find.byWidget(row.widget)).contains(point),
        );
    expect(under, isNotEmpty);

    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);
  });

  testWidgets('a long press on the composer between its buttons never '
      'reaches a message under it', (tester) async {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 30, read: 30, lastMessageAt: at(30)),
      ],
      histories: {
        bob: [for (var i = 1; i <= 30; i++) message(bob, i, text: 'm$i')],
      },
    );
    await openBob(tester);
    // Older messages up, slowly so it stays: the newest slide under the
    // composer.
    await tester.timedDrag(
      find.byType(SuperListView),
      const Offset(0, 80),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    // Between the attach button and the field, over a message.
    final attach = tester.getRect(find.byTooltip('Attach'));
    final point = Offset(attach.right + 4, attach.center.dy);
    expect(
      find
          .byType(MessageBubble)
          .evaluate()
          .any(
            (bubble) =>
                tester.getRect(find.byWidget(bubble.widget)).contains(point),
          ),
      isTrue,
    );

    await tester.longPressAt(point);
    await tester.pumpAndSettle();
    // A long press on a message opens its actions.
    expect(find.byType(BottomSheet), findsNothing);
  });

  /// How far down the top fade on [screen] stays solid.
  double solidFadeOf(WidgetTester tester, Finder screen) {
    final fade = find.descendant(of: screen, matching: find.byType(EdgeFade));
    return tester.widget<EdgeFade>(fade.first).solid *
        tester.getSize(fade.first).height;
  }

  testWidgets('a plain title reads on a solid fade; the chat lets its '
      'messages show behind its name pill', (tester) async {
    await openBob(tester);
    final chatBar = find.byType(ChatHeader);
    // Solid under the status bar only (none in tests).
    expect(solidFadeOf(tester, chatBar), 0);

    await tester.tap(find.byType(ChatBackButton));
    await tester.pumpAndSettle();
    final listBar = find.byType(ChatListHeader);
    final title = tester.getRect(
      find.descendant(of: listBar, matching: find.text('Chats')),
    );
    expect(solidFadeOf(tester, listBar), greaterThanOrEqualTo(title.bottom));
    // It eases out below the bar, and only the bar takes touches.
    final fade = find.descendant(of: listBar, matching: find.byType(EdgeFade));
    expect(tester.getRect(fade).bottom, tester.getRect(listBar).bottom + 16);
  });

  testWidgets('an opaque bar is solid down to its edge and paints nothing '
      'past it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: TinodeAppBar(
            title: Text('Photo'),
            fadeColor: Colors.black,
            opaque: true,
          ),
          body: SizedBox.expand(),
        ),
      ),
    );
    final bar = find.byType(TinodeAppBar);
    expect(
      find.descendant(of: bar, matching: find.byType(EdgeFade)),
      findsNothing,
    );
    final fill = find.descendant(of: bar, matching: find.byType(ColoredBox));
    expect(tester.widget<ColoredBox>(fill.first).color, Colors.black);
    expect(tester.getRect(fill.first), tester.getRect(bar));
  });

  /// Whether a chat's row covers [point].
  bool rowAt(WidgetTester tester, Offset point) => find
      .byType(ChatListTile)
      .evaluate()
      .any((row) => tester.getRect(find.byWidget(row.widget)).contains(point));

  /// The fade at the bottom of the chat list, if any.
  Finder bottomFade() => find.descendant(
    of: find.byType(ChatListScreen),
    matching: find.byWidgetPredicate(
      (w) => w is EdgeFade && w.edge == VerticalDirection.down,
    ),
  );

  List<Subscription> manyChats() => [
    for (var i = 0; i < 20; i++)
      chat('grp$i', name: 'Chat $i', lastMessageAt: at(100 - i)),
  ];

  testWidgets('chats scroll under the tab bar behind a light veil, and '
      'never take a tap beside or below it', (tester) async {
    session = FakeTinodeSession(chats: manyChats());
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
    );

    final bar = tester.getRect(find.byType(HomeTabBar));
    final screen = tester.getRect(find.byType(ChatListScreen));
    // From the screen's edge, never solid, to clear at the bar's top.
    final veil = tester.widget<EdgeFade>(bottomFade());
    final veilRect = tester.getRect(bottomFade());
    expect(veilRect.bottom, screen.bottom);
    expect(veilRect.top, bar.top);
    expect(veil.solid, 0);
    expect(veil.color.a, lessThan(1));

    for (final point in [
      Offset(bar.left / 2, bar.center.dy),
      Offset(bar.center.dx, (bar.bottom + screen.bottom) / 2),
    ]) {
      expect(rowAt(tester, point), isTrue);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsNothing);
    }

    // Just above the bar's room, a row opens.
    final above = Offset(bar.center.dx, bar.top - 4);
    expect(rowAt(tester, above), isTrue);
    await tester.tapAt(above);
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets("without the tab bar, the chats fade under the system's bars "
      'and never take a tap through them', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 144);
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    session = FakeTinodeSession(chats: manyChats());
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    final screen = tester.getRect(find.byType(ChatListScreen));
    final fadeRect = tester.getRect(bottomFade());
    expect(fadeRect.bottom, screen.bottom);
    expect(fadeRect.height, 48);

    final under = Offset(screen.center.dx, fadeRect.center.dy);
    expect(rowAt(tester, under), isTrue);
    await tester.tapAt(under);
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);
  });
}
