import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/read_only_notice.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_network_monitor.dart';
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

  testWidgets('a refused message shows as not sent and can be retried', (
    tester,
  ) async {
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

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(find.text('Hello?'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.longPress(find.text('Hello?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('Hello?'), findsOneWidget);
    expect(
      session.calls.where((c) => c == 'publish $bob Hello?'),
      hasLength(2),
    );
  });

  testWidgets('offline, a message waits with a clock and goes out later', (
    tester,
  ) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    session.emitStatus(
      const Reconnecting(attempt: 1, retryIn: Duration(seconds: 5)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'See you');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('See you'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    session.emitStatus(const Connected());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.schedule), findsNothing);
    expect(find.text('See you'), findsOneWidget);
  });

  testWidgets('a long press deletes a message for me', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    final text = session.histories[bob]!.last.content.text;

    await tester.longPress(find.text(text));
    await tester.pumpAndSettle();
    expect(find.text('Delete for everyone'), findsNothing);
    await tester.tap(find.text('Delete for me'));
    await tester.pumpAndSettle();

    expect(find.text(text), findsNothing);
    expect(session.calls, contains(startsWith('delete $bob')));
  });

  testWidgets('logging out shows the login screen and tells the host', (
    tester,
  ) async {
    var loggedOut = 0;
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      onLoggedOut: () => loggedOut++,
    );

    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(loggedOut, 1);
  });

  testWidgets('the host can log out through the controller', (tester) async {
    final controller = TinodeChatController();
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      controller: controller,
    );

    unawaited(controller.logOut());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
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

  testWidgets('a banner shows while the link is restored', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    session.emitStatus(
      const Reconnecting(attempt: 1, retryIn: Duration(seconds: 1)),
    );
    await tester.pump();
    expect(find.text('Reconnecting…'), findsOneWidget);
    expect(find.text('Hi Alice'), findsOneWidget);

    session.emitStatus(const Connected());
    await tester.pumpAndSettle();
    expect(find.text('Reconnecting…'), findsNothing);
  });

  group('in the background', () {
    Future<void> setLifecycle(
      WidgetTester tester,
      List<AppLifecycleState> states,
    ) async {
      states.forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump();
    }

    const hide = [AppLifecycleState.inactive, AppLifecycleState.hidden];
    const show = [AppLifecycleState.inactive, AppLifecycleState.resumed];

    testWidgets('the session is suspended after the grace period', (
      tester,
    ) async {
      await pumpTinodeChat(tester, session);
      await setLifecycle(tester, hide);

      await tester.pump(const Duration(seconds: 14));
      expect(session.calls, isNot(contains('suspend')));
      await tester.pump(const Duration(seconds: 1));
      expect(session.calls, contains('suspend'));

      await setLifecycle(tester, show);
      expect(session.calls.last, 'resume');
    });

    testWidgets('coming back within the grace keeps the socket', (
      tester,
    ) async {
      await pumpTinodeChat(tester, session);
      await setLifecycle(tester, hide);
      await tester.pump(const Duration(seconds: 5));
      await setLifecycle(tester, show);

      await tester.pump(const Duration(minutes: 1));
      expect(session.calls, isNot(contains('suspend')));
      expect(session.calls, contains('resume'));
    });
  });

  group('network changes', () {
    late FakeNetworkMonitor network;

    Future<void> pumpLoggedIn(WidgetTester tester) {
      network = FakeNetworkMonitor();
      return pumpTinodeChat(
        tester,
        session,
        credentials: TinodeCredentials.token(session.token),
        network: network,
      );
    }

    List<String> resumes() =>
        session.calls.where((c) => c.startsWith('resume')).toList();

    testWidgets('probe a connected socket once reports settle', (tester) async {
      await pumpLoggedIn(tester);

      network.report(available: false);
      await tester.pump(const Duration(milliseconds: 500));
      network.report(available: true);
      await tester.pump(const Duration(milliseconds: 900));
      expect(resumes(), isEmpty);

      await tester.pump(const Duration(milliseconds: 100));
      expect(resumes(), ['resume probe 4s']);
    });

    testWidgets('while reconnecting, a network back retries at once', (
      tester,
    ) async {
      await pumpLoggedIn(tester);
      session.emitStatus(
        const Reconnecting(attempt: 2, retryIn: Duration.zero),
      );

      network.report(available: false);
      await tester.pump(const Duration(seconds: 2));
      expect(resumes(), isEmpty);

      network.report(available: true);
      await tester.pump(const Duration(seconds: 1));
      expect(resumes(), ['resume']);
    });

    testWidgets('a suspended session is not woken', (tester) async {
      await pumpLoggedIn(tester);
      session.emitStatus(const Suspended());

      network.report(available: true);
      await tester.pump(const Duration(seconds: 2));
      expect(resumes(), isEmpty);
    });

    testWidgets('a failing monitor is ignored', (tester) async {
      await pumpLoggedIn(tester);

      network.fail(Exception('no NetworkManager'));
      await tester.pump();
      network.report(available: true);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Bob'), findsOneWidget);
      expect(resumes(), ['resume probe 4s']);
    });
  });

  testWidgets('removing the widget closes the session', (tester) async {
    await pumpTinodeChat(tester, session);

    await tester.pumpWidget(const SizedBox());

    expect(session.isClosed, isTrue);
  });
}
