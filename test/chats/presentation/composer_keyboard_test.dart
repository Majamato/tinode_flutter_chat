import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, read: 1, lastMessageAt: at(1)),
      ],
      histories: {
        bob: [message(bob, 1, text: 'Hi Alice')],
      },
    );
  });

  /// Opens Bob's chat with the keyboard up.
  Future<void> typeInBob(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  }

  testWidgets('a tap on a message closes the keyboard', (tester) async {
    await typeInBob(tester);

    await tester.tap(find.text('Hi Alice'));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a scroll over the messages closes the keyboard', (tester) async {
    await typeInBob(tester);

    await tester.drag(find.text('Hi Alice'), const Offset(0, 100));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('sending leaves the keyboard open', (tester) async {
    await typeInBob(tester);

    await tester.enterText(find.byType(TextField), 'Yes!');
    await tester.pump(); // The send button enables on the next frame.
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Yes!'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('a tap on the header closes the keyboard for good', (
    tester,
  ) async {
    await typeInBob(tester);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Hi Alice'), findsOneWidget, reason: 'back in the chat');
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
