import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
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

  Future<void> openProfile(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      attachmentPicker: picker,
    );
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.profile));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  }

  testWidgets('edits only the name; the note stays as it was', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.text('Alice'), findsOneWidget);
    // The photo and the name, nothing else to edit.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Hiking'), findsNothing);
    expect(find.text(strings.changePassword), findsNothing);
    expect(find.text(strings.deleteAccount), findsNothing);

    await tester.enterText(field(strings.nameField), 'Alicia');
    await tester.tap(find.text(strings.save));
    await tester.pumpAndSettle();

    expect(session.profile?.name, 'Alicia');
    expect(session.profile?.note, 'Hiking');
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
}
