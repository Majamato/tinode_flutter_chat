import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/message_bubble.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/reveal_highlight.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/search/application/message_search_controller.dart';
import 'package:tinode_flutter_chat/src/search/presentation/found_message_tile.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';
import '../../support/test_container.dart';

const strings = TinodeChatStrings();

String textOf(int seq) => seq == 5 ? 'the secret recipe' : 'message $seq';

void main() {
  late FakeTinodeSession session;
  late MemoryChatStoreOpener stores;

  setUp(() async {
    final history = [
      for (var seq = 1; seq <= 100; seq++) message(bob, seq, text: textOf(seq)),
    ];
    session = FakeTinodeSession(
      chats: [chat(bob, name: 'Bob', lastSeq: 100, read: 100)],
      histories: {bob: history},
    );
    // Bob's whole chat is on the device, as after scrolling through it.
    stores = MemoryChatStoreOpener();
    final store = await stores.open(testConfig.server, alice);
    await store.replaceChats([chat(bob, name: 'Bob', lastSeq: 100)]);
    await store.putMessages(bob, history, covering: const SeqRange(1, 101));
  });

  Future<void> pump(WidgetTester tester) => pumpTinodeChat(
    tester,
    session,
    storeOpener: stores,
    credentials: TinodeCredentials.token(session.token),
  );

  Future<void> search(WidgetTester tester, String input) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(MessageSearchScreen),
        matching: find.byType(TextField),
      ),
      input,
    );
    await tester.pump(messageSearchDebounce);
    await tester.pumpAndSettle();
  }

  bool highlighted(WidgetTester tester, int seq) {
    final band = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is RevealHighlight && w.seq == seq),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return (band.decoration as BoxDecoration?)?.color != Colors.transparent;
  }

  Future<void> openSearch(WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(strings.searchInChat));
    await tester.pumpAndSettle();
    expect(find.text(strings.messageSearchIdle), findsOneWidget);
  }

  testWidgets('a message found in the chat shows back in the chat', (
    tester,
  ) async {
    await openSearch(tester);
    // Only the newest messages are loaded: the found one is far older.
    expect(
      find.byWidgetPredicate((w) => w is MessageBubble && w.seq == 5),
      findsNothing,
    );

    await search(tester, 'recip');
    expect(find.byType(FoundMessageTile), findsOneWidget);
    await search(tester, 'nothing like it');
    expect(find.text(strings.noMessagesFound), findsOneWidget);
    await search(tester, 'secret');
    await tester.tap(find.byType(FoundMessageTile));
    await tester.pumpAndSettle();

    expect(find.byType(MessageSearchScreen), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);
    final bubble = find.byWidgetPredicate(
      (w) => w is MessageBubble && w.seq == 5,
    );
    expect(bubble, findsOneWidget);
    expect(
      tester.getRect(bubble).overlaps(tester.getRect(find.byType(ChatScreen))),
      isTrue,
    );
    expect(find.text('the secret recipe'), findsOneWidget);
    expect(highlighted(tester, 5), isTrue);

    // The highlight fades after a while.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(highlighted(tester, 5), isFalse);
  });

  testWidgets('the chat list searches people and groups', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip(strings.findPeople));
    await tester.pumpAndSettle();

    expect(find.byType(FindPeopleScreen), findsOneWidget);
    expect(find.byType(MessageSearchScreen), findsNothing);
  });
}
