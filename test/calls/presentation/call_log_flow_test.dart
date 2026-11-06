import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_network_monitor.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

/// The bug this all came from, as a user meets it: calls gone after logging
/// out and back in. Real taps on the real screens.
void main() {
  late List<Subscription> chats;
  late Map<String, List<DataMessage>> histories;
  late MemoryChatStoreOpener stores;
  late List<FakeTinodeSession> links;
  late List<FakeTinodeSession> opened;

  FakeTinodeSession link() =>
      FakeTinodeSession(chats: chats, histories: histories);

  setUp(() {
    stores = MemoryChatStoreOpener();
    opened = [];
    chats = [
      chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2)),
      chat(carol, name: 'Carol', lastSeq: 4, read: 4, lastMessageAt: at(4)),
    ];
    histories = {
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
    };
    links = [link(), link(), link()];
  });

  Future<FakeTinodeSession> connect(TinodeConfig _) async {
    final next = links.removeAt(0);
    opened.add(next);
    return next;
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(HomeTabBar), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester, {FakeTinodeSession? session}) =>
      pumpTinodeChat(
        tester,
        session ?? links.first,
        connector: connect,
        credentials: TinodeCredentials.token(links.first.token),
        storeOpener: stores,
        tabBar: true,
      );

  Future<void> logOut(WidgetTester tester) async {
    await tab(tester, strings.settingsTitle);
    await tester.tap(find.text(strings.account));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.logOut));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  Future<void> logIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'alice');
    await tester.enterText(find.byType(TextField).last, 'alice123');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);
  }

  void expectBothCalls(WidgetTester tester) {
    final rows = tester.widgetList<CallHistoryTile>(
      find.byType(CallHistoryTile),
    );
    expect(rows.map((r) => r.id.topic), [carol, bob]);
    Finder inRow(String name, String text) => find.descendant(
      of: find.ancestor(
        of: find.text(name),
        matching: find.byType(CallHistoryTile),
      ),
      matching: find.text(text),
    );
    expect(
      inRow('Bob', '${strings.voiceCall} · ${strings.callMissed}'),
      findsOneWidget,
    );
    expect(inRow('Carol', '${strings.videoCall} · 4:00'), findsOneWidget);
    const icons = TinodeChatIcons();
    expect(find.byIcon(icons.missedCall), findsOneWidget);
    expect(find.byIcon(icons.outgoingCall), findsOneWidget);
  }

  testWidgets('the calls are all there after logging out and in', (
    tester,
  ) async {
    await start(tester);
    await tab(tester, strings.callsTitle);
    expectBothCalls(tester);

    await logOut(tester);
    final hold = Completer<void>();
    addTearDown(hold.complete);
    links.first.holdHistory = hold;
    await logIn(tester);
    await tab(tester, strings.callsTitle);

    // The server hasn't answered a single page: they came from the device.
    expectBothCalls(tester);
  });

  testWidgets('and survive the server sending far fewer of them', (
    tester,
  ) async {
    await start(tester);
    await tab(tester, strings.callsTitle);
    expectBothCalls(tester);

    await logOut(tester);
    histories[bob] = [for (var seq = 3; seq <= 60; seq++) message(bob, seq)];
    await logIn(tester);
    await tab(tester, strings.callsTitle);

    expectBothCalls(tester);
  });

  testWidgets('a call while the tab shows joins the list at the top', (
    tester,
  ) async {
    await start(tester);
    final session = opened.single;
    await tab(tester, strings.callsTitle);

    session.emitMessage(callMessage(bob, 8));
    await tester.pumpAndSettle();

    final rows = tester.widgetList<CallHistoryTile>(
      find.byType(CallHistoryTile),
    );
    expect(rows.map((r) => (r.id.topic, r.id.seq)), [
      (bob, 8),
      (carol, 3),
      (bob, 1),
    ]);
  });

  testWidgets('the calls show on a start with no network', (tester) async {
    await start(tester);
    await tab(tester, strings.callsTitle);
    expectBothCalls(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final offline = links.first..reachable = false;
    await pumpTinodeChat(
      tester,
      offline,
      connector: connect,
      credentials: TinodeCredentials.token(offline.token),
      storeOpener: stores,
      network: FakeNetworkMonitor(),
      tabBar: true,
    );
    // Frames, not settling: the title spins while the link is down.
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.callsTitle),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expectBothCalls(tester);
    expect(offline.calls, isNot(contains(startsWith('history'))));
  });

  testWidgets('a chat deleted leaves the list at once', (tester) async {
    await start(tester);
    final session = opened.single;
    await tab(tester, strings.callsTitle);
    expectBothCalls(tester);

    session
      ..chats.removeWhere((c) => c.topic == bob)
      ..emitPresence(
        const PresMessage(topic: 'me', event: PresenceEvent.gone, source: bob),
      );
    await tester.pumpAndSettle();

    final rows = tester.widgetList<CallHistoryTile>(
      find.byType(CallHistoryTile),
    );
    expect(rows.map((r) => r.id.topic), [carol]);
  });

  testWidgets('deleting the account leaves nothing for the next login', (
    tester,
  ) async {
    await start(tester);
    await tab(tester, strings.callsTitle);
    expectBothCalls(tester);
    chats.clear();
    histories.clear();

    await tab(tester, strings.settingsTitle);
    await tester.tap(find.text(strings.account));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.deleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(strings.deleteAccount),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await logIn(tester);
    await tab(tester, strings.callsTitle);

    expect(find.byType(CallHistoryTile), findsNothing);
    expect(find.text(strings.noCalls), findsOneWidget);
  });
}
