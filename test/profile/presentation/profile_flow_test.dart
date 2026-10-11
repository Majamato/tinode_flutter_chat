import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/change_password_screen.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;
  late FakeAttachmentPicker picker;

  setUp(() {
    session = FakeTinodeSession()
      ..profile = const Profile(name: 'Alice', note: 'Hiking');
    picker = FakeAttachmentPicker(hasCamera: false);
  });

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> openProfile(
    WidgetTester tester, {
    VoidCallback? onLoggedOut,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      attachmentPicker: picker,
      onLoggedOut: onLoggedOut,
    );
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.profile));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  }

  testWidgets('edits the name and note', (tester) async {
    await openProfile(tester);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hiking'), findsOneWidget);

    await tester.enterText(field(strings.nameField), 'Alicia');
    await tester.enterText(field(strings.noteField), 'Climbing');
    await tester.tap(find.text(strings.save));
    await tester.pumpAndSettle();

    expect(session.profile?.name, 'Alicia');
    expect(session.profile?.note, 'Climbing');
    expect(find.text(strings.profileSaved), findsOneWidget);
  });

  testWidgets('a new photo from the gallery', (tester) async {
    await openProfile(tester);
    picker.next = pickedFile(
      'me.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );

    await tester.tap(find.byTooltip(strings.changePhoto));
    await tester.pumpAndSettle();

    expect(session.profile?.photo?.ref, startsWith('/v0/file/s/'));
    expect(session.profile?.name, 'Alice');
  });

  testWidgets('changes the password', (tester) async {
    await openProfile(tester);
    await tester.tap(find.text(strings.changePassword));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    await tester.enterText(field(strings.newPasswordField), 'new-pw');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, strings.changePassword));
    await tester.pumpAndSettle();

    expect(session.changedPassword, 'new-pw');
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text(strings.passwordChanged), findsOneWidget);
  });

  testWidgets('deletes the account after asking', (tester) async {
    var loggedOut = false;
    await openProfile(tester, onLoggedOut: () => loggedOut = true);

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
}
