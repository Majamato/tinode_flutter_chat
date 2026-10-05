import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/read_only_notice.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 2, read: 1, lastMessageAt: at(2)),
        chat(channel, name: 'News', lastSeq: 1, read: 1, mode: 'JRP'),
      ],
      histories: {
        bob: [
          message(bob, 1, text: 'Hi Alice'),
          message(bob, 2, text: 'Are you there?'),
        ],
        channel: [message(channel, 1, from: null, text: 'Welcome')],
      },
    );
  });

  testWidgets('logs in with the built-in form', (tester) async {
    LoginResult? loggedIn;
    await pumpTinodeChat(tester, session, onLoggedIn: (r) => loggedIn = r);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'alice');
    await tester.enterText(find.byType(TextField).last, 'wrong');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Wrong login or password.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'alice123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(loggedIn?.token, session.token);
  });

  testWidgets('a rejected token shows the login form with the reason', (
    tester,
  ) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: const TinodeCredentials.token('expired'),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Wrong login or password.'), findsOneWidget);
  });

  testWidgets('opens a chat, sends and receives messages', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    expect(find.text('1'), findsOneWidget); // Bob's unread badge.

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text('Hi Alice'), findsOneWidget);
    expect(find.text('Are you there?'), findsOneWidget);
    expect(session.calls, contains('markRead $bob 2'));

    await tester.enterText(find.byType(TextField), 'Yes!');
    await tester.pump(); // The send button enables on the next frame.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Yes!'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );

    session.emitMessage(message(bob, 4, text: 'Great'));
    await tester.pumpAndSettle();
    expect(find.text('Great'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(session.calls, contains('detach $bob'));
  });

  testWidgets('a failed send keeps the text and shows why', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    session.failPublish = const ServerException(403, 'denied');

    await tester.enterText(find.byType(TextField), 'Hello?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('The chat server refused the request.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Hello?',
    );
  });

  testWidgets('channel followers see a read-only notice', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byType(ReadOnlyNotice), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a dropped connection offers to reconnect', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    session.dropConnection();
    await tester.pumpAndSettle();

    expect(
      find.text('The connection to the chat server was lost.'),
      findsOneWidget,
    );
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Hi Alice'), findsNothing);
  });

  testWidgets('removing the widget closes the session', (tester) async {
    await pumpTinodeChat(tester, session);

    await tester.pumpWidget(const SizedBox());

    expect(session.isClosed, isTrue);
  });
}
