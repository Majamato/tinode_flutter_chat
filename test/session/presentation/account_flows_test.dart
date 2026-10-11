import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/session/presentation/confirm_email_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/password_reset_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() => session = FakeTinodeSession());

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('sign up', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await tester.tap(find.text(strings.createAccountLink));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
    }

    testWidgets('creates the account and opens the chat list', (tester) async {
      LoginResult? loggedIn;
      await pumpTinodeChat(tester, session, onLoggedIn: (r) => loggedIn = r);
      await openSignUp(tester);

      final button = find.widgetWithText(FilledButton, strings.signUp);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(field(strings.displayNameField), 'Carol');
      await tester.enterText(field(strings.loginField), 'carol');
      await tester.enterText(field(strings.passwordField), 'carol123');
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(session.calls, contains('createAccount carol Carol'));
      expect(find.text(strings.chatListTitle), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(loggedIn?.token, session.token);
    });

    testWidgets('a taken login says so and stays', (tester) async {
      await pumpTinodeChat(tester, session);
      await openSignUp(tester);

      await tester.enterText(field(strings.displayNameField), 'Alice');
      await tester.enterText(field(strings.loginField), 'alice');
      await tester.enterText(field(strings.passwordField), 'pw');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, strings.signUp));
      await tester.pumpAndSettle();

      expect(find.text(strings.loginTaken), findsOneWidget);
      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('back returns to the login screen', (tester) async {
      await pumpTinodeChat(tester, session);
      await openSignUp(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('email confirmation', () {
    setUp(() => session.requireEmails());

    testWidgets('a sign-up needs the email, then its mailed code', (
      tester,
    ) async {
      await pumpTinodeChat(tester, session);
      await tester.tap(find.text(strings.createAccountLink));
      await tester.pumpAndSettle();
      expect(field(strings.emailOptionalField), findsNothing);

      await tester.enterText(field(strings.displayNameField), 'Carol');
      await tester.enterText(field(strings.loginField), 'carol');
      await tester.enterText(field(strings.passwordField), 'carol123');
      await tester.pump();
      final button = find.widgetWithText(FilledButton, strings.signUp);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(field(strings.emailField), 'carol@example.com');
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);

      await tester.enterText(field(strings.resetCodeField), '000000');
      await tester.pump();
      await tester.tap(find.text(strings.confirm));
      await tester.pumpAndSettle();
      expect(find.text(strings.wrongResetCode), findsOneWidget);

      await tester.enterText(field(strings.resetCodeField), '654321');
      await tester.tap(find.text(strings.confirm));
      await tester.pumpAndSettle();
      expect(find.text(strings.chatListTitle), findsOneWidget);
    });

    testWidgets('a login whose email waits for its code asks for it', (
      tester,
    ) async {
      session
        ..accounts['carol'] = 'carol123'
        ..emailCodes['carol'] = '654321';
      await pumpTinodeChat(tester, session);

      await tester.enterText(field(strings.loginField), 'carol');
      await tester.enterText(field(strings.passwordField), 'carol123');
      await tester.tap(find.widgetWithText(FilledButton, strings.signIn));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);

      await tester.enterText(field(strings.resetCodeField), '654321');
      await tester.pump();
      await tester.tap(find.text(strings.confirm));
      await tester.pumpAndSettle();
      expect(find.text(strings.chatListTitle), findsOneWidget);
    });
  });

  group('the links the login screen offers', () {
    Finder signUp() => find.text(strings.createAccountLink);
    Finder reset() => find.text(strings.forgotPassword);

    testWidgets('by default sign-up, but no reset without email', (
      tester,
    ) async {
      await pumpTinodeChat(tester, session);
      expect(signUp(), findsOneWidget);
      expect(reset(), findsNothing);
    });

    testWidgets('by default a reset where the server requires email', (
      tester,
    ) async {
      session.requireEmails();
      await pumpTinodeChat(tester, session);
      expect(reset(), findsOneWidget);
    });

    testWidgets('as the host switches them', (tester) async {
      await pumpTinodeChat(
        tester,
        session,
        features: const TinodeChatFeatures(
          signUp: false,
          passwordReset: PasswordResetMode.always,
        ),
      );
      expect(signUp(), findsNothing);
      expect(reset(), findsOneWidget);
    });

    testWidgets('never hides the reset even where email is required', (
      tester,
    ) async {
      session.requireEmails();
      await pumpTinodeChat(
        tester,
        session,
        features: const TinodeChatFeatures(
          passwordReset: PasswordResetMode.never,
        ),
      );
      expect(reset(), findsNothing);
    });
  });

  testWidgets('a reset code sets a new password, then the user signs in', (
    tester,
  ) async {
    session.requireEmails();
    await pumpTinodeChat(tester, session);
    await tester.tap(find.text(strings.forgotPassword));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordResetScreen), findsOneWidget);

    await tester.enterText(field(strings.emailField), 'alice@example.com');
    await tester.tap(find.text(strings.sendResetCode));
    await tester.pumpAndSettle();
    expect(find.text(strings.resetCodeSent), findsOneWidget);

    await tester.enterText(field(strings.resetCodeField), '000000');
    await tester.enterText(field(strings.newPasswordField), 'new-pw');
    await tester.tap(find.text(strings.setPassword));
    await tester.pumpAndSettle();
    expect(find.text(strings.wrongResetCode), findsOneWidget);

    await tester.enterText(field(strings.resetCodeField), '123456');
    await tester.tap(find.text(strings.setPassword));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(strings.passwordResetDone), findsOneWidget);
    expect(session.passwords['alice'], 'new-pw');
  });
}
