import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/account/presentation/account_screen.dart';
import 'package:tinode_flutter_chat/src/account/presentation/change_password_screen.dart';
import 'package:tinode_flutter_chat/src/app/presentation/home/home_tab_bar.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession()..profile = const Profile(name: 'Alice');
  });

  Finder field(String label) => find.widgetWithText(TextField, label);

  Finder changeButton() =>
      find.widgetWithText(FilledButton, strings.changePassword);

  /// Opens the account screen from the settings tab.
  Future<void> openAccount(
    WidgetTester tester, {
    VoidCallback? onLoggedOut,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      tabBar: true,
      onLoggedOut: onLoggedOut,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(HomeTabBar),
        matching: find.text(strings.settingsTitle),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.account));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
  }

  Future<void> openPasswordChange(WidgetTester tester) async {
    await openAccount(tester);
    await tester.tap(find.text(strings.changePassword));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  }

  testWidgets('holds the password, logging out and deleting the account', (
    tester,
  ) async {
    await openAccount(tester);

    expect(find.text(strings.changePassword), findsOneWidget);
    expect(find.text(strings.logOut), findsOneWidget);
    expect(find.text(strings.deleteAccount), findsOneWidget);
    // Back to the settings.
    expect(find.text(strings.settingsTitle), findsWidgets);
  });

  testWidgets('changes the password, typed twice, and keeps the login', (
    tester,
  ) async {
    await openPasswordChange(tester);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.widget<FilledButton>(changeButton()).onPressed, isNull);

    await tester.enterText(field(strings.newPasswordField), 'new-pw');
    await tester.enterText(field(strings.confirmNewPasswordField), 'new-pw');
    await tester.pump();
    await tester.tap(changeButton());
    await tester.pumpAndSettle();

    expect(session.changedPassword, 'new-pw');
    expect(session.changedLogin, isNull);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text(strings.passwordChanged), findsOneWidget);
  });

  testWidgets('passwords that differ say so and send nothing', (tester) async {
    await openPasswordChange(tester);

    await tester.enterText(field(strings.newPasswordField), 'new-pw');
    await tester.enterText(field(strings.confirmNewPasswordField), 'new-pv');
    await tester.pump();

    expect(find.text(strings.passwordsDontMatch), findsOneWidget);
    expect(tester.widget<FilledButton>(changeButton()).onPressed, isNull);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(session.changedPassword, isNull);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    await tester.enterText(field(strings.confirmNewPasswordField), 'new-pw');
    await tester.pump();
    expect(find.text(strings.passwordsDontMatch), findsNothing);
    expect(tester.widget<FilledButton>(changeButton()).onPressed, isNotNull);
  });

  testWidgets('logging out shows the login screen and tells the host', (
    tester,
  ) async {
    var loggedOut = 0;
    await openAccount(tester, onLoggedOut: () => loggedOut++);

    await tester.tap(find.text(strings.logOut));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(loggedOut, 1);
  });

  testWidgets('deletes the account after asking', (tester) async {
    var loggedOut = false;
    await openAccount(tester, onLoggedOut: () => loggedOut = true);

    await tester.tap(find.text(strings.deleteAccount));
    await tester.pumpAndSettle();
    expect(find.text(strings.deleteAccountConfirm), findsOneWidget);
    await tester.tap(find.text(strings.cancel));
    await tester.pumpAndSettle();
    expect(session.accountDeleted, isFalse);

    await tester.tap(find.text(strings.deleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(strings.deleteAccount),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.accountDeleted, isTrue);
    expect(loggedOut, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('without the tab bar the menu opens the account, and has no '
      'log out of its own', (tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();

    expect(find.text(strings.profile), findsOneWidget);
    expect(find.text(strings.logOut), findsNothing);

    await tester.tap(find.text(strings.account));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text(strings.chatListTitle), findsWidgets);
    expect(find.text(strings.logOut), findsOneWidget);
  });
}
