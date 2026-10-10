import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_preview_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_viewer_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/outgoing_attachment_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/ref_photo_avatar.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const reportRef = '/v0/file/s/report.pdf';

DataMessage fileMessage(int seq) => DataMessage(
  topic: bob,
  seq: seq,
  from: bob,
  time: at(seq),
  head: const MessageHead(mime: MessageHead.draftyMime),
  content: DraftyContent(
    Drafty.file(
      const DraftyFile(
        name: 'report.pdf',
        mimeType: 'application/pdf',
        size: 2048,
        ref: reportRef,
      ),
      caption: 'The report',
    ),
  ),
);

void main() {
  late FakeTinodeSession session;
  late FakeAttachmentPicker picker;
  late List<LocalFile> opened;
  late bool openWorks;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, read: 1, lastMessageAt: at(1)),
      ],
      histories: {
        bob: [fileMessage(1)],
      },
    );
    session.files[reportRef] = pngBytes;
    picker = FakeAttachmentPicker();
    opened = [];
    openWorks = true;
  });

  Future<void> openBob(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      attachmentPicker: picker,
      fileOpener: (file, {mimeType}) async {
        opened.add(file);
        return openWorks;
      },
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromMenu(WidgetTester tester, String entry) async {
    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  testWidgets('sends a photo with a caption, then shows and opens it', (
    tester,
  ) async {
    await openBob(tester);
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );

    await chooseFromMenu(tester, 'Photo');
    expect(picker.picks, [AttachmentSource.gallery]);
    expect(find.byType(AttachmentPreviewScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sunset');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentPreviewScreen), findsNothing);
    expect(
      session.calls,
      containsAllInOrder(['upload sunset.png', 'publish $bob   Sunset']),
    );
    expect(find.byType(ImageBubbleContent), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    // Sent from here: shown from the cache, never downloaded.
    expect(session.calls, isNot(contains(startsWith('download'))));

    await tester.tap(find.byType(ImageBubbleContent));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewerScreen), findsOneWidget);
  });

  testWidgets('a received file downloads and opens on tap', (tester) async {
    await openBob(tester);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('The report'), findsOneWidget);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(session.calls, contains('download $reportRef'));
    expect(opened.single.length, pngBytes.length);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a file nothing opens says so', (tester) async {
    openWorks = false;
    await openBob(tester);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('No app on this device opens this file.'), findsOneWidget);
  });

  testWidgets('a failed download says so', (tester) async {
    session.failDownload = const ServerException(404, 'not found');
    await openBob(tester);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('The file could not be downloaded.'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('without a camera the menu offers none', (tester) async {
    picker.hasCamera = false;
    await openBob(tester);

    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pumpAndSettle();

    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);
  });

  testWidgets('a file over the limit is refused, naming the limit', (
    tester,
  ) async {
    session.serverInfo = const ServerInfo(
      version: '0.25',
      maxFileUploadSize: 4,
    );
    await openBob(tester);
    picker.next = pickedText('notes.txt', 'hello');

    await chooseFromMenu(tester, 'File');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(
      find.text('The file is too large to send: the limit is 4 B.'),
      findsOneWidget,
    );
    expect(session.calls, isNot(contains(startsWith('upload'))));
  });

  testWidgets('upload progress rebuilds only the ring', (tester) async {
    await openBob(tester);
    final steps = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'big.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Photo');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(OutgoingAttachmentView), findsOneWidget);

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, _) =>
        rebuilt.add(element.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    for (final sent in [10, 30, 50]) {
      steps.add(sent);
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(rebuilt, contains('UploadProgressRing'));
    expect(
      rebuilt.where((w) => w.contains('Bubble') || w.contains('Message')),
      isEmpty,
    );

    debugOnRebuildDirtyWidget = null;
    await steps.close();
    await tester.pumpAndSettle();
    expect(find.byType(ImageBubbleContent), findsOneWidget);
  });

  testWidgets('a profile photo given by ref shows once downloaded', (
    tester,
  ) async {
    const photoRef = '/v0/file/s/bob.png';
    session.files[photoRef] = pngBytes;
    session.chats
      ..clear()
      ..add(
        Subscription(
          topic: bob,
          lastSeq: 1,
          read: 1,
          lastMessageAt: at(1),
          public: const Profile(
            name: 'Bob',
            photo: ProfilePhoto(type: 'png', ref: photoRef),
          ),
        ),
      );

    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    expect(session.calls, contains('download $photoRef'));
    final avatar = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byType(RefPhotoAvatar),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(avatar.backgroundImage, isNotNull);
  });
}
